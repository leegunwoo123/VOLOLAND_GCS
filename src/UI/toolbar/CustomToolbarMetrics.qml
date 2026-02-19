pragma Singleton
import QtQuick

/// CustomToolbar / CustomPlanViewToolBar 공통: 아이콘·버튼 크기, 간격, 마진 등 한곳에서 관리
QtObject {
    id: root

    // 툴바 레이아웃
    readonly property real horizontalMargin: 10
    readonly property real spacing: 10
    readonly property real windowControlButtonsSpacing: 5

    // 좌측 메인 버튼(로고/툴 선택)
    readonly property real toolButtonSize: 48

    // 서버 연결 상태 아이콘 (Fly/Plan 툴바 동일 크기)
    readonly property real serverConnectionIconSize: 24

    // 윈도우 제어 버튼 (최소화/최대화/닫기)
    readonly property real windowControlButtonSize: 32
    readonly property real windowControlButtonRadius: 3
    readonly property real windowControlMinimizeFontSize: 20
    readonly property real windowControlIconFontSize: 16
}
