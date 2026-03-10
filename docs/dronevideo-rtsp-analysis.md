# DroneVideo RTSP 스트리밍 미동작 원인 분석

## 1. 요약

- **DroneVideo**는 QML `MediaPlayer`(Qt Multimedia 6)에 `source: videoRoot.rtspSource`로 RTSP URL을 넣어 재생합니다.
- **가능한 원인**: (1) **Windows에서 Qt Multimedia가 RTSP를 지원하지 않음**, (2) 사용 중인 **RTSP URL/설정 문제**, (3) **설정 화면에서 RTSP를 선택하지 않아 URL이 비어 있음**.

---

## 2. 원인 1: Qt Multimedia 백엔드 (가장 유력)

### 사실

- Qt 6 Multimedia는 플랫폼별 백엔드를 사용합니다.
  - **Windows**: 기본값은 **WMF(Windows Media Foundation)**.
  - WMF는 **RTSP 스트림을 지원하지 않습니다**.
- 포럼/이슈에서도 Windows에서 `QMediaPlayer::setSource(QUrl("rtsp://..."))` 사용 시 실패(예: WinRT 오류)가 보고되어 있습니다. 같은 URL은 VLC에서는 재생되는 경우가 많습니다.

### 결론

- **Windows 빌드**에서는 DroneVideo처럼 **QML MediaPlayer에 rtsp:// URL만 넣는 방식은 기본 백엔드(WMF)로는 동작하지 않을 가능성이 큽니다.**

### 대응 옵션

1. **FFmpeg 백엔드 사용(가능한 경우)**  
   - Qt가 FFmpeg 지원으로 빌드되어 있다면 실행 시:
     - `QT_MEDIA_BACKEND=ffmpeg` 환경 변수 설정 후 앱 실행.
   - FFmpeg 백엔드는 기술 프리뷰이며, RTSP 지원이 WMF보다 나은 편입니다.
2. **기존 비디오 파이프라인 활용**  
   - QGC는 `VideoManager` → `VideoReceiver`(GStreamer 또는 QtMultimediaReceiver)로 스트리밍을 처리합니다.
   - GStreamer 빌드(`QGC_GST_STREAMING`)에서는 RTSP가 정상 동작하는 경로가 이미 있습니다.
   - DroneVideo를 **VideoManager가 사용하는 디코더/출력**과 연동하면, Windows에서도 RTSP 재생 가능성을 높일 수 있습니다.

---

## 3. 원인 2: RTSP URL/설정

### URL 결정 순서 (DroneVideo.qml)

```qml
readonly property string rtspSource: (backend && backend.rtspUrl)
    ? backend.rtspUrl
    : (String(QGroundControl.settingsManager.videoSettings.rtspUrl.rawValue || "").trim() || "rtsp://127.0.0.1:8554/live")
```

- **backend**  
  - `CustomFlyView.qml`에서 DroneVideo에 `backend: null`로 두고 있어, 현재는 항상 설정/기본값 경로를 사용합니다.
- **설정**  
  - `VideoSettings.rtspUrl`은 **Video Source = "RTSP Video Stream"** 일 때만 설정 UI에 노출됩니다.
  - 사용자가 Video Source를 RTSP로 바꾸지 않았거나, URL을 비워 두면 `rtspUrl.rawValue`는 빈 문자열일 수 있습니다.
- **기본값**  
  - 위 경우 `rtspSource`는 `"rtsp://127.0.0.1:8554/live"`로 고정됩니다.
  - 해당 주소에서 RTSP 서버가 떠 있지 않으면 연결 자체가 실패합니다.

### 결론

- **설정**: 설정 화면에서 **Video > Source = "RTSP Video Stream"** 선택 후 **RTSP URL**에 실제 스트리밍 주소를 넣었는지 확인해야 합니다.
- **기본 URL**: `127.0.0.1:8554/live`는 테스트용이므로, 실제 장비/서버 URL로 바꾸거나, VLC 등으로 같은 URL이 재생되는지 먼저 확인하는 것이 좋습니다.

---

## 4. 원인 3: streamEnabled / 재생 로직

- DroneVideo는 `streamEnabled: true`(CustomFlyView에서 지정), `_applySourceAndPlay()`에서 `streamEnabled`/`rtspSource`가 있을 때만 `mediaPlayer.play()`를 호출합니다.
- 여기서의 조건 자체는 타당하고, **스트리밍이 안 되는 직접 원인으로 보기보다는**, 위 1·2번이 해결된 뒤에도 문제가 있으면 함께 점검하면 됩니다.

---

## 5. 권장 확인 순서

1. **설정**  
   - **설정 > Video > Source**를 **"RTSP Video Stream"**으로 두고, **RTSP URL**에 사용 중인 카메라/서버의 실제 URL 입력.
2. **URL 검증**  
   - 같은 URL을 **VLC** 등으로 재생해 보기. VLC에서도 안 되면 URL/네트워크/서버 문제일 가능성이 큼.
3. **플랫폼**  
   - **Windows**에서 재생이 안 되면, Qt Multimedia WMF 백엔드 한계일 가능성이 큼.  
   - 가능하면 `QT_MEDIA_BACKEND=ffmpeg` 시도, 또는 VideoManager 기반 재생 경로와 연동 검토.
4. **디버깅**  
   - 필요 시 `MediaPlayer`의 `mediaStatus`, `errorString`을 잠시 로그로 남겨,  
     - 어떤 URL로 시도했는지,  
     - `InvalidMedia`/`NoMedia`인지,  
     - 에러 메시지가 무엇인지  
     확인하면 원인 좁히는 데 도움이 됩니다.

---

## 6. 연관 파일

| 파일 | 역할 |
|------|------|
| `src/UI/toolbar/DroneVideo.qml` | RTSP URL 소스, MediaPlayer 재생 |
| `src/FlightDisplay/CustomFlyView.qml` | DroneVideo 사용, `backend: null` |
| `src/Settings/VideoSettings.cc` | rtspUrl Fact, videoSource enum |
| `src/UI/AppSettings/VideoSettings.qml` | RTSP URL 필드 표시(_isRTSP일 때) |
| `src/VideoManager/VideoManager.cc` | 공식 비디오 경로(VideoReceiver, RTSP URL 적용) |
| `src/VideoManager/VideoReceiver/QtMultimedia/QtMultimediaReceiver.cc` | Qt 쪽 수신기(QMediaPlayer 사용) |
| `src/VideoManager/VideoReceiver/GStreamer/` | GStreamer 빌드 시 RTSP 처리 |

---

## 7. 결론

- **가장 유력한 원인**: Windows에서 Qt Multimedia 기본 백엔드(WMF)가 **RTSP를 지원하지 않음**.
- **추가 가능 원인**: 설정에서 RTSP를 선택하지 않아 URL이 비어 있고, 그 결과 **기본값 `rtsp://127.0.0.1:8554/live`**만 사용되는데, 해당 서버가 없음.
- **개선 방향**:  
  - 단기: 설정에서 RTSP URL 확인, VLC로 URL 검증, 가능하면 `QT_MEDIA_BACKEND=ffmpeg` 시도.  
  - 중장기: DroneVideo가 **VideoManager/기존 VideoReceiver 파이프라인**을 사용하도록 연동하면 Windows에서도 RTSP 재생 안정성 확보에 유리합니다.
