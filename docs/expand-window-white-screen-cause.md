# 확대창 하얀 화면 원인 분석

## 현상
확대창(별도 Window)을 열면 영상 대신 **하얀 창**만 보임.

---

## 1. 구조 요약

```
ApplicationWindow (메인 창)
└── CustomFlyView (root = RowLayout)
    ├── leftPanelItem
    │   └── ColumnLayout (droneStatus)
    │       └── DroneVideo { id: droneVideo }   ← 영상 소스 (메인 창 씬에 속함)
    ├── mapHolder
    └── Window (droneVideoExpandWindow)          ← 별도 네이티브 윈도우
        └── Item (expandWindowContent)
            └── ShaderEffectSource {
                    sourceItem: droneVideo       ← 다른 윈도우의 Item 참조
                }
```

- **droneVideo**: 메인 ApplicationWindow의 씬 그래프(렌더 트리)에 속함 → **메인 창**에서만 그려짐.
- **ShaderEffectSource**: 확대창(Window)의 씬 그래프에 속함 → **확대창**에서 그려짐.
- 즉, **서로 다른 윈도우(서로 다른 QQuickWindow)** 에 속한 Item을 소스로 쓰는 구조.

---

## 2. 근본 원인: 크로스 윈도우 ShaderEffectSource 미지원

Qt 문서 및 버그 트래커 기준:

- **ShaderEffectSource**는 `sourceItem`으로 지정한 Item을 **텍스처로 캡처**해, 같은 씬에서 셰이더 등으로 사용하는 기능이다.
- 이때 **sourceItem과 ShaderEffectSource는 반드시 “같은 윈도우”의 자식**이어야 한다고 제한되어 있다.
- 참고: [QTBUG-68910](https://bugreports.qt.io/browse/QTBUG-68910), [QTBUG-43117](https://bugreports.qt.io/browse/QTBUG-43117)  
  → “ShaderEffectSource: sourceItem and ShaderEffectSource must both be children of the same window.”  
  → 크로스 윈도우는 “Won’t Do” / “Out of scope”로 정리됨.

현재 코드는:

- `sourceItem: droneVideo` → 메인 창의 Item  
- ShaderEffectSource → 확대 **Window**의 자식  

이므로 **“다른 윈도우의 Item을 소스로 쓰는” 미지원 케이스**에 해당한다.

---

## 3. 왜 하얀 화면이 나오는가

- 지원되지 않는 크로스 윈도우 사용 시, Qt는 소스 윈도우의 픽셀을 확대창의 렌더에 **안전하게 공유하지 않음** (씬 그래프/OpenGL 컨텍스트가 윈도우별로 분리됨).
- 그 결과 ShaderEffectSource가 참조하는 텍스처는:
  - 비어 있거나,
  - 초기화되지 않았거나,
  - 클리어 컬러(흰색/검정)만 그려진 상태가 됨.
- Windows + Qt 6 조합에서 **흰색**으로 보이는 것은 이런 “유효한 소스가 바인딩되지 않은” 상태에서의 기본 배경/클리어 컬러로 해석할 수 있음.

즉, **버그라기보다 “지원하지 않는 사용 방식” 때문에 생기는 동작**에 가깝다.

---

## 4. 요약 표

| 항목 | 내용 |
|------|------|
| **원인** | ShaderEffectSource가 **다른 윈도우(droneVideo 소유 창)** 의 Item을 `sourceItem`으로 참조함. |
| **Qt 제한** | sourceItem과 ShaderEffectSource는 **같은 윈도우**에 있어야 함. 크로스 윈도우는 미지원. |
| **결과** | 확대창에서는 유효한 텍스처가 없어 **하얀(또는 검은) 화면**만 표시됨. |
| **정상 여부** | 설계상 “확대창에 같은 영상이 보여야 함”이 정상이지만, 현재 구현 방식은 Qt 제한에 걸려 **정상 동작이 아님**. |

---

## 5. 가능한 대응 방향 (참고)

- **Popup으로 되돌리기**  
  확대창을 별도 Window가 아니라 **메인 창 안의 Popup**으로 두면, droneVideo와 ShaderEffectSource가 **같은 윈도우**가 되어 영상이 보인다. 대신 다른 모니터로 창을 빼낼 수는 없다.
- **같은 윈도우 안에 “붙어 있는” 확대 패널**  
  별도 Window 대신, 메인 창 내부에 플로팅 패널 형태로 두고 ShaderEffectSource로 droneVideo를 보여 주면, 같은 이유로 영상은 정상 표시된다.
- **C++에서 프레임 복사**  
  비디오 프레임을 C++에서 받아 다른 윈도우용 텍스처/이미지로 넘겨 그리면, 별도 Window에서도 영상을 띄울 수 있으나, 구조 변경이 크다.

이 문서는 “확대창을 열면 하얀 창이 나오는 현상”에 대한 **원인 분석**만 담고 있으며, 실제 코드 변경은 필요 시 별도로 진행하면 된다.
