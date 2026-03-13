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
    flags:          Qt.Window | Qt.FramelessWindowHint

    minimumHeight: customFlyView.implicitHeight + customtoolBar.height + 40

    property bool   _utmspSendActTrigger
    property bool   _utmspStartTelemetry
    /// Plan 뷰 / Custom Plan 뷰 진입 여부 (툴바 숨김·컨텐츠 상단 정렬용)
    property bool   _planViewShown: false
    /// true = Custom Plan View(드론상태+CustomPlanView), false = Plan Flight(PlanView)
    property bool   _customPlanViewShown: false
    /// PlanView의 planMasterController(0번 mission start 포함). FlyViewMap/CustomPlanView에서 공유
    readonly property var _planController: typeof planViewArea !== "undefined" ? planViewArea._planController : null
    
    /// 최소화 전 윈도우 상태 저장 (최대화 상태 복원용)
    property int _savedVisibilityBeforeMinimize: Window.Windowed
    /// 사용자가 의도적으로 상태를 변경했는지 여부 (최대화/복원 버튼 클릭 시 true)
    property bool _userInitiatedStateChange: false
    /// 서버 연결 상태 (0: 연결됨, 1: 연결중, 그 외: 연결끊김). DroneList backend와 동기화, 상단바 아이콘 표시용
    property int serverConnectionStatus: 2
    /// 서버 설정 팝업용 목록 (config 로드/저장). 각 요소: { serverName, ipAddress, port, isSelected }
    property var serverListData: []

    Component.onCompleted: {
        var raw = QGroundControl.loadGlobalSetting("ServerSettings/List", "[]")
        try {
            var arr = JSON.parse(raw)
            if (Array.isArray(arr))
                mainWindow.serverListData = arr
        } catch (_) { }
        firstRunPromptManager.nextPrompt()
    }

    // 최소화에서 복원 시 저장된 상태로 복원 (사용자가 의도적으로 변경한 경우 제외)
    onVisibilityChanged: (newVisibility) => {
        if (!_userInitiatedStateChange && newVisibility === Window.Windowed && _savedVisibilityBeforeMinimize === Window.Maximized) {
            // 최소화에서 복원 시 저장된 상태가 최대화였으면 다시 최대화
            Qt.callLater(function() {
                if (mainWindow.visibility === Window.Windowed && !_userInitiatedStateChange) {
                    mainWindow.showMaximized()
                }
            })
        }
        
        
        // 상태 변경 완료 후 플래그 리셋
        if (_userInitiatedStateChange) {
            _userInitiatedStateChange = false
        }
    }
    
    // 최소화 전 상태를 저장하는 함수
    function saveVisibilityBeforeMinimize() {
        _savedVisibilityBeforeMinimize = mainWindow.visibility === Window.Maximized ? Window.Maximized : Window.Windowed
    }
    
    // 사용자가 의도적으로 상태를 변경할 때 호출하는 함수
    function setUserInitiatedStateChange() {
        _userInitiatedStateChange = true
        // 현재 상태를 저장된 상태로 업데이트
        _savedVisibilityBeforeMinimize = mainWindow.visibility === Window.Maximized ? Window.Maximized : Window.Windowed
    }
    
    // Keys는 Item에만 부착 가능. ApplicationWindow 대신 내부 Item에서 키 처리
    Item {
        id: mainWindowKeyHandler
        anchors.fill: parent
        focus: true

        Keys.onPressed: (event) => {
            // Aero Snap 단축키 처리 (Windows 키 + 방향키)
            var isWindowsKey = (event.modifiers & Qt.MetaModifier) || (event.modifiers & Qt.AltModifier)
            
            if (isWindowsKey && !ScreenTools.isMobile && mainWindow.visibility !== Window.FullScreen) {
                if (event.key === Qt.Key_Up) {
                    mainWindow.setUserInitiatedStateChange()
                    WindowHelper.handleAeroSnapShortcut(mainWindow, "up")
                    event.accepted = true
                    return
                } else if (event.key === Qt.Key_Down) {
                    mainWindow.setUserInitiatedStateChange()
                    WindowHelper.handleAeroSnapShortcut(mainWindow, "down")
                    event.accepted = true
                    return
                } else if (event.key === Qt.Key_Left) {
                    mainWindow.setUserInitiatedStateChange()
                    WindowHelper.handleAeroSnapShortcut(mainWindow, "left")
                    event.accepted = true
                    return
                } else if (event.key === Qt.Key_Right) {
                    mainWindow.setUserInitiatedStateChange()
                    WindowHelper.handleAeroSnapShortcut(mainWindow, "right")
                    event.accepted = true
                    return
                }
            }
            
            // 키보드 이동 모드 처리
            if (mainWindow._keyboardMoveMode) {
                var moveStep = 10
                var deltaX = 0
                var deltaY = 0
                
                if (event.key === Qt.Key_Left) {
                    deltaX = -moveStep
                } else if (event.key === Qt.Key_Right) {
                    deltaX = moveStep
                } else if (event.key === Qt.Key_Up) {
                    deltaY = -moveStep
                } else if (event.key === Qt.Key_Down) {
                    deltaY = moveStep
                } else if (event.key === Qt.Key_Escape || event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                    mainWindow._keyboardMoveMode = false
                    event.accepted = true
                    return
                }
                
                if (deltaX !== 0 || deltaY !== 0) {
                    WindowHelper.moveWindowByKeys(mainWindow, deltaX, deltaY)
                    event.accepted = true
                }
            }
        }
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

        // FlyViewMap 등 mapToItem(globals.parent, ...)용 (QGC와 동일)
        property var                parent:                         mainWindow

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
    }

    /// Custom Plan 뷰에서 droneStatus(좌측 패널) 접었을 때 다시 펼치기용
    function expandFlyViewLeftPanel() {
        if (customFlyView)
            customFlyView.leftPanelVisible = true
    }

    /// Custom Plan 뷰: 좌측 droneStatus + CustomPlanView (독립 화면)
    function showCustomPlanView() {
        if (allowViewSwitch()) {
            _planViewShown = true
            _customPlanViewShown = true
        }
    }

    /// Plan Flight: PlanView만 표시 (독립 화면)
    function showPlanView() {
        _planViewShown = true
        _customPlanViewShown = false
    }

    function showFlyView() {
        _planViewShown = false
        _customPlanViewShown = false
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
        QGroundControl.saveGlobalSetting("ServerSettings/List", JSON.stringify(mainWindow.serverListData))
        if (!_forceClose) {
            _closeChecksToSkip = 0
            close.accepted = performCloseChecks()
        }
    }

    background: Rectangle {
        anchors.fill:   parent
        color:          QGroundControl.globalPalette.window
    }

    // 툴바 하나로 통일 (Fly / Custom Plan 동일)
    Item {
        id: toolbarContainer
        anchors.top: parent.top
        width: parent.width
        height: (visible ? ScreenTools.toolbarHeight : 0)
        visible: !mainWindow._planViewShown || mainWindow._customPlanViewShown

        CustomToolbar {
            id: customtoolBar
            anchors.fill: parent
            visible: true
            showPlanReturnButton: mainWindow._customPlanViewShown
        }
    }

    // Fly/Plan 뷰 컨테이너
    Item {
        id: flyPlanContainer
        anchors.top: (mainWindow._customPlanViewShown || !mainWindow._planViewShown) ? toolbarContainer.bottom : parent.top
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
                    Layout.preferredWidth: mainWindow._planViewShown
                                        ? (mainWindow._customPlanViewShown && customFlyView.leftPanelVisible ? customFlyView.leftPanelWidth : 0)
                                        : 0
                    planViewActive: mainWindow._customPlanViewShown
                    planMasterController: mainWindow._planController
                }
                Item {
                    id: planViewArea
                    Layout.fillWidth: mainWindow._planViewShown
                    Layout.fillHeight: mainWindow._planViewShown
                    Layout.minimumWidth: 0
                    Layout.preferredWidth: 0
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
                        droneStatusWidth: mainWindow._customPlanViewShown ? customFlyView.leftPanelWidth : 0
                        leftPanelCollapsed: mainWindow._customPlanViewShown && !customFlyView.leftPanelVisible
                    }
                }
            }
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

    // 프레임리스 윈도우 드래그 및 우클릭 메뉴 처리
    MouseArea {
        id: windowDragArea
        anchors.top: parent.top
        height: customtoolBar.visible ? customtoolBar.height : 0
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.ArrowCursor
        z: -100
        enabled: true
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: customtoolBar.visible ? customtoolBar.dragAreaLeft : 0
        anchors.rightMargin: customtoolBar.visible ? customtoolBar.dragAreaRight : 0

        property point _pressPos: Qt.point(0, 0)
        property bool _dragStarted: false
        
        onPressed: (mouse) => {
            if (customtoolBar.visible) {
                var toolbarPos = mapToItem(customtoolBar, mouse.x, mouse.y)
                var leftButtonArea = toolbarPos.x < customtoolBar.dragAreaLeft
                var rightButtonArea = toolbarPos.x > (customtoolBar.width - customtoolBar.dragAreaRight)
                if (leftButtonArea || rightButtonArea) {
                    mouse.accepted = false
                    return
                }
            }
            if (mouse.button === Qt.LeftButton) {
                // 클릭 위치 저장
                _pressPos = Qt.point(mouse.x, mouse.y)
                _dragStarted = false
            } else if (mouse.button === Qt.RightButton) {
                // 우클릭: Windows 시스템 메뉴 표시
                if (!ScreenTools.isMobile && mainWindow.visibility !== Window.FullScreen) {
                    var rootPos = mapToItem(mainWindow.contentItem, mouse.x, mouse.y)
                    var globalX = mainWindow.x + rootPos.x
                    var globalY = mainWindow.y + rootPos.y
                    
                    WindowHelper.showSystemMenu(mainWindow, globalX, globalY)
                    mouse.accepted = true
                }
            }
        }
        
        // 타이틀바 더블클릭: Windows 기본 동작 (최대화/복원 토글)
        // 단일 클릭은 툴바·버튼으로 전달되므로 onDoubleClicked만 처리
        onDoubleClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton && !ScreenTools.isMobile && mainWindow.visibility !== Window.FullScreen) {
                mainWindow.setUserInitiatedStateChange()
                WindowHelper.toggleMaximizeRestore(mainWindow)
            }
        }
        
        onPositionChanged: (mouse) => {
            if (mouse.buttons & Qt.LeftButton && !_dragStarted) {
                // 마우스가 움직였으면 드래그 시작으로 간주
                var deltaX = Math.abs(mouse.x - _pressPos.x)
                var deltaY = Math.abs(mouse.y - _pressPos.y)
                
                // 최소 이동 거리 체크 (드래그 시작으로 간주) - 5픽셀 이상
                if (deltaX > 5 || deltaY > 5) {
                    _dragStarted = true
                    
                    if (mainWindow.visibility === Window.Windowed) {
                        // 일반 상태에서는 바로 드래그 시작
                        var rootPos = mapToItem(mainWindow.contentItem, _pressPos.x, _pressPos.y)
                        WindowHelper.startSystemMove(mainWindow, rootPos.x, rootPos.y)
                    }
                    // 최대화 상태에서는 드래그하지 않음 (복원 로직 제거)
                }
            }
        }
        
        onReleased: (mouse) => {
            // 드래그가 실제로 시작되었을 때만 Aero Snap 처리
            if (_dragStarted && mouse.button === Qt.LeftButton) {
                // 마우스의 글로벌 화면 좌표 가져오기
                var rootPos = mapToItem(mainWindow.contentItem, mouse.x, mouse.y)
                var globalX = mainWindow.x + rootPos.x
                var globalY = mainWindow.y + rootPos.y
                
                // Aero Snap 처리 (상단/좌/우 가장자리 감지)
                if (!ScreenTools.isMobile && mainWindow.visibility !== Window.FullScreen) {
                    WindowHelper.handleAeroSnap(mainWindow, globalX, globalY)
                }
            }
            _dragStarted = false
        }
    }

    // 창 테두리 드래그 리사이즈 (상·하·좌·우)
    Item {
        id: windowEdgeResizeLayer
        anchors.fill: parent
        z: 50
        visible: !ScreenTools.isMobile && mainWindow.visibility !== Window.FullScreen && mainWindow.visibility !== Window.Maximized

        property int _edgeSize: 5
        property int _cornerSize: 10

        // 좌상·우상·좌하·우하 모서리 드래그 리사이즈
        MouseArea {
            anchors.left: parent.left
            anchors.top: parent.top
            width: windowEdgeResizeLayer._cornerSize
            height: windowEdgeResizeLayer._cornerSize
            cursorShape: Qt.SizeFDiagCursor
            acceptedButtons: Qt.LeftButton
            onPressed: (mouse) => {
                if (mouse.button === Qt.LeftButton) {
                    WindowHelper.startSystemResize(mainWindow, Qt.TopEdge | Qt.LeftEdge)
                }
            }
        }
        MouseArea {
            anchors.right: parent.right
            anchors.top: parent.top
            width: windowEdgeResizeLayer._cornerSize
            height: windowEdgeResizeLayer._cornerSize
            cursorShape: Qt.SizeBDiagCursor
            acceptedButtons: Qt.LeftButton
            onPressed: (mouse) => {
                if (mouse.button === Qt.LeftButton) {
                    WindowHelper.startSystemResize(mainWindow, Qt.TopEdge | Qt.RightEdge)
                }
            }
        }
        MouseArea {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: windowEdgeResizeLayer._cornerSize
            height: windowEdgeResizeLayer._cornerSize
            cursorShape: Qt.SizeBDiagCursor
            acceptedButtons: Qt.LeftButton
            onPressed: (mouse) => {
                if (mouse.button === Qt.LeftButton) {
                    WindowHelper.startSystemResize(mainWindow, Qt.BottomEdge | Qt.LeftEdge)
                }
            }
        }
        MouseArea {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: windowEdgeResizeLayer._cornerSize
            height: windowEdgeResizeLayer._cornerSize
            cursorShape: Qt.SizeFDiagCursor
            acceptedButtons: Qt.LeftButton
            onPressed: (mouse) => {
                if (mouse.button === Qt.LeftButton) {
                    WindowHelper.startSystemResize(mainWindow, Qt.BottomEdge | Qt.RightEdge)
                }
            }
        }

        MouseArea {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: windowEdgeResizeLayer._edgeSize
            cursorShape: Qt.SizeHorCursor
            acceptedButtons: Qt.LeftButton
            onPressed: (mouse) => {
                if (mouse.button === Qt.LeftButton) {
                    WindowHelper.startSystemResize(mainWindow, Qt.LeftEdge)
                }
            }
        }
        MouseArea {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: windowEdgeResizeLayer._edgeSize
            cursorShape: Qt.SizeHorCursor
            acceptedButtons: Qt.LeftButton
            onPressed: (mouse) => {
                if (mouse.button === Qt.LeftButton) {
                    WindowHelper.startSystemResize(mainWindow, Qt.RightEdge)
                }
            }
        }
        MouseArea {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: windowEdgeResizeLayer._edgeSize
            cursorShape: Qt.SizeVerCursor
            acceptedButtons: Qt.LeftButton
            onPressed: (mouse) => {
                if (mouse.button === Qt.LeftButton) {
                    WindowHelper.startSystemResize(mainWindow, Qt.TopEdge)
                }
            }
        }
        MouseArea {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: windowEdgeResizeLayer._edgeSize
            cursorShape: Qt.SizeVerCursor
            acceptedButtons: Qt.LeftButton
            onPressed: (mouse) => {
                if (mouse.button === Qt.LeftButton) {
                    WindowHelper.startSystemResize(mainWindow, Qt.BottomEdge)
                }
            }
        }
    }

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
