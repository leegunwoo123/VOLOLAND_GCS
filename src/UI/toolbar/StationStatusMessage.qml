import QtQuick 6.8
import QtQuick.Controls 6.8
import QtQuick.Layouts 6.8

Rectangle{

    id: root
    implicitWidth: parent.width
    implicitHeight: 100
    color: "#252525"
    border.color: "#333"
    radius: 4

    property string selectedStation: ""

    ListModel{

        id: messageModel

    }

    ColumnLayout {
            anchors.fill: parent
            anchors.margins: 5
            spacing: 5

            Text {
                text: selectedStation + " Messages"
                color: "#AAAAAA"
                font.pixelSize: 12
                font.bold: true
            }

            // 스크롤 가능한 영역
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                ScrollBar.vertical.policy: ScrollBar.AlwaysOn

                ListView {
                    id: messageListView
                    model: messageModel
                    spacing: 4

                    // 새로운 항목 추가 시 자동으로 하단 스크롤
                    onCountChanged: messageListView.positionViewAtEnd()

                    delegate: Item {
                        width: messageListView.width
                        height: messageText.implicitHeight

                        Text {
                            id: messageText
                            width: parent.width - 10
                            text: model.text
                            color: getSeverityColor(model.severity) // 심각도에 따른 색상 변경
                            font.pixelSize: 13
                            wrapMode: Text.WrapAnywhere // 자동 줄바꿈
                            lineHeight: 1.2
                        }
                    }
                }
            }
        }
}
