# DroneVideo 아키텍처 비교: QGC vs 우리 경로

## QGC가 활용하는 구조 (공식 비디오 파이프라인)

| 단계 | 역할 | QGC (GStreamer 빌드) | QGC (Qt Multimedia 수신기) |
|------|------|------------------------|----------------------------|
| **네트워크 스트림 수신/디코딩** | RTSP·UDP·TCP 수신, 디코딩 | **GStreamer** (rtspsrc, udpsrc, tcpclientsrc 등) | **Qt Multimedia** (QMediaPlayer, C++ VideoReceiver) |
| **비디오 프레임 데이터 구조화** | 프레임 포맷·버퍼 관리 | GStreamer 파이프라인 내부 (GL 텍스처 등) | **QVideoFrame** / **QVideoSink** (C++에서 노출) |
| **UI 상태 제어 및 이벤트** | 재생/정지, 설정, 에러 처리 | **Qt Core** (Signals & Slots, VideoManager ↔ VideoReceiver) | 동일 |
| **최종 화면 렌더링** | 픽셀을 화면에 그리기 | **GstGLQt6VideoItem** (GStreamer GL 싱크 → OpenGL) | Qt Quick **VideoOutput** / QVideoSink 연동 → **OpenGL** |

- GStreamer 빌드: `VideoManager` → `GstVideoReceiver` → `rtspsrc` 등 → `GstGLQt6VideoItem` (QML에 위젯 등록).
- Qt Multimedia 수신기: `VideoManager` → `QtMultimediaReceiver` (QMediaPlayer + QVideoSink) → QVideoFrame → 스트림 위젯에 전달 → Qt Quick/OpenGL 렌더링.

---

## 우리 경로 (현재 DroneVideo.qml)

| 단계 | 역할 | 우리 구현 |
|------|------|-----------|
| **네트워크 스트림 수신/디코딩** | RTSP 수신, 디코딩 | **Qt Multimedia** (QML `MediaPlayer`, 백엔드: **FFmpeg** 설정 시) — **GStreamer 미사용** |
| **비디오 프레임 데이터 구조화** | 프레임 포맷·버퍼 | Qt 내부에서 **QVideoFrame** 사용하지만 **QML에 노출되지 않음** (`VideoOutput`이 내부 처리) |
| **UI 상태 제어 및 이벤트** | 재생/재연결/설정 | **Qt Quick (QML)** + **Qt Core** (MediaPlayer의 `mediaStatus`, `errorOccurred` 등 시그널) |
| **최종 화면 렌더링** | 픽셀을 화면에 그리기 | **Qt Quick `VideoOutput`** (MediaPlayer에 바인딩) → **OpenGL** |

- **VideoManager / VideoReceiver와 분리됨**: DroneVideo는 `VideoManager.registerDroneVideoWidget()`을 호출하지 않고, 단일 QML `MediaPlayer`에 `rtspSource`(및 `_effectiveRtspSource`)를 넣어 직접 재생.
- **확대창**: `CustomFlyView`의 확대 창은 같은 URL을 쓰는 **별도 `MediaPlayer`**로 재생 (기본 DroneVideo와 독립).

### 멀티화면(채널) 구조 (하이브리드 C)

- **채널 목록**: `CustomFlyView._videoChannels` — `[{ label, enabled, url? }, ...]`. `url`이 없으면 설정 기본값(`_defaultRtspUrl`) 사용.
- **Repeater**: 채널 수만큼 `DroneVideo` 생성. 각 인스턴스에 `channelUrl`, `channelLabel`, `streamEnabled`(← `enabled`) 전달.
- **DroneVideo**: `channelUrl`이 있으면 해당 URL 사용, 없으면 기존 `rtspSource`(설정/backend). `channelLabel`은 연결 중 문구에 사용.
- **확대 버튼**: 첫 채널(`index === 0`)에만 표시. 확대창 소스는 `_primaryEffectiveRtspUrl`(첫 채널과 동일).
- 나중에 채널 추가 시 `_videoChannels`에 항목만 추가하면 되고, 녹화/활성화는 채널별 `enabled` 또는 별도 API로 확장 가능.

---

## 요약 비교

| 구분 | QGC 공식 (GStreamer) | QGC 공식 (Qt Multimedia 수신기) | 우리 (DroneVideo.qml) |
|------|----------------------|---------------------------------|------------------------|
| 수신/디코딩 | GStreamer (rtspsrc 등) | Qt Multimedia (C++) | Qt Multimedia (QML MediaPlayer, FFmpeg) |
| 프레임 구조 | GStreamer GL 내부 | QVideoFrame / QVideoSink (C++) | Qt 내부만 (QML에서 접근 안 함) |
| UI/이벤트 | Qt Core (시그널/슬롯) | 동일 | Qt Quick + Qt Core (MediaPlayer 시그널) |
| 렌더링 | GstGLQt6VideoItem (OpenGL) | Qt Quick / OpenGL | Qt Quick VideoOutput (OpenGL) |
| VideoManager 연동 | 있음 (설정·재시작·녹화 등) | 있음 | **없음** (독립 재생) |

---

## 우리 구조의 장단점

- **장점**: 구현이 단순함 (QML만으로 URL → 재생 → 렌더링). VideoManager/설정과 결합도를 낮게 유지 가능.
- **단점**:  
  - Windows에서 FFmpeg 백엔드가 없으면 RTSP 미지원(WMF 한계).  
  - 녹화·캡처·스트림 정보 등 VideoManager 기능을 쓰려면 별도 연동 필요.  
  - GStreamer 빌드의 `DroneVideoGStreamer.qml` + `registerDroneVideoWidget()` 경로를 쓰면 QGC와 동일한 구조를 활용할 수 있음.
