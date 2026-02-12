/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Window

import QGroundControl
import QGroundControl.Palette
import QGroundControl.Controls
import QGroundControl.FactControls
import QGroundControl.ScreenTools
import QGroundControl.FlightDisplay
import QGroundControl.FlightMap
import QGroundControl.Toolbar

import QGroundControl.UTMSP

/// @brief Native QML top level window
/// All properties defined here are visible to all QML pages.
ApplicationWindow {
    id:             mainWindow
    visible:        true

    minimumHeight: customFlyView.implicitHeight + customtoolBar.height + 40

    property bool   _utmspSendActTrigger
    property bool   _utmspStartTelemetry
    /// Plan 뷰 / Custom Plan 뷰 진입 여부 (툴바 숨김·컨텐츠 상단 정렬용)
    property bool   _planViewShown: false
    /// true = Custom Plan View(드론상태+CustomPlanView), false = Plan Flight(PlanView)
    property bool   _customPlanViewShown: false
    /// PlanView의 planMasterController(0번 mission start 포함). FlyViewMap/CustomPlanView에서 공유
    readonly property var _planController: typeof planViewArea !== "undefined" ? planViewArea._planController : null

    Component.onCompleted: {
        // Start the sequence of first run prompt(s)
        firstRunPromptManager.nextPrompt()
    }

    /// Saves main window position and size and re-opens it in the same position and size next time
    MainWindowSavedState {
        window: mainWindow
    }

    QtObject {
        id: firstRunPromptManager

        property var currentDialog:     null
        property var rgPromptIds:       QGroundControl.corePlugin.firstRunPromptsToShow()
        property int nextPromptIdIndex: 0

        function clearNextPromptSignal() {
            if (currentDialog) {
                currentDialog.closed.disconnect(nextPrompt)
            }
        }

        function nextPrompt() {
            if (nextPromptIdIndex < rgPromptIds.length) {
                var component = Qt.createComponent(QGroundControl.corePlugin.firstRunPromptResource(rgPromptIds[nextPromptIdIndex]));
                currentDialog = component.createObject(mainWindow)
                currentDialog.closed.connect(nextPrompt)
                currentDialog.open()
                nextPromptIdIndex++
            } else {
                currentDialog = null
                showPreFlightChecklistIfNeeded()
            }
        }
    }

    readonly property real      _topBottomMargins:          ScreenTools.defaultFontPixelHeight * 0.5

    //-------------------------------------------------------------------------
    //-- Global Scope Variables

    QtObject {
        id: globals

        readonly property var       activeVehicle:                  QGroundControl.multiVehicleManager.activeVehicle
        readonly property real      defaultTextHeight:              ScreenTools.defaultFontPixelHeight
        readonly property real      defaultTextWidth:               ScreenTools.defaultFontPixelWidth
        readonly property var       planMasterControllerFlyView:    customFlyView.planController !== undefined ? customFlyView.planController : null
        readonly property var       guidedControllerFlyView:        customFlyView.guidedController !== undefined ? customFlyView.guidedController : null

<<<<<<< HEAD
=======
        // FlyViewMap 등 mapToItem(globals.parent, ...)용 (QGC와 동일)
        property var                parent:                         mainWindow

>>>>>>> f9dfdbd69 (commit (clean))
        // Number of QGCTextField's with validation errors. Used to prevent closing panels with validation errors.
        property int                validationErrorCount:           0 

        // Property to manage RemoteID quick access to settings page
        property bool               commingFromRIDIndicator:        false
    }

    /// Default color palette used throughout the UI
    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    //-------------------------------------------------------------------------
    //-- Actions

    signal armVehicleRequest
    signal forceArmVehicleRequest
    signal disarmVehicleRequest
    signal vtolTransitionToFwdFlightRequest
    signal vtolTransitionToMRFlightRequest
    signal showPreFlightChecklistIfNeeded

    //-------------------------------------------------------------------------
    //-- Global Scope Functions

    // This function is used to prevent view switching if there are validation errors
    function allowViewSwitch(previousValidationErrorCount = 0) {
        // Run validation on active focus control to ensure it is valid before switching views
        if (mainWindow.activeFocusControl instanceof FactTextField) {
            mainWindow.activeFocusControl._onEditingFinished()
        }
        return globals.validationErrorCount <= previousValidationErrorCount
    }

    //custom view: Plan/Custom Plan 뷰에서 뒤로갈 때 호출. 툴바 다시 표시되도록 _planViewShown 해제
    function showCustomFlyView() {
        _planViewShown = false
        _customPlanViewShown = false
        planView.visible = false
        customPlanView.visible = false
    }

    /// Custom Plan 뷰: 좌측 droneStatus + CustomPlanView (독립 화면)
    function showCustomPlanView() {
        if (allowViewSwitch()) {
            _planViewShown = true
            _customPlanViewShown = true
            planView.visible = false
            customPlanView.visible = true
        }
    }

    /// Plan Flight: PlanView만 표시 (독립 화면)
    function showPlanView() {
        _planViewShown = true
        _customPlanViewShown = false
        planView.visible = true
        customPlanView.visible = false
    }

    function showFlyView() {
        _planViewShown = false
        _customPlanViewShown = false
        planView.visible = false
        customPlanView.visible = false
    }

    function showTool(toolTitle, toolSource, toolIcon) {
        toolDrawer.backIcon     = customFlyView.visible ? "/qmlimages/PaperPlane.svg" : "/qmlimages/Plan.svg"
        toolDrawer.toolTitle    = toolTitle
        toolDrawer.toolSource   = toolSource
        toolDrawer.toolIcon     = toolIcon
        toolDrawer.visible      = true
    }

    function showAnalyzeTool() {
        showTool(qsTr("Analyze Tools"), "qrc:/qml/QGroundControl/AnalyzeView/AnalyzeView.qml", "/qmlimages/Analyze.svg")
    }

    function showVehicleConfig() {
        showTool(qsTr("Vehicle Configuration"), "qrc:/qml/QGroundControl/VehicleSetup/SetupView.qml", "/qmlimages/Gears.svg")
    }

    function showVehicleConfigParametersPage() {
        showVehicleConfig()
        toolDrawerLoader.item.showParametersPanel()
    }

    function showKnownVehicleComponentConfigPage(knownVehicleComponent) {
        showVehicleConfig()
        let vehicleComponent = globals.activeVehicle.autopilotPlugin.findKnownVehicleComponent(knownVehicleComponent)
        if (vehicleComponent) {
            toolDrawerLoader.item.showVehicleComponentPanel(vehicleComponent)
        }
    }

    function showSettingsTool(settingsPage = "") {
        showTool(qsTr("Application Settings"), "qrc:/qml/QGroundControl/Controls/AppSettings.qml", "/res/QGCLogoWhite")
        if (settingsPage !== "") {
            toolDrawerLoader.item.showSettingsPage(settingsPage)
        }
    }

    //-------------------------------------------------------------------------
    //-- Global simple message dialog

    function showMessageDialog(dialogTitle, dialogText, buttons = Dialog.Ok, acceptFunction = null, closeFunction = null) {
        simpleMessageDialogComponent.createObject(mainWindow, { title: dialogTitle, text: dialogText, buttons: buttons, acceptFunction: acceptFunction, closeFunction: closeFunction }).open()
    }

    // This variant is only meant to be called by QGCApplication
    function _showMessageDialog(dialogTitle, dialogText) {
        showMessageDialog(dialogTitle, dialogText)
    }

    Component {
        id: simpleMessageDialogComponent

        QGCSimpleMessageDialog {
        }
    }

    property bool _forceClose: false

    function finishCloseProcess() {
        _forceClose = true
        // For some reason on the Qml side Qt doesn't automatically disconnect a signal when an object is destroyed.
        // So we have to do it ourselves otherwise the signal flows through on app shutdown to an object which no longer exists.
        firstRunPromptManager.clearNextPromptSignal()
        QGroundControl.linkManager.shutdown()
        QGroundControl.videoManager.stopVideo();
        mainWindow.close()
    }

    // Check for things which should prevent the app from closing
    //  Returns true if it is OK to close
    readonly property int _skipUnsavedMissionCheckMask: 0x01
    readonly property int _skipPendingParameterWritesCheckMask: 0x02
    readonly property int _skipActiveConnectionsCheckMask: 0x04
    property int _closeChecksToSkip: 0
    function performCloseChecks() {
        if (!(_closeChecksToSkip & _skipUnsavedMissionCheckMask) && !checkForUnsavedMission()) {
            return false
        }
        if (!(_closeChecksToSkip & _skipPendingParameterWritesCheckMask) && !checkForPendingParameterWrites()) {
            return false
        }
        if (!(_closeChecksToSkip & _skipActiveConnectionsCheckMask) && !checkForActiveConnections()) {
            return false
        }
        finishCloseProcess()
        return true
    }

    property string closeDialogTitle: qsTr("Close %1").arg(QGroundControl.appName)

    function checkForUnsavedMission() {
        if (planView._planMasterController.dirty) {
            showMessageDialog(closeDialogTitle,
                              qsTr("You have a mission edit in progress which has not been saved/sent. If you close you will lose changes. Are you sure you want to close?"),
                              Dialog.Yes | Dialog.No,
                              function() { _closeChecksToSkip |= _skipUnsavedMissionCheckMask; performCloseChecks() })
            return false
        } else {
            return true
        }
    }

    function checkForPendingParameterWrites() {
        for (var index=0; index<QGroundControl.multiVehicleManager.vehicles.count; index++) {
            if (QGroundControl.multiVehicleManager.vehicles.get(index).parameterManager.pendingWrites) {
                mainWindow.showMessageDialog(closeDialogTitle,
                    qsTr("You have pending parameter updates to a vehicle. If you close you will lose changes. Are you sure you want to close?"),
                    Dialog.Yes | Dialog.No,
                    function() { _closeChecksToSkip |= _skipPendingParameterWritesCheckMask; performCloseChecks() })
                return false
            }
        }
        return true
    }

    function checkForActiveConnections() {
        if (QGroundControl.multiVehicleManager.activeVehicle) {
            mainWindow.showMessageDialog(closeDialogTitle,
                qsTr("There are still active connections to vehicles. Are you sure you want to exit?"),
                Dialog.Yes | Dialog.No,
                function() { _closeChecksToSkip |= _skipActiveConnectionsCheckMask; performCloseChecks() })
            return false
        } else {
            return true
        }
    }

    onClosing: (close) => {
        if (!_forceClose) {
            _closeChecksToSkip = 0
            close.accepted = performCloseChecks()
        }
    }

    background: Rectangle {
        anchors.fill:   parent
        color:          QGroundControl.globalPalette.window
    }

<<<<<<< HEAD
    FlyViewMap {
        id:                     mapControl
        anchors.fill: parent
        z: -1
        planMasterController:   _planController
        rightPanelWidth:        ScreenTools.defaultFontPixelHeight * 9
        pipView:                _pipView
        pipMode:                !_mainWindowIsMap
        toolInsets:             customOverlay.totalToolInsets
        mapName:                "FlightDisplayView"
        enabled:                !viewer3DWindow.isOpen
    }

=======
    // QGC와 동일: Fly 맵은 MainWindow가 아닌 Fly 뷰(CustomFlyView) 내부에 둠
>>>>>>> f9dfdbd69 (commit (clean))
    CustomToolbar {
        id: customtoolBar
        anchors.top: parent.top
        // 높이 미지정 → CustomToolbar.qml 기본값 ScreenTools.toolbarHeight (CustomPlanViewToolBar와 동일)
        // Fly 뷰에서만 표시. Plan/Custom Plan 진입 시 숨김
        visible: !mainWindow._planViewShown
    }

    // Custom Plan View일 때만 상단 툴바 → CustomFlyView와 동일하게 툴바 밑에 droneStatus
    CustomPlanViewToolBar {
        id: customPlanToolBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        visible: mainWindow._customPlanViewShown
        planMasterController: _planController
    }

    // Fly/Plan 뷰 컨테이너. Custom Plan = 툴바 밑(droneStatus 동일 위치), Plan Flight = 상단부터, Fly = customtoolBar 밑
    Item {
        id: flyPlanContainer
        anchors.top: mainWindow._customPlanViewShown ? customPlanToolBar.bottom : (mainWindow._planViewShown ? parent.top : customtoolBar.bottom)
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        RowLayout {
            anchors.fill: parent
            spacing: 0
            CustomFlyView {
                id: customFlyView
                Layout.fillHeight: true
                Layout.fillWidth: !mainWindow._planViewShown
<<<<<<< HEAD
                Layout.preferredWidth: mainWindow._planViewShown ? (mainWindow._customPlanViewShown ? Math.min(mainWindow.width * 0.20, 350 * 1.25) : 0) : undefined
                planViewActive: mainWindow._customPlanViewShown
            }
            // PlanView와 CustomPlanView는 독립 화면. 같은 영역에 겹쳐 두고 한 번에 하나만 표시. PlanView의 planMasterController(0번 mission start 포함)를 공유.
            Item {
                id: planViewArea
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 0
=======
                // Custom Plan 뷰: 내부 DroneList 등 minimumWidth(350) 만족하도록 최소 350 부여 (짤림 방지)
                // QML double 속성에는 undefined를 넣지 않고, Fly 모드에서는 0으로 두어 경고를 제거한다.
                Layout.preferredWidth: mainWindow._planViewShown
                                        ? (mainWindow._customPlanViewShown ? Math.max(Math.min(mainWindow.width * 0.20, 350 * 1.25), 350) : 0)
                                        : 0
                planViewActive: mainWindow._customPlanViewShown
                planMasterController: mainWindow._planController
            }
            // PlanView와 CustomPlanView는 독립 화면. 같은 영역에 겹쳐 두고 한 번에 하나만 표시. PlanView의 planMasterController(0번 mission start 포함)를 공유.
            // Fly 모드(_planViewShown == false)에서는 레이아웃에서 폭을 차지하지 않도록 Layout.*을 조건부로 제어한다.
            Item {
                id: planViewArea
                Layout.fillWidth:  mainWindow._planViewShown
                Layout.fillHeight: mainWindow._planViewShown
                Layout.minimumWidth: mainWindow._planViewShown ? 0 : 0
                Layout.preferredWidth: mainWindow._planViewShown ? undefined : 0
>>>>>>> f9dfdbd69 (commit (clean))
                readonly property var _planController: planView._planMasterController
                PlanView {
                    id: planView
                    anchors.fill: parent
                    visible: mainWindow._planViewShown && !mainWindow._customPlanViewShown
                    z: mainWindow._customPlanViewShown ? 0 : 1
                }
                CustomPlanView {
                    id: customPlanView
                    anchors.fill: parent
                    visible: mainWindow._customPlanViewShown
                    z: mainWindow._customPlanViewShown ? 1 : 0
                    planMasterController: planViewArea._planController
                    showToolbar: false
                    deviceName: customFlyView.selectedDeviceName
<<<<<<< HEAD
                    // droneStatus와 동일한 식으로 고정 (customFlyView.width는 레이아웃 갱신 시점에 0일 수 있음)
                    droneStatusWidth: mainWindow._customPlanViewShown ? Math.min(mainWindow.width * 0.20, 350 * 1.25) : 0
=======
                    // CustomFlyView 좌측 패널 실제 너비와 동기화
                    droneStatusWidth: mainWindow._customPlanViewShown ? customFlyView.leftPanelWidth : 0
>>>>>>> f9dfdbd69 (commit (clean))
                }
            }
        }
        // Plan 뷰가 숨겨질 때마다 툴바 표시 플래그 해제 (뒤로가기 등 모든 경로 대응)
        Connections {
            target: planView
            function onVisibleChanged() {
                if (!planView.visible && !customPlanView.visible)
                    mainWindow._planViewShown = false
            }
        }
        Connections {
            target: customPlanView
            function onVisibleChanged() {
                if (!planView.visible && !customPlanView.visible)
                    mainWindow._planViewShown = false
            }
        }
    }
<<<<<<< HEAD
/*
    ColumnLayout{
    id: droneStatus
    
    anchors.left: parent.left
    anchors.top: customtoolBar.bottom
    anchors.bottom: parent.bottom

    anchors.leftMargin: 10
    anchors.topMargin: 20
    anchors.bottomMargin: 20

    width: mainWindow.width * 0.18
    height: mainWindow.height

    spacing: 10 

        DroneList {
            id:                     droneList
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 350
            Layout.minimumHeight: 300
            Layout.preferredWidth: droneStatus.width
            Layout.preferredHeight: droneStatus.height
            Layout.maximumWidth: 350 * 1.25
            
            utmspSendActTrigger:    _utmspSendActTrigger
        }
        Item { Layout.fillHeight: true }

        FlyViewBottomRightRowLayout {
            id:                 bottomRightRowLayout
            Layout.fillWidth:   true
            // 여기서 높이와 너비를 너무 빡빡하게 제한하지 마세요.
            Layout.preferredHeight: implicitHeight 
            deviceName:         droneList.selectedDevice
            //visible: droneList.selectedDevice !== ""
        }

        DroneVideo{
        
            id: droneVideo
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 350
            Layout.minimumHeight: 200
            Layout.preferredWidth: droneStatus.width
            Layout.preferredHeight: droneVideo.width * 0.75
            Layout.maximumWidth: 350 * 1.25
            Layout.maximumHeight: 200 * 1.25
            
            
            deviceName: droneList.selectedDevice

            //visible: droneList.selectedDevice !== ""
        }

        DroneStatusMessage{

            id: droneStatusMessage
            Layout.fillWidth: true
            Layout.minimumHeight: 100
            Layout.minimumWidth: droneStatus.width
            Layout.preferredWidth: droneStatus.width
            Layout.preferredHeight: droneStatus.width * 0.35
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
            Layout.minimumWidth: droneStatus.width
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

=======
>>>>>>> f9dfdbd69 (commit (clean))

    footer: LogReplayStatusBar {
        visible: QGroundControl.settingsManager.flyViewSettings.showLogReplayStatusBar.rawValue
    }

    MessageDialog {
        id:                 showTouchAreasNotification
        title:              qsTr("Debug Touch Areas")
        text:               qsTr("Touch Area display toggled")
        buttons:            MessageDialog.Ok
    }

    MessageDialog {
        id:                 advancedModeOnConfirmation
        title:              qsTr("Advanced Mode")
        text:               QGroundControl.corePlugin.showAdvancedUIMessage
        buttons:            MessageDialog.Yes | MessageDialog.No
        onButtonClicked: function (button, role) {
            if (button === MessageDialog.Yes) {
                QGroundControl.corePlugin.showAdvancedUI = true
            }
        }
    }

    MessageDialog {
        id:                 advancedModeOffConfirmation
        title:              qsTr("Advanced Mode")
        text:               qsTr("Turn off Advanced Mode?")
        buttons:            MessageDialog.Yes | MessageDialog.No
        onButtonClicked: function (button, role) {
            if (button === MessageDialog.Yes) {
                QGroundControl.corePlugin.showAdvancedUI = false
            }
        }
    }

    function showToolSelectDialog() {
        if (mainWindow.allowViewSwitch()) {
            mainWindow.showIndicatorDrawer(toolSelectComponent, null)
        }
    }

    Component {
        id: toolSelectComponent

        ToolIndicatorPage {
            id:         toolSelectDialog
            //title:      qsTr("Select Tool")

            property real _toolButtonHeight:    ScreenTools.defaultFontPixelHeight * 3
            property real _margins:             ScreenTools.defaultFontPixelWidth

            contentComponent: Component {
                ColumnLayout {
                    width:  innerLayout.width + (toolSelectDialog._margins * 2)
                    height: innerLayout.height + (toolSelectDialog._margins * 2)

                    ColumnLayout {
                        id:             innerLayout
                        Layout.margins: toolSelectDialog._margins
                        spacing:        ScreenTools.defaultFontPixelWidth

                        SubMenuButton {
                            height:             toolSelectDialog._toolButtonHeight
                            Layout.fillWidth:   true
                            text:               qsTr("Plan Flight")
                            imageResource:      "/qmlimages/Plan.svg"
                            onClicked: {
                                if (mainWindow.allowViewSwitch()) {
                                    mainWindow.closeIndicatorDrawer()
                                    mainWindow.showPlanView()
                                }
                            }
                        }

                        // 26.01.30 test: Custom Plan 뷰 진입 (좌측 droneStatus만 표시)
                        SubMenuButton {
                            height:             toolSelectDialog._toolButtonHeight
                            Layout.fillWidth:   true
                            text:               qsTr("Custom Plan View")
                            imageResource:      "/qmlimages/Plan.svg"
                            onClicked: {
                                if (mainWindow.allowViewSwitch()) {
                                    mainWindow.closeIndicatorDrawer()
                                    mainWindow.showCustomPlanView()
                                }
                            }
                        }

                        SubMenuButton {
                            id:                 analyzeButton
                            height:             toolSelectDialog._toolButtonHeight
                            Layout.fillWidth:   true
                            text:               qsTr("Analyze Tools")
                            imageResource:      "/qmlimages/Analyze.svg"
                            visible:            QGroundControl.corePlugin.showAdvancedUI
                            onClicked: {
                                if (mainWindow.allowViewSwitch()) {
                                    mainWindow.closeIndicatorDrawer()
                                    mainWindow.showAnalyzeTool()
                                }
                            }
                        }

                        SubMenuButton {
                            id:                 setupButton
                            height:             toolSelectDialog._toolButtonHeight
                            Layout.fillWidth:   true
                            text:               qsTr("Vehicle Configuration")
                            imageResource:      "/qmlimages/Gears.svg"
                            onClicked: {
                                if (mainWindow.allowViewSwitch()) {
                                    mainWindow.closeIndicatorDrawer()
                                    mainWindow.showVehicleConfig()
                                }
                            }
                        }

                        SubMenuButton {
                            id:                 settingsButton
                            height:             toolSelectDialog._toolButtonHeight
                            Layout.fillWidth:   true
                            text:               qsTr("Application Settings")
                            imageResource:      "/res/QGCLogoFull.svg"
                            imageColor:         "transparent"
                            visible:            !QGroundControl.corePlugin.options.combineSettingsAndSetup
                            onClicked: {
                                if (mainWindow.allowViewSwitch()) {
                                    drawer.close()
                                    mainWindow.showSettingsTool()
                                }
                            }
                        }

                        SubMenuButton {
                            id:                 closeButton
                            height:             toolSelectDialog._toolButtonHeight
                            Layout.fillWidth:   true
                            text:               qsTr("Close %1").arg(QGroundControl.appName)
                            imageResource:      "/res/cancel.svg"
                            visible:            mainWindow.visibility === Window.FullScreen
                            onClicked: {
                                if (mainWindow.allowViewSwitch()) {
                                    mainWindow.finishCloseProcess()
                                }
                            }
                        }

                        ColumnLayout {
                            width:                  innerLayout.width
                            spacing:                0
                            Layout.alignment:       Qt.AlignHCenter

                            QGCLabel {
                                id:                     versionLabel
                                text:                   qsTr("%1 Version").arg(QGroundControl.appName)
                                font.pointSize:         ScreenTools.smallFontPointSize
                                wrapMode:               QGCLabel.WordWrap
                                Layout.maximumWidth:    parent.width
                                Layout.alignment:       Qt.AlignHCenter
                            }

                            QGCLabel {
                                text:                   QGroundControl.qgcVersion
                                font.pointSize:         ScreenTools.smallFontPointSize
                                wrapMode:               QGCLabel.WrapAnywhere
                                Layout.maximumWidth:    parent.width
                                Layout.alignment:       Qt.AlignHCenter

                                QGCMouseArea {
                                    id:                 easterEggMouseArea
                                    anchors.topMargin:  -versionLabel.height
                                    anchors.fill:       parent

                                    onClicked: (mouse) => {
                                        if (mouse.modifiers & Qt.ControlModifier) {
                                            QGroundControl.corePlugin.showTouchAreas = !QGroundControl.corePlugin.showTouchAreas
                                            showTouchAreasNotification.open()
                                        } else if (ScreenTools.isMobile || mouse.modifiers & Qt.ShiftModifier) {
                                            mainWindow.closeIndicatorDrawer()
                                            if(!QGroundControl.corePlugin.showAdvancedUI) {
                                                advancedModeOnConfirmation.open()
                                            } else {
                                                advancedModeOffConfirmation.open()
                                            }
                                        }
                                    }

                                    // This allows you to change this on mobile
                                    onPressAndHold: {
                                        QGroundControl.corePlugin.showTouchAreas = !QGroundControl.corePlugin.showTouchAreas
                                        showTouchAreasNotification.open()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id:             toolDrawer
        anchors.fill:   parent
        visible:        false
        color:          qgcPal.window

        property var backIcon
        property string toolTitle
        property alias toolSource:  toolDrawerLoader.source
        property var toolIcon

        onVisibleChanged: {
            if (!toolDrawer.visible) {
                toolDrawerLoader.source = ""
            }
        }

        // This need to block click event leakage to underlying map.
        DeadMouseArea {
            anchors.fill: parent
        }

        Rectangle {
            id:             toolDrawerToolbar
            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.top:    parent.top
            height:         ScreenTools.toolbarHeight
            color:          qgcPal.toolbarBackground

            RowLayout {
                id:                 toolDrawerToolbarLayout
                anchors.leftMargin: ScreenTools.defaultFontPixelWidth
                anchors.left:       parent.left
                anchors.top:        parent.top
                anchors.bottom:     parent.bottom
                spacing:            ScreenTools.defaultFontPixelWidth

                QGCLabel {
                    font.pointSize: ScreenTools.largeFontPointSize
                    text:           "<"
                }

                QGCLabel {
                    id:             toolbarDrawerText
                    text:           qsTr("Exit") + " " + toolDrawer.toolTitle
                    font.pointSize: ScreenTools.largeFontPointSize
                }
            }

            QGCMouseArea {
                anchors.fill: toolDrawerToolbarLayout
                onClicked: {
                    if (mainWindow.allowViewSwitch()) {
                        toolDrawer.visible = false
                    }
                }
            }
        }

        Loader {
            id:             toolDrawerLoader
            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.top:    toolDrawerToolbar.bottom
            anchors.bottom: parent.bottom

            Connections {
                target:                 toolDrawerLoader.item
                ignoreUnknownSignals:   true
                onPopout:               toolDrawer.visible = false
            }
        }
    }

    //-------------------------------------------------------------------------
    //-- Critical Vehicle Message Popup

    function showCriticalVehicleMessage(message) {
        closeIndicatorDrawer()
        if (criticalVehicleMessagePopup.visible || QGroundControl.videoManager.fullScreen) {
            // We received additional warning message while an older warning message was still displayed.
            // When the user close the older one drop the message indicator tool so they can see the rest of them.
            criticalVehicleMessagePopup.additionalCriticalMessagesReceived = true
        } else {
            criticalVehicleMessagePopup.criticalVehicleMessage      = message
            criticalVehicleMessagePopup.additionalCriticalMessagesReceived = false
            criticalVehicleMessagePopup.open()
        }
    }

    Popup {
        id:                 criticalVehicleMessagePopup
        y:                  ScreenTools.toolbarHeight + ScreenTools.defaultFontPixelHeight
        x:                  Math.round((mainWindow.width - width) * 0.5)
        width:              mainWindow.width  * 0.55
        height:             criticalVehicleMessageText.contentHeight + ScreenTools.defaultFontPixelHeight * 2
        modal:              false
        focus:              true

        property alias  criticalVehicleMessage:             criticalVehicleMessageText.text
        property bool   additionalCriticalMessagesReceived: false

        background: Rectangle {
            anchors.fill:   parent
            color:          qgcPal.alertBackground
            radius:         ScreenTools.defaultFontPixelHeight * 0.5
            border.color:   qgcPal.alertBorder
            border.width:   2

            Rectangle {
                anchors.horizontalCenter:   parent.horizontalCenter
                anchors.top:                parent.top
                anchors.topMargin:          -(height / 2)
                color:                      qgcPal.alertBackground
                radius:                     ScreenTools.defaultFontPixelHeight * 0.25
                border.color:               qgcPal.alertBorder
                border.width:               1
                width:                      vehicleWarningLabel.contentWidth + _margins
                height:                     vehicleWarningLabel.contentHeight + _margins

                property real _margins: ScreenTools.defaultFontPixelHeight * 0.25

                QGCLabel {
                    id:                 vehicleWarningLabel
                    anchors.centerIn:   parent
                    text:               qsTr("Vehicle Error")
                    font.pointSize:     ScreenTools.smallFontPointSize
                    color:              qgcPal.alertText
                }
            }

            Rectangle {
                id:                         additionalErrorsIndicator
                anchors.horizontalCenter:   parent.horizontalCenter
                anchors.bottom:             parent.bottom
                anchors.bottomMargin:       -(height / 2)
                color:                      qgcPal.alertBackground
                radius:                     ScreenTools.defaultFontPixelHeight * 0.25
                border.color:               qgcPal.alertBorder
                border.width:               1
                width:                      additionalErrorsLabel.contentWidth + _margins
                height:                     additionalErrorsLabel.contentHeight + _margins
                visible:                    criticalVehicleMessagePopup.additionalCriticalMessagesReceived

                property real _margins: ScreenTools.defaultFontPixelHeight * 0.25

                QGCLabel {
                    id:                 additionalErrorsLabel
                    anchors.centerIn:   parent
                    text:               qsTr("Additional errors received")
                    font.pointSize:     ScreenTools.smallFontPointSize
                    color:              qgcPal.alertText
                }
            }
        }

        QGCLabel {
            id:                 criticalVehicleMessageText
            width:              criticalVehicleMessagePopup.width - ScreenTools.defaultFontPixelHeight
            anchors.centerIn:   parent
            wrapMode:           Text.WordWrap
            color:              qgcPal.alertText
            textFormat:         TextEdit.RichText
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                criticalVehicleMessagePopup.close()
                if (criticalVehicleMessagePopup.additionalCriticalMessagesReceived) {
                    criticalVehicleMessagePopup.additionalCriticalMessagesReceived = false;
                    customFlyView.dropMainStatusIndicatorTool !== undefined && customFlyView.dropMainStatusIndicatorTool();
                } else {
                    QGroundControl.multiVehicleManager.activeVehicle.resetErrorLevelMessages();
                }
            }
        }
    }

    //-------------------------------------------------------------------------
    //-- Indicator Drawer

    function showIndicatorDrawer(drawerComponent, indicatorItem) {
        indicatorDrawer.sourceComponent = drawerComponent
        indicatorDrawer.indicatorItem = indicatorItem
        indicatorDrawer.open()
    }

    function closeIndicatorDrawer() {
        indicatorDrawer.close()
    }

    Popup {
        id:             indicatorDrawer
        x:              calcXPosition()
        y:              ScreenTools.toolbarHeight + _margins
        leftInset:      0
        rightInset:     0
        topInset:       0
        bottomInset:    0
        padding:        _margins * 2
        visible:        false
        modal:          true
        focus:          true
        closePolicy:    Popup.CloseOnEscape | Popup.CloseOnPressOutside

        property var sourceComponent
        property var indicatorItem

        property bool _expanded:    false
        property real _margins:     ScreenTools.defaultFontPixelHeight / 4

        function calcXPosition() {
            if (indicatorItem) {
                var xCenter = indicatorItem.mapToItem(mainWindow.contentItem, indicatorItem.width / 2, 0).x
                return Math.max(_margins, Math.min(xCenter - (contentItem.implicitWidth / 2), mainWindow.contentItem.width - contentItem.implicitWidth - _margins - (indicatorDrawer.padding * 2) - (ScreenTools.defaultFontPixelHeight / 2)))
            } else {
                return _margins
            }
        }

        onOpened: {
            _expanded                               = false;
            indicatorDrawerLoader.sourceComponent   = indicatorDrawer.sourceComponent
        }
        onClosed: {
            _expanded                               = false
            indicatorItem                           = undefined
            indicatorDrawerLoader.sourceComponent   = undefined
        }

        background: Item {
            Rectangle {
                id:             backgroundRect
                anchors.fill:   parent
                color:          QGroundControl.globalPalette.window
                radius:         indicatorDrawer._margins
                opacity:        0.85
            }

            Rectangle {
                anchors.horizontalCenter:   backgroundRect.right
                anchors.verticalCenter:     backgroundRect.top
                width:                      ScreenTools.largeFontPixelHeight
                height:                     width
                radius:                     width / 2
                color:                      QGroundControl.globalPalette.button
                border.color:               QGroundControl.globalPalette.buttonText
                visible:                    indicatorDrawerLoader.item && indicatorDrawerLoader.item.showExpand && !indicatorDrawer._expanded

                QGCLabel {
                    anchors.centerIn:   parent
                    text:               ">"
                    color:              QGroundControl.globalPalette.buttonText
                }  

                QGCMouseArea {
                    fillItem: parent
                    onClicked: indicatorDrawer._expanded = true
                }
            }
        }

        contentItem: QGCFlickable {
            id:             indicatorDrawerLoaderFlickable
            implicitWidth:  Math.min(mainWindow.contentItem.width - (2 * indicatorDrawer._margins) - (indicatorDrawer.padding * 2), indicatorDrawerLoader.width)
            implicitHeight: Math.min(mainWindow.contentItem.height - ScreenTools.toolbarHeight - (2 * indicatorDrawer._margins) - (indicatorDrawer.padding * 2), indicatorDrawerLoader.height)
            contentWidth:   indicatorDrawerLoader.width
            contentHeight:  indicatorDrawerLoader.height

            Loader {
                id: indicatorDrawerLoader

                Binding {
                    target:     indicatorDrawerLoader.item
                    property:   "expanded"
                    value:      indicatorDrawer._expanded
                }

                Binding {
                    target:     indicatorDrawerLoader.item
                    property:   "drawer"
                    value:      indicatorDrawer
                }
            }
        }
    }

    // We have to create the popup windows for the Analyze pages here so that the creation context is rooted
    // to mainWindow. Otherwise if they are rooted to the AnalyzeView itself they will die when the analyze viewSwitch
    // closes.

    function createrWindowedAnalyzePage(title, source) {
        var windowedPage = windowedAnalyzePage.createObject(mainWindow)
        windowedPage.title = title
        windowedPage.source = source
    }

    Component {
        id: windowedAnalyzePage

        Window {
            width:      ScreenTools.defaultFontPixelWidth  * 100
            height:     ScreenTools.defaultFontPixelHeight * 40
            visible:    true

            property alias source: loader.source

            Rectangle {
                color:          QGroundControl.globalPalette.window
                anchors.fill:   parent

                Loader {
                    id:             loader
                    anchors.fill:   parent
                    onLoaded:       item.popped = true
                }
            }

            onClosing: {
                visible = false
                source = ""
            }
        }
    }

    Connections{
         target: activationbar
         function onActivationTriggered(value){
              _utmspSendActTrigger= value
         }
    }

    UTMSPActivationStatusBar{
         id:                         activationbar
         activationStartTimestamp:   UTMSPStateStorage.startTimeStamp
         activationApproval:         UTMSPStateStorage.showActivationTab && QGroundControl.utmspManager.utmspVehicle.vehicleActivation
         flightID:                   UTMSPStateStorage.flightID
         anchors.fill:               parent
    }
}
