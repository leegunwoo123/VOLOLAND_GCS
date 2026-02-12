// import QtQuick 6.5
// import QtQuick.Controls 6.5
// import QtQuick.Layouts 1.15

// // (필요 없으면 지워도 되지만, 나중에 QGC 객체 쓸 수 있으니 남겨둬도 OK)
// import QGroundControl
// import QGroundControl.Controls
// import QGroundControl.ScreenTools

// Item {
//     id: root
//     //anchors.fill: parent
//      implicitWidth: droneList.implicitWidth
//      implicitHeight: droneList.implicitHeight

//     // ------------------------------------------------------------
//     // MainWindow.qml이 FlyView에 "반드시" 기대하는 인터페이스
//     // ------------------------------------------------------------
//     // globals.planMasterControllerFlyView: flyView.planController
//     // globals.guidedControllerFlyView:     flyView.guidedController
//     property var planController: null
//     property var guidedController: null

//     // MainWindow에서 넘겨줌: FlyView { utmspSendActTrigger: _utmspSendActTrigger }
//     property bool utmspSendActTrigger: false

//     // criticalVehicleMessagePopup에서 호출됨
//     function dropMainStatusIndicatorTool() {
//         // 커스텀 UI에서는 아무 동작 안 해도 됨
//     }

//     // ------------------------------------------------------------
//     // 네 UI가 쓰는 외부 주입 객체들
//     // ------------------------------------------------------------
//     // C++/상위에서 contextProperty로 "deviceListModel"을 올려둔 상태면 자동으로 잡힘
//     // (없으면 null이므로 ListView가 안 뜸)
//     property var deviceListModel: (typeof deviceListModel !== "undefined") ? deviceListModel : null

//     // C++/상위에서 "backend"를 올려둔 상태면 backend.status로 LED 표시
//     property var backend: (typeof backend !== "undefined") ? backend : null

//     Rectangle {
//         id: droneList
//         width: parent.width
//         height: parent.height

//         implicitWidth: 350
//         color: "#1a1a1a"
//         property string selectedDevice: ""
//         property var backend: root.backend

//         ColumnLayout {
//             anchors.fill: parent
//             anchors.centerIn: parent
//             anchors.topMargin: 10
//             anchors.bottomMargin: 10
//             spacing: 10
//             clip: true

//             // 선택 장비 예시
//             Rectangle {
//                 id: selectedBar_border
//                 Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
//                 Layout.preferredWidth: 280
//                 Layout.preferredHeight: 30
//                 color: "transparent"
//                 border.color: "white"
//                 border.width: 1
//                 radius: 4
//                 clip: true

//                 Rectangle {
//                     id: selectedBar
//                     anchors.left: parent.left
//                     anchors.right: parent.right
//                     height: 28
//                     color: "#111"
//                     border.color: "#333"
//                     z: 100

//                     Text {
//                         anchors.verticalCenter: parent.verticalCenter
//                         anchors.left: parent.left
//                         anchors.leftMargin: 12
//                         color: "white"
//                         font.pixelSize: 12
//                         text: droneList.selectedDevice === ""
//                               ? "선택된 장비: 없음"
//                               : ("선택된 장비: " + droneList.selectedDevice)
//                     }
//                 }
//             }

//             RowLayout {
//                 Layout.fillWidth: true
//                 Layout.leftMargin: 10
//                 Layout.rightMargin: 10
//                 spacing: 10

//                 Rectangle {
//                     id: serverConnectionStatus
//                     Layout.leftMargin: 10
//                     Layout.alignment: Qt.AlignTop
//                     Layout.preferredWidth: 20
//                     Layout.preferredHeight: 20
//                     color: {
//                         if (backend && backend.status === 0) return "#44ff44" // 초록
//                         if (backend && backend.status === 1) return "#ffb300" // 노랑
//                         return "#ff4444" // 빨강 (기본값)
//                     }

//                     radius: width /2
//                     clip: true
//                 }

//                 Item { Layout.fillWidth: true }

//                 TextField {
//                     id: deviceSearchBox
//                     placeholderText: "장치 검색..."
//                     placeholderTextColor: "#ffffff"
//                     horizontalAlignment: Text.AlignLeft
//                     verticalAlignment: Text.AlignVCenter
//                     Layout.preferredWidth: 180
//                     Layout.preferredHeight: 30
//                     leftPadding: 10
//                     color: "white"
//                     font.pixelSize: 12

//                     background: Rectangle {
//                         color: "#2a2a2a"
//                         border.color: deviceSearchBox.activeFocus ? "#00BFFF" : "#444"
//                         border.width: 1
//                         radius: 4
//                     }

//                     onTextChanged: {
//                         if (!root.deviceListModel) return
//                         root.deviceListModel.toggleSection(-1, text)
//                     }
//                 }
//             }

//             Rectangle {
//                 id: droneScroll
//                 Layout.preferredWidth: parent.width - 10
//                 Layout.fillHeight: true
//                 Layout.alignment: Qt.AlignHCenter
//                 color: "transparent"
//                 border.color: "white"
//                 border.width: 1
//                 radius: 4
//                 clip: true

//                 ScrollView {
//                     id: viewContainer
//                     anchors.fill: parent
//                     anchors.margins: 10
//                     clip: true

//                     ListView {
//                         id: listView
//                         width: viewContainer.availableWidth
//                         model: root.deviceListModel
//                         spacing: 2

//                         delegate: Item {
//                             id: delegateItem
//                             width: listView.width
//                             height: isVisible ? (nodeType === "device" ? 60 : 40) : 0
//                             visible: isVisible
//                             clip: true

//                             Behavior on height {
//                                 NumberAnimation { duration: 150 }
//                             }

//                             Rectangle {
//                                 id: bgRect
//                                 anchors.fill: parent
//                                 anchors.margins: 2
//                                 z: 0

//                                 color: nodeType === "company"
//                                        ? "#252525"
//                                        : (nodeType.includes("department") ? "#1e1e1e" : "#151515")

//                                 border.color: (nodeType === "device"
//                                                && droneList.selectedDevice === deviceName) ? "#00BFFF" : "#333"
//                                 border.width: (nodeType === "device"
//                                                && droneList.selectedDevice === deviceName) ? 3 : 1
//                                 radius: 4
//                             }

//                             RowLayout {
//                                 id: contentLayout
//                                 anchors.fill: bgRect
//                                 anchors.leftMargin: 10
//                                 anchors.rightMargin: 2
//                                 spacing: 10
//                                 z: 1

//                                 Text {
//                                     text: isExpanded ? "▼" : "▶"
//                                     Layout.alignment: Qt.AlignVCenter
//                                     Layout.preferredWidth: 15
//                                     color: "white"
//                                     font.pixelSize: 12
//                                     visible: nodeType !== "device"
//                                 }

//                                 Item {
//                                     width: 12
//                                     height: 12
//                                     visible: nodeType === "device"
//                                 }

//                                 Text {
//                                     id: iconText
//                                     font.pixelSize: 16
//                                     text: nodeType === "device"
//                                           ? (flighttype === "copter" ? "🚁" : flighttype === "plane" ? "✈️" : "🛸")
//                                           : (nodeType === "company" ? "🏢" : "📂")
//                                     Layout.preferredWidth: 25
//                                 }

//                                 Text {
//                                     text: {
//                                         if (nodeType === "device") return model.deviceName || "Unknown"
//                                         return model.groupName || ""
//                                     }
//                                     color: nodeType === "company"
//                                            ? "#00BFFF"
//                                            : (nodeType.includes("department") ? "#FFD700" : "white")
//                                     font.bold: nodeType !== "device"
//                                     font.pixelSize: 14
//                                     elide: Text.ElideRight
//                                     Layout.fillWidth: true
//                                     verticalAlignment: Text.AlignVCenter
//                                 }

//                                 RowLayout {
//                                     visible: nodeType === "device"
//                                     spacing: 15
//                                     Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

//                                     Text {
//                                         id: heartbeatIcon
//                                         text: status === "ONLINE" ? "📶" : "⚠️"
//                                         font.pixelSize: 14
//                                         Layout.preferredWidth: 20
//                                         Layout.alignment: Qt.AlignVCenter
//                                         color: status === "ONLINE" ? "#44ff44" : "#ff4444"
//                                     }

//                                     Text {
//                                         text: flightmode || "Mode"
//                                         color: "white"
//                                         font.pixelSize: 11
//                                         Layout.preferredWidth: 40
//                                         horizontalAlignment: Text.AlignHCenter
//                                     }

//                                     Text {
//                                         text: isArmed ? "ARM" : "DISR"
//                                         color: isArmed ? "#ff4444" : "#44ff44"
//                                         font.pixelSize: 11
//                                         font.bold: true
//                                         Layout.preferredWidth: 35
//                                     }

//                                     Text {
//                                         id: stateIndicator
//                                         width: 12
//                                         height: 12
//                                         text: "!"
//                                         font.bold: true
//                                         font.pixelSize: 14
//                                         horizontalAlignment: Text.AlignHCenter
//                                         verticalAlignment: Text.AlignVCenter
//                                         Layout.alignment: Qt.AlignVCenter
//                                         Layout.preferredWidth: 12
//                                         Layout.preferredHeight: 12

//                                         readonly property int currentState:
//                                             (typeof model.systemState !== "undefined") ? Number(model.systemState) : 0

//                                         color: (currentState === 3) ? "#44ff44" : "#ff4444"
//                                     }
//                                 }
//                             }

//                             MouseArea {
//                                 id: clickArea
//                                 anchors.fill: parent
//                                 z: 2

//                                 onClicked: {
//                                     if (nodeType === "device") {
//                                         droneList.selectedDevice =
//                                             (droneList.selectedDevice === deviceName) ? "" : deviceName
//                                     } else {
//                                         if (!root.deviceListModel) return
//                                         root.deviceListModel.toggleSection(index, deviceSearchBox.text)
//                                     }
//                                 }
//                             }
//                         }
//                     }
//                 }
//             }
//         }
//     }
// }

import QtQuick 6.5
import QtQuick.Controls 6.5
import QtQuick.Layouts 1.15

import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools

Item {
    id: root
    implicitWidth: droneList.implicitWidth
    implicitHeight: droneList.implicitHeight

    property alias selectedDevice: droneList.selectedDevice

    // ------------------------------------------------------------
    // [데이터 로직 추가] 기존 인터페이스 유지 및 로컬 모델 정의
    // ------------------------------------------------------------
    property var planController: null
    property var guidedController: null
    property bool utmspSendActTrigger: false

    // ListView가 참조할 모델 (기존 root.deviceListModel 참조 유지)
    property var deviceListModel: localDeviceModel
    //property var backend: (typeof backend !== "undefined") ? backend : null
    property var backend: null
    property string currentSearchText: "" // 현재 검색어 저장

    ListModel {
        id: localDeviceModel
    }

    function initializeData() {
        var rawListData = [
            { "depth": 0, "nodeType": "company", "groupName": "VoloLand", "deviceName": "" },
            { "depth": 1, "nodeType": "parent department", "groupName": "Future Air Mobility Lab", "deviceName": "" },
            { "depth": 2, "nodeType": "department", "groupName": "Autonomous Flight Platform Group", "deviceName": "" },
            { "depth": 3, "nodeType": "device", "groupName": "", "deviceName": "A-1" },
            { "depth": 3, "nodeType": "device", "groupName": "", "deviceName": "A-2" },
            { "depth": 3, "nodeType": "device", "groupName": "", "deviceName": "A-3" },
            { "depth": 2, "nodeType": "department", "groupName": "Unmanned & Ground Platform Group", "deviceName": "" },
            { "depth": 3, "nodeType": "device", "groupName": "", "deviceName": "B-1" },
            { "depth": 3, "nodeType": "device", "groupName": "", "deviceName": "B-2" },
            { "depth": 0, "nodeType": "company", "groupName": "Personal User", "deviceName": "" },
            { "depth": 3, "nodeType": "device", "groupName": "", "deviceName": "C-1" }
        ];

        localDeviceModel.clear();
        for (var i = 0; i < rawListData.length; i++) {
            var item = rawListData[i];
            item.status = "OFFLINE";
            item.isArmed = false;
            item.systemState = 0;
            item.flightmode = "N/A";
            item.flighttype = "copter";
            item.isVisible = true;
            item.isExpanded = true;
            localDeviceModel.append(item);
        }
    }

    function updateHeartbeat(hb) {
        for (var i = 0; i < localDeviceModel.count; i++) {
            if (localDeviceModel.get(i).deviceName === hb.deviceName) {
                localDeviceModel.setProperty(i, "status", hb.status);
                localDeviceModel.setProperty(i, "isArmed", hb.isArmed);
                localDeviceModel.setProperty(i, "systemState", hb.systemState);
                localDeviceModel.setProperty(i, "flightmode", hb.flightmode);
                localDeviceModel.setProperty(i, "flighttype", hb.flighttype);
                break;
            }
        }
    }

    function filterDevices(searchText) {
        root.currentSearchText = searchText // 현재 검색어 저장
        var searchLower = searchText.toLowerCase().trim()
        
        if (searchLower === "") {
            // 검색어가 비어있으면 접기/펼치기 상태만 확인
            for (var i = 0; i < localDeviceModel.count; i++) {
                var shouldBeVisible = root.shouldItemBeVisible(i)
                localDeviceModel.setProperty(i, "isVisible", shouldBeVisible)
            }
            return
        }
        
        // 1단계: 각 항목이 직접 매칭되는지 확인하고, 자식이 매칭되면 부모도 표시
        var itemMatches = []
        for (var i = localDeviceModel.count - 1; i >= 0; i--) {
            var item = localDeviceModel.get(i)
            var deviceName = (item.deviceName || "").toLowerCase()
            var groupName = (item.groupName || "").toLowerCase()
            var directMatch = deviceName.indexOf(searchLower) !== -1 || groupName.indexOf(searchLower) !== -1
            
            // 자식 중 하나라도 매칭되면 부모도 표시
            var childMatches = false
            if (!directMatch && item.depth < 3) {
                for (var j = i + 1; j < localDeviceModel.count; j++) {
                    var childItem = localDeviceModel.get(j)
                    if (childItem.depth <= item.depth) break
                    if (itemMatches[j]) {
                        childMatches = true
                        break
                    }
                }
            }
            
            itemMatches[i] = directMatch || childMatches
        }
        
        // 2단계: 매칭 결과와 접기/펼치기 상태를 함께 확인
        for (var i = 0; i < localDeviceModel.count; i++) {
            if (!itemMatches[i]) {
                localDeviceModel.setProperty(i, "isVisible", false)
                continue
            }
            var shouldBeVisible = root.shouldItemBeVisible(i)
            localDeviceModel.setProperty(i, "isVisible", shouldBeVisible)
        }
    }
    
    function shouldItemBeVisible(itemIndex) {
        var item = localDeviceModel.get(itemIndex)
        var searchLower = root.currentSearchText.toLowerCase().trim()
        
        // 검색 필터링은 이미 filterDevices에서 처리되었으므로, 여기서는 접기/펼치기 상태만 확인
        // 모든 부모 항목의 접기/펼치기 상태를 재귀적으로 확인
        if (item.depth > 0) {
            for (var j = itemIndex - 1; j >= 0; j--) {
                var parentItem = localDeviceModel.get(j)
                if (parentItem.depth < item.depth) {
                    // 직접 부모가 접혀있으면 숨김
                    if (!parentItem.isExpanded) return false
                    // 직접 부모의 부모도 확인 (재귀적으로)
                    return root.shouldItemBeVisible(j)
                }
            }
        }
        
        return true
    }

    Component.onCompleted: {
        initializeData();
        updateHeartbeat({"deviceName": "A-1", "status": "ONLINE", "isArmed": true, "systemState": 3, "flightmode": "Loiter", "flighttype": "copter"});
        updateHeartbeat({"deviceName": "A-2", "status": "ONLINE", "isArmed": true, "systemState": 3, "flightmode": "Auto", "flighttype": "copter"});
    }

    function dropMainStatusIndicatorTool() { }

    Rectangle {
        id: droneList
        //implicitHeight:500
        width: parent.width
        height: parent.height

        implicitWidth: 350
        color: "#1a1a1a"
        property string selectedDevice: ""
        property var backend: root.backend

        ColumnLayout {
            anchors.fill: parent
            anchors.centerIn: parent
            anchors.topMargin: 10
            anchors.bottomMargin: 10
            spacing: 10
            clip: true

            Rectangle {
                id: selectedBar_border
                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                Layout.preferredWidth: 280
                Layout.preferredHeight: 30
                color: "transparent"
                //border.color: "white"
                //border.width: 1
                radius: 4
                clip: true

                Rectangle {
                    id: selectedBar
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 28
                    color: "#111"
                    border.color: "#333"
                    z: 100

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        color: "white"
                        font.pixelSize: 12
                        text: droneList.selectedDevice === ""
                              ? "선택된 장비: 없음"
                              : ("선택된 장비: " + droneList.selectedDevice)
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                spacing: 10

                Rectangle {
                    id: serverConnectionStatus
                    Layout.leftMargin: 10
                    Layout.alignment: Qt.AlignTop
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    color: {
                        if (backend && backend.status === 0) return "#44ff44"
                        if (backend && backend.status === 1) return "#ffb300"
                        return "#ff4444"
                    }
                    radius: width /2
                    clip: true
                }

                Item { Layout.fillWidth: true }

                TextField {
                    id: deviceSearchBox
                    placeholderText: "장치 검색..."
                    placeholderTextColor: "#ffffff"
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    Layout.preferredWidth: 180
                    Layout.preferredHeight: 30
                    leftPadding: 10
                    color: "white"
                    font.pixelSize: 12

                    background: Rectangle {
                        color: "#2a2a2a"
                        border.color: deviceSearchBox.activeFocus ? "#00BFFF" : "#444"
                        border.width: 1
                        radius: 4
                    }

                    onTextChanged: {
                        root.filterDevices(text)
                    }
                }
            }

            Rectangle {
                id: droneScroll
                Layout.preferredWidth: parent.width - 10
                Layout.fillWidth: true // 1.27
                Layout.fillHeight: true

                Layout.preferredHeight: droneStatus.width * 0.86 //1.27
                Layout.minimumHeight: 200 // 1.27
                Layout.alignment: Qt.AlignHCenter
                color: "transparent"
                //border.color: "white"
                //border.width: 1
                radius: 4
                clip: true

                ScrollView {
                    id: viewContainer
                    anchors.fill: parent
                    anchors.margins: 10
                    clip: true

                    ListView {
                        id: listView
                        width: viewContainer.availableWidth
                        model: root.deviceListModel // 위에서 정의한 localDeviceModel 연결됨
                        spacing: 2

                        delegate: Item {
                            id: delegateItem
                            width: listView.width
                            height: isVisible ? (nodeType === "device" ? 60 : 40) : 0
                            visible: isVisible
                            clip: true

                            Behavior on height {
                                NumberAnimation { duration: 150 }
                            }

                            Rectangle {
                                id: bgRect
                                anchors.fill: parent
                                anchors.margins: 2
                                z: 0
                                color: nodeType === "company"
                                       ? "#252525"
                                       : (nodeType.includes("department") ? "#1e1e1e" : "#151515")
                                border.color: (nodeType === "device"
                                               && droneList.selectedDevice === deviceName) ? "#00BFFF" : "#333"
                                border.width: (nodeType === "device"
                                               && droneList.selectedDevice === deviceName) ? 3 : 1
                                radius: 4
                            }

                            RowLayout {
                                id: contentLayout
                                anchors.fill: bgRect
                                anchors.leftMargin: 10
                                anchors.rightMargin: 2
                                spacing: 10
                                z: 1

                                Text {
                                    text: isExpanded ? "▼" : "▶"
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.preferredWidth: 15
                                    color: "white"
                                    font.pixelSize: 12
                                    visible: nodeType !== "device"
                                }

                                Item {
                                    width: 12
                                    height: 12
                                    visible: nodeType === "device"
                                }

                                Text {
                                    id: iconText
                                    font.pixelSize: 16
                                    text: nodeType === "device"
                                          ? (flighttype === "copter" ? "🚁" : flighttype === "plane" ? "✈️" : "🛸")
                                          : (nodeType === "company" ? "🏢" : "📂")
                                    Layout.preferredWidth: 25
                                }

                                Text {
                                    text: {
                                        if (nodeType === "device") return model.deviceName || "Unknown"
                                        return model.groupName || ""
                                    }
                                    color: nodeType === "company"
                                           ? "#00BFFF"
                                           : (nodeType.includes("department") ? "#FFD700" : "white")
                                    font.bold: nodeType !== "device"
                                    font.pixelSize: 14
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                    verticalAlignment: Text.AlignVCenter
                                }

                                RowLayout {
                                    visible: nodeType === "device"
                                    spacing: 15
                                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                                    Text {
                                        id: heartbeatIcon
                                        text: status === "ONLINE" ? "📶" : "⚠️"
                                        font.pixelSize: 14
                                        Layout.preferredWidth: 20
                                        Layout.alignment: Qt.AlignVCenter
                                        color: status === "ONLINE" ? "#44ff44" : "#ff4444"
                                    }

                                    Text {
                                        text: flightmode || "Mode"
                                        color: "white"
                                        font.pixelSize: 11
                                        Layout.preferredWidth: 40
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    Text {
                                        text: isArmed ? "ARM" : "DISR"
                                        color: isArmed ? "#ff4444" : "#44ff44"
                                        font.pixelSize: 11
                                        font.bold: true
                                        Layout.preferredWidth: 35
                                    }

                                    Text {
                                        id: stateIndicator
                                        text: "!"
                                        font.bold: true
                                        font.pixelSize: 14
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        Layout.alignment: Qt.AlignVCenter
                                        Layout.preferredWidth: 12
                                        Layout.preferredHeight: 12
                                        readonly property int currentState:
                                            (typeof model.systemState !== "undefined") ? Number(model.systemState) : 0
                                        color: (currentState === 3) ? "#44ff44" : "#ff4444"
                                    }
                                }
                            }

                            MouseArea {
                                id: clickArea
                                anchors.fill: parent
                                z: 2
                                onClicked: {
                                    if (nodeType === "device") {
                                        droneList.selectedDevice = (droneList.selectedDevice === deviceName) ? "" : deviceName
                                    } else {
                                        var newExpanded = !isExpanded
                                        localDeviceModel.setProperty(index, "isExpanded", newExpanded)

                                        // 하위 항목들의 가시성을 결정하는 함수 (필터링 상태 고려, isExpanded 상태는 유지)
                                        function updateChildVisibility(parentIndex, visible) {
                                            var parentDepth = localDeviceModel.get(parentIndex).depth
                                            for (var i = parentIndex + 1; i < localDeviceModel.count; i++) {
                                                var item = localDeviceModel.get(i)

                                                if (item.depth > parentDepth) {
                                                    // 필터링 상태와 접기/펼치기 상태를 모두 확인
                                                    // 부모가 접혀있으면 자식도 숨김 (하지만 isExpanded 상태는 유지)
                                                    var shouldBeVisible = visible && root.shouldItemBeVisible(i)
                                                    localDeviceModel.setProperty(i, "isVisible", shouldBeVisible)
                                                    
                                                    // 부모가 펼쳐져 있고, 자식이 펼쳐져 있으면 그 자식들도 처리
                                                    if (visible && item.isExpanded) {
                                                        // 재귀적으로 자식의 자식들도 업데이트
                                                        var childDepth = item.depth
                                                        for (var j = i + 1; j < localDeviceModel.count; j++) {
                                                            var childItem = localDeviceModel.get(j)
                                                            if (childItem.depth > childDepth) {
                                                                var childShouldBeVisible = root.shouldItemBeVisible(j)
                                                                localDeviceModel.setProperty(j, "isVisible", childShouldBeVisible)
                                                            } else {
                                                                break
                                                            }
                                                        }
                                                    }
                                                } else {
                                                    break
                                                }
                                            }
                                        }
                                        updateChildVisibility(index, newExpanded)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
