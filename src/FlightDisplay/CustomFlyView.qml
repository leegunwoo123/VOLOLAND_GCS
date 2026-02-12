import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import QtLocation
import QtPositioning
import QtQuick.Window
import QtQml.Models

import QGroundControl
import QGroundControl.Controllers
import QGroundControl.Controls
import QGroundControl.FactSystem
import QGroundControl.FlightDisplay
import QGroundControl.FlightMap
import QGroundControl.Palette
import QGroundControl.ScreenTools
import QGroundControl.Vehicle
import QGroundControl.Toolbar
<<<<<<< HEAD

// 3D Viewer modules
=======
import QGroundControl.Palette
import QGroundControl.ScreenTools
>>>>>>> f9dfdbd69 (commit (clean))
import Viewer3D

RowLayout {
    id: root
<<<<<<< HEAD
    // 부모(MainWindow RowLayout)가 Layout.fillWidth/fillHeight 등으로 크기 지정 → anchors 사용 시 경고/미정의 동작
    spacing: 0

    /// Plan 뷰가 켜져 있을 때 true. 이때 좌측 droneStatus만 표시하고 중앙/우측은 숨김
    property bool planViewActive: false
    /// 좌측 DroneList에서 선택한 기체명 (CustomPlanView 등에서 deviceName 바인딩용)
    readonly property string selectedDeviceName: droneList.selectedDevice

    readonly property real sidebarWidth: mainWindow.width * 0.20
    readonly property real sidebarMaxWidth: 350 * 1.25

    // 좌측: 드론 상태 (빈 영역 드래그 시 맵으로 이벤트 전달 방지)
    Item {
        Layout.preferredWidth: Math.min(root.sidebarWidth, root.sidebarMaxWidth)
        Layout.minimumWidth: 200
        Layout.maximumWidth: root.sidebarMaxWidth
        Layout.fillHeight: true
        Layout.leftMargin: 10
        Layout.topMargin: 10
        Layout.bottomMargin: 10
=======
    spacing: 0

    property bool planViewActive: false
    property var planMasterController: null
    readonly property var planController: planMasterController
    readonly property var guidedController: null
    readonly property string selectedDeviceName: droneList.selectedDevice
    /// MainWindow/CustomPlanView에서 좌측 패널 너비 동기화용
    readonly property real leftPanelWidth: leftPanelItem.width
    readonly property real sidebarWidth: mainWindow.width * 0.20
    readonly property real sidebarMaxWidth: 350 * 1.25

    property bool _cursorOverSidePanels: _cursorOverLeftPanel || _cursorOverRightPanel
    property bool _cursorOverLeftPanel: leftPanelHoverArea.containsMouse
    property bool _cursorOverRightPanel: rightPanelHoverArea.containsMouse
    property bool rightPanelStationVisible: true

    Item {
        id: leftPanelItem
        // root(=CustomFlyView)가 너비 0으로 접힐 때 레이아웃에서 완전히 제외되도록 방어
        visible: root.width > 0
        Layout.preferredWidth: root.width > 0 ? Math.min(root.sidebarWidth, root.sidebarMaxWidth) : 0
        Layout.minimumWidth: root.width > 0 ? 200 : 0
        Layout.maximumWidth: root.width > 0 ? root.sidebarMaxWidth : 0
        Layout.fillHeight: root.width > 0
        Layout.leftMargin: 2
        Layout.topMargin: 2
        Layout.bottomMargin: 2
        Layout.rightMargin: 2

        // Fly / CustomPlan 전환 시 좌측 패널 실제 폭 확인용 로그
        onWidthChanged: {
            console.log("[CustomFlyView] leftPanelItem.width =", width,
                        " planViewActive =", root.planViewActive,
                        " _planViewShown =", mainWindow._planViewShown,
                        " _customPlanViewShown =", mainWindow._customPlanViewShown)
        }
>>>>>>> f9dfdbd69 (commit (clean))

        MouseArea {
            anchors.fill: parent
            z: -1
            acceptedButtons: Qt.AllButtons
            onPressed: (mouse) => { mouse.accepted = true }
            onReleased: (mouse) => { mouse.accepted = true }
<<<<<<< HEAD
=======
            onWheel: (wheel) => { wheel.accepted = true }
>>>>>>> f9dfdbd69 (commit (clean))
        }

        ColumnLayout {
            id: droneStatus
            anchors.fill: parent
            spacing: 2

<<<<<<< HEAD
        DroneList {
            id:                     droneList
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 350
            Layout.minimumHeight: 300
            // fillHeight를 사용할 때는 minimumHeight를 제거하거나 낮춰야
            // 다른 컴포넌트들이 필요한 공간을 먼저 확보한 후 남은 공간을 차지하도록 함
            // Layout.preferredWidth: droneStatus.width
            Layout.preferredWidth: parent.width
            // Layout.preferredHeight: droneStatus.height
            // ColumnLayout에서 아래 위젯들과 공간을 나눠야 하므로, 리스트가 전체 높이를 선점하지 않도록 제거
            Layout.maximumWidth: 350 * 1.25
        
            utmspSendActTrigger:    _utmspSendActTrigger
        }

        CustomHUDWidget{
            id: customHUDWidget
            Layout.fillWidth: true
            // preferredWidth는 숫자여야 함 (Item이 아니라 width)
            // Layout.preferredWidth: droneStatus.width
            Layout.preferredWidth: droneStatus.width
            // 다른 카드들과 동일하게 너무 커지지 않도록 캡
            Layout.maximumWidth: 350 * 1.25
            // 높이는 CustomHUDWidget.qml 내부에서 설정됨 (100으로 고정)
            // 여기서 중복 설정하지 않음

        }

        DroneVideo{
    
            id: droneVideo
            Layout.fillWidth: true
            //Layout.fillHeight: true
            Layout.minimumWidth: 350
            Layout.minimumHeight: 200
            // Layout.preferredWidth: droneStatus.width
            Layout.preferredWidth: droneStatus.width
            //Layout.preferredHeight: droneVideo.width * 0.75
            Layout.preferredHeight: Layout.preferredWidth * 0.75
            Layout.maximumWidth: 350 * 1.25
            Layout.maximumHeight: 200 * 1.25
        
            deviceName: droneList.selectedDevice

            //visible: droneList.selectedDevice !== ""
        }

        DroneStatusMessage{

            id: droneStatusMessage
            Layout.fillWidth: true
            Layout.minimumHeight: 100
            // Layout.minimumWidth: droneStatus.width
            Layout.minimumWidth: 350
            // Layout.preferredWidth: droneStatus.width
            Layout.preferredWidth: droneStatus.width
            // Layout.preferredHeight: droneStatus.width * 0.35
            Layout.preferredHeight: Layout.preferredWidth * 0.35
            Layout.maximumWidth: 350 * 1.25
            Layout.maximumHeight: 100 * 1.25
    
        
            deviceName: droneList.selectedDevice

            //visible: droneList.selectedDevice !== ""
        }

        //Item { Layout.fillHeight: true }

        DroneControlPanel{
            id: controlPanel
            Layout.fillWidth: true
            Layout.minimumHeight: droneControlButton.implicitHeight + 20
            // Layout.minimumWidth: droneStatus.width
            Layout.minimumWidth: 350
            // Layout.preferredWidth: droneStatus.width
            Layout.preferredWidth: droneStatus.width
            Layout.preferredHeight: droneControlButton.implicitHeight + 20
            Layout.maximumWidth: 350 * 1.25
            Layout.maximumHeight: 300 * 1.25
            Layout.alignment: Qt.AlignBottom

            deviceName: droneList.selectedDevice
            backend: backendClient

            //visible: droneList.selectedDevice !== ""
        }
        }
    }

    // 중앙: 지도/메인 콘텐츠 영역 (좌·우 사이드바가 붙지 않도록 공간 차지). Plan 뷰 활성 시 숨김
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: !root.planViewActive
    }

    // 우측: 스테이션 상태 (버튼 포함). Plan 뷰 활성 시 숨김
    Item {
        id: stationStatusContainer
        visible: !root.planViewActive
        Layout.preferredWidth: stationStatusVisible ? Math.min(root.sidebarWidth, root.sidebarMaxWidth) : 40
        Layout.minimumWidth: 40 // 버튼(20) + 좌측마진(10) + 여유(10) = 항상 버튼이 보이도록
        Layout.maximumWidth: stationStatusVisible ? root.sidebarMaxWidth : 40
        Layout.fillHeight: true
        
        property bool stationStatusVisible: true

        // 빈 영역 드래그 시 맵으로 이벤트 전달 방지
=======
            DroneList {
                id:                     droneList
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: root.width > 0 ? 350 : 0
                Layout.minimumHeight: 300
                Layout.preferredWidth: parent.width
                Layout.maximumWidth: 350 * 1.25
                utmspSendActTrigger:    _utmspSendActTrigger
            }

            CustomHUDWidget{
                id: customHUDWidget
                Layout.fillWidth: true
                Layout.preferredWidth: droneStatus.width
                Layout.maximumWidth: 350 * 1.25
            }

            DroneVideo{

                id: droneVideo
                Layout.fillWidth: true
                Layout.minimumWidth: root.width > 0 ? 350 : 0
                Layout.minimumHeight: 200
                Layout.preferredWidth: droneStatus.width
                Layout.preferredHeight: Layout.preferredWidth * 0.75
                Layout.maximumWidth: 350 * 1.25
                Layout.maximumHeight: 200 * 1.25

                deviceName: droneList.selectedDevice
                //visible: droneList.selectedDevice !== ""
            }

            DroneStatusMessage{

                id: droneStatusMessage
                Layout.fillWidth: true
                Layout.minimumHeight: 100
                Layout.minimumWidth: root.width > 0 ? 350 : 0
                Layout.preferredWidth: droneStatus.width
                Layout.preferredHeight: Layout.preferredWidth * 0.35
                Layout.maximumWidth: 350 * 1.25
                Layout.maximumHeight: 100 * 1.25

                deviceName: droneList.selectedDevice
                //visible: droneList.selectedDevice !== ""
            }

            DroneControlPanel{
                id: controlPanel
                Layout.fillWidth: true
                // 실제 높이는 DroneControlPanel 내부에서 implicitHeight로 결정되므로,
                // 여기서는 그 값을 그대로 사용하고, 내부 id(droneControlButton)는 직접 참조하지 않는다.
                Layout.minimumHeight: controlPanel.implicitHeight
                Layout.minimumWidth: root.width > 0 ? 350 : 0
                Layout.preferredWidth: droneStatus.width
                Layout.preferredHeight: controlPanel.implicitHeight
                Layout.maximumWidth: 350 * 1.25
                Layout.maximumHeight: 300 * 1.25
                Layout.alignment: Qt.AlignBottom

                deviceName: droneList.selectedDevice
                // backend 연동은 아직 구현 전이므로 일단 null로 둔다.
                backend: null

                //visible: droneList.selectedDevice !== ""
            }
        }

        MouseArea {
            id: leftPanelHoverArea
            anchors.fill: parent
            z: 1
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }
    }

    Item {
        id: mapHolder
        Layout.fillWidth: !root.planViewActive
        Layout.fillHeight: !root.planViewActive
        // QML double 속성에는 undefined를 넣지 않고, 중앙 맵 칼럼 폭은 fillWidth/visible로만 제어한다.
        Layout.preferredWidth: 0
        Layout.minimumWidth:  0
        visible: !root.planViewActive

        QtObject {
            id: _flyToolInsets
            property real leftEdgeCenterInset: 0
            property real leftEdgeTopInset: 0
            property real leftEdgeBottomInset: 0
            property real rightEdgeCenterInset: 0
            property real rightEdgeTopInset: 0
            property real rightEdgeBottomInset: 0
            property real topEdgeCenterInset: 0
            property real topEdgeLeftInset: 0
            property real topEdgeRightInset: 0
            property real bottomEdgeCenterInset: 0
            property real bottomEdgeLeftInset: 0
            property real bottomEdgeRightInset: 0
        }
        Item {
            id: _pipView
            visible: false
        }
        FlyViewMap {
            id: mapControl
            anchors.fill: parent
            planMasterController: root.planMasterController
            rightPanelWidth: ScreenTools.defaultFontPixelHeight * 9
            pipView: _pipView
            pipMode: false
            toolInsets: _flyToolInsets
            mapName: "FlightDisplayView"
            enabled: !viewer3DWindow.isOpen && !root._cursorOverSidePanels
        }
        Viewer3D {
            id: viewer3DWindow
            anchors.fill: parent
        }

        Item {
            id: stationToggleButton
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: 2
            anchors.topMargin: 2
            width: 20
            height: 20
            z: 1000

            MouseArea {
                anchors.fill: parent
                onClicked: root.rightPanelStationVisible = !root.rightPanelStationVisible
            }

            Text {
                anchors.centerIn: parent
                text: root.rightPanelStationVisible ? "▶" : "◀"
                color: "#ffffff"
                font.pixelSize: 12
            }
        }

        Item {
            id: vehicleCurrentPostion
            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.bottom: parent.bottom
            height: ScreenTools.defaultFontPixelHeight * 4
            z: 10

            Rectangle {
                id: vehicleCurrentPostion_background
                anchors.fill: parent
                color: qgcPal.window
                opacity: 0.85
                radius: 4
                border.color: qgcPal.windowShade
                border.width: 1
            }

            Canvas {
                id: currentPositionVisual
                anchors.fill: parent
                anchors.margins: ScreenTools.defaultFontPointSize

                onTotalWpCountChanged: requestPaint()
                onCurrentWpIndexChanged: requestPaint()

                property int totalWpCount: 15
                property int currentWpIndex: 8

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);

                    if (totalWpCount < 2) return;

                    var padding = 40;
                    var drawWidth = width - (padding * 2);
                    var centerY = height / 2 + 10;
                    var stepX = drawWidth / (totalWpCount - 1);

                    ctx.strokeStyle = qgcPal.text;
                    ctx.setLineDash([6, 4]);
                    ctx.lineWidth = 1.5;
                    ctx.beginPath();
                    ctx.moveTo(padding, centerY);
                    ctx.lineTo(width - padding, centerY);
                    ctx.stroke();
                    ctx.setLineDash([]);
                    ctx.font = ScreenTools.smallFontPointSize + "pt " + ScreenTools.normalFontFamily;
                    ctx.textAlign = "center";

                    for (var i = 0; i < totalWpCount; i++) {
                        var posX = padding + (i * stepX);
                        ctx.fillStyle = (i === currentWpIndex) ? "#E05E00" : qgcPal.text;
                        ctx.fillText(i + 1, posX, centerY - 15);

                        ctx.beginPath();
                        if (i === currentWpIndex) {
                            ctx.fillStyle = "#E05E00";
                            ctx.arc(posX, centerY, 7, 0, 2 * Math.PI);
                            ctx.fill();
                            ctx.strokeStyle = "white";
                            ctx.lineWidth = 2;
                            ctx.stroke();
                        } else {
                            ctx.fillStyle = "white";
                            ctx.arc(posX, centerY, 4, 0, 2 * Math.PI);
                            ctx.fill();
                        }
                    }
                }
            }
        }
    }

    Item {
        id: rightPanelItem
        visible: !root.planViewActive
        Layout.preferredWidth: root.planViewActive ? 0 : (root.rightPanelStationVisible ? Math.min(root.sidebarWidth, root.sidebarMaxWidth) : 0)
        Layout.minimumWidth: root.planViewActive ? 0 : (root.rightPanelStationVisible ? 200 : 0)
        Layout.maximumWidth: root.planViewActive ? 0 : (root.rightPanelStationVisible ? root.sidebarMaxWidth : 0)
        Layout.fillHeight: !root.planViewActive
        Layout.leftMargin: 2
        Layout.topMargin: 2
        Layout.bottomMargin: 2
        Layout.rightMargin: 2

>>>>>>> f9dfdbd69 (commit (clean))
        MouseArea {
            anchors.fill: parent
            z: -1
            acceptedButtons: Qt.AllButtons
            onPressed: (mouse) => { mouse.accepted = true }
            onReleased: (mouse) => { mouse.accepted = true }
<<<<<<< HEAD
        }

        // 토글 버튼 (항상 보임)
        Rectangle {
            id: stationToggleButton
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: 10
            anchors.topMargin: 10
            width: 20
            height: 20
            radius: width / 2
            color: "#252525"
            z: 1000 // 항상 위에 표시
            
            QGCMouseArea {
                anchors.fill: parent
                onClicked: {
                    stationStatusContainer.stationStatusVisible = !stationStatusContainer.stationStatusVisible
                }
            }
            
            Text {
                anchors.centerIn: parent
                text: stationStatusContainer.stationStatusVisible ? "▶" : "◀"
                color: "#ffffff"
                font.pixelSize: 12
            }
        }

        ColumnLayout{
            id: stationStatus
            anchors.fill: parent
            anchors.rightMargin: 10
            anchors.topMargin: 10
            anchors.bottomMargin: 10
            visible: stationStatusContainer.stationStatusVisible
=======
            onWheel: (wheel) => { wheel.accepted = true }
        }

        ColumnLayout {
            id: stationStatus
            anchors.fill: parent
            visible: root.rightPanelStationVisible
>>>>>>> f9dfdbd69 (commit (clean))
            spacing: 2

            StationList{

            id: stationList

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 350
            Layout.minimumHeight: 300
            Layout.preferredWidth: stationStatus.width
            Layout.maximumWidth: 350 * 1.25

<<<<<<< HEAD
        }
        Item { Layout.fillHeight: true }

        CustomStationMetrics{
            id: customStationMetrics
            Layout.fillWidth: true
            Layout.preferredWidth: stationStatus.width
            Layout.preferredHeight: 100
            Layout.minimumHeight: 100
            Layout.maximumHeight: 100
            Layout.maximumWidth: 350 * 1.25
        }

        StationVideo{

            id: stationVideo
            Layout.fillWidth: true
            Layout.minimumWidth: 350
            Layout.minimumHeight: 200
            Layout.preferredWidth: stationStatus.width
            Layout.preferredHeight: Layout.preferredWidth * 0.75
            Layout.maximumWidth: 350 * 1.25
            Layout.maximumHeight: 200 * 1.25
        
            selectedStation: stationList.selectedStation

        }

        StationStatusMessage{

            id: stationStatusMessage
            Layout.fillWidth: true
            Layout.minimumHeight: 100
            Layout.minimumWidth: 350
            Layout.preferredWidth: stationStatus.width
            Layout.preferredHeight: Layout.preferredWidth * 0.35
            Layout.maximumWidth: 350 * 1.25
            Layout.maximumHeight: 100 * 1.25

            selectedStation: stationList.selectedStation

        }

        StationControlPanel{

            id: stationControlPanel
            Layout.fillWidth: true
            Layout.minimumHeight: stationControlButton.implicitHeight + 20
            Layout.minimumWidth: 350
            Layout.preferredWidth: stationStatus.width
            Layout.preferredHeight: stationControlButton.implicitHeight + 20
            Layout.maximumWidth: 350 * 1.25
            Layout.maximumHeight: 300 * 1.25

            selectedStation: stationList.selectedStation
            
        }
        }
    }    
=======
            }

            Item { Layout.fillHeight: true }

            CustomStationMetrics{
                id: customStationMetrics
                Layout.fillWidth: true
                Layout.preferredWidth: stationStatus.width
                Layout.maximumWidth: 350 * 1.25
            }

            StationVideo{

                id: stationVideo
                Layout.fillWidth: true
                Layout.minimumWidth: 350
                Layout.minimumHeight: 200
                Layout.preferredWidth: stationStatus.width
                Layout.preferredHeight: Layout.preferredWidth * 0.75
                Layout.maximumWidth: 350 * 1.25
                Layout.maximumHeight: 200 * 1.25

                selectedStation: stationList.selectedStation

            }

            StationStatusMessage{

                id: stationStatusMessage
                Layout.fillWidth: true
                Layout.minimumHeight: 100
                Layout.minimumWidth: 350
                Layout.preferredWidth: stationStatus.width
                Layout.preferredHeight: Layout.preferredWidth * 0.35
                Layout.maximumWidth: 350 * 1.25
                Layout.maximumHeight: 100 * 1.25

                selectedStation: stationList.selectedStation

            }

            StationControlPanel{

                id: stationControlPanel
                Layout.fillWidth: true
                // 실제 높이는 StationControlPanel 내부에서 implicitHeight로 결정되므로,
                // 여기서는 그 값을 그대로 사용하고, 내부 id(stationControlButton)는 직접 참조하지 않는다.
                Layout.minimumHeight: stationControlPanel.implicitHeight
                Layout.minimumWidth: 350
                Layout.preferredWidth: stationStatus.width
                Layout.preferredHeight: stationControlPanel.implicitHeight
                Layout.maximumWidth: 350 * 1.25
                Layout.maximumHeight: 300 * 1.25

                selectedStation: stationList.selectedStation

            }
        }

        MouseArea {
            id: rightPanelHoverArea
            anchors.fill: parent
            z: 1
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }
    }
>>>>>>> f9dfdbd69 (commit (clean))
}

/*
Column {
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.margins: 10
    spacing: 8
    z:9999

    Text {
        text: "Debug JSON Input"
        color: "white"
        font.pixelSize: 14
    }
    TextArea {
        id: debugJsonInput
        width: 500
        height: 170
        wrapMode: TextEdit.WrapAnywhere
        placeholderText: "{\"type\":\"list\",\"data\":[...]}"
    }

    Row {
        spacing: 8
        Button {
            text: "Inject"
            onClicked: droneManager.injectJsonText(debugJsonInput.text)
        }
        Button {
            text: "Clear"
            onClicked: debugJsonInput.text = ""
        }
    }
}*/
