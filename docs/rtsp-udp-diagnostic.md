# RTSP UDP: 패킷 미수신 vs 앱 미지원 판별

실제로 UDP가 안 쓰일 때 **UDP 패킷이 아예 안 오는 것인지**, **앱(백엔드)이 UDP를 안 쓰는 것인지** 구분하는 방법입니다.

---

## 1. 판별 요약

| 확인 방법 | 결과 | 의미 |
|-----------|------|------|
| **ffprobe/ffplay로 같은 URL + udp 테스트** | 성공 | UDP 패킷은 도달함 → **앱/백엔드가 UDP를 안 쓰는 쪽** (Qt 옵션 미전달 등) |
| **ffprobe/ffplay로 같은 URL + udp 테스트** | 실패/타임아웃 | UDP가 안 옴 → **UDP 패킷이 안 오는 쪽** (방화벽, 서버 설정, 네트워크) |

---

## 2. 앱 밖에서 UDP 도달 여부 확인 (ffprobe/ffplay)

같은 PC에서, **앱과 동일한 RTSP URL**로 `rtsp_transport=udp`만 강제해서 테스트합니다.

```bash
# 예: URL이 rtsp://127.0.0.1:8554/live 일 때
ffprobe -rtsp_transport udp "rtsp://127.0.0.1:8554/live"
# 또는
ffplay -rtsp_transport udp "rtsp://127.0.0.1:8554/live"
```

- **스트림 정보 나오거나 영상 재생됨**  
  → UDP 패킷은 이 PC까지 옵니다.  
  → 앱에서 UDP가 안 쓰이는 건 **앱/백엔드 문제** (Qt FFmpeg가 `rtsp_transport`를 안 넘기는 경우 등).

- **타임아웃/연결 실패/재시도 후 TCP로 넘어감**  
  → 이 환경에서는 **UDP가 안 오는 것** (방화벽, 서버가 UDP 미지원, 네트워크 정책 등).

---

## 3. 앱 쪽에서 보는 단서

- **DroneVideo 로그**  
  - `play source: ... [transport=udp]`  
  - URL에는 udp가 들어가지만, Qt FFmpeg 백엔드는 이 옵션을 FFmpeg에 넘기지 않아 **실제 전송은 TCP일 수 있음**.

- **초반 "Protocol not found" 후 재생됨**  
  - 백엔드가 한 번 실패 후 다른 방식(TCP 등)으로 연결했을 가능성.

- **QT_FFMPEG_DEBUG=1**  
  - 실행 전에 환경변수 설정 후 실행하면 FFmpeg 쪽 로그가 나와, 실제로 어떤 프로토콜/옵션으로 열었는지 추정하는 데 도움이 됨.

---

## 4. 정리

1. **ffprobe/ffplay로 `-rtsp_transport udp` 테스트**  
   - 성공 → **UDP 패킷은 옴** → 원인은 앱/백엔드가 UDP를 사용하지 않는 쪽.  
   - 실패 → **UDP 패킷이 안 옴** → 서버/방화벽/네트워크부터 확인.

2. **앱 로그**  
   - URL의 `[transport=udp]`는 “앱이 URL로는 udp를 요청했다”는 의미일 뿐, **실제 전송이 UDP인지는 백엔드(Qt/FFmpeg) 동작에 따름**.

이 순서로 보면 “UDP 패킷이 안 오는지 / 앱이 UDP를 인코딩(사용) 못 하는지” 판단할 수 있습니다.
