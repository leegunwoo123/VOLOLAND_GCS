import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QGroundControl.Palette
import QGroundControl.ScreenTools

Rectangle {
    id: root
    width: parent.width
    height: ScreenTools.toolbarHeight

    // QGCPalette 정의 (색상 사용을 위해 필요)
    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    // Rectangle은 color 속성에 바로 할당 가능합니다.
    color: qgcPal.toolbarBackground

    ToolButton {
        id: toolSelectBtn
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 10

        implicitWidth: 48
        implicitHeight: 48

        // 버튼 배경 제거
        background: Rectangle { color: "transparent" }

        contentItem: Item {
            anchors.fill: parent
            Image {
                anchors.centerIn: parent
                source: "qrc:/qmlimages/vololandlogo.svg"
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
                width: parent.height * 0.85
                height: parent.height * 0.85
            }
        }
        onClicked: mainWindow.showToolSelectDialog()
    }
}

