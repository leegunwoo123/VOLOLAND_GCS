/****************************************************************************
 *
 * DroneVideo 전용 독립 GStreamer RTSP 수신기.
 * VideoManager를 사용하지 않고 자체 파이프라인으로 RTSP 재생.
 *
 ****************************************************************************/

#include "CustomRtspReceiver.h"
#include "QGCCorePlugin.h"
#include "QGCLoggingCategory.h"
#include "VideoReceiver.h"

#include <QtCore/QTimer>
#include <QtQuick/QQuickItem>

QGC_LOGGING_CATEGORY(CustomRtspReceiverLog, "qgc.customrtspreceiver")

CustomRtspReceiver::CustomRtspReceiver(QObject *parent)
    : QObject(parent)
{
}

CustomRtspReceiver::~CustomRtspReceiver()
{
    _stop();
}

void CustomRtspReceiver::setChannelUrl(const QString &url)
{
    if (_channelUrl != url) {
        _channelUrl = url;
        emit channelUrlChanged();
        QTimer::singleShot(0, this, [this]() { _applySourceAndPlay(); });
    }
}

void CustomRtspReceiver::setVideoOutput(QQuickItem *item)
{
    if (_videoOutput != item) {
        _stop();
        _videoOutput = item;
        emit videoOutputChanged();
        QTimer::singleShot(0, this, [this]() { _applySourceAndPlay(); });
    }
}

void CustomRtspReceiver::setStreamEnabled(bool enabled)
{
    if (_streamEnabled != enabled) {
        _streamEnabled = enabled;
        emit streamEnabledChanged();
        if (!enabled)
            _stop();
        else
            QTimer::singleShot(0, this, [this]() { _applySourceAndPlay(); });
    }
}

void CustomRtspReceiver::_applySourceAndPlay()
{
#ifdef QGC_GST_STREAMING
    const QString url = _channelUrl.trimmed();
    if (!_streamEnabled || url.isEmpty() || !_videoOutput) {
        _stop();
        return;
    }

    if (_receiver) {
        if (_receiver->uri() == url)
            return;
        _stop();
    }

    VideoReceiver *receiver = qobject_cast<VideoReceiver*>(QGCCorePlugin::instance()->createVideoReceiver(nullptr));
    if (!receiver) {
        qCWarning(CustomRtspReceiverLog) << "createVideoReceiver failed";
        return;
    }

    void *sink = QGCCorePlugin::instance()->createVideoSink(_videoOutput, receiver);
    if (!sink) {
        qCWarning(CustomRtspReceiverLog) << "createVideoSink failed";
        receiver->deleteLater();
        return;
    }

    receiver->setWidget(_videoOutput);
    receiver->setSink(sink);
    receiver->setUri(url);
    receiver->setLowLatency(true);

    connect(receiver, &VideoReceiver::onStartComplete, this, [this, receiver](VideoReceiver::STATUS status) {
        if (receiver != _receiver)
            return;
        if (status == VideoReceiver::STATUS_OK && receiver->sink()) {
            receiver->startDecoding(receiver->sink());
            qCDebug(CustomRtspReceiverLog) << "Decoding started" << receiver->uri();
        }
    }, Qt::SingleShotConnection);

    connect(receiver, &VideoReceiver::onStopComplete, this, [this, receiver]() {
        QGCCorePlugin::instance()->releaseVideoSink(receiver->sink());
        receiver->disconnect();
        receiver->deleteLater();
        const bool wasActive = (_receiver == receiver);
        if (_receiver == receiver)
            _receiver = nullptr;
        qCDebug(CustomRtspReceiverLog) << "Receiver stopped and released";
        // 송신 측 꺼짐/재기동 등으로 끊겼을 때 자동 재연결
        if (wasActive && _streamEnabled && !_channelUrl.trimmed().isEmpty() && _videoOutput) {
            qCDebug(CustomRtspReceiverLog) << "Scheduling reconnect in 2s";
            QTimer::singleShot(2000, this, [this]() { _applySourceAndPlay(); });
        }
    }, Qt::SingleShotConnection);

    _receiver = receiver;
    receiver->start(5);
    qCDebug(CustomRtspReceiverLog) << "Started" << url;
#else
    Q_UNUSED(_streamEnabled);
    Q_UNUSED(_videoOutput);
    Q_UNUSED(_channelUrl);
#endif
}

void CustomRtspReceiver::_stop()
{
#ifdef QGC_GST_STREAMING
    if (!_receiver)
        return;

    VideoReceiver *receiver = _receiver;
    _receiver = nullptr;

    if (!receiver->started()) {
        QGCCorePlugin::instance()->releaseVideoSink(receiver->sink());
        receiver->deleteLater();
        return;
    }

    connect(receiver, &VideoReceiver::onStopComplete, receiver, [receiver]() {
        QGCCorePlugin::instance()->releaseVideoSink(receiver->sink());
        receiver->disconnect();
        receiver->deleteLater();
    }, Qt::SingleShotConnection);

    receiver->stop();
    qCDebug(CustomRtspReceiverLog) << "Stop requested";
#endif
}
