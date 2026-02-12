import QtQuick
<<<<<<< HEAD
=======
import QtQuick.Layouts
>>>>>>> f9dfdbd69 (commit (clean))

import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools
<<<<<<< HEAD
import QGroundControl.FlightDisplay
import QGroundControl.FlightMap

Rectangle{
    color: "#252525"
    Text {
        id: example
        text: qsTr("Drone Detail Info")
        anchors.centerIn: parent
=======
import QGroundControl.Palette

Rectangle {
    id: root
    width: 300
    height: 200
    color: qgcPal.window // QGC 기본 배경색 적용
    radius: ScreenTools.defaultFontPointSize * 0.5

    border.width: 1
    border.color: "#333"

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

   ColumnLayout {
        anchors.fill: parent
        anchors.margins: ScreenTools.defaultFontPointSize
        spacing: ScreenTools.defaultFontPointSize * 0.5

        // 2. 데이터 그리드 섹션 (Label: Value 형태)
        GridLayout {
            Layout.fillWidth: true
            columns: 4
            rowSpacing: 12
            columnSpacing: 25

            // 데이터 값 공통 스타일 (글자 크기 통일)
            component DataLabel : QGCLabel {
                Layout.fillWidth: true
                font.family: ScreenTools.fixedFontFamily
                font.pointSize: ScreenTools.defaultFontPointSize
                color: qgcPal.text
            }

            // --- 1행 ---
            QGCLabel { text: qsTr("위도:") }
            DataLabel { text: "36.261515" }

            QGCLabel { text: qsTr("경도:") }
            DataLabel { text: "123.123123" }

            // --- 2행 ---
            QGCLabel { text: qsTr("고도:") }
            DataLabel { text: "120.5 m" }

            QGCLabel { text: qsTr("속도:") }
            DataLabel { text: "0.0 m/s" }

            // --- 3행 ---
            QGCLabel { text: qsTr("방향:") }
            DataLabel { text: "362.5 deg" }

            QGCLabel { text: qsTr("배터리:") }
            DataLabel { text: "0.0 V" }

            // --- 4행 ---
            QGCLabel { text: qsTr("GPS:") }
            DataLabel { text: "3D Fixed (18)" }

            QGCLabel { text: qsTr("전체 거리:") }
            DataLabel { text: "0.0 m" }

            // --- 5행 ---
            QGCLabel { text: qsTr("비행 시간:") }
            DataLabel { text: "00:00:00" }
            
            // 5행의 빈 칸을 채워 정렬 유지
            Item { Layout.columnSpan: 2 }
        }
>>>>>>> f9dfdbd69 (commit (clean))
    }
}
