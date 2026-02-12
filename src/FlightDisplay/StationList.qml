import QtQuick 6.5
import QtQuick.Controls 6.5
import QtQuick.Layouts 1.15
import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools

Item {
    id: root

    implicitWidth: stationBackground.implicitWidth
    implicitHeight: stationBackground.implicitHeight

    property alias selectedStation: stationBackground.selectedStation

    // 데이터 로직 (DroneList의 구조와 동일하게 배치)
    property var backend: null
    property string currentSearchText: "" // 현재 검색어 저장

    ListModel {
        id: stationModel
    }

    function initializeData() {
        var rawListData = [
            { "depth": 0, "nodeType": "company",           "groupName": "VoloLand",                      "stationName": "" },
            { "depth": 1, "nodeType": "parent department", "groupName": "Future Air Mobility Lab",      "stationName": "" },
            { "depth": 2, "nodeType": "department",        "groupName": "Autonomous Ground System Group", "stationName": "" },
            { "depth": 3, "nodeType": "station",           "groupName": "",                              "stationName": "VLS-770C" },
            { "depth": 3, "nodeType": "station",           "groupName": "",                              "stationName": "VLS-1300C" },
            { "depth": 3, "nodeType": "station",           "groupName": "",                              "stationName": "VLS-450S" },
            { "depth": 2, "nodeType": "department",        "groupName": "Maintenance Support Group",    "stationName": "" },
            { "depth": 3, "nodeType": "station",           "groupName": "",                              "stationName": "VLS-400C" },
            { "depth": 0, "nodeType": "company",           "groupName": "Regional User",                 "stationName": "" },
            { "depth": 3, "nodeType": "station",           "groupName": "",                              "stationName": "THEO-3" }
        ];

        stationModel.clear();
        for (var i = 0; i < rawListData.length; i++) {
            var item = rawListData[i];
            item.status = "OFFLINE";
            item.isVisible = true;
            item.isExpanded = true;
            item.battery = 100;
            item.isLocked = false;
            stationModel.append(item);
        }
    }

    Component.onCompleted: {
        initializeData();
        updateStationStatus({"stationName": "Station-Alpha", "status": "ONLINE"});
    }

    function updateStationStatus(hb) {
        for (var i = 0; i < stationModel.count; i++) {
            if (stationModel.get(i).stationName === hb.stationName) {
                stationModel.setProperty(i, "status", hb.status);
                break;
            }
        }
    }

    function filterStations(searchText) {
        root.currentSearchText = searchText // 현재 검색어 저장
        var searchLower = searchText.toLowerCase().trim()
        
        if (searchLower === "") {
            // 검색어가 비어있으면 접기/펼치기 상태만 확인
            for (var i = 0; i < stationModel.count; i++) {
                var shouldBeVisible = root.shouldItemBeVisible(i)
                stationModel.setProperty(i, "isVisible", shouldBeVisible)
            }
            return
        }
        
        // 1단계: 각 항목이 직접 매칭되는지 확인하고, 자식이 매칭되면 부모도 표시
        var itemMatches = []
        for (var i = stationModel.count - 1; i >= 0; i--) {
            var item = stationModel.get(i)
            var stationName = (item.stationName || "").toLowerCase()
            var groupName = (item.groupName || "").toLowerCase()
            var directMatch = stationName.indexOf(searchLower) !== -1 || groupName.indexOf(searchLower) !== -1
            
            // 자식 중 하나라도 매칭되면 부모도 표시
            var childMatches = false
            if (!directMatch && item.depth < 3) {
                for (var j = i + 1; j < stationModel.count; j++) {
                    var childItem = stationModel.get(j)
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
        for (var i = 0; i < stationModel.count; i++) {
            if (!itemMatches[i]) {
                stationModel.setProperty(i, "isVisible", false)
                continue
            }
            var shouldBeVisible = root.shouldItemBeVisible(i)
            stationModel.setProperty(i, "isVisible", shouldBeVisible)
        }
    }
    
    function shouldItemBeVisible(itemIndex) {
        var item = stationModel.get(itemIndex)
        
        // 검색 필터링은 이미 filterStations에서 처리되었으므로, 여기서는 접기/펼치기 상태만 확인
        // 모든 부모 항목의 접기/펼치기 상태를 재귀적으로 확인
        if (item.depth > 0) {
            for (var j = itemIndex - 1; j >= 0; j--) {
                var parentItem = stationModel.get(j)
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

    Rectangle {
        id: stationBackground
        width: parent.width
        height: parent.height
        implicitWidth: 350 
        color: "#1a1a1a"

        property string selectedStation: ""
        property var backend: root.backend

        ColumnLayout {
            anchors.fill: parent
<<<<<<< HEAD
=======
            anchors.centerIn: parent
>>>>>>> f9dfdbd69 (commit (clean))
            anchors.topMargin: 10
            anchors.bottomMargin: 10
            spacing: 10
            clip: true

<<<<<<< HEAD
            // 상단 선택바: 드론 정보와 스테이션 정보를 동시에 표시
=======
            // 상단 선택바 (DroneList와 동일 구조)
>>>>>>> f9dfdbd69 (commit (clean))
            Rectangle {
                id: selectedBar_border
                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                Layout.preferredWidth: 280
                Layout.preferredHeight: 30
                color: "transparent"
                border.color: "white"
                border.width: 1
                radius: 4
                clip: true

                Rectangle {
                    id: selectedBar
<<<<<<< HEAD
                    anchors.fill: parent
                    color: "#111"
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        spacing: 0
                        Text {
                            color: "white"
                            font.pixelSize: 12
                            text: "선택된 장비: " + (stationBackground.selectedStation === "" ? "없음" : stationBackground.selectedStation)
                        }
=======
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
                        text: stationBackground.selectedStation === ""
                              ? "선택된 장비: 없음"
                              : ("선택된 장비: " + stationBackground.selectedStation)
>>>>>>> f9dfdbd69 (commit (clean))
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                spacing: 10
<<<<<<< HEAD
                Item { Layout.fillWidth: true }
=======

                Item { Layout.fillWidth: true }

>>>>>>> f9dfdbd69 (commit (clean))
                TextField {
                    id: stationSearchBox
                    placeholderText: "스테이션 검색..."
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
                        border.color: stationSearchBox.activeFocus ? "#00BFFF" : "#444"
                        border.width: 1
                        radius: 4
                    }

                    onTextChanged: {
                        root.filterStations(text)
                    }
                }
            }

            Rectangle {
                id: stationScroll
<<<<<<< HEAD
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"
=======
                Layout.preferredWidth: parent.width - 10
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignHCenter
                color: "transparent"
                radius: 4
>>>>>>> f9dfdbd69 (commit (clean))
                clip: true

                ScrollView {
                    id: viewContainer
                    anchors.fill: parent
                    anchors.margins: 10
<<<<<<< HEAD
=======
                    clip: true
>>>>>>> f9dfdbd69 (commit (clean))

                    ListView {
                        id: listView
                        width: viewContainer.availableWidth
                        model: stationModel
                        spacing: 2

                        delegate: Item {
                            id: delegateItem
                            width: listView.width
                            height: isVisible ? (nodeType === "station" ? 60 : 40) : 0
                            visible: isVisible
                            clip: true

                            Behavior on height { NumberAnimation { duration: 150 } }

                            Rectangle {
                                id: bgRect
                                anchors.fill: parent
                                anchors.margins: 2
<<<<<<< HEAD
                                // depth에 따른 배경색 분기 (DroneList 스타일)
                                color: nodeType === "company" ? "#252525" : 
                                       nodeType === "parent department" ? "#202020" :
                                       nodeType === "department" ? "#1a1a1a" : "#111111"
                                
                                border.color: (nodeType === "station" && stationBackground.selectedStation === stationName) ? "#00BFFF" : "#333"
                                border.width: (nodeType === "station" && stationBackground.selectedStation === stationName) ? 2 : 1
=======
                                z: 0
                                color: nodeType === "company"
                                       ? "#252525"
                                       : (nodeType.includes("department") ? "#1e1e1e" : "#151515")
                                border.color: (nodeType === "station" && stationBackground.selectedStation === stationName) ? "#00BFFF" : "#333"
                                border.width: (nodeType === "station" && stationBackground.selectedStation === stationName) ? 3 : 1
>>>>>>> f9dfdbd69 (commit (clean))
                                radius: 4
                            }

                            RowLayout {
<<<<<<< HEAD
                                anchors.fill: bgRect
                                anchors.leftMargin: 10 + (depth * 15)
                                spacing: 10

                                Text {
                                    text: isExpanded ? "▼" : "▶"
                                    color: "white"
                                    font.pixelSize: 10
                                    visible: nodeType !== "station"
                                }

                                Text {
                                    text: nodeType === "station" ? "📡" : (nodeType === "company" ? "🏢" : "📁")
                                    font.pixelSize: 14
                                }

                                Text {
                                    // 중요: depth 0, 1, 2는 groupName을, 3은 stationName을 출력
                                    text: nodeType === "station" ? stationName : groupName
                                    Layout.fillWidth: true
                                    color: nodeType === "company" ? "#00BFFF" : (nodeType.includes("department") ? "#FFD700" : "white")
                                    font.bold: nodeType !== "station"
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                }

                                Text {
                                    visible: nodeType === "station"
                                    text: status
                                    color: status === "ONLINE" ? "#44ff44" : "#ff4444"
                                    font.pixelSize: 11
                                    Layout.rightMargin: 10
=======
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
                                    visible: nodeType !== "station"
                                }

                                Item {
                                    width: 12
                                    height: 12
                                    visible: nodeType === "station"
                                }

                                Text {
                                    id: iconText
                                    font.pixelSize: 16
                                    text: nodeType === "station" ? "📡" : (nodeType === "company" ? "🏢" : "📂")
                                    Layout.preferredWidth: 25
                                }

                                Text {
                                    text: nodeType === "station" ? stationName : groupName
                                    color: nodeType === "company"
                                           ? "#00BFFF"
                                           : (nodeType.includes("department") ? "#FFD700" : "white")
                                    font.bold: nodeType !== "station"
                                    font.pixelSize: 14
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                    verticalAlignment: Text.AlignVCenter
                                }

                                RowLayout {
                                    visible: nodeType === "station"
                                    spacing: 15
                                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                                    Text {
                                        text: status === "ONLINE" ? "📶" : "⚠️"
                                        font.pixelSize: 14
                                        Layout.preferredWidth: 20
                                        Layout.alignment: Qt.AlignVCenter
                                        color: status === "ONLINE" ? "#44ff44" : "#ff4444"
                                    }

                                    Text {
                                        text: status
                                        color: status === "ONLINE" ? "#44ff44" : "#ff4444"
                                        font.pixelSize: 11
                                    }
>>>>>>> f9dfdbd69 (commit (clean))
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (nodeType === "station") {
                                        stationBackground.selectedStation = (stationBackground.selectedStation === stationName) ? "" : stationName
                                    } else {
                                        var newExpanded = !isExpanded
                                        stationModel.setProperty(index, "isExpanded", newExpanded)
                                        // 하위 항목들의 가시성을 결정 (필터링 상태 고려, isExpanded 상태는 유지)
                                        for (var i = index + 1; i < stationModel.count; i++) {
                                            if (stationModel.get(i).depth > depth) {
                                                // 필터링 상태와 접기/펼치기 상태를 모두 확인
                                                // 부모가 접혀있으면 자식도 숨김 (하지만 isExpanded 상태는 유지)
                                                var shouldBeVisible = newExpanded && root.shouldItemBeVisible(i)
                                                stationModel.setProperty(i, "isVisible", shouldBeVisible)
                                                
                                                // 부모가 펼쳐져 있고, 자식이 펼쳐져 있으면 그 자식들도 처리
                                                if (newExpanded && stationModel.get(i).isExpanded) {
                                                    // 재귀적으로 자식의 자식들도 업데이트
                                                    var childDepth = stationModel.get(i).depth
                                                    for (var j = i + 1; j < stationModel.count; j++) {
                                                        if (stationModel.get(j).depth > childDepth) {
                                                            var childShouldBeVisible = root.shouldItemBeVisible(j)
                                                            stationModel.setProperty(j, "isVisible", childShouldBeVisible)
                                                        } else {
                                                            break
                                                        }
                                                    }
                                                }
                                            } else break
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
}
