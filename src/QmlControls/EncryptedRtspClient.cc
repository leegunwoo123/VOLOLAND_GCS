#include "EncryptedRtspClient.h"

#include "QGCCorePlugin.h"
#include "QGCLoggingCategory.h"

#include <QtCore/QDateTime>
#include <QtCore/QRegularExpression>
#include <QtCore/QtEndian>
#include <QtCore/QTimer>
#include <QtCore/QUrlQuery>
#include <QtNetwork/QAbstractSocket>
#include <QtNetwork/QTcpSocket>
#include <QtQuick/QQuickItem>

#include <cstring>

#ifdef QGC_GST_STREAMING
#include <gst/gst.h>
#endif

QGC_LOGGING_CATEGORY(EncryptedRtspClientLog, "qgc.encryptedrtsp.client")

namespace {
constexpr quint16 kDefaultRtspPort = 554;
constexpr qsizetype kMaxPlainBufferBytes = 8 * 1024 * 1024;
constexpr qsizetype kMaxInterleavedPayload = 2 * 1024 * 1024;
constexpr qsizetype kMinRtpHeaderBytes = 12;

constexpr int kDiagSampleSize = 40;
constexpr int kDiagInvalidLimit = kDiagSampleSize / 2;
constexpr int kCorruptInvalidLimit = 3;
constexpr int kSeqAnomalyLimit = 3;
constexpr qint64 kNoRtspTimeoutMs = 5000;
constexpr qint64 kNoRtpTimeoutMs = 3000;
constexpr int kWatchIntervalMs = 500;

int diagnosisRank(EncryptedRtspClient::Diagnosis diagnosis)
{
    return static_cast<int>(diagnosis);
}
}

EncryptedRtspClient::EncryptedRtspClient(QObject *parent)
    : QObject(parent)
{
}

EncryptedRtspClient::~EncryptedRtspClient()
{
    stop();
}

bool EncryptedRtspClient::start(const QUrl &remoteUrl,
                                TngVideoCryptoService::SpeedMode mode,
                                QQuickItem *videoOutput,
                                QString *error)
{
#ifdef QGC_GST_STREAMING
    stop();
    _stopping = false;

    if (!videoOutput) {
        if (error) {
            *error = QStringLiteral("encrypted RTSP requires a video output item");
        }
        return false;
    }

    if (!remoteUrl.isValid()
        || remoteUrl.scheme().compare(QLatin1String("rtsp"), Qt::CaseInsensitive) != 0
        || remoteUrl.host().isEmpty()) {
        if (error) {
            *error = QStringLiteral("encrypted video requires a valid rtsp:// URL");
        }
        return false;
    }

    const QString rtpTransport =
        QUrlQuery(remoteUrl).queryItemValue(QStringLiteral("rtsp_transport")).trimmed().toLower();
    if (rtpTransport != QLatin1String("tcp")) {
        if (error) {
            *error = QStringLiteral("encrypted RTSP requires rtp_transport=tcp");
        }
        return false;
    }

    _remoteUrl = remoteUrl;
    _videoOutput = videoOutput;
    _mode = mode;
    _cseq = 0;
    _phase = RtspPhase::Connecting;
    _session.clear();
    _trackUri.clear();
    _encodingName.clear();
    _plainBuffer.clear();
    _videoRtpChannel = 0;
    _videoRtcpChannel = 1;
    _payloadType = 96;
    _clockRate = 90000;

    const QUrl locationUrl = remoteUrl.adjusted(QUrl::RemoveQuery | QUrl::RemoveFragment);
    _requestUri = locationUrl.toString(QUrl::FullyEncoded).toUtf8();
    _baseUri = _requestUri;
    if (!_baseUri.endsWith('/')) {
        _baseUri.append('/');
    }

    _resetDiagnosisState();

    if (!TngVideoCryptoService::instance().acquire(mode, error)) {
        _phase = RtspPhase::Idle;
        return false;
    }
    _cryptoAcquired = true;

    _socket = new QTcpSocket(this);
    connect(_socket, &QTcpSocket::connected, this, &EncryptedRtspClient::_onConnected);
    connect(_socket, &QTcpSocket::readyRead, this, &EncryptedRtspClient::_onReadyRead);
    connect(_socket, &QTcpSocket::disconnected, this, [this]() {
        if (!_stopping) {
            emit sessionEnded(tr("서버 연결이 끊어져 세션을 종료했습니다"));
            stop();
        }
    });
    connect(_socket, &QTcpSocket::errorOccurred, this, [this](QAbstractSocket::SocketError error) {
        if (_stopping || !_socket) {
            return;
        }
        if (error == QAbstractSocket::RemoteHostClosedError) {
            emit sessionEnded(tr("서버 연결이 끊어져 세션을 종료했습니다"));
            stop();
            return;
        }
        _fail(QStringLiteral("encrypted RTSP upstream error: %1").arg(_socket->errorString()));
    });

    if (!_watchTimer) {
        _watchTimer = new QTimer(this);
        connect(_watchTimer, &QTimer::timeout, this, &EncryptedRtspClient::_checkDataFlow);
    }
    _watchTimer->start(kWatchIntervalMs);

    const quint16 port = static_cast<quint16>(remoteUrl.port(kDefaultRtspPort));
    qCDebug(EncryptedRtspClientLog) << "Connecting encrypted RTSP" << remoteUrl.host() << port;
    _socket->connectToHost(remoteUrl.host(), port);
    return true;
#else
    Q_UNUSED(remoteUrl);
    Q_UNUSED(mode);
    Q_UNUSED(videoOutput);
    if (error) {
        *error = QStringLiteral("GStreamer streaming is not enabled");
    }
    return false;
#endif
}

void EncryptedRtspClient::stop()
{
    _stopping = true;
    _phase = RtspPhase::Idle;

    if (_busTimer) {
        _busTimer->stop();
        _busTimer->deleteLater();
        _busTimer = nullptr;
    }

    // 진단 메시지는 지우지 않는다. 재연결 루프에서 오버레이가 깜빡이지 않도록
    // 다음 세션이 정상 데이터를 확인했을 때만 _clearDiagnosis()로 해제된다.
    if (_watchTimer) {
        _watchTimer->stop();
        _watchTimer->deleteLater();
        _watchTimer = nullptr;
    }

    if (_socket) {
        _socket->disconnect(this);
        if (!_session.isEmpty() && _socket->state() == QAbstractSocket::ConnectedState) {
            // best-effort; ignore write failures during teardown
            ++_cseq;
            const QByteArray teardown =
                "TEARDOWN " + _requestUri + " RTSP/1.0\r\n"
                "CSeq: " + QByteArray::number(_cseq) + "\r\n"
                "Session: " + _session + "\r\n"
                "\r\n";
            _sendRtsp(teardown);
        }
        _socket->abort();
        _socket->deleteLater();
        _socket = nullptr;
    }

    _teardownPipeline();

    _plainBuffer.clear();
    _session.clear();
    _trackUri.clear();
    _encodingName.clear();
    _videoOutput = nullptr;

    if (_cryptoAcquired) {
        TngVideoCryptoService::instance().release();
        _cryptoAcquired = false;
    }

    _stopping = false;
}

void EncryptedRtspClient::_fail(const QString &message)
{
    if (_stopping) {
        return;
    }
    qCWarning(EncryptedRtspClientLog) << message;
    emit fatalError(message);
}

void EncryptedRtspClient::_resetDiagnosisState()
{
    _lastRtspMs = QDateTime::currentMSecsSinceEpoch();
    _lastRtpMs = 0;
    _lastSeq = 0;
    _haveLastSeq = false;
    _seqAnomalies = 0;
    _sampleChecked = 0;
    _sampleInvalid = 0;
    _invalidAfterSample = 0;
}

void EncryptedRtspClient::_setDiagnosis(Diagnosis diagnosis, const QString &message)
{
    // 더 근본적인 원인이 표시 중이면 덮지 않는다(손상 < 패킷이상 < 복호실패 < 데이터없음).
    if (diagnosisRank(diagnosis) < diagnosisRank(_diagnosis)) {
        return;
    }
    if (_diagnosis == diagnosis && _diagnosisMessage == message) {
        return;
    }

    _diagnosis = diagnosis;
    _diagnosisMessage = message;
    // 콘솔 출력은 CustomRtspReceiver::_setStatus 가 코드 변경 시에만 한 번 한다.
    // 여기서 찍으면 NoServerData 초 카운트·GStreamer WARNING 이 무한 반복된다.
    emit diagnosisChanged(static_cast<int>(diagnosis), message);
}

void EncryptedRtspClient::_clearDiagnosis()
{
    if (_diagnosis == Diagnosis::None) {
        return;
    }
    _diagnosis = Diagnosis::None;
    _diagnosisMessage.clear();
    emit diagnosisChanged(static_cast<int>(Diagnosis::None), QString());
}

void EncryptedRtspClient::_checkDataFlow()
{
    if (_stopping || _phase == RtspPhase::Idle) {
        return;
    }

    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    if (_phase == RtspPhase::Streaming) {
        const qint64 since = (_lastRtpMs > 0) ? (now - _lastRtpMs) : (now - _lastRtspMs);
        if (since > kNoRtpTimeoutMs) {
            _setDiagnosis(Diagnosis::NoServerData,
                          tr("서버에서 영상 데이터를 보내지 않습니다\n(%1초간 RTP 없음)")
                              .arg(since / 1000));
        }
    } else if (now - _lastRtspMs > kNoRtspTimeoutMs) {
        // start() 는 connectToHost 직후 true 를 돌려주므로, 요청을 보냈는데 응답이 없는
        // 경우는 StartFailed 가 아니었다. 콘솔/진단도 시작 실패로 올린다.
        QString step;
        switch (_phase) {
        case RtspPhase::Connecting:
            step = QStringLiteral("CONNECT");
            break;
        case RtspPhase::Options:
            step = QStringLiteral("OPTIONS");
            break;
        case RtspPhase::Describe:
            step = QStringLiteral("DESCRIBE");
            break;
        case RtspPhase::Setup:
            step = QStringLiteral("SETUP");
            break;
        case RtspPhase::Play:
            step = QStringLiteral("PLAY");
            break;
        default:
            step = QStringLiteral("RTSP");
            break;
        }
        _setDiagnosis(Diagnosis::StartFailed,
                      _phase == RtspPhase::Connecting
                          ? tr("암호 영상 시작 실패\n서버에 연결되지 않습니다")
                          : tr("암호 영상 시작 실패\n서버가 %1 요청에 응답하지 않습니다").arg(step));
    }
}

void EncryptedRtspClient::_checkRtpSequence(quint16 seq)
{
    if (_haveLastSeq) {
        const auto expected = static_cast<quint16>(_lastSeq + 1);
        if (seq != expected) {
            ++_seqAnomalies;
            if (_seqAnomalies >= kSeqAnomalyLimit) {
                _setDiagnosis(Diagnosis::PacketAnomaly,
                              tr("패킷 이상\n시퀀스 불연속 %1건").arg(_seqAnomalies));
            }
        }
    }
    _lastSeq = seq;
    _haveLastSeq = true;
}

void EncryptedRtspClient::_inspectDecryptedPayload(const QByteArray &plain)
{
    // H.264 외 코덱은 페이로드 헤더 구조가 달라 이 판정을 적용하면 오탐이 난다.
    if (plain.isEmpty() || _encodingName != QLatin1String("H264")) {
        return;
    }

    const auto nal = static_cast<quint8>(plain.at(0));
    const int type = nal & 0x1f;
    const bool valid = ((nal & 0x80) == 0) && (type >= 1) && (type <= 29);

    if (_sampleChecked < kDiagSampleSize) {
        ++_sampleChecked;
        if (!valid) {
            ++_sampleInvalid;
        }
        if (_sampleChecked < kDiagSampleSize) {
            return;
        }

        if (_sampleInvalid > kDiagInvalidLimit) {
            _setDiagnosis(Diagnosis::DecryptFailed,
                          tr("복호화 실패\n알고리즘 및 설정 값 확인 (%1/%2 무효)")
                              .arg(_sampleInvalid)
                              .arg(_sampleChecked));
        } else if (_sampleInvalid > 0) {
            _setDiagnosis(Diagnosis::CorruptAfterDecrypt,
                          tr("복호화 이후 데이터 손상\n(%1/%2 무효 NAL)")
                              .arg(_sampleInvalid)
                              .arg(_sampleChecked));
        } else {
            _clearDiagnosis();
        }
        return;
    }

    if (!valid) {
        ++_invalidAfterSample;
        if (_invalidAfterSample >= kCorruptInvalidLimit) {
            _setDiagnosis(Diagnosis::CorruptAfterDecrypt,
                          tr("복호화 이후 데이터 손상\n(무효 NAL %1건)").arg(_invalidAfterSample));
        }
    }
}

void EncryptedRtspClient::_onConnected()
{
    if (_stopping) {
        return;
    }
    qCDebug(EncryptedRtspClientLog) << "TCP connected, starting RTSP handshake";
    _phase = RtspPhase::Options;
    _sendNextRequest();
}

void EncryptedRtspClient::_onReadyRead()
{
    if (!_socket || _stopping) {
        return;
    }

    // RTSP 제어 채널과 RTP 헤더는 평문이다. 암호문은 RTP 페이로드에만 있다.
    _plainBuffer.append(_socket->readAll());
    if (_plainBuffer.size() > kMaxPlainBufferBytes) {
        _fail(QStringLiteral("RTSP receive buffer exceeded limit"));
        return;
    }
    _consumePlain();
}

void EncryptedRtspClient::_consumePlain()
{
    while (!_plainBuffer.isEmpty()) {
        if (_plainBuffer[0] == '$') {
            if (_plainBuffer.size() < 4) {
                return;
            }
            const auto channel = static_cast<quint8>(_plainBuffer[1]);
            const quint16 payloadLen =
                qFromBigEndian<quint16>(reinterpret_cast<const uchar *>(_plainBuffer.constData() + 2));
            if (payloadLen > kMaxInterleavedPayload) {
                _fail(QStringLiteral("invalid interleaved RTP length: %1").arg(payloadLen));
                return;
            }
            const qsizetype frameSize = 4 + payloadLen;
            if (_plainBuffer.size() < frameSize) {
                return;
            }
            const QByteArray payload = _plainBuffer.sliced(4, payloadLen);
            _plainBuffer.remove(0, frameSize);
            _handleInterleaved(channel, payload);
            if (_stopping || _phase == RtspPhase::Idle) {
                return;
            }
            continue;
        }

        const int headerEnd = _plainBuffer.indexOf("\r\n\r\n");
        if (headerEnd < 0) {
            return;
        }

        const QByteArray headers = _plainBuffer.left(headerEnd);
        const qsizetype headerBytes = headerEnd + 4;
        const QByteArray contentLengthValue = _headerValue(headers, "Content-Length");
        qsizetype bodyLen = 0;
        if (!contentLengthValue.isEmpty()) {
            bool ok = false;
            bodyLen = contentLengthValue.trimmed().toLongLong(&ok);
            if (!ok || bodyLen < 0 || bodyLen > kMaxPlainBufferBytes) {
                _fail(QStringLiteral("invalid RTSP Content-Length"));
                return;
            }
        }

        if (_plainBuffer.size() < headerBytes + bodyLen) {
            return;
        }

        const QByteArray body = _plainBuffer.mid(headerBytes, bodyLen);
        _plainBuffer.remove(0, headerBytes + bodyLen);

        if (!_handleRtspResponse(headers, body)) {
            return;
        }
    }
}

bool EncryptedRtspClient::_sendRtsp(const QByteArray &request)
{
    if (!_socket || _socket->state() != QAbstractSocket::ConnectedState) {
        return false;
    }

    const int eol = request.indexOf('\r');
    qCDebug(EncryptedRtspClientLog) << "RTSP TX" << (eol >= 0 ? request.left(eol) : request);

    if (_socket->write(request) < 0) {
        _fail(QStringLiteral("RTSP write failed: %1").arg(_socket->errorString()));
        return false;
    }
    // 응답 타임아웃은 요청을 실제로 보낸 시점부터 센다.
    _lastRtspMs = QDateTime::currentMSecsSinceEpoch();
    return true;
}

void EncryptedRtspClient::_sendNextRequest()
{
    ++_cseq;
    QByteArray req;

    switch (_phase) {
    case RtspPhase::Options:
        req = "OPTIONS " + _requestUri + " RTSP/1.0\r\n"
              "CSeq: " + QByteArray::number(_cseq) + "\r\n"
              "User-Agent: QGroundControl-EncryptedRtsp/1.0\r\n"
              "\r\n";
        break;
    case RtspPhase::Describe:
        req = "DESCRIBE " + _requestUri + " RTSP/1.0\r\n"
              "CSeq: " + QByteArray::number(_cseq) + "\r\n"
              "Accept: application/sdp\r\n"
              "User-Agent: QGroundControl-EncryptedRtsp/1.0\r\n"
              "\r\n";
        break;
    case RtspPhase::Setup:
        req = "SETUP " + _trackUri + " RTSP/1.0\r\n"
              "CSeq: " + QByteArray::number(_cseq) + "\r\n"
              "Transport: RTP/AVP/TCP;unicast;interleaved=0-1\r\n"
              "User-Agent: QGroundControl-EncryptedRtsp/1.0\r\n"
              "\r\n";
        break;
    case RtspPhase::Play:
        req = "PLAY " + _requestUri + " RTSP/1.0\r\n"
              "CSeq: " + QByteArray::number(_cseq) + "\r\n"
              "Session: " + _session + "\r\n"
              "Range: npt=0.000-\r\n"
              "User-Agent: QGroundControl-EncryptedRtsp/1.0\r\n"
              "\r\n";
        break;
    default:
        return;
    }

    if (!_sendRtsp(req)) {
        return;
    }
}

bool EncryptedRtspClient::_handleRtspResponse(const QByteArray &headers, const QByteArray &body)
{
    const int firstLineEnd = headers.indexOf("\r\n");
    const QByteArray statusLine = firstLineEnd >= 0 ? headers.left(firstLineEnd) : headers;
    qCDebug(EncryptedRtspClientLog) << "RTSP RX" << statusLine;

    _lastRtspMs = QDateTime::currentMSecsSinceEpoch();

    if (!statusLine.startsWith("RTSP/1.0 ")) {
        _fail(QStringLiteral("invalid RTSP response"));
        return false;
    }

    const int code = statusLine.mid(9, 3).toInt();
    if (code == 401 || code == 407) {
        _fail(QStringLiteral("RTSP authentication is not supported"));
        return false;
    }
    if (code < 200 || code >= 300) {
        _fail(QStringLiteral("RTSP request failed: %1").arg(QString::fromLatin1(statusLine)));
        return false;
    }

    switch (_phase) {
    case RtspPhase::Options:
        _phase = RtspPhase::Describe;
        _sendNextRequest();
        return true;

    case RtspPhase::Describe: {
        const QByteArray contentBase = _headerValue(headers, "Content-Base");
        const QByteArray contentLocation = _headerValue(headers, "Content-Location");
        if (!contentBase.isEmpty()) {
            _baseUri = contentBase.trimmed();
        } else if (!contentLocation.isEmpty()) {
            _baseUri = contentLocation.trimmed();
        }
        if (!_baseUri.endsWith('/')) {
            _baseUri.append('/');
        }
        if (!_parseSdp(body)) {
            return false;
        }
        QString pipeError;
        if (!_buildPipeline(&pipeError)) {
            _fail(pipeError);
            return false;
        }
        _phase = RtspPhase::Setup;
        _sendNextRequest();
        return true;
    }

    case RtspPhase::Setup: {
        _session = _headerValue(headers, "Session");
        const int semicolon = _session.indexOf(';');
        if (semicolon >= 0) {
            _session = _session.left(semicolon);
        }
        _session = _session.trimmed();
        if (_session.isEmpty()) {
            _fail(QStringLiteral("SETUP response missing Session"));
            return false;
        }
        if (!_parseSetupTransport(headers)) {
            return false;
        }
        _phase = RtspPhase::Play;
        _sendNextRequest();
        return true;
    }

    case RtspPhase::Play:
        _phase = RtspPhase::Streaming;
        qCDebug(EncryptedRtspClientLog) << "PLAY ok, streaming interleaved RTP"
                                        << "encoding" << _encodingName
                                        << "rtp-ch" << _videoRtpChannel;
        return true;

    default:
        return true;
    }
}

bool EncryptedRtspClient::_parseSdp(const QByteArray &sdp)
{
    const QList<QByteArray> lines = sdp.split('\n');
    bool inVideo = false;
    QByteArray control;
    QString encoding;
    int clockRate = 90000;
    int payloadType = -1;

    for (QByteArray line : lines) {
        if (line.endsWith('\r')) {
            line.chop(1);
        }
        if (line.startsWith("m=")) {
            inVideo = line.startsWith("m=video");
            if (inVideo) {
                const QList<QByteArray> parts = line.split(' ');
                if (parts.size() >= 4) {
                    bool ok = false;
                    const int pt = parts.last().toInt(&ok);
                    if (ok) {
                        payloadType = pt;
                    }
                }
                control.clear();
                encoding.clear();
            }
            continue;
        }
        if (!inVideo) {
            continue;
        }
        if (line.startsWith("a=control:")) {
            control = line.mid(10).trimmed();
        } else if (line.startsWith("a=rtpmap:")) {
            // a=rtpmap:<pt> <encoding>/<clock>[/channels]
            const QByteArray value = line.mid(9).trimmed();
            const int space = value.indexOf(' ');
            if (space <= 0) {
                continue;
            }
            bool ok = false;
            const int pt = value.left(space).toInt(&ok);
            if (!ok) {
                continue;
            }
            payloadType = pt;
            const QByteArray rest = value.mid(space + 1);
            const int slash = rest.indexOf('/');
            encoding = QString::fromLatin1(slash >= 0 ? rest.left(slash) : rest).trimmed().toUpper();
            if (slash >= 0) {
                const QByteArray ratePart = rest.mid(slash + 1);
                const int nextSlash = ratePart.indexOf('/');
                clockRate = (nextSlash >= 0 ? ratePart.left(nextSlash) : ratePart).toInt(&ok);
                if (!ok || clockRate <= 0) {
                    clockRate = 90000;
                }
            }
        }
    }

    if (encoding.isEmpty()) {
        _fail(QStringLiteral("SDP has no video rtpmap (H264/H265/etc)"));
        return false;
    }

    // QGC Video Source에 대응하는 RTSP/RTP 코덱. decodebin이 플러그 가능한 범위.
    static const QStringList kSupported = {
        QStringLiteral("H264"),
        QStringLiteral("H265"),
        QStringLiteral("HEVC"),
        QStringLiteral("MP4V-ES"),
        QStringLiteral("JPEG"),
        QStringLiteral("MP2T"),
    };
    if (!kSupported.contains(encoding)) {
        _fail(QStringLiteral("unsupported RTP encoding in SDP: %1").arg(encoding));
        return false;
    }
    if (encoding == QLatin1String("HEVC")) {
        encoding = QStringLiteral("H265");
    }

    if (control.isEmpty()) {
        _fail(QStringLiteral("SDP video track missing a=control"));
        return false;
    }

    if (control.size() >= 7
        && control.first(7).compare("rtsp://", Qt::CaseInsensitive) == 0) {
        _trackUri = control;
    } else if (control == "*") {
        _trackUri = _requestUri;
    } else {
        _trackUri = _baseUri + control;
    }

    _encodingName = encoding;
    _clockRate = clockRate;
    if (payloadType >= 0) {
        _payloadType = payloadType;
    }

    qCDebug(EncryptedRtspClientLog) << "SDP video" << _encodingName << "pt" << _payloadType
                                    << "rate" << _clockRate << "track" << _trackUri;
    return true;
}

bool EncryptedRtspClient::_parseSetupTransport(const QByteArray &headers)
{
    const QByteArray transport = _headerValue(headers, "Transport");
    if (transport.isEmpty()) {
        _fail(QStringLiteral("SETUP response missing Transport"));
        return false;
    }

    static const QRegularExpression re(QStringLiteral("interleaved=(\\d+)-(\\d+)"));
    const QRegularExpressionMatch match = re.match(QString::fromLatin1(transport));
    if (!match.hasMatch()) {
        _fail(QStringLiteral("SETUP Transport missing interleaved channels: %1")
                  .arg(QString::fromLatin1(transport)));
        return false;
    }

    _videoRtpChannel = match.captured(1).toInt();
    _videoRtcpChannel = match.captured(2).toInt();
    return true;
}

bool EncryptedRtspClient::_buildPipeline(QString *error)
{
#ifdef QGC_GST_STREAMING
    _teardownPipeline();

    _videoSink = QGCCorePlugin::instance()->createVideoSink(_videoOutput, this);
    if (!_videoSink) {
        if (error) {
            *error = QStringLiteral("createVideoSink failed");
        }
        return false;
    }

    GstElement *pipeline = gst_pipeline_new("encrypted-rtsp");
    GstElement *appsrc = gst_element_factory_make("appsrc", "enc-rtsp-appsrc");
    GstElement *jitter = gst_element_factory_make("rtpjitterbuffer", "enc-rtsp-jitter");
    GstElement *decode = gst_element_factory_make("decodebin3", "enc-rtsp-decode");
    GstElement *queue = gst_element_factory_make("queue", "enc-rtsp-queue");
    auto *sink = static_cast<GstElement *>(_videoSink);

    if (!pipeline || !appsrc || !jitter || !decode || !queue || !sink) {
        if (error) {
            *error = QStringLiteral("failed to create GStreamer elements for encrypted RTSP");
        }
        if (pipeline) {
            gst_object_unref(pipeline);
        }
        if (appsrc) {
            gst_object_unref(appsrc);
        }
        if (jitter) {
            gst_object_unref(jitter);
        }
        if (decode) {
            gst_object_unref(decode);
        }
        if (queue) {
            gst_object_unref(queue);
        }
        _teardownPipeline();
        return false;
    }

    const QString capsStr = QStringLiteral(
                                "application/x-rtp, media=(string)video, clock-rate=(int)%1, "
                                "encoding-name=(string)%2, payload=(int)%3")
                                .arg(_clockRate)
                                .arg(_encodingName)
                                .arg(_payloadType);
    GstCaps *caps = gst_caps_from_string(capsStr.toUtf8().constData());
    if (!caps) {
        if (error) {
            *error = QStringLiteral("failed to build RTP caps");
        }
        gst_object_unref(pipeline);
        gst_object_unref(appsrc);
        gst_object_unref(jitter);
        gst_object_unref(decode);
        gst_object_unref(queue);
        _teardownPipeline();
        return false;
    }

    g_object_set(appsrc,
                 "is-live", TRUE,
                 "format", GST_FORMAT_TIME,
                 "block", FALSE,
                 "max-bytes", static_cast<guint64>(2 * 1024 * 1024),
                 "caps", caps,
                 nullptr);
    gst_caps_unref(caps);

    g_object_set(jitter, "latency", 50, nullptr);
    g_object_set(sink, "widget", _videoOutput, "sync", FALSE, nullptr);

    gst_bin_add_many(GST_BIN(pipeline), appsrc, jitter, decode, queue, sink, nullptr);
    if (!gst_element_link(appsrc, jitter) || !gst_element_link(jitter, decode)) {
        if (error) {
            *error = QStringLiteral("failed to link appsrc/jitter/decodebin");
        }
        // pipeline owns children after gst_bin_add_many
        gst_element_set_state(pipeline, GST_STATE_NULL);
        gst_object_unref(pipeline);
        _videoSink = nullptr;
        _pipeline = nullptr;
        _appsrc = nullptr;
        return false;
    }
    if (!gst_element_link(queue, sink)) {
        if (error) {
            *error = QStringLiteral("failed to link queue/sink");
        }
        gst_element_set_state(pipeline, GST_STATE_NULL);
        gst_object_unref(pipeline);
        _videoSink = nullptr;
        _pipeline = nullptr;
        _appsrc = nullptr;
        return false;
    }

    g_signal_connect(decode, "pad-added", G_CALLBACK(_onDecodePadAdded), this);

    const GstStateChangeReturn ret = gst_element_set_state(pipeline, GST_STATE_PLAYING);
    if (ret == GST_STATE_CHANGE_FAILURE) {
        if (error) {
            *error = QStringLiteral("failed to set encrypted RTSP pipeline to PLAYING");
        }
        gst_element_set_state(pipeline, GST_STATE_NULL);
        gst_object_unref(pipeline);
        _videoSink = nullptr;
        return false;
    }

    // sink ownership moved into pipeline
    _pipeline = pipeline;
    _appsrc = appsrc;
    _videoSink = nullptr;

    if (!_busTimer) {
        _busTimer = new QTimer(this);
        connect(_busTimer, &QTimer::timeout, this, &EncryptedRtspClient::_pollBus);
    }
    _busTimer->start(100);

    qCDebug(EncryptedRtspClientLog) << "Pipeline ready" << capsStr;
    return true;
#else
    if (error) {
        *error = QStringLiteral("GStreamer streaming is not enabled");
    }
    return false;
#endif
}

void EncryptedRtspClient::_teardownPipeline()
{
#ifdef QGC_GST_STREAMING
    if (_busTimer) {
        _busTimer->stop();
    }

    if (_pipeline) {
        auto *pipeline = static_cast<GstElement *>(_pipeline);
        gst_element_set_state(pipeline, GST_STATE_NULL);
        gst_object_unref(pipeline);
        _pipeline = nullptr;
        _appsrc = nullptr;
    }

    if (_videoSink) {
        QGCCorePlugin::instance()->releaseVideoSink(_videoSink);
        _videoSink = nullptr;
    }
#endif
}

void EncryptedRtspClient::_handleInterleaved(quint8 channel, const QByteArray &payload)
{
    if (_phase != RtspPhase::Streaming && _phase != RtspPhase::Play) {
        return;
    }
    if (channel != static_cast<quint8>(_videoRtpChannel)) {
        return; // RTCP / other
    }
    if (payload.size() < kMinRtpHeaderBytes) {
        _setDiagnosis(Diagnosis::PacketAnomaly,
                      tr("패킷 이상\nRTP 헤더 길이 부족 (%1바이트)").arg(payload.size()));
        return;
    }

    _lastRtpMs = QDateTime::currentMSecsSinceEpoch();

    QByteArray plainRtp;
    if (!_decryptRtpPayload(payload, &plainRtp)) {
        return;
    }
    _pushRtp(plainRtp);
}

bool EncryptedRtspClient::_decryptRtpPayload(const QByteArray &rtp, QByteArray *plainRtp)
{
    const auto *bytes = reinterpret_cast<const quint8 *>(rtp.constData());
    if ((bytes[0] >> 6) != 2) {
        _setDiagnosis(Diagnosis::PacketAnomaly,
                      tr("패킷 이상\nRTP 버전 불일치 (%1)").arg(bytes[0] >> 6));
        _fail(QStringLiteral("unexpected RTP version %1 (payload framing mismatch)").arg(bytes[0] >> 6));
        return false;
    }

    _checkRtpSequence(qFromBigEndian<quint16>(bytes + 2));

    const bool hasPadding = (bytes[0] & 0x20) != 0;
    const bool hasExtension = (bytes[0] & 0x10) != 0;
    qsizetype headerLen = kMinRtpHeaderBytes + 4 * (bytes[0] & 0x0f);

    if (hasExtension) {
        if (rtp.size() < headerLen + 4) {
            qCDebug(EncryptedRtspClientLog) << "RTP extension header truncated, dropping" << rtp.size();
            return false;
        }
        const quint16 extWords = qFromBigEndian<quint16>(bytes + headerLen + 2);
        headerLen += 4 + 4 * static_cast<qsizetype>(extWords);
    }

    // 송신측은 RTP 헤더 뒤부터(FU-A/단일 NAL 헤더 포함) 패킷 단위로 암호화한다.
    qsizetype paddingLen = 0;
    if (hasPadding) {
        paddingLen = static_cast<quint8>(rtp.at(rtp.size() - 1));
    }

    const qsizetype cipherLen = rtp.size() - headerLen - paddingLen;
    if (headerLen >= rtp.size() || cipherLen <= 0) {
        qCDebug(EncryptedRtspClientLog) << "RTP packet has no payload, dropping"
                                        << rtp.size() << headerLen << paddingLen;
        return false;
    }

    QString error;
    const QByteArray plain =
        TngVideoCryptoService::instance().decryptChunk(rtp.sliced(headerLen, cipherLen), _mode, &error);
    if (plain.size() != cipherLen) {
        _setDiagnosis(Diagnosis::DecryptFailed,
                      tr("복호화 실패\n알고리즘 및 설정 값 확인 (%1 -> %2바이트)")
                          .arg(cipherLen)
                          .arg(plain.size()));
        _fail(QStringLiteral("RTP payload decryption failed (%1 -> %2 bytes): %3")
                  .arg(cipherLen)
                  .arg(plain.size())
                  .arg(error));
        return false;
    }

    _inspectDecryptedPayload(plain);

    plainRtp->clear();
    plainRtp->reserve(rtp.size());
    plainRtp->append(rtp.first(headerLen));
    plainRtp->append(plain);
    if (paddingLen > 0) {
        plainRtp->append(rtp.last(paddingLen));
    }
    return true;
}

void EncryptedRtspClient::_onDecodePadAdded(void *decode, void *pad, void *userData)
{
    Q_UNUSED(decode);
    auto *self = static_cast<EncryptedRtspClient *>(userData);
    if (self) {
        self->_linkDecodePad(pad);
    }
}

void EncryptedRtspClient::_linkDecodePad(void *padPtr)
{
#ifdef QGC_GST_STREAMING
    if (!_pipeline || _stopping || !padPtr) {
        return;
    }

    auto *pad = static_cast<GstPad *>(padPtr);
    auto *pipe = static_cast<GstElement *>(_pipeline);
    GstElement *queueEl = gst_bin_get_by_name(GST_BIN(pipe), "enc-rtsp-queue");
    if (!queueEl) {
        return;
    }

    GstPad *sinkPad = gst_element_get_static_pad(queueEl, "sink");
    if (sinkPad && !gst_pad_is_linked(sinkPad)) {
        GstCaps *padCaps = gst_pad_get_current_caps(pad);
        if (!padCaps) {
            padCaps = gst_pad_query_caps(pad, nullptr);
        }
        bool isVideo = false;
        if (padCaps && !gst_caps_is_empty(padCaps)) {
            const GstStructure *st = gst_caps_get_structure(padCaps, 0);
            const gchar *name = st ? gst_structure_get_name(st) : nullptr;
            isVideo = name && g_str_has_prefix(name, "video/");
        }
        if (padCaps) {
            gst_caps_unref(padCaps);
        }
        if (isVideo) {
            gst_pad_link(pad, sinkPad);
        }
    }
    gst_clear_object(&sinkPad);
    gst_object_unref(queueEl);
#else
    Q_UNUSED(padPtr);
#endif
}

void EncryptedRtspClient::_pushRtp(const QByteArray &rtp)
{
#ifdef QGC_GST_STREAMING
    if (!_appsrc || _stopping) {
        return;
    }

    GstBuffer *buffer = gst_buffer_new_allocate(nullptr, static_cast<gsize>(rtp.size()), nullptr);
    if (!buffer) {
        _fail(QStringLiteral("gst_buffer_new_allocate failed"));
        return;
    }

    GstMapInfo map;
    if (!gst_buffer_map(buffer, &map, GST_MAP_WRITE)) {
        gst_buffer_unref(buffer);
        _fail(QStringLiteral("gst_buffer_map failed"));
        return;
    }
    memcpy(map.data, rtp.constData(), static_cast<size_t>(rtp.size()));
    gst_buffer_unmap(buffer, &map);
    GST_BUFFER_DTS(buffer) = GST_CLOCK_TIME_NONE;
    GST_BUFFER_PTS(buffer) = GST_CLOCK_TIME_NONE;

    GstFlowReturn flow = GST_FLOW_ERROR;
    g_signal_emit_by_name(static_cast<GstElement *>(_appsrc), "push-buffer", buffer, &flow);
    gst_buffer_unref(buffer);

    if (flow != GST_FLOW_OK && flow != GST_FLOW_FLUSHING) {
        _fail(QStringLiteral("appsrc push-buffer failed: %1").arg(static_cast<int>(flow)));
    }
#else
    Q_UNUSED(rtp);
#endif
}

void EncryptedRtspClient::_pollBus()
{
#ifdef QGC_GST_STREAMING
    if (!_pipeline || _stopping) {
        return;
    }

    GstBus *bus = gst_element_get_bus(static_cast<GstElement *>(_pipeline));
    if (!bus) {
        return;
    }

    while (true) {
        GstMessage *msg = gst_bus_pop_filtered(
            bus, static_cast<GstMessageType>(GST_MESSAGE_ERROR | GST_MESSAGE_EOS | GST_MESSAGE_WARNING));
        if (!msg) {
            break;
        }
        // 파서·디코더 경고는 복호는 됐지만 비트스트림이 깨진 경우다. 세션을 끊지 않고 표시만 한다.
        if (GST_MESSAGE_TYPE(msg) == GST_MESSAGE_WARNING) {
            GError *warn = nullptr;
            gchar *dbg = nullptr;
            gst_message_parse_warning(msg, &warn, &dbg);
            const QString text = warn ? QString::fromUtf8(warn->message) : QStringLiteral("decode warning");
            g_clear_error(&warn);
            g_free(dbg);
            gst_message_unref(msg);
            _setDiagnosis(Diagnosis::CorruptAfterDecrypt,
                          tr("복호화 이후 데이터 손상\n%1").arg(text));
            continue;
        }
        if (GST_MESSAGE_TYPE(msg) == GST_MESSAGE_ERROR) {
            GError *err = nullptr;
            gchar *dbg = nullptr;
            gst_message_parse_error(msg, &err, &dbg);
            const QString text = err ? QString::fromUtf8(err->message) : QStringLiteral("GStreamer error");
            g_clear_error(&err);
            g_free(dbg);
            gst_message_unref(msg);
            gst_object_unref(bus);
            _fail(QStringLiteral("encrypted RTSP pipeline error: %1").arg(text));
            return;
        }
        if (GST_MESSAGE_TYPE(msg) == GST_MESSAGE_EOS) {
            gst_message_unref(msg);
            gst_object_unref(bus);
            _fail(QStringLiteral("encrypted RTSP pipeline EOS"));
            return;
        }
        gst_message_unref(msg);
    }
    gst_object_unref(bus);
#endif
}

QByteArray EncryptedRtspClient::_headerValue(const QByteArray &headers, const QByteArray &name)
{
    const QList<QByteArray> lines = headers.split('\n');
    const QByteArray prefix = name + ":";
    for (QByteArray line : lines) {
        if (line.endsWith('\r')) {
            line.chop(1);
        }
        if (line.size() >= prefix.size()
            && line.left(prefix.size()).compare(prefix, Qt::CaseInsensitive) == 0) {
            return line.mid(prefix.size()).trimmed();
        }
    }
    return {};
}
