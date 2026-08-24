#pragma once

#include "TngVideoCryptoService.h"

#include <QtCore/QByteArray>
#include <QtCore/QObject>
#include <QtCore/QUrl>

class QQuickItem;
class QTcpSocket;
class QTimer;

class EncryptedRtspClient : public QObject
{
    Q_OBJECT

public:
    /// 화면 중앙 오버레이에 표시할 진단 상태. 값이 클수록 근본 원인에 가깝다.
    enum class Diagnosis {
        None = 0,
        CorruptAfterDecrypt = 1, // 복호화 이후 데이터 손상
        PacketAnomaly = 2,       // RTP 시퀀스/헤더 이상
        DecryptFailed = 3,       // 복호화 실패 (알고리즘·키·IV 불일치)
        NoServerData = 4,        // 서버가 데이터를 주지 않음
        StartFailed = 5,         // 클라이언트를 시작조차 못함 (암호 코어 취득/전송 설정 오류)
        SessionEnded = 6,        // 서버가 끊어져 세션 종료 (재접속 없음)
    };

    explicit EncryptedRtspClient(QObject *parent = nullptr);
    ~EncryptedRtspClient() override;

    bool start(const QUrl &remoteUrl,
               TngVideoCryptoService::SpeedMode mode,
               QQuickItem *videoOutput,
               QString *error = nullptr);
    void stop();

signals:
    void fatalError(const QString &message);
    void sessionEnded(const QString &message);
    void diagnosisChanged(int code, const QString &message);

private:
    enum class RtspPhase {
        Idle,
        Connecting,
        Options,
        Describe,
        Setup,
        Play,
        Streaming,
    };

    void _fail(const QString &message);
    void _onConnected();
    void _onReadyRead();
    void _consumePlain();
    bool _sendRtsp(const QByteArray &request);
    void _sendNextRequest();
    bool _handleRtspResponse(const QByteArray &headers, const QByteArray &body);
    bool _parseSdp(const QByteArray &sdp);
    bool _parseSetupTransport(const QByteArray &headers);
    bool _buildPipeline(QString *error);
    void _teardownPipeline();
    void _pushRtp(const QByteArray &rtp);
    void _pollBus();
    void _handleInterleaved(quint8 channel, const QByteArray &payload);
    /// RTP 헤더는 평문, 페이로드만 암호문인 스트림을 표준 RTP 패킷으로 복원한다.
    bool _decryptRtpPayload(const QByteArray &rtp, QByteArray *plainRtp);
    /// 복호 결과 선두 바이트가 유효한 H.264 NAL/FU 헤더인지 집계해 설정 불일치와 손상을 구분한다.
    void _inspectDecryptedPayload(const QByteArray &plain);
    void _checkRtpSequence(quint16 seq);
    void _checkDataFlow();
    void _setDiagnosis(Diagnosis diagnosis, const QString &message);
    void _clearDiagnosis();
    void _resetDiagnosisState();
    void _linkDecodePad(void *pad);

    static void _onDecodePadAdded(void *decode, void *pad, void *userData);
    static QByteArray _headerValue(const QByteArray &headers, const QByteArray &name);

    QUrl _remoteUrl;
    QByteArray _requestUri;
    QByteArray _baseUri;
    QByteArray _trackUri;
    QByteArray _session;
    QString _encodingName;
    int _clockRate = 90000;
    int _payloadType = 96;
    int _videoRtpChannel = 0;
    int _videoRtcpChannel = 1;
    int _cseq = 0;
    RtspPhase _phase = RtspPhase::Idle;
    TngVideoCryptoService::SpeedMode _mode = TngVideoCryptoService::SpeedMode::Normal;
    bool _cryptoAcquired = false;
    bool _stopping = false;

    QTcpSocket *_socket = nullptr;
    QTimer *_busTimer = nullptr;
    QTimer *_watchTimer = nullptr;
    QQuickItem *_videoOutput = nullptr;

    QByteArray _plainBuffer;

    Diagnosis _diagnosis = Diagnosis::None;
    QString _diagnosisMessage;
    qint64 _lastRtspMs = 0;
    qint64 _lastRtpMs = 0;
    quint16 _lastSeq = 0;
    bool _haveLastSeq = false;
    int _seqAnomalies = 0;
    int _sampleChecked = 0;
    int _sampleInvalid = 0;
    int _invalidAfterSample = 0;

#ifdef QGC_GST_STREAMING
    void *_pipeline = nullptr;
    void *_appsrc = nullptr;
    void *_videoSink = nullptr;
#endif
};
