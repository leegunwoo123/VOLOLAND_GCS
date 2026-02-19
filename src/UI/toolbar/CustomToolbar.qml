import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QGroundControl.Palette
import QGroundControl.ScreenTools
import QGroundControl
import QGroundControl.Controls
import QGroundControl.Toolbar

Rectangle {
    id: root
    width: parent.width
    height: ScreenTools.toolbarHeight
    implicitHeight: ScreenTools.toolbarHeight

    /// true면 Plan 뷰용 "< Return" 표시, false면 Fly 뷰용 로고. 툴바 하나로 통일
    property bool showPlanReturnButton: false

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }
    color: qgcPal.toolbarBackground

    readonly property real dragAreaLeft: CustomToolbarMetrics.horizontalMargin
        + (showPlanReturnButton ? returnButtonRow.width : toolSelectBtn.width)
        + CustomToolbarMetrics.spacing
    readonly property real dragAreaRight: _rightBlockWidth

    // 우측 블록 고정 너비 (앵커 배치용). RowLayout 재계산과 무관하게 항상 동일
    readonly property real _rightBlockWidth: CustomToolbarMetrics.horizontalMargin
        + root.height
        + CustomToolbarMetrics.spacing
        + root.height
        + CustomToolbarMetrics.spacing
        + (windowControlButtons.visible ? (3 * CustomToolbarMetrics.windowControlButtonSize + 2 * CustomToolbarMetrics.windowControlButtonsSpacing) : 0)
        + CustomToolbarMetrics.horizontalMargin

    RowLayout {
        id: toolbarLayout
        anchors.fill: parent
        anchors.leftMargin: CustomToolbarMetrics.horizontalMargin
        anchors.rightMargin: _rightBlockWidth
        spacing: CustomToolbarMetrics.spacing

        ToolButton {
            id: toolSelectBtn
            Layout.alignment: Qt.AlignVCenter
            visible: !root.showPlanReturnButton
            implicitWidth: CustomToolbarMetrics.toolButtonSize
            implicitHeight: CustomToolbarMetrics.toolButtonSize
            background: Rectangle { color: "transparent" }
            contentItem: Item {
                anchors.fill: parent
                Image {
                    anchors.centerIn: parent
                    source: "qrc:/qmlimages/vololandlogo.svg"
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                    width: parent.height
                    height: parent.height
                }
            }
            z: 1
            onClicked: mainWindow.showToolSelectDialog()
        }

        // RowLayout 자식에는 anchors 사용 불가 → Item으로 감싸고 내부에 Row + MouseArea
        Item {
            id: returnButtonRow
            Layout.alignment: Qt.AlignVCenter
            Layout.maximumHeight: root.height
            visible: root.showPlanReturnButton
            implicitWidth: returnLabelsRow.width
            implicitHeight: returnLabelsRow.height
            z: 1000
            Row {
                id: returnLabelsRow
                anchors.centerIn: parent
                spacing: ScreenTools.defaultFontPixelWidth / 2
                QGCLabel { font.pointSize: ScreenTools.largeFontPointSize; text: "<" }
                QGCLabel { text: qsTr("Return"); font.pointSize: ScreenTools.largeFontPointSize }
            }
            MouseArea {
                anchors.fill: parent
                z: 1001
                preventStealing: true
                onClicked: mainWindow.showCustomFlyView()
                onPressed: (mouse) => { mouse.accepted = true }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: root.height
        }
    }

    // 우측 블록: RowLayout 밖에서 앵커로 고정 → Fly/Plan 전환 시 왼쪽만 바뀌고 아이콘 위치 불변
    Item {
        id: rightBlock
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: _rightBlockWidth

        RowLayout {
            id: rightBlockRow
            anchors.fill: parent
            anchors.rightMargin: CustomToolbarMetrics.horizontalMargin
            anchors.leftMargin: CustomToolbarMetrics.horizontalMargin
            spacing: CustomToolbarMetrics.spacing

            Item {
                Layout.fillWidth: true
            }

            Item {
                id: serverConnectionIcon
                Layout.preferredWidth: root.height
                Layout.preferredHeight: root.height
                Layout.alignment: Qt.AlignVCenter
                visible: true

                Image {
                    anchors.centerIn: parent
                    width: root.height
                    height: root.height
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                    source: {
                        if (mainWindow.serverConnectionStatus === 0) return "qrc:/qmlimages/ServerConnected.png"
                        if (mainWindow.serverConnectionStatus === 1) return "qrc:/qmlimages/ServerConnecting.png"
                        return "qrc:/qmlimages/ServerDisconnected.png"
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (serverSettingsPopupComponent.status === Component.Ready)
                            serverSettingsPopupComponent.createObject(mainWindow).open()
                    }
                }
            }

            Item {
                id: userInfoIcon
                Layout.preferredWidth: root.height
                Layout.preferredHeight: root.height
                Layout.alignment: Qt.AlignVCenter
                visible: true
                Image {
                    anchors.centerIn: parent
                    width: root.height
                    height: root.height
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                    source: "qrc:/qmlimages/UserInfo.png"
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (userInfoPopupComponent.status === Component.Ready)
                            userInfoPopupComponent.createObject(mainWindow).open()
                    }
                }
            }

            Component {
                id: serverSettingsPopupComponent
                ServerSettingsPopup { }
            }

            Component {
                id: userInfoPopupComponent
                UserInfoPopup { }
            }

            RowLayout {
                id: windowControlButtons
                Layout.alignment: Qt.AlignVCenter
                spacing: CustomToolbarMetrics.windowControlButtonsSpacing
                visible: !ScreenTools.isMobile && mainWindow.visibility !== Window.FullScreen

                ToolButton {
                    id: minimizeBtn
                    implicitWidth: CustomToolbarMetrics.windowControlButtonSize
                    implicitHeight: CustomToolbarMetrics.windowControlButtonSize
                    background: Rectangle {
                        color: minimizeBtn.hovered ? (minimizeBtn.pressed ? qgcPal.buttonHighlight : qgcPal.button) : "transparent"
                        radius: CustomToolbarMetrics.windowControlButtonRadius
                    }
                    contentItem: Text {
                        text: "−"
                        font.pixelSize: CustomToolbarMetrics.windowControlMinimizeFontSize
                        color: qgcPal.buttonText
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        mainWindow.saveVisibilityBeforeMinimize()
                        mainWindow.showMinimized()
                    }
                }

                ToolButton {
                    id: maximizeBtn
                    implicitWidth: CustomToolbarMetrics.windowControlButtonSize
                    implicitHeight: CustomToolbarMetrics.windowControlButtonSize
                    background: Rectangle {
                        color: maximizeBtn.hovered ? (maximizeBtn.pressed ? qgcPal.buttonHighlight : qgcPal.button) : "transparent"
                        radius: CustomToolbarMetrics.windowControlButtonRadius
                    }
                    contentItem: Text {
                        text: mainWindow.visibility === Window.Maximized ? "❐" : "□"
                        font.pixelSize: CustomToolbarMetrics.windowControlIconFontSize
                        color: qgcPal.buttonText
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        mainWindow.setUserInitiatedStateChange()
                        if (mainWindow.visibility === Window.Maximized) {
                            mainWindow.showNormal()
                        } else {
                            mainWindow.showMaximized()
                        }
                    }
                }

                ToolButton {
                    id: closeBtn
                    implicitWidth: CustomToolbarMetrics.windowControlButtonSize
                    implicitHeight: CustomToolbarMetrics.windowControlButtonSize
                    background: Rectangle {
                        color: closeBtn.hovered ? (closeBtn.pressed ? "#e81123" : "#c42b1c") : "transparent"
                        radius: CustomToolbarMetrics.windowControlButtonRadius
                    }
                    contentItem: Text {
                        text: "✕"
                        font.pixelSize: CustomToolbarMetrics.windowControlIconFontSize
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        if (mainWindow.allowViewSwitch()) {
                            mainWindow.performCloseChecks()
                        }
                    }
                }
            }
        }
    }
}

