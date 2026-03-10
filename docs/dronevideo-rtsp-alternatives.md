# DroneVideo RTSP 재생 — WMF 대안 방법

Qt Multimedia의 기본 WMF(Windows Media Foundation) 백엔드는 RTSP를 지원하지 않습니다. 아래는 사용 가능한 **다른 방법**입니다.

---

## 1. VideoManager + GStreamer 연동 (권장, QGC 내장) — **구현 완료**

**조건:** 앱이 **GStreamer**로 빌드된 경우 (`QGC_GST_STREAMING`).

**방식:** DroneVideo가 별도 `MediaPlayer` 대신 **VideoManager**의 스트리밍 파이프라인을 사용합니다. GStreamer의 `rtspsrc`는 Windows에서도 RTSP를 지원합니다.

- **구현:**  
  - `VideoManager::registerDroneVideoWidget(QQuickItem*)` / `unregisterDroneVideoWidget()` 로 드론 전용 수신기 등록·해제.  
  - DroneVideo.qml에서 `gstreamerEnabled`이면 `DroneVideoGStreamer.qml`(GstGLQt6VideoItem)을 로드하고 위젯을 등록.  
  - 설정의 RTSP URL은 기존 Video 설정과 동일하게 사용.  
- **장점:** 기존 설정·재시작 로직 재사용, VLC에서 되면 여기서도 동작 가능.  
- **제한:** GStreamer 빌드일 때만 적용됩니다. Qt 전용 빌드에서는 아래 2·3번을 고려하세요.

---

## 2. Qt FFmpeg 백엔드 (환경 변수)

**조건:** Qt가 **FFmpeg 지원**으로 빌드되어 있을 때.

**방식:** 실행 시 환경 변수로 미디어 백엔드를 FFmpeg으로 지정합니다.

```text
QT_MEDIA_BACKEND=ffmpeg
```

- **장점:** DroneVideo 쪽 QML/코드 변경 없이, 기존 Qt Multimedia 경로로 RTSP 재생을 시도할 수 있음.
- **제한:** 사용 중인 Qt 배포본이 FFmpeg을 포함해야 합니다. 포함 여부는 빌드 옵션/문서를 확인해야 합니다.

---

## 3. libVLC / VLC 연동 (외부 라이브러리)

**방식:** RTSP 디코딩을 **libVLC**로 수행하고, 프레임 또는 비디오 표면을 QML/Qt 위젯에 전달합니다.

- **장점:** VLC에서 재생되는 스트림은 동일 엔진으로 앱 내에서도 재생 가능.
- **단점:** libVLC(vlc-qt 등) 의존성 추가, 빌드·배포 복잡도 증가.

---

## 4. FFmpeg 직접 사용 (libavformat/libavcodec)

**방식:** RTSP 수신·디코딩을 **FFmpeg**으로 직접 구현하고, 디코딩된 프레임을 `QVideoFrame` 등으로 Qt 쪽에 넘겨 표시합니다.

- **장점:** 플랫폼/백엔드 제한 없이 RTSP 제어 가능.
- **단점:** 구현량이 많고, 버퍼링·재연결·에러 처리 등을 직접 관리해야 합니다.

---

## 5. 외부 프로세스 임베딩 (VLC/ffplay 창 붙이기)

**방식:** VLC 또는 ffplay를 **자식 프로세스**로 실행하고, 해당 창을 `QWindow::fromWinId()` 등으로 Qt 창에 붙입니다.

- **장점:** 빠르게 “VLC에서 나오는 화면”을 앱 안에 넣을 수 있음.
- **단점:** 플랫폼별 창 임베딩 이슈, 프로세스 생명 주기 관리 필요.

---

## 요약

| 방법                    | 코드 변경 | 조건              | 권장도   |
|-------------------------|-----------|-------------------|----------|
| VideoManager + GStreamer | 있음      | GStreamer 빌드    | ★★★★★ |
| QT_MEDIA_BACKEND=ffmpeg | 없음      | Qt FFmpeg 빌드    | ★★★☆☆ |
| libVLC                  | 많음      | libVLC 의존성     | ★★☆☆☆ |
| FFmpeg 직접             | 많음      | FFmpeg 의존성     | ★★☆☆☆ |
| 외부 프로세스 임베딩    | 중간      | 플랫폼별 처리     | ★☆☆☆☆ |

**실제 적용:** GStreamer 빌드라면 **1번(VideoManager 연동)**을 사용하고, 그렇지 않으면 **2번(FFmpeg 백엔드)**를 먼저 시도하는 것이 좋습니다.
