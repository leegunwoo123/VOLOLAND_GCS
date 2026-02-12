import QtQuick 6.8
import QtQuick.Controls 6.8
import QtQuick.Layouts 6.8

Rectangle {
    id: controlRoot
    implicitWidth: parent.width
    implicitHeight:  droneControlButton.implicitHeight + 20

    color: "#252525"
    border.color: "#333"
    radius: 4

    property string deviceName: ""
    property var backend: null

    ColumnLayout {
        id: droneControlButton
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 10
        spacing: 10

        // selected device cehck box
        // Text {
        //     text: controlRoot.deviceName === "" ? "No Device Selected" : controlRoot.deviceName
        //     color: "#00BFFF"
        //     font.pixelSize: 18
        //     font.bold: true
        //     Layout.alignment: Qt.AlignHCenter
        // }

        // 제목 구분선
        // Rectangle {
        //     Layout.fillWidth: true
        //     height: 2
        //     color: "#444"
        // }

        // 제어 버튼들
        RowLayout{
            Layout.fillWidth: true
            spacing: 5

            // ARM 버튼
            Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 0 // 3등분 가중치 설정
                text: "ARM"
                onClicked: {
                    // 기능
                }
            }

            // DISARM 버튼
            Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: "DISARM"
                onClicked: {
                    // 기능
                }
            }

            // Auto 버튼
            Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: "Auto"
                onClicked: {
                    // 기능
                }
            }
        }

        RowLayout{
            Layout.fillWidth: true
            spacing: 5

            // Takeoff 버튼
            Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: "Takeoff"
                onClicked: {
                    // 기능
                }
            }

            // Land 버튼
            Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: "Land"
                onClicked: {
                    // 기능
                }
            }

            // RTL 버튼
            Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: "RTL"
                onClicked: {
                    // 기능
                }
            }
        }

        RowLayout{
            Layout.fillWidth: true
            spacing: 5

            // Move 버튼
            Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: "Move"
                onClicked: {
                    // 기능
                }
            }

            // Pause 버튼
            Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: "Pause"
                onClicked: {
                    // 기능
                }
            }

            RowLayout{

                spacing: 5
                Layout.fillWidth: true

                // ModeChange 버튼
                Button {
                    id: modeChangeButton
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    text: "ModeChange"
                    onClicked: flightModeMenu.opened = !flightModeMenu.opened
                }

                RowLayout{

                    id: flightModeMenu
                    property bool opened: false

                    Layout.preferredWidth: opened ? 150 : 0
                    opacity: opened ? 1 : 0
                    visible: opacity > 0 // 완전히 가려지면 클릭 방지
                    clip: true

                    // 부드러운 확장 애니메이션
                    Behavior on Layout.preferredWidth { NumberAnimation { duration: 200 } }
                    Behavior on opacity { NumberAnimation { duration: 200 } }

                    Button {
                        text: "Stabilize"
                        Layout.preferredWidth: 70
                        onClicked: {
                        //기능
                        }
                    }
                    Button {
                        text: "AltHold"
                        Layout.preferredWidth: 70
                        onClicked:{
                        //기능
                        }
                    }

                    Button {
                        text: "Loiter"
                        Layout.preferredWidth: 70
                        onClicked:{
                        //기능
                        }
                    }

                }
            }
        }
    }
}
