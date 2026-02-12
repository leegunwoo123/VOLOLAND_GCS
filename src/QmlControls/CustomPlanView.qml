import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
<<<<<<< HEAD
=======
import QtQml
>>>>>>> f9dfdbd69 (commit (clean))
import QtLocation
import QtPositioning
import QtQuick.Layouts
import QtQuick.Window

import QGroundControl
import QGroundControl.FlightMap
import QGroundControl.ScreenTools
import QGroundControl.Controls
import QGroundControl.FactSystem
import QGroundControl.FactControls
import QGroundControl.Palette
import QGroundControl.Controllers
import QGroundControl.ShapeFileHelper
import QGroundControl.FlightDisplay
import QGroundControl.UTMSP

// CustomPlanView: 기존 우측 패널 유지. missionEditor에 지도+Takeoff/Waypoint+우측 편집 패널 포함. (다른 QGC 파일 수정 없음)
Item {
    id: root

<<<<<<< HEAD
=======
    Rectangle {
        anchors.fill: parent
        z: -1
        color: "#1a1a1a"
    }

>>>>>>> f9dfdbd69 (commit (clean))
    property var    planMasterController
    property bool   showToolbar: true
    property string deviceName: ""
    property real   droneStatusWidth: 0
<<<<<<< HEAD
=======
    property real   _lastMouseX: 0
>>>>>>> f9dfdbd69 (commit (clean))
    property var    _planMasterController:              planMasterController
    property var    _missionController:                 _planMasterController ? _planMasterController.missionController : null
    property var    _geoFenceController:                _planMasterController ? _planMasterController.geoFenceController : null
    property var    _rallyPointController:              _planMasterController ? _planMasterController.rallyPointController : null
<<<<<<< HEAD
=======
    property var    _appSettings:                      QGroundControl.settingsManager.appSettings
>>>>>>> f9dfdbd69 (commit (clean))

    readonly property int   _decimalPlaces:              8
    readonly property real  _margin:                     ScreenTools.defaultFontPixelHeight * 0.5
    readonly property real  _toolsMargin:                ScreenTools.defaultFontPixelWidth * 0.75
    readonly property var   _visualItems:                _missionController ? _missionController.visualItems : null
    property bool   _utmspEnabled:                       QGroundControl.utmspSupported
    property bool   _resetGeofencePolygon:              false
    property bool   _triggerSubmit:                     false
    property bool   _resetRegisterFlightPlan:            false
    property int    _customEditingLayer:                 _layerMission
    readonly property int   _editingLayer:               _customEditingLayer
    readonly property var   _layers:                     [_layerMission, _layerGeoFence, _layerRallyPoints]
    readonly property var   _layersUTMSP:                [_layerMission, _layerRallyPoints, _layerUTMSP]
    readonly property int   _layerMission:               1
    readonly property int   _layerGeoFence:             2
    readonly property int   _layerRallyPoints:           3
    readonly property int   _layerUTMSP:                 4
<<<<<<< HEAD
=======
    property bool           _waypointAddMode:            false
    /// 로컬/서버 목록 또는 파일 다이얼로그에서 선택한 파일 이름 (단일 소스)
    property string         selectedPlanPath:            ""
>>>>>>> f9dfdbd69 (commit (clean))

    function mapCenter() {
        if (!editorMap) return QtPositioning.coordinate()
        var coordinate = editorMap.center
        coordinate.latitude  = coordinate.latitude.toFixed(_decimalPlaces)
        coordinate.longitude = coordinate.longitude.toFixed(_decimalPlaces)
        coordinate.altitude  = coordinate.altitude.toFixed(_decimalPlaces)
        return coordinate
    }
    function insertSimpleItemAfterCurrent(coordinate) {
        if (!_missionController) return
        var nextIndex = _missionController.currentPlanViewVIIndex + 1
        _missionController.insertSimpleMissionItem(coordinate, nextIndex, true)
    }
    function insertTakeoffItemAfterCurrent() {
        if (!_missionController) return
        var nextIndex = _missionController.currentPlanViewVIIndex + 1
        _missionController.insertTakeoffItem(mapCenter(), nextIndex, true)
    }
<<<<<<< HEAD
=======
    function insertLandItemAfterCurrent() {
        if (!_missionController) return
        var nextIndex = _missionController.currentPlanViewVIIndex + 1
        _missionController.insertLandItem(mapCenter(), nextIndex, true)
    }
>>>>>>> f9dfdbd69 (commit (clean))
    function selectNextNotReady() {
        if (!_missionController || !_missionController.visualItems) return
        for (var i = 0; i < _missionController.visualItems.count; i++) {
            var vmi = _missionController.visualItems.get(i)
            if (vmi.readyForSaveState === VisualMissionItem.NotReadyForSaveData) {
                _missionController.setCurrentPlanViewSeqNum(vmi.sequenceNumber, true)
                break
            }
        }
    }

<<<<<<< HEAD
=======
    /// QGC처럼 계획 파일 선택 창을 띄워 불러오기 (로컬 저장소 "목록 열기"에서 사용)
    function openPlanFileSelection() {
        if (!_planMasterController) return
        planFileDialog.title =       qsTr("Select Plan File")
        planFileDialog.planFiles =    true
        planFileDialog.nameFilters = _planMasterController.loadNameFilters
        planFileDialog.openForLoad()
    }

    /// 로컬 저장소: 현재 그려진 경로를 선택된 파일 이름으로 저장 (파일 다이얼로그 → saveToFile)
    function openPlanFileSave() {
        if (!_planMasterController) return
        planFileDialog.title =           qsTr("Save Plan")
        planFileDialog.planFiles =       true
        planFileDialog.nameFilters =     _planMasterController.saveNameFilters
        planFileDialog.suggestedFileName = root.selectedPlanPath
        planFileDialog.openForSave()
    }

    /// 서버 저장소: 현재 그려진 경로 + 선택된 파일 이름으로 서버에 저장 요청 (구조만, 서버 미구현)
    function savePlanToServer() {
        if (!_planMasterController || root.selectedPlanPath === "") return
        // TODO: 서버에 현재 계획 + selectedPlanPath 이름으로 저장 요청
    }

    /// 서버 저장소: 선택된 파일에 대해 서버에 삭제 요청 (확인 후 실행, 서버 미구현)
    function requestDeletePlanFromServer() {
        if (root.selectedPlanPath === "") return
        mainWindow.showMessageDialog(qsTr("삭제"),
                                     qsTr("선택된 파일 '%1' 삭제하겠습니다. 계속하시겠습니까?").arg(root.selectedPlanPath),
                                     Dialog.Yes | Dialog.No,
                                     function() {
                                         // TODO: 서버에 선택된 파일(selectedPlanPath) 삭제 요청 후 serverPlanListModel 갱신
                                     })
    }

    /// 서버 저장소: 서버에 계획 목록 요청 (후에 연결할 서버 API 호출)
    function requestServerPlanList() {
        // TODO: 서버 연결 후 목록 요청 → 수신 데이터로 serverPlanListModel 채우기
    }

    /// 서버 저장소: 목록에서 지정된 항목을 서버에 요청하여 계획 파일 받은 뒤 불러오기
    function loadPlanFromServer() {
        if (!_planMasterController || root.selectedPlanPath === "") return
        // TODO: 서버에 선택된 계획(selectedPath 또는 selectedServerPlanId) 요청
        //       → 응답 파일(또는 스트림) 수신 후 임시 파일로 저장 등
        //       → _planMasterController.loadFromFile(파일경로) 및 fitViewportToItems(), setCurrentPlanViewSeqNum(0, true)
    }

    /// 선택된 파일(로컬/서버 공통) 이름 변경 — 로컬: 파일 rename, 서버: API 호출 등 후에 구현
    function renameSelectedPlan(oldName, newName) {
        if (!newName || newName.trim() === "" || newName === oldName) return
        // TODO: 로컬 저장소면 파일 rename, 서버 저장소면 서버 API로 이름 변경 후 serverPlanListModel 갱신
    }

    /// 서버에서 받은 계획 목록 (후에 requestServerPlanList 응답으로 채움). role: name, id 등 확장 가능
    ListModel {
        id: serverPlanListModel
    }

    /// 현재 그려진 경로(계획) 삭제 — QGC removeAll 기반, Mission Start만 남김
    function clearDrawnPlan() {
        if (!_planMasterController) return
        mainWindow.showMessageDialog(qsTr("삭제"),
                                     qsTr("현재 그려진 경로를 모두 삭제하시겠습니까?"),
                                     Dialog.Yes | Dialog.Cancel,
                                     function() {
                                         _planMasterController.removeAll()
                                         if (_missionController)
                                             _missionController.setCurrentPlanViewSeqNum(0, true)
                                     })
    }

    QGCFileDialog {
        id:             planFileDialog
        folder:         _appSettings ? _appSettings.missionSavePath : ""
        property bool planFiles: true
        onAcceptedForLoad: (file) => {
            if (_planMasterController) {
                _planMasterController.loadFromFile(file)
                _planMasterController.fitViewportToItems()
                if (_missionController)
                    _missionController.setCurrentPlanViewSeqNum(0, true)
            }
            var path = file.toString()
            var normalized = path.replace(/\\/g, "/")
            var segments = normalized.split("/").filter(function(s) { return s.length > 0 })
            root.selectedPlanPath = segments.length > 0 ? segments[segments.length - 1] : path
            close()
        }
        onAcceptedForSave: (file) => {
            if (_planMasterController) {
                _planMasterController.saveToFile(file)
            }
            var path = file.toString()
            var normalized = path.replace(/\\/g, "/")
            var segments = normalized.split("/").filter(function(s) { return s.length > 0 })
            root.selectedPlanPath = segments.length > 0 ? segments[segments.length - 1] : path
            close()
        }
    }

>>>>>>> f9dfdbd69 (commit (clean))
    CustomPlanViewToolBar {
        id:                     planToolBar
        visible:                root.showToolbar
        planMasterController:   _planMasterController
    }

    function _ensurePlanViewSeqNum() {
        if (_missionController)
            _missionController.setCurrentPlanViewSeqNum(0, true)
    }
    Component.onCompleted: _ensurePlanViewSeqNum()
    onVisibleChanged: {
        if (visible) {
            // PlanView와 동일: 미션에 항목이 없으면 removeAll()로 0번 Mission Start만 생성
            if (_planMasterController && !_planMasterController.containsItems)
                _planMasterController.removeAll()
            _ensurePlanViewSeqNum()
            initSeqNumTimer.start()
<<<<<<< HEAD
=======
            // Fly 뷰 → Custom Plan 전환 시 editorMap이 FlyViewMap과 동일한 중심/줌을 쓰도록 강제 동기화 (맵 튐/다른 맵 느낌 방지)
            if (editorMap) {
                editorMap.center = QGroundControl.flightMapPosition
                editorMap.zoomLevel = QGroundControl.flightMapZoom
            }
            syncMapTimer.start()
        }
    }
    Timer {
        id: syncMapTimer
        interval: 50
        repeat: false
        onTriggered: {
            if (editorMap) {
                editorMap.center = QGroundControl.flightMapPosition
                editorMap.zoomLevel = QGroundControl.flightMapZoom
            }
>>>>>>> f9dfdbd69 (commit (clean))
        }
    }
    Timer {
        id: initSeqNumTimer
        interval: 150
        repeat: false
        onTriggered: _ensurePlanViewSeqNum()
    }
    Connections {
        target: _planMasterController
        function onControllerVehicleChanged() { _ensurePlanViewSeqNum() }
    }
    Connections {
        target: root
        function on_PlanMasterControllerChanged() { _ensurePlanViewSeqNum() }
    }

<<<<<<< HEAD
    // missionEditor 영역: 지도(좌) + Takeoff/Waypoint 스트립 + 우측 편집 패널은 missionPanel 내 missionEditor에 구성
    Item {
        id: mapPanel
        anchors.left: parent.left
        anchors.right: missionPanel.left
        anchors.top: root.showToolbar ? planToolBar.bottom : parent.top
        anchors.bottom: parent.bottom
        visible: _planMasterController != null

        ToolStripActionList {
            id: customToolStripActionList
            model: [
                ToolStripAction {
                    text: qsTr("Takeoff")
                    iconSource: "/res/takeoff.svg"
                    enabled: _missionController && _missionController.isInsertTakeoffValid
                    visible: (_editingLayer == _layerMission || _editingLayer == _layerUTMSP) && _planMasterController && (!_planMasterController.controllerVehicle || !_planMasterController.controllerVehicle.rover)
                    onTriggered: {
                        addWaypointRallyPointAction.checked = false
                        insertTakeoffItemAfterCurrent()
                        _triggerSubmit = true
                    }
                },
                ToolStripAction {
                    id: addWaypointRallyPointAction
                    text: _editingLayer == _layerRallyPoints ? qsTr("Rally Point") : qsTr("Waypoint")
                    iconSource: "/qmlimages/MapAddMission.svg"
                    enabled: _editingLayer == _layerRallyPoints ? true : (_missionController && _missionController.flyThroughCommandsAllowed)
                    visible: _editingLayer == _layerRallyPoints || _editingLayer == _layerMission || _editingLayer == _layerUTMSP
                    checkable: true
                }
            ]
        }
        ToolStrip {
            id: customToolStrip
            anchors.margins: _toolsMargin
            anchors.left: parent.left
            anchors.top: parent.top
            z: QGroundControl.zOrderWidgets
            maxHeight: parent.height - (customToolStrip.y || 0)
            model: customToolStripActionList.model
        }

=======
    Item {
        id: contentRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: root.showToolbar ? planToolBar.bottom : parent.top
        anchors.bottom: parent.bottom

        Rectangle {
            anchors.fill: parent
            z: -1
            color: "#1a1a1a"
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            Item {
                id: mapPanel
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: _planMasterController !== null
                enabled: root._lastMouseX < root._mapAreaRightEdge

>>>>>>> f9dfdbd69 (commit (clean))
        FlightMap {
            id: editorMap
            anchors.fill: parent
            mapName: "MissionEditor"
            allowGCSLocationCenter: true
            allowVehicleLocationCenter: true
            planView: true
            zoomLevel: QGroundControl.flightMapZoom
            center: QGroundControl.flightMapPosition
            property rect centerViewport: Qt.rect(_leftToolWidth + _margin, _margin, Math.max(0, width - _leftToolWidth - _margin * 2), Math.max(0, height - _margin * 2))
<<<<<<< HEAD
            property real _leftToolWidth: (customToolStrip && customToolStrip.width) ? (customToolStrip.x + customToolStrip.width) : 0
=======
            property real _leftToolWidth: 0
>>>>>>> f9dfdbd69 (commit (clean))
            property real _nonInteractiveOpacity: 0.5
            Component.onCompleted: editorMap.center = QGroundControl.flightMapPosition
            QGCMapPalette { id: mapPal; lightColors: editorMap.isSatelliteMap }
            onZoomLevelChanged: QGroundControl.flightMapZoom = editorMap.zoomLevel
            onCenterChanged: QGroundControl.flightMapPosition = editorMap.center
            onMapClicked: (mouse) => {
                editorMap.focus = true
                var coordinate = editorMap.toCoordinate(Qt.point(mouse.x, mouse.y), false)
                coordinate.latitude = coordinate.latitude.toFixed(_decimalPlaces)
                coordinate.longitude = coordinate.longitude.toFixed(_decimalPlaces)
                coordinate.altitude = coordinate.altitude.toFixed(_decimalPlaces)
                if (_utmspEnabled) QGroundControl.utmspManager.utmspVehicle.updateLastCoordinates(coordinate.latitude, coordinate.longitude)
                switch (_editingLayer) {
                case _layerMission:
<<<<<<< HEAD
                    if (addWaypointRallyPointAction.checked) insertSimpleItemAfterCurrent(coordinate)
                    break
                case _layerRallyPoints:
                    if (_rallyPointController && _rallyPointController.supported && addWaypointRallyPointAction.checked) _rallyPointController.addPoint(coordinate)
                    break
                case _layerUTMSP:
                    if (addWaypointRallyPointAction.checked) insertSimpleItemAfterCurrent(coordinate)
=======
                    if (root._waypointAddMode) insertSimpleItemAfterCurrent(coordinate)
                    break
                case _layerRallyPoints:
                    if (_rallyPointController && _rallyPointController.supported && root._waypointAddMode) _rallyPointController.addPoint(coordinate)
                    break
                case _layerUTMSP:
                    if (root._waypointAddMode) insertSimpleItemAfterCurrent(coordinate)
>>>>>>> f9dfdbd69 (commit (clean))
                    break
                }
            }

            Repeater {
                model: _missionController && _missionController.visualItems ? _missionController.visualItems : []
                delegate: MissionItemMapVisual {
                    map: editorMap
                    opacity: _editingLayer == _layerMission || _editingLayer == _layerUTMSP ? 1 : editorMap._nonInteractiveOpacity
                    interactive: _editingLayer == _layerMission || _editingLayer == _layerUTMSP
                    vehicle: _planMasterController ? _planMasterController.controllerVehicle : null
                    onClicked: (sequenceNumber) => { _missionController.setCurrentPlanViewSeqNum(sequenceNumber, false) }
                }
            }
            MissionLineView {
                showSpecialVisual: _missionController && _missionController.isROIBeginCurrentItem
                model: _missionController ? _missionController.simpleFlightPathSegments : null
                opacity: _editingLayer == _layerMission || _editingLayer == _layerUTMSP ? 1 : editorMap._nonInteractiveOpacity
            }
            MapItemView {
                model: _editingLayer == _layerMission || _editingLayer == _layerUTMSP && _missionController ? _missionController.directionArrows : undefined
                delegate: MapLineArrow {
                    fromCoord: object ? object.coordinate1 : undefined
                    toCoord: object ? object.coordinate2 : undefined
                    arrowPosition: 3
                    z: QGroundControl.zOrderWaypointLines + 1
                }
            }
            MapItemView {
                model: _missionController ? _missionController.incompleteComplexItemLines : null
                delegate: MapPolyline {
                    path: [object.coordinate1, object.coordinate2]
                    line.width: 1
                    line.color: "red"
                    z: QGroundControl.zOrderWaypointLines
                    opacity: _editingLayer == _layerMission ? 1 : editorMap._nonInteractiveOpacity
                }
            }
            MapQuickItem {
                id: splitSegmentItem
                anchorPoint.x: sourceItem.width / 2
                anchorPoint.y: sourceItem.height / 2
                z: QGroundControl.zOrderWaypointLines + 1
                visible: _editingLayer == _layerMission || _editingLayer == _layerUTMSP
                sourceItem: SplitIndicator {
                    onClicked: _missionController.insertSimpleMissionItem(splitSegmentItem.coordinate, _missionController.currentPlanViewVIIndex, true)
                }
                function _updateSplitCoord() {
                    if (_missionController && _missionController.splitSegment) {
                        var d = _missionController.splitSegment.coordinate1.distanceTo(_missionController.splitSegment.coordinate2)
                        var a = _missionController.splitSegment.coordinate1.azimuthTo(_missionController.splitSegment.coordinate2)
                        splitSegmentItem.coordinate = _missionController.splitSegment.coordinate1.atDistanceAndAzimuth(d / 2, a)
                    } else {
                        coordinate = QtPositioning.coordinate()
                    }
                }
                Connections {
                    target: _missionController
                    function onSplitSegmentChanged() { splitSegmentItem._updateSplitCoord() }
                }
                Connections {
                    target: _missionController && _missionController.splitSegment ? _missionController.splitSegment : null
                    function onCoordinate1Changed() { splitSegmentItem._updateSplitCoord() }
                    function onCoordinate2Changed() { splitSegmentItem._updateSplitCoord() }
                }
            }
            MapItemView {
                model: QGroundControl.multiVehicleManager.vehicles
                delegate: VehicleMapItem {
                    vehicle: object
                    coordinate: object.coordinate
                    map: editorMap
                    size: ScreenTools.defaultFontPixelHeight * 3
                    z: QGroundControl.zOrderMapItems - 1
                }
            }
            GeoFenceMapVisuals {
                map: editorMap
                myGeoFenceController: _geoFenceController
                interactive: _editingLayer == _layerGeoFence
                homePosition: _missionController ? _missionController.plannedHomePosition : null
                planView: true
                opacity: _editingLayer != _layerGeoFence ? editorMap._nonInteractiveOpacity : 1
            }
            RallyPointMapVisuals {
                map: editorMap
                myRallyPointController: _rallyPointController
                interactive: _editingLayer == _layerRallyPoints
                planView: true
                opacity: _editingLayer != _layerRallyPoints ? editorMap._nonInteractiveOpacity : 1
            }
            UTMSPMapVisuals {
                id: utmspvisual
                enabled: _utmspEnabled
                map: editorMap
                currentMissionItems: _visualItems
                myGeoFenceController: _geoFenceController
                interactive: _editingLayer == _layerUTMSP
                homePosition: _missionController ? _missionController.plannedHomePosition : null
                planView: true
                opacity: _editingLayer != _layerUTMSP ? editorMap._nonInteractiveOpacity : 1
                resetCheck: _resetGeofencePolygon
            }
            Connections { target: utmspEditor; function onResetGeofencePolygonTriggered() { resetTimer.start() } }
            Timer { id: resetTimer; interval: 2500; repeat: false; onTriggered: { _resetGeofencePolygon = true } }
        }

        MapFitFunctions {
            id: mapFitFunctions
            map: editorMap
            usePlannedHomePosition: true
            planMasterController: _planMasterController
        }
<<<<<<< HEAD
    }

    Item {
        id: missionPanel
        width: root.droneStatusWidth > 0 ? root.droneStatusWidth : parent.width
        anchors.right: parent.right
        anchors.top: root.showToolbar ? planToolBar.bottom : parent.top
        anchors.bottom: parent.bottom
=======
            }

            Item {
                id: missionPanel
                Layout.preferredWidth: root.droneStatusWidth > 0 ? root.droneStatusWidth : 350
                Layout.minimumWidth:  root.droneStatusWidth > 0 ? root.droneStatusWidth : 350
                Layout.maximumWidth:  root.droneStatusWidth > 0 ? root.droneStatusWidth : 350
                Layout.fillHeight: true
                Layout.leftMargin: 2
                Layout.topMargin: 2
                Layout.bottomMargin: 2
                Layout.rightMargin: 2

        MouseArea {
            anchors.fill: parent
            z: -1
            acceptedButtons: Qt.NoButton
            onWheel: (wheel) => wheel.accepted = false
        }

        MouseArea {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: root._missionPanelTopStripHeight
            z: 1
            acceptedButtons: Qt.AllButtons
            onPressed: (mouse) => mouse.accepted = true
            onReleased: (mouse) => mouse.accepted = true
            onPositionChanged: (mouse) => mouse.accepted = true
        }
>>>>>>> f9dfdbd69 (commit (clean))

        Rectangle {
            id: missionPanelBackground
            anchors.fill: parent
            color: "#1a1a1a"
            anchors.topMargin: 10
            anchors.rightMargin: 10
            anchors.bottomMargin: 10

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 15

<<<<<<< HEAD
                // 1. 저장소 선택 버튼 행
=======
>>>>>>> f9dfdbd69 (commit (clean))
                RowLayout {
                    id: storageButtom
                    Layout.fillWidth: true
                    spacing: 10

                    Button {
                        id: localBtn
                        text: qsTr("로컬저장소")
                        checkable: true
                        checked: true
                        autoExclusive: true
                        Layout.fillWidth: true
                        contentItem: Text {
                            text: localBtn.text
                            color: localBtn.checked ? "black" : "#ffffff"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: localBtn.checked ? "#ffffff" : "#4DFFFFFF"
                            radius: 4
                        }
                    }

                    Button {
                        id: serverBtn
                        text: qsTr("서버저장소")
                        checkable: true
                        autoExclusive: true
                        Layout.fillWidth: true
                        contentItem: Text {
                            text: serverBtn.text
                            color: serverBtn.checked ? "black" : "#ffffff"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: serverBtn.checked ? "#ffffff" : "#4DFFFFFF"
                            radius: 4
                        }
                    }
                }

                RowLayout {
                    id: pathHeader
                    Layout.fillWidth: true

                    Text {
                        text: qsTr("비행 경로 불러오기")
                        color: "#ffffff"
                        font.pixelSize: 13
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        id: statusText
<<<<<<< HEAD
                        property string selectedPath: ""
                        text: missionPanelBackground.pathListVisible ? qsTr("닫기 ▲") : (selectedPath === "" ? qsTr("목록 열기 ▼") : selectedPath + " ▼")
=======
                        text: missionPanelBackground.pathListVisible ? qsTr("닫기 ▲") : (serverBtn.checked ? qsTr("목록 요청 ▼") : qsTr("목록 열기 ▼"))
>>>>>>> f9dfdbd69 (commit (clean))
                        color: "#ffffff"
                        font.pixelSize: 13
                        font.bold: true

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
<<<<<<< HEAD
                            onClicked: missionPanelBackground.pathListVisible = !missionPanelBackground.pathListVisible
=======
                            onClicked: {
                                if (missionPanelBackground.pathListVisible) {
                                    missionPanelBackground.pathListVisible = false
                                } else if (serverBtn.checked) {
                                    root.requestServerPlanList()
                                    missionPanelBackground.pathListVisible = true
                                } else {
                                    root.openPlanFileSelection()
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    id: selectedFileRow
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: qsTr("선택된 파일:")
                        color: "#ffffff"
                        font.pixelSize: 12
                        Layout.alignment: Qt.AlignVCenter
                    }

                    TextField {
                        id: selectedFileNameField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        text: root.selectedPlanPath
                        placeholderText: qsTr("선택된 파일 없음")
                        placeholderTextColor: "#888888"
                        color: "#ffffff"
                        font.pixelSize: 12
                        background: Rectangle {
                            color: "#252525"
                            border.color: selectedFileNameField.activeFocus ? "#666666" : "#444444"
                            radius: 4
                        }
                        onEditingFinished: {
                            var newName = text.trim()
                            if (newName !== "" && newName !== root.selectedPlanPath) {
                                root.renameSelectedPlan(root.selectedPlanPath, newName)
                                root.selectedPlanPath = newName
                            }
>>>>>>> f9dfdbd69 (commit (clean))
                        }
                    }
                }

                RowLayout {
                    id: fileAction
                    Layout.fillWidth: true
                    spacing: 8

                    Button {
                        id: saveBtn
                        text: qsTr("저장")
                        Layout.fillWidth: true
<<<<<<< HEAD
                    }
=======
                        onClicked: {
                            if (localBtn.checked)
                                root.openPlanFileSave()
                            else
                                root.savePlanToServer()
                        }
                    }

>>>>>>> f9dfdbd69 (commit (clean))
                    Button {
                        id: loadBtn
                        text: qsTr("불러오기")
                        Layout.fillWidth: true
<<<<<<< HEAD
                        enabled: statusText.selectedPath !== ""
                    }
                    Button {
                        id: deleteBtn
                        text: qsTr("삭제")
                        Layout.fillWidth: true
=======
                        enabled: !localBtn.checked && root.selectedPlanPath !== ""
                        onClicked: {
                            if (serverBtn.checked)
                                root.loadPlanFromServer()
                        }
                    }

                    Button {
                        id: deleteBtn
                        text: localBtn.checked ? qsTr("경로 전체 삭제") : qsTr("삭제")
                        Layout.fillWidth: true
                        onClicked: {
                            if (localBtn.checked)
                                root.clearDrawnPlan()
                            else
                                root.requestDeletePlanFromServer()
                        }
>>>>>>> f9dfdbd69 (commit (clean))
                    }
                }

                RowLayout {
                    id: deviceSelectInfo
                    Layout.fillWidth: true

                    Item { Layout.fillWidth: true }

                    Text {
                        text: root.deviceName === "" ? qsTr("대상 기체를 선택하시오") : qsTr("선택된 기체: ") + root.deviceName
                        color: "#ffffff"
                        font.pixelSize: 14
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Item { Layout.fillWidth: true }
                }

                RowLayout{

                    id: deviceAction
                    Layout.fillWidth: true
                    spacing: 8

                    Button{
<<<<<<< HEAD
=======
                        id: uploadBtn
                        text: qsTr("업로드")
                        Layout.fillWidth: true
                        enabled: root.deviceName !== ""
                    }

                    Button{
>>>>>>> f9dfdbd69 (commit (clean))
                        id: deviceLoadBtn
                        text: qsTr("경로 불러오기")
                        Layout.fillWidth: true
                        enabled: root.deviceName !== ""
                    }

                    Button{
                        id: deviceDeleteBtn
                        text: qsTr("업로드 경로 삭제")
                        Layout.fillWidth: true
                        enabled: root.deviceName !== ""
                    }

                }

<<<<<<< HEAD
                // missionEditor: Takeoff/Waypoint 버튼 + 우측 편집 패널(탭·미션/펜스/랠리/UTMSP). 지형 라이선스 미포함.
=======
>>>>>>> f9dfdbd69 (commit (clean))
                ColumnLayout {
                    id: missionEditor
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: ScreenTools.defaultFontPixelHeight * 0.25

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        QGCButton {
                            text: qsTr("Takeoff")
                            enabled: _missionController && _missionController.isInsertTakeoffValid
                            visible: (_editingLayer == _layerMission || _editingLayer == _layerUTMSP) && _planMasterController && (!_planMasterController.controllerVehicle || !_planMasterController.controllerVehicle.rover)
                            onClicked: {
<<<<<<< HEAD
                                if (addWaypointRallyPointAction) addWaypointRallyPointAction.checked = false
=======
                                root._waypointAddMode = false
>>>>>>> f9dfdbd69 (commit (clean))
                                insertTakeoffItemAfterCurrent()
                                _triggerSubmit = true
                            }
                        }
                        QGCButton {
                            id: addWaypointBtn
                            text: _editingLayer == _layerRallyPoints ? qsTr("Rally Point") : qsTr("Waypoint")
                            checkable: true
                            enabled: _editingLayer == _layerRallyPoints ? true : (_missionController && _missionController.flyThroughCommandsAllowed)
                            visible: _editingLayer == _layerRallyPoints || _editingLayer == _layerMission || _editingLayer == _layerUTMSP
<<<<<<< HEAD
                            onClicked: { if (addWaypointRallyPointAction) addWaypointRallyPointAction.checked = addWaypointBtn.checked }
                        }
=======
                            onClicked: root._waypointAddMode = addWaypointBtn.checked
                        }

                        QGCButton {
                            id:       addRTLBtn
                            text:     qsTr("Return")
                            enabled:  _missionController && _missionController.isInsertLandValid
                            visible:  _editingLayer == _layerMission || _editingLayer == _layerUTMSP
                            onClicked: {
                                root._waypointAddMode = false
                                // Return(RTL) 아이템을 현재 위치 다음에 삽입
                                insertLandItemAfterCurrent()
                                _triggerSubmit = true
                            }
                        }

                        Button{
                            id: landPointBtn
                            text: qsTr("Land")
                            enabled:  _missionController && _missionController.isInsertLandValid
                            visible:  _editingLayer == _layerMission || _editingLayer == _layerUTMSP
                            onClicked: stationLandPoint.open()
                        }

>>>>>>> f9dfdbd69 (commit (clean))
                        Item { Layout.fillWidth: true }
                    }
                    Binding {
                        target: addWaypointBtn
                        property: "checked"
<<<<<<< HEAD
                        value: addWaypointRallyPointAction ? addWaypointRallyPointAction.checked : false
                        when: addWaypointRallyPointAction != null
=======
                        value: root._waypointAddMode
>>>>>>> f9dfdbd69 (commit (clean))
                    }

                    QGCTabBar {
                        id: customLayerTabBar
                        Layout.fillWidth: true
                        visible: !_utmspEnabled
                        Component.onCompleted: { currentIndex = 0; root._customEditingLayer = root._layers[0] }
                        onCurrentIndexChanged: root._customEditingLayer = root._layers[currentIndex]
                        QGCTabButton { text: qsTr("Mission") }
                        QGCTabButton { text: qsTr("Fence"); enabled: _geoFenceController && _geoFenceController.supported }
                        QGCTabButton { text: qsTr("Rally"); enabled: _rallyPointController && _rallyPointController.supported }
                    }
                    QGCTabBar {
                        id: customLayerTabBarUTMSP
                        Layout.fillWidth: true
                        visible: _utmspEnabled
                        Component.onCompleted: { currentIndex = 0; root._customEditingLayer = root._layersUTMSP[0] }
                        onCurrentIndexChanged: root._customEditingLayer = root._layersUTMSP[currentIndex]
                        QGCTabButton { text: qsTr("Mission") }
                        QGCTabButton { text: qsTr("Rally"); enabled: _rallyPointController && _rallyPointController.supported }
                        QGCTabButton { text: qsTr("UTM-Adapter"); visible: _utmspEnabled }
                    }

                    Item {
                        id: missionEditorListContainer
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        QGCListView {
                            id: missionItemEditorListView
                            anchors.fill: parent
                            spacing: ScreenTools.defaultFontPixelHeight / 4
                            orientation: ListView.Vertical
                            model: _missionController ? _missionController.visualItems : null
                            cacheBuffer: Math.max(height * 2, 0)
                            clip: true
                            currentIndex: _missionController ? _missionController.currentPlanViewSeqNum : -1
                            highlightMoveDuration: 250
                            visible: _editingLayer == _layerMission
                            delegate: CustomMissionItemEditor {
                                map: editorMap
                                masterController: _planMasterController
                                missionItem: object
                                listView: missionItemEditorListView
                                width: missionItemEditorListView.width
                                readOnly: false
                                onClicked: (sequenceNumber) => { _missionController.setCurrentPlanViewSeqNum(object.sequenceNumber, false) }
                                onRemove: {
                                    var removeVIIndex = index
                                    _missionController.removeVisualItem(removeVIIndex)
                                    if (removeVIIndex >= _missionController.visualItems.count) removeVIIndex--
                                }
                                onSelectNextNotReadyItem: selectNextNotReady()
                            }
                        }
                        // 단일 DropArea 오버레이: 드롭을 여기서 받아 indexAt + move 수행. release는 다른 행으로 가므로 delegate onReleased 미호출 문제 회피.
                        Item {
                            id: missionReorderOverlay
                            anchors.fill: missionItemEditorListView
                            z: 1000
                            visible: _editingLayer == _layerMission
                            DropArea {
                                anchors.fill: parent
                                keys: ["mission-item-reorder"]
                                onEntered: (drag) => {
<<<<<<< HEAD
                                    if (drag.source && drag.source._dragStartIndex !== undefined && drag.source._dragStartIndex >= 2)
                                        drag.accepted = true
=======
                                    var from = drag.source && drag.source._dragStartIndex !== undefined ? drag.source._dragStartIndex : -1
                                    if (drag.source && drag.source._dragStartIndex !== undefined && drag.source._dragStartIndex >= 2)
                                        drag.accepted = true
                                    console.log("[MissionReorder] overlay onEntered fromIdx=" + from + " accepted=" + drag.accepted)
>>>>>>> f9dfdbd69 (commit (clean))
                                }
                                onDropped: (drag) => {
                                    if (!drag.source || !_missionController || typeof CustomMissionReorderHelper === "undefined" || !CustomMissionReorderHelper.moveVisualItem)
                                        return
                                    var fromIdx = drag.source._dragStartIndex
                                    if (fromIdx === undefined || fromIdx < 0) {
                                        var model = _missionController.visualItems
                                        if (!model) return
                                        for (var i = 0; i < model.count; i++) {
                                            if (model.get(i) === drag.source.missionItem) {
                                                fromIdx = i
                                                break
                                            }
                                        }
                                    }
                                    var p = missionReorderOverlay.mapToItem(missionItemEditorListView.contentItem, drag.x, drag.y)
                                    var toIdx = missionItemEditorListView.indexAt(p.x, p.y)
<<<<<<< HEAD
                                    if (fromIdx >= 2 && toIdx >= 2 && fromIdx !== toIdx) {
                                        CustomMissionReorderHelper.moveVisualItem(_missionController, fromIdx, toIdx)
                                        if (missionItemEditorListView.forceLayout)
                                            Qt.callLater(missionItemEditorListView.forceLayout)
                                    }
=======
                                    console.log("[MissionReorder] overlay onDropped drag.x=" + drag.x + " drag.y=" + drag.y + " p.x=" + p.x + " p.y=" + p.y + " fromIdx=" + fromIdx + " toIdx(indexAt)=" + toIdx)
                                    if (toIdx < 2 || fromIdx < 2 || fromIdx === toIdx) {
                                        console.log("[MissionReorder] overlay SKIP toIdx<2=" + (toIdx < 2) + " fromIdx===toIdx=" + (fromIdx === toIdx))
                                        return
                                    }
                                    var item = missionItemEditorListView.itemAtIndex(toIdx)
                                    if (!item) {
                                        console.log("[MissionReorder] overlay SKIP item is null for toIdx=" + toIdx)
                                        return
                                    }
                                    var inRow = p.x >= item.x && p.x < item.x + item.width && p.y >= item.y && p.y < item.y + item.height
                                    console.log("[MissionReorder] overlay item bounds x=" + item.x + " y=" + item.y + " w=" + item.width + " h=" + item.height + " inRow=" + inRow)
                                    if (!inRow) {
                                        console.log("[MissionReorder] overlay SKIP not inRow")
                                        return
                                    }
                                    console.log("[MissionReorder] overlay CALL moveVisualItem(" + fromIdx + "," + toIdx + ")")
                                    CustomMissionReorderHelper.moveVisualItem(_missionController, fromIdx, toIdx)
                                    if (missionItemEditorListView.forceLayout)
                                        Qt.callLater(missionItemEditorListView.forceLayout)
>>>>>>> f9dfdbd69 (commit (clean))
                                }
                            }
                            Item {
                                id: reorderDragTargetRef
                                width: 1
                                height: 1
                            }
                        }
                        Component.onCompleted: missionItemEditorListView.reorderDragTarget = reorderDragTargetRef
                        GeoFenceEditor {
                            anchors.fill: parent
                            myGeoFenceController: _geoFenceController
                            flightMap: editorMap
                            visible: _editingLayer == _layerGeoFence
                        }
                        RallyPointEditorHeader {
                            id: customRallyPointHeader
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            controller: _rallyPointController
                            visible: _editingLayer == _layerRallyPoints
                        }
                        RallyPointItemEditor {
                            anchors.top: customRallyPointHeader.bottom
                            anchors.topMargin: ScreenTools.defaultFontPixelHeight * 0.25
                            anchors.left: parent.left
                            anchors.right: parent.right
                            rallyPoint: _rallyPointController ? _rallyPointController.currentRallyPoint : null
                            controller: _rallyPointController
                            visible: _editingLayer == _layerRallyPoints && _rallyPointController && _rallyPointController.points.count
                        }
                        UTMSPAdapterEditor {
                            id: utmspEditor
                            enabled: _utmspEnabled
                            anchors.fill: parent
                            currentMissionItems: _visualItems
                            myGeoFenceController: _geoFenceController
                            flightMap: editorMap
                            visible: _editingLayer == _layerUTMSP
                            triggerSubmitButton: _triggerSubmit
                            resetRegisterFlightPlan: _resetRegisterFlightPlan
                        }
                        Connections {
                            target: utmspEditor
                            function onRemoveFlightPlanTriggered() {
                                if (_planMasterController) _planMasterController.removeAllFromVehicle()
                                if (_missionController) _missionController.setCurrentPlanViewSeqNum(0, true)
                                if (_utmspEnabled) _resetRegisterFlightPlan = true
                            }
                        }
                    }
                }
            }

            Popup {
<<<<<<< HEAD
=======
                id: stationLandPoint
                anchors.centerIn: Overlay.overlay
                modal: true
                focus: true
                closePolicy: Popup.CloseOnEscape | Popup.CloseOnReleaseOutside

                padding: 0
                background: Item {}

                width: contentItem.implicitWidth
                height: contentItem.implicitHeight

                QGCPalette { id: qgcPal; colorGroupEnabled: true }

                contentItem: Rectangle {

                    radius: 4
                    color: qgcPal.windowShade
                    border.color: qgcPal.separator
                    border.width: 1

                    property int pad: ScreenTools.defaultFontPixelHeight * 0.8
                    property int gap: ScreenTools.defaultFontPixelWidth * 1.0
                    property int minW: ScreenTools.defaultFontPixelWidth * 90
                    property int minH: ScreenTools.defaultFontPixelHeight * 6.5

                    implicitWidth: Math.max(minW, layout.implicitWidth + pad * 2)
                    implicitHeight: Math.max(minH, layout.implicitHeight + pad * 2)

                    RowLayout {
                        id: layout
                        anchors.fill: parent
                        anchors.margins: parent.pad
                        spacing: parent.gap

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: ScreenTools.defaultFontPixelHeight * 0.6

                            Label {
                                text: qsTr("착륙 지점 선택하세요")
                                color: qgcPal.text
                                font.pixelSize: ScreenTools.defaultFontPixelHeight * 1.15
                                font.bold: true
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                radius: 2
                                color: qgcPal.window
                                border.color: qgcPal.separator
                                border.width: 1
                                implicitHeight: ScreenTools.defaultFontPixelHeight * 2.6

                                Repeater{
                                    ScrollView{
                                    // 스테이션 위치 정보 값
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignTop
                            spacing: ScreenTools.defaultFontPixelWidth * 0.7

                            QGCButton {
                                text: qsTr("Cancel")
                                onClicked: stationLandPoint.close()
                            }

                            QGCButton {
                                text: qsTr("Yes")
                                primary: true
                                onClicked: {
                                    stationLandPoint.close()
                                }
                            }
                        }
                    }
                }
            }

            Popup {
>>>>>>> f9dfdbd69 (commit (clean))
                id: pathContainer
                visible: missionPanelBackground.pathListVisible
                parent: pathHeader
                x: 0
                y: pathHeader.height + 5
<<<<<<< HEAD
                // x: pathHeader.mapToItem(missionPanelBackground, 0, 0).x
                // y: pathHeader.mapToItem(missionPanelBackground, 0, pathHeader.height).y + 5
=======
>>>>>>> f9dfdbd69 (commit (clean))
                width: pathHeader.width
                height: 150
                padding: 0
                margins: 0
                background: Rectangle {
                    color: "#252525"
                    radius: 4
                    border.color: "#444444"
                }
<<<<<<< HEAD
                contentItem: ScrollView {
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded
                    contentWidth: pathListView.width
                    contentHeight: pathListView.contentHeight

                    ListView {
                        id: pathListView
                        model: localBtn.checked ? ["Local_Path_01", "Local_Path_02", "Local_Path_03", "Local_Path_04"]
                                                : ["Server_Path_A", "Server_Path_B", "Server_Path_C"]
                        delegate: ItemDelegate {
                            width: pathContainer.width - 20
                            text: modelData

                            contentItem: Text {
                                text: parent.text
                                color: parent.down ? "#aaaaaa" : "#ffffff"
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 10
                            }

                            onClicked: {
                                statusText.selectedPath = modelData
                                missionPanelBackground.pathListVisible = false
=======
                contentItem: Item {
                    width: pathContainer.width
                    height: pathContainer.height
                    // 서버 저장소용 목록만 표시 (로컬은 목록 열기 시 파일 다이얼로그만 사용)
                    Text {
                        anchors.centerIn: parent
                        visible: root.serverPlanListModel.count === 0
                        text: qsTr("서버 연결 후 '목록 요청'을 눌러 주세요.")
                        color: "#aaaaaa"
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                    }
                    ScrollView {
                        anchors.fill: parent
                        visible: root.serverPlanListModel.count > 0
                        ScrollBar.vertical.policy: ScrollBar.AsNeeded
                        contentWidth: serverPathListView.width
                        contentHeight: serverPathListView.contentHeight
                        ListView {
                            id: serverPathListView
                            model: root.serverPlanListModel
                            delegate: ItemDelegate {
                                width: pathContainer.width - 20
                                text: (typeof model.name !== "undefined") ? model.name : ""
                                contentItem: Text {
                                    text: parent.text
                                    color: parent.down ? "#aaaaaa" : "#ffffff"
                                    verticalAlignment: Text.AlignVCenter
                                    leftPadding: 10
                                }
                                onClicked: {
                                    root.selectedPlanPath = (typeof model.name !== "undefined") ? model.name : ""
                                    missionPanelBackground.pathListVisible = false
                                    // TODO: 서버에서 선택한 계획 불러오기
                                }
>>>>>>> f9dfdbd69 (commit (clean))
                            }
                        }
                    }
                }
            }

            property bool pathListVisible: false
        }
<<<<<<< HEAD
=======
            }
        }
    }

    property real _missionPanelTopStripHeight: 24
    /// CustomFlyView와 동일: 맵 영역 우측 경계(루트 기준 x). 좌|맵|우 레이아웃에서 우측 패널 왼쪽 = 맵 영역 끝
    readonly property real _mapAreaRightEdge: contentRow ? (contentRow.x + missionPanel.x) : 0

    MouseArea {
        anchors.fill: parent
        z: 10000
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons
        onPositionChanged: (mouse) => { root._lastMouseX = mouse.x; mouse.accepted = (mouse.x >= root._mapAreaRightEdge) }
        onPressed: (mouse) => {
            root._lastMouseX = mouse.x
            mouse.accepted = (mouse.x >= root._mapAreaRightEdge && mouse.y < root._missionPanelTopStripHeight)
        }
        onReleased: (mouse) => {
            root._lastMouseX = mouse.x
            mouse.accepted = (mouse.x >= root._mapAreaRightEdge && mouse.y < root._missionPanelTopStripHeight)
        }

        onWheel: (wheel) => {
            root._lastMouseX = wheel.x
            wheel.accepted = false
        }
>>>>>>> f9dfdbd69 (commit (clean))
    }
}
