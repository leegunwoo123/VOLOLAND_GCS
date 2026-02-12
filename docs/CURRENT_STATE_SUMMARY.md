# 현재 코드 상태 요약 (Latest)

> 많은 수정 반영 후 기준. PlanView / CustomPlanView / Fly 뷰 구조 및 툴바·missionPanel 정리.

---

## 1. MainWindow.qml

### 속성
| 속성 | 설명 |
|------|------|
| `_planViewShown` | Plan 뷰(Custom Plan 포함) 진입 여부. true면 Fly 툴바 숨김, 컨텐츠 상단 정렬 |
| `_customPlanViewShown` | true = Custom Plan View(드론상태+CustomPlanView), false = Plan Flight(PlanView) |

### 뷰 전환 함수
| 함수 | 동작 |
|------|------|
| `showPlanView()` | Plan Flight. `_planViewShown=true`, `_customPlanViewShown=false`, PlanView만 표시 |
| `showCustomPlanView()` | Custom Plan View. `_planViewShown=true`, `_customPlanViewShown=true`, CustomPlanView만 표시 |
| `showFlyView()` | Fly 뷰. `_planViewShown=false`, `_customPlanViewShown=false`, planView/customPlanView 숨김 |
| `showCustomFlyView()` | Plan/Custom Plan에서 뒤로가기. 위와 동일 + 툴바 복구 |

### 툴바
- **CustomToolbar** (`customtoolBar`): Fly 뷰에서만 표시. `visible: !_planViewShown`. 높이 미지정 → CustomToolbar.qml 기본값 `ScreenTools.toolbarHeight`.
- **CustomPlanViewToolBar** (`customPlanToolBar`): Custom Plan View일 때만 상단 표시. `visible: _customPlanViewShown`. `planMasterController: _planController`. 툴바 밑에 droneStatus가 오도록 사용.

### 레이아웃 구조
- **flyPlanContainer** (Item)
  - `anchors.top`: Custom Plan = `customPlanToolBar.bottom`, Plan Flight = `parent.top`, Fly = `customtoolBar.bottom`
  - **RowLayout**
    - **CustomFlyView**: Plan Flight 시 너비 0, Custom Plan 시 sidebar 너비(`Math.min(mainWindow.width*0.20, 350*1.25)`), Fly 시 fill. `planViewActive: _customPlanViewShown`
    - **Item** (PlanView + CustomPlanView 겹침)
      - **PlanView**: `visible: _planViewShown && !_customPlanViewShown`
      - **CustomPlanView**: `visible: _customPlanViewShown`, `showToolbar: false`, `droneStatusWidth: _customPlanViewShown ? customFlyView.width : 0`
- **Connections**: planView / customPlanView `visible` → false 시 `_planViewShown = false`

### 도구 메뉴 (toolSelectComponent)
- **Plan Flight**: `showPlanView()` → PlanView
- **Custom Plan View**: `showCustomPlanView()` → CustomPlanView

---

## 2. CustomFlyView.qml

### 구조 (RowLayout)
1. **좌측 – droneStatus** (Item + ColumnLayout)
   - `Layout.fillWidth: false`, `Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter`
   - DroneList, CustomHUDWidget, DroneVideo, DroneStatusMessage, DroneControlPanel
   - MouseArea로 빈 영역 드래그 시 맵 이벤트 방지
2. **중앙** – 빈 Item (지도/메인). `Layout.fillWidth: true`, `visible: !planViewActive`
3. **우측 – stationStatusContainer**
   - `Layout.fillWidth: false`, `Layout.alignment: Qt.AlignRight | Qt.AlignVCenter`
   - `visible: !planViewActive`. 토글 버튼, StationList, CustomStationMetrics, StationVideo, StationStatusMessage, StationControlPanel

### 속성
- **planViewActive**: Custom Plan View일 때 true. 중앙/우측 숨김, 좌측 droneStatus만 표시.
- **anchors.top**: `planViewActive ? parent.top : customtoolBar.bottom`

### 바인딩 (MainWindow)
- `planViewActive: mainWindow._customPlanViewShown`
- Layout: `_planViewShown`일 때 Custom Plan이면 sidebar 너비, Plan Flight이면 0, Fly면 fill.

---

## 3. CustomPlanView.qml

### 속성
- **planMasterController**: 부모에서 전달.
- **showToolbar**: true면 내부 CustomPlanViewToolBar 표시. MainWindow에서는 false로 전달(상단에 CustomPlanViewToolBar 별도 표시).
- **droneStatusWidth**: MainWindow에서 `customFlyView.width` 전달. missionPanel 너비 = droneStatus와 동일하게 맞춤.

### 구조
- **CustomPlanViewToolBar**: `visible: root.showToolbar`
- **missionPanel** (Item)
  - `width: root.droneStatusWidth > 0 ? root.droneStatusWidth : parent.width`
  - **ColumnLayout** (planStorageContainer): `anchors.fill: parent` → missionPanel 전체 = droneStatus 너비
    - **RowLayout** (planstorage): 로컬 저장소 / 서버 저장소 / 열기·닫기 버튼. `Layout.fillWidth: true` → 로컬+서버 버튼 합 너비 = missionPanel = droneStatus
    - ComboBox (pathList) 등
  - Repeater(MissionItemMapVisual), MissionLineView, MapItemView 등 미션 관련 맵 UI

---

## 4. CustomPlanViewToolBar.qml

- "Return" 버튼: `mainWindow.showCustomFlyView()` → Fly 뷰 복귀, 툴바 복구.
- `height: ScreenTools.toolbarHeight` (CustomToolbar와 동일 높이 유지).

---

## 5. 설계 의도

- **PlanView**와 **CustomPlanView**는 **별개 화면**. 이후 PlanView는 다른 모드에서 호출 예정.
- Custom Plan View: 툴바는 CustomPlanViewToolBar, 그 밑에 droneStatus(좌) + CustomPlanView 본문(우). missionPanel(로컬/서버 버튼 등) 너비 = droneStatus.

---

## 6. 현재 동작 요약

| 진입 경로 | 툴바 | 표시 |
|-----------|------|------|
| Fly 뷰 | CustomToolbar | CustomFlyView 전체 (droneStatus + 중앙 + stationStatus) |
| Plan Flight | 없음 | PlanView 전체 |
| Custom Plan View | CustomPlanViewToolBar | droneStatus(좌) + CustomPlanView(우). missionPanel 너비 = droneStatus |
| Return | CustomToolbar 복귀 | Fly 뷰 |

---

*마지막 업데이트: 소스코드 최신화 반영*
