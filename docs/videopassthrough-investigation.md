# 확대창 영상 타이밍 전수 조사

## 현상
- 확대창이 메인 화면보다 영상이 먼저 나오는 것처럼 보임.

## 조사 결과 요약

### 1. 확대창에 별도 재생 경로 없음 ✅
- **CustomFlyView.qml**: 확대창(`droneVideoExpandWindow`) 내부에 `MediaPlayer` 없음. `VideoOutput`(expandVideoOutput)만 존재.
- 확대창이 받는 프레임은 **오직** `VideoPassthroughHelper`가 메인 sink에서 전달하는 것뿐.

### 2. 메인 소스 등록 경로 ✅
- **DroneVideo.qml**: `isMainVideo: true`(Repeater의 index === 0)일 때 `Component.onCompleted`에서 `VideoPassthroughHelper.setSourceOutput(videoOutput)` 호출.
- **CustomFlyView.qml**: Repeater delegate에서 `isMainVideo: (index === 0)` 전달.
- 메인은 좌측 패널의 첫 번째 DroneVideo 한 개만 소스로 등록됨.

### 3. 보조 등록 시점 ✅
- 확대창 표시 시: `VideoPassthroughHelper.isSourceSet()`이 true일 때만 `addSecondaryOutput(expandVideoOutput)` 호출.
- 메인 소스가 나중에 등록되면: `VideoPassthroughHelper.sourceSet()` 연결로 이미 열린 확대창을 그때 보조로 등록.

### 4. 프레임 전달 순서 (원인)
- **기존**: 메인 sink의 `videoFrameChanged` → 동기적으로 `onSourceFrameChanged` → 즉시 `setVideoFrame(frame)` 호출로 확대창 sink에 전달.
- 메인/확대 **동일 프레임**을 같은 호출 스택에서 받음. 데이터상 확대가 “더 앞서” 있는 것은 아님.
- **가능 원인**: 윈도우/씬 그래프 **그리기 순서**. 확대창이 별도 윈도우이고 작아서, 컴포지터가 확대창을 먼저 그리거나 vsync 타이밍상 확대창이 먼저 보일 수 있음.

### 5. 적용한 대응
- **VideoPassthroughHelper.cc**: 보조 출력에는 `QTimer::singleShot(0, ...)`로 **한 틱 지연** 후 `setVideoFrame` 호출.
- 의도: 메인 윈도우가 해당 프레임으로 먼저 페인트될 기회를 주고, 그 다음 이벤트 루프에서 확대창에 같은 프레임 전달.
- 프레임은 복사(`QVideoFrame frameCopy(frame)`) 후 람다에 넘겨, 다음 틱에서 원본이 무효화되어도 안전하게 전달.

### 6. 기타 확인 사항
- **FlightDisplay 모듈**: CustomFlyView는 `FlightDisplayModule`에서 빌드되며, MainWindow에서 `CustomFlyView { }`로 로드. 소스는 `src/FlightDisplay/CustomFlyView.qml` 기준.
- **다른 비디오 경로**: FlightDisplayViewQtMultimedia, FlightDisplayViewUVC 등은 다른 Fly 뷰용. CustomFlyView 확대창과 직결된 별도 재생 경로 없음.
- **빌드 산출물**: 리빌드 시 FlightDisplay/Toolbar QML이 새로 복사되므로, 예전 버전(확대창에 MediaPlayer 있던 시점)이 남아 있으면 확대창만 먼저 나오는 현상이 재현될 수 있음. **클린 리빌드** 권장.

## 결론
- 확대창이 “먼저 나온다”는 것은 **별도 스트림** 때문이 아니라, **동일 프레임을 받는 두 출력의 그리기/컴포지트 순서** 영향으로 보는 것이 타당함.
- 보조 출력으로의 전달을 1틱 지연해, 메인 쪽이 먼저 그려지도록 했음.
- 여전히 체감상 확대가 빠르면: 클린 리빌드 여부, 다른 모니터/vsync 설정, 또는 추가로 1프레임만큼 지연하는 방식(프레임 복사 비용 고려) 검토 가능.
