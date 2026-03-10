/****************************************************************************
 *
 * DroneVideo 전용 GStreamer 비디오 아이템.
 * VideoManager.registerDroneVideoWidget()에 이 아이템을 전달해 RTSP 스트림을 표시.
 * (GStreamer 빌드에서만 사용, Windows 등 WMF가 RTSP를 지원하지 않는 환경 대응)
 *
 ****************************************************************************/

import QtQuick
import org.freedesktop.gstreamer.Qt6GLVideoItem

GstGLQt6VideoItem {
    id: droneVideoGstItem
}
