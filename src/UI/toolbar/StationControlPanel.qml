import QtQuick 6.8
import QtQuick.Controls 6.8
import QtQuick.Layouts 6.8

Rectangle {
    id: controlRoot
    implicitWidth: parent.width
    implicitHeight:  stationControlButton.implicitHeight + 20

    color: "#252525"
    border.color: "#333"
    radius: 4

    property string selectedStation: ""
    property var backend: null

    ColumnLayout {
        id: stationControlButton
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

            // 이륙준비
            Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 0 // 3등분 가중치 설정
                text: "이륙준비"
                onClicked: {
                    // 기능
                }
            }

            // 이륙완료
            Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: "이륙완료"
                onClicked: {
                    // 기능
                }
            }

            // 착륙준비
            Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: "착륙준비"
                onClicked: {
                    // 기능
                }
            }

            // 착륙완료
            Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: "착륙완료"
                onClicked: {
                    // 기능
                }
            }
        }

        RowLayout{
            Layout.fillWidth: true
            spacing: 5

            // 메인도어/랜딩패드 열림
            Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: "도어 열림"
                //text: targetValue === 0 ? "도어 열림" : "랜딩패드 닫힘"
                onClicked: {
                    // 기능
                }
            }

            // 메인도어/랜딩패드 닫힘
            Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: "도어 닫힘"
                //text: targetValue === 0 ? "도어 열림" : "랜딩패드 닫힘"
                onClicked: {
                    // 기능
                }
            }

            // 기체 전원 ON
            Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: "전원 ON"
                onClicked: {
                    // 기능
                }
            }

            //기체 전원 OFF
            Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: "전원 OFF"
                onClicked: {
                    // 기능
                }
            }
        }

        RowLayout{
            Layout.fillWidth: true
            spacing: 5

            // 충전기 OM
            Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: "충전기 ON"
                onClicked: {
                    // 기능
                }
            }

            // 충전기 OFF
            Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: "충전기 OFF"
                onClicked: {
                    // 기능
                }
            }

            // 냉방기 ON
            Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: "냉방기 ON"
                onClicked: {
                    // 기능
                }
            }

            // 냉방기 OFF
            Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: "냉방기 OFF"
                onClicked: {
                    // 기능
                }
            }
        }

        RowLayout{
            Layout.fillWidth: true
            spacing: 5

            // 난방기 ON
            Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: "난방기 ON"
                onClicked: {
                    // 기능
                }
            }

            // 난방기 OFF
            Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: "난방기 OFF"
                onClicked: {
                    // 기능
                }
            }

            // LED ON
            Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: "LED ON"
                onClicked: {
                    // 기능
                }
            }

            // LED OFF
            Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: "LED OFF"
                onClicked: {
                    // 기능
                }
            }
        }

        RowLayout{

            // 긴급멈춤
            Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: "긴급멈춤"
                onClicked: {
                    // 기능
                }
            }

            // 모터 초기화
            Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: "모터 초기화"
                onClicked: {
                    // 기능
                }
            }
        }


            // RowLayout{

            //     spacing: 5
            //     Layout.fillWidth: true

            //     // ModeChange 버튼
            //     Button {
            //         id: modeChangeButton
            //         Layout.fillWidth: true
            //         Layout.preferredWidth: 0
            //         text: "ModeChange"
            //         onClicked: flightModeMenu.opened = !flightModeMenu.opened
            //     }

            //     RowLayout{

            //         id: flightModeMenu
            //         property bool opened: false

            //         Layout.preferredWidth: opened ? 150 : 0
            //         opacity: opened ? 1 : 0
            //         visible: opacity > 0 // 완전히 가려지면 클릭 방지
            //         clip: true

            //         // 부드러운 확장 애니메이션
            //         Behavior on Layout.preferredWidth { NumberAnimation { duration: 200 } }
            //         Behavior on opacity { NumberAnimation { duration: 200 } }

            //         Button {
            //             text: "Stabilize"
            //             Layout.preferredWidth: 70
            //             onClicked: {
            //             //기능
            //             }
            //         }
            //         Button {
            //             text: "AltHold"
            //             Layout.preferredWidth: 70
            //             onClicked:{
            //             //기능
            //             }
            //         }

            //         Button {
            //             text: "Loiter"
            //             Layout.preferredWidth: 70
            //             onClicked:{
            //             //기능
            //             }
            //         }

            //     }
            // }
    }
}
