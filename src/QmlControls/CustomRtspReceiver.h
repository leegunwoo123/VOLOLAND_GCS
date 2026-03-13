/****************************************************************************
 *
 * DroneVideo 전용 독립 GStreamer RTSP 수신기.
 * VideoManager를 사용하지 않고 자체 파이프라인으로 RTSP 재생.
 *
 ****************************************************************************/

#pragma once

#include <QtCore/QObject>
#include <QtQuick/QQuickItem>

class VideoReceiver;

class CustomRtspReceiver : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString channelUrl READ channelUrl WRITE setChannelUrl NOTIFY channelUrlChanged)
    Q_PROPERTY(QQuickItem* videoOutput READ videoOutput WRITE setVideoOutput NOTIFY videoOutputChanged)
    Q_PROPERTY(bool streamEnabled READ streamEnabled WRITE setStreamEnabled NOTIFY streamEnabledChanged)

public:
    explicit CustomRtspReceiver(QObject *parent = nullptr);
    ~CustomRtspReceiver();

    QString channelUrl() const { return _channelUrl; }
    void setChannelUrl(const QString &url);

    QQuickItem* videoOutput() const { return _videoOutput; }
    void setVideoOutput(QQuickItem *item);

    bool streamEnabled() const { return _streamEnabled; }
    void setStreamEnabled(bool enabled);

signals:
    void channelUrlChanged();
    void videoOutputChanged();
    void streamEnabledChanged();

private:
    void _applySourceAndPlay();
    void _stop();

    QString _channelUrl;
    QQuickItem *_videoOutput = nullptr;
    bool _streamEnabled = true;

#ifdef QGC_GST_STREAMING
    VideoReceiver *_receiver = nullptr;
#endif
};
