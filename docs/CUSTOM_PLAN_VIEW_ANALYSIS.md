# CustomPlanView / 미션 재정렬(Drag&Drop) 분석

## 1. 바인딩 루프 경고 (MissionItemIndexLabel)

### 경고 내용
```
MissionItemIndicator.qml:31 - MissionItemIndexLabel: Binding loop detected for property "_height"
MissionItemIndexLabel.qml:31
```

### 관련성
**관련 있음.** CustomPlanView에서 항목 순서를 바꾼 뒤 `recalcSequenceNumbers()`가 호출되면, 모든 미션 항목의 `sequenceNumber`와 지도 표시용 `abbreviation` 등이 한꺼번에 바뀝니다. 지도 마커는 `MissionItemIndicator` → `MissionItemIndexLabel`을 쓰고, 여기서 `index: missionItem.sequenceNumber`로 바인딩되어 있습니다. 이 값들이 갱신되면서 `MissionItemIndexLabel`의 `_height` 바인딩이 재평가되고, 기존에 있던 **바인딩 루프**가 드러납니다.

### 루프 원인 (MissionItemIndexLabel)
- `_height` = `labelControl.visible ? labelControl.height : indicator.height`
- `labelControl`은 `anchors.fill: labelControlLabel`
- `labelControlLabel`은 `anchors.top/bottom: indicator.top/bottom` 등으로 레이아웃에 묶임
- Canvas는 `height: _height` → 레이아웃이 바뀌고, `anchorPointX/Y = _height/2`로 인해 자식 위치가 바뀜
- 그 결과 `labelControl`/`labelControlLabel` 높이 계산이 다시 트리거되고, `_height`로 되돌아가는 **순환 참조** 발생

### 적용한 수정
- `_height`에서 `labelControl.height`(레이아웃 결과에 의존) 대신 **`labelControlLabel.implicitHeight`** 를 사용하도록 변경.
- `implicitHeight`는 부모 크기에 의존하지 않으므로 루프가 끊깁니다.
- 수식: `labelControl.visible ? Math.max(indicator.height, labelControlLabel.implicitHeight + _labelMargin*2) : indicator.height`

---

## 2. CustomPlanView / 재정렬 구조 요약

### 구성 요소
| 구성 요소 | 역할 |
|-----------|------|
| **CustomPlanView.qml** | Plan 뷰 진입 시 미션 패널(지도 + Takeoff/Waypoint + 미션·펜스·랠리·UTMSP 탭) 표시. ListView의 model = `_missionController.visualItems` |
| **CustomMissionItemEditor.qml** | 각 미션 항목 한 줄(순번, 명령, 삭제 버튼). 드래그 시 `dragProxy` 표시, DropArea에서 놓으면 `CustomMissionReorderHelper.moveVisualItem()` 호출 |
| **CustomMissionReorderHelper** (C++) | `moveVisualItem(missionController, from, to)` → 모델에서 항목 제거 후 삽입, `recalcSequenceNumbers()`, 현재 항목 설정 |

### 드롭 시 데이터 흐름
1. 사용자가 항목 A를 드래그해 항목 B 위에 드롭.
2. **onDropped** (CustomMissionItemEditor)
   - `drag.source` = 드래그한 델리게이트(_root), `drag.source.missionItem` = A.
   - `_root.missionItem` = 드롭한 행의 항목(B).
   - `fromIdx`: `model.get(i) === drag.source.missionItem`인 i.
   - `toIdx`: `model.get(i) === _root.missionItem`인 i (드롭 타깃 행 인덱스).
3. **moveVisualItem(_missionController, fromIdx, toIdx)** (C++)
   - `model->removeAt(fromIdx)` → A 제거, `beginRemoveRows`/`endRemoveRows` 발생.
   - `insertIndex = (toIdx > fromIdx) ? toIdx - 1 : toIdx`.
   - `model->insert(insertIndex, item)` → A를 원하는 위치에 삽입, `beginInsertRows`/`endInsertRows` 발생.
   - `recalcSequenceNumbers()` → 모든 항목의 `sequenceNumber`를 0,1,2,… 로 재계산 + 자식/비행경로 갱신.
   - `setCurrentPlanViewSeqNum(moved->sequenceNumber(), true)` → 현재 선택을 이동한 항목으로 설정.

### ListView와의 관계
- ListView `currentIndex` = `_missionController.currentPlanViewSeqNum` (시퀀스 번호 = 인덱스와 1:1 대응).
- `recalcSequenceNumbers()` 후 시퀀스가 0,1,2,… 로 맞아야 하이라이트와 리스트 순서가 일치합니다.

---

## 3. "순서가 안 바뀐다" 가능 원인과 점검

### (1) fromIdx / toIdx가 잘못 나오는 경우
- **fromIdx**: `model.get(i) === drag.source.missionItem`으로 구함. 델리게이트가 재사용되면 같은 `missionItem`을 가리키지 않을 수 있음(보통은 드롭 시점에는 유효).
- **toIdx**: `_dropTargetIndex()`에서 `_root.missionItem`이 속한 인덱스. 드롭한 행이 올바른지 확인 필요.
- **점검**: `onDropped` 안에서 `console.log(fromIdx, toIdx)` 등으로 값 확인. fromIdx < 2 또는 toIdx < 2이면 early return 하므로, 0·1번(Mission Start, Takeoff)에는 드롭이 막혀 있는지 확인.

### (2) moveVisualItem이 호출되지 않는 경우
- `CustomMissionReorderHelper`가 QML에 제대로 등록되지 않았거나, 이름이 다르면 호출 실패.
- **점검**: `CustomMissionReorderHelper.moveVisualItem` 호출 직전에 `console.log("move", fromIdx, toIdx)` 추가 후, 드롭 시 로그가 찍히는지 확인.

### (3) 모델은 바뀌는데 화면만 안 바뀌는 경우
- `removeAt`/`insert`는 `removeRows`/`insertRows`를 발생시키므로 ListView는 갱신되어야 함.
- **점검**: 드롭 후 리스트에서 순번(sequenceNumber) 텍스트가 1,2,3,… 순으로 바뀌는지, 지도 마커 순서가 바뀌는지 확인.

### (4) recalcSequenceNumbers 타이밍
- `removeAt`/`insert` 직후 바로 `recalcSequenceNumbers()`를 호출. 레이아웃/시그널이 완전히 반영되기 전에 호출되면 이론상 꼬일 수 있음.
- **대안**: QML에서 `moveVisualItem` 호출 후 `Qt.callLater`로 한 프레임 뒤에 `recalcSequenceNumbers()`만 호출하는 방식은 C++ 한 번에 처리하는 현재 구조에서는 적용 어렵고, 우선 현재 순서로 두고 (3)까지 점검하는 것이 좋음.

### (5) MissionController / visualItems가 다른 인스턴스
- CustomPlanView의 ListView `model`과 `moveVisualItem`에 넘기는 `_missionController`가 동일한지 확인. 같은 Plan 마스터 컨트롤러 아래라면 보통 동일.

---

## 4. 정리 및 권장 순서

1. **바인딩 루프**  
   - MissionItemIndexLabel의 `_height`를 `implicitHeight` 기반으로 바꾼 수정으로 제거됨.  
   - 같은 경고가 다시 나오면, `_width` 쪽이나 다른 속성에서 비슷한 순환 바인딩이 있는지 확인.

2. **순서가 안 바뀌는 문제**  
   - 위 (1)~(3) 순서로:  
     - onDropped에서 **fromIdx, toIdx** 로그로 유효한지,  
     - **moveVisualItem** 호출 로그로 실제 호출 여부,  
     - 드롭 후 **리스트/지도**에서 순서·시퀀스 번호가 바뀌는지  
   확인하면 원인 구간을 좁힐 수 있습니다.

3. **추가로 손댈 부분**  
   - CustomPlanView/CustomMissionItemEditor/CustomMissionReorderHelper는 그대로 두고,  
   - **MissionController**에는 `recalcSequenceNumbers()` 공개와 move 후 호출만 추가된 상태이므로,  
   - “순서는 안 바뀐다”가 남으면 **인덱스/호출/모델 갱신** 쪽을 위 순서대로 디버깅하는 것을 권장합니다.
