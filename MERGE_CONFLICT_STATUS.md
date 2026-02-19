# 병합 충돌 해결 상태 (Merge Conflict Status)

## 현재 상태: **전체 해결 완료**

모든 소스 파일에서 `<<<<<<< HEAD` / `=======` / `>>>>>>> f9dfdbd69 (commit (clean))` 충돌 마커를 제거했으며, **상대방 커밋(theirs) 내용만 남기는 방식**으로 정리했습니다.

### 처리한 파일 (요약)
- **src:** Line3D.qml, CustomFlyView.qml, CustomPlanView.qml, CustomMissionSettingEditor.qml, QGCFileDialog.qml, CustomMissionItemEditor.qml, CustomDroneMetrics.qml, CustomStationMetrics.qml, CustomMissionReorderHelper.cc, MAVLink/LibEvents/CMakeLists.txt
- **deploy:** windows/QGroundControl.rc.in
- **test:** MissionManager 내 waypoints/mission 파일
- **기타:** .gitignore, .qtcreator/project.json.qtds (마커만 제거)

### 참고
- `out/build/` 아래 빌드 산출물은 수정하지 않았습니다. (빌드 시 소스에서 다시 생성됨)
- 추가로 충돌이 보이면 해당 파일에서 위 세 가지 마커를 검색해 수동으로 제거하면 됩니다.
