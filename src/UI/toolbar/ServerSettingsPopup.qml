import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QGroundControl
import QGroundControl.Palette
import QGroundControl.ScreenTools
import QGroundControl.Controls
import QGroundControl.Toolbar

Popup {
    id: root
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    padding: 0
    width: typeof mainWindow !== "undefined" ? mainWindow.width : 800
    height: typeof mainWindow !== "undefined" ? mainWindow.height : 600
    x: 0
    y: 0

    property real _contentMargin: ScreenTools.defaultFontPixelHeight / 2
    property real _popupWidth: 500
    property real _popupHeight: 400

    ButtonGroup {
        id: serverGroup
        exclusive: true
    }

    function _loadFromConfig() {
        serverModel.clear()
        if (typeof mainWindow === "undefined" || !mainWindow.serverListData) return
        var list = mainWindow.serverListData
        for (var i = 0; i < list.length; i++) {
            var o = list[i]
            var name_ = o.serverName || ""
            var ip_ = o.ipAddress || ""
            var port_ = o.port || ""
            var valid = _rowValid(name_, ip_, port_)
            serverModel.append({
                serverName: name_,
                ipAddress: ip_,
                port: port_,
                isSelected: valid && !!o.isSelected
            })
        }
    }

    function _saveToConfig() {
        if (typeof mainWindow === "undefined") return
        var arr = []
        for (var i = 0; i < serverModel.count; i++) {
            var item = serverModel.get(i)
            arr.push({
                serverName: item.serverName || "",
                ipAddress: item.ipAddress || "",
                port: item.port || "",
                isSelected: !!item.isSelected
            })
        }
        mainWindow.serverListData = arr
    }

    onOpened: _loadFromConfig()
    onClosed: {
        _removeInvalidRows()
        _saveToConfig()
    }

    function _removeInvalidRows() {
        for (var i = serverModel.count - 1; i >= 0; i--) {
            var item = serverModel.get(i)
            if (!_rowValid(item.serverName, item.ipAddress, item.port))
                serverModel.remove(i)
        }
    }

    function _isOnlyKoreanJamo(s) {
        if (!s || typeof s !== "string") return true
        var t = s.trim()
        if (t.length === 0) return true
        return /^[\u1100-\u11FF\u3130-\u318F\s]*$/.test(t)
    }

    function _isValidServerName(name) {
        if (!name || typeof name !== "string") return false
        var t = name.trim()
        return t.length > 0 && !_isOnlyKoreanJamo(t)
    }

    function _isValidIPv4(ip) {
        if (!ip || typeof ip !== "string") return false
        var t = ip.trim()
        var re = /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/
        var m = re.exec(t)
        if (!m) return false
        for (var i = 1; i <= 4; i++) {
            var n = parseInt(m[i], 10)
            if (n < 0 || n > 255) return false
        }
        return true
    }

    function _isValidPort(port) {
        if (port === undefined || port === null) return false
        var p = typeof port === "string" ? port.trim() : String(port)
        if (p.length === 0) return false
        var n = parseInt(p, 10)
        if (isNaN(n)) return false
        return n > 0
    }

    function _rowValid(serverName, ipAddress, port) {
        return _isValidServerName(serverName) && _isValidIPv4(ipAddress) && _isValidPort(port)
    }

    function _rowValidationErrorLines(serverName, ipAddress, port) {
        var lines = []
        if (!_isValidServerName(serverName)) {
            if (!serverName || !serverName.trim()) lines.push(qsTr("서버 이름을 입력해 주세요."))
            else if (_isOnlyKoreanJamo(serverName)) lines.push(qsTr("서버 이름은 한글·영어·특수문자를 사용할 수 있습니다. 단 한글 낱자(ㄱ, ㄴ, ㅏ 등)만으로는 설정할 수 없습니다."))
        }
        if (!_isValidIPv4(ipAddress)) lines.push(qsTr("IPv4 형식을 맞춰주세요."))
        if (!_isValidPort(port)) lines.push(qsTr("포트는 0보다 큰 숫자로 입력해 주세요."))
        return lines.join("\n")
    }

    function _showValidationAlert(msg) {
        validationMessage = (msg !== undefined && msg !== null) ? String(msg) : ""
        validationPopup.open()
    }

    property string validationMessage: ""
    Popup {
        id: validationPopup
        parent: Overlay.overlay
        anchors.centerIn: Overlay.overlay
        width: Math.min(320, (Overlay.overlay ? Overlay.overlay.width : 320) - 40)
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        padding: 15
        onOpened: validationCloseTimer.start()
        Timer {
            id: validationCloseTimer
            interval: 3000
            repeat: false
            onTriggered: validationPopup.close()
        }
        background: Rectangle {
            color: qgcPal.windowShade
            border.color: qgcPal.windowShadeLight
            radius: 4
        }
        contentItem: ColumnLayout {
            spacing: 10
            QGCLabel {
                text: root.validationMessage
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                color: qgcPal.buttonText
            }
            QGCButton {
                text: qsTr("확인")
                Layout.alignment: Qt.AlignHCenter
                onClicked: validationPopup.close()
            }
        }
    }

    background: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.4)
        anchors.fill: parent
    }

    Rectangle {
        anchors.centerIn: parent
        width: root._popupWidth
        height: root._popupHeight
        color: qgcPal.windowShade
        radius: 4
        border.width: 1
        border.color: qgcPal.windowShadeLight

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root._contentMargin
            spacing: root._contentMargin

            RowLayout {
                Layout.fillWidth: true
                spacing: root._contentMargin

                QGCLabel {
                    text: qsTr("서버 설정")
                    font.pointSize: ScreenTools.mediumFontPointSize
                    Layout.fillWidth: true
                    verticalAlignment: Text.AlignVCenter
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
                    onClicked: root.close()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: qgcPal.window
                radius: 2

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    ListView {
                        id: serverListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 5

                        model: ListModel { id: serverModel }

                        delegate: RowLayout {
                            width: serverListView.width
                            spacing: 10
                            property bool rowValid: root._rowValid(serverName, ipAddress, port)
                            property string rowErrorLines: root._rowValidationErrorLines(serverName, ipAddress, port)

                            Item {
                                id: checkBoxWrapper
                                Layout.preferredWidth: 28
                                Layout.preferredHeight: 28
                                Layout.alignment: Qt.AlignVCenter
                                property bool rowValid: checkBoxWrapper.parent.rowValid
                                property string rowErrorLines: checkBoxWrapper.parent.rowErrorLines
                                CheckBox {
                                    id: rowCheckBox
                                    anchors.centerIn: parent
                                    checked: isSelected
                                    enabled: checkBoxWrapper.rowValid
                                    ButtonGroup.group: serverGroup
                                    onCheckedChanged: {
                                        if (checkBoxWrapper.rowValid) {
                                            serverModel.setProperty(index, "isSelected", checked)
                                            root._saveToConfig()
                                        }
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    visible: !checkBoxWrapper.rowValid
                                    onPressed: (mouse) => mouse.accepted = true
                                    onReleased: (mouse) => mouse.accepted = true
                                    onClicked: root._showValidationAlert(checkBoxWrapper.rowErrorLines || "")
                                }
                            }

                            QGCTextField {
                                Layout.fillWidth: true
                                placeholderText: qsTr("서버 이름")
                                text: serverName
                                onEditingFinished: {
                                    serverModel.setProperty(index, "serverName", text)
                                    root._saveToConfig()
                                    if (!root._rowValid(text, ipAddress, port) && isSelected)
                                        serverModel.setProperty(index, "isSelected", false)
                                }
                            }

                            QGCTextField {
                                Layout.preferredWidth: 120
                                placeholderText: qsTr("IP 주소")
                                text: ipAddress
                                onEditingFinished: {
                                    serverModel.setProperty(index, "ipAddress", text)
                                    root._saveToConfig()
                                    if (!root._rowValid(serverName, text, port) && isSelected)
                                        serverModel.setProperty(index, "isSelected", false)
                                }
                            }

                            QGCTextField {
                                Layout.preferredWidth: 60
                                placeholderText: qsTr("포트")
                                text: port
                                onEditingFinished: {
                                    serverModel.setProperty(index, "port", text)
                                    root._saveToConfig()
                                    if (!root._rowValid(serverName, ipAddress, text) && isSelected)
                                        serverModel.setProperty(index, "isSelected", false)
                                }
                            }

                            QGCButton {
                                text: "삭제"
                                onClicked: {
                                    serverModel.remove(index)
                                    root._saveToConfig()
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Item { Layout.fillWidth: true }

                        QGCButton {
                            id: addBtn
                            text: "추가"
                            enabled: serverModel.count < 10

                            ToolTip.visible: hovered && !enabled
                            ToolTip.text: qsTr("최대 10개까지만 등록 가능합니다.")

                            onClicked: {
                                if (serverModel.count < 10) {
                                    serverModel.append({
                                        "isSelected": false,
                                        "serverName": "",
                                        "ipAddress": "",
                                        "port": ""
                                    })
                                    root._saveToConfig()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }
}
