import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools
import QGroundControl.FlightDisplay
import QGroundControl.FlightMap
Column{

    id: root
    spacing: 2
    width: parent.width

    IntegratedCompassAttitude {
        id: compass
        clip: true
        // 70x70 안에 들어오면서도 최대한 크게 보이도록 튜닝
        attitudeSize: 25
        attitudeSpacing: 13
        compassRadius: 55
        compassBorder: 13
        Layout.preferredWidth: 150
        Layout.preferredHeight: 150
        anchors.horizontalCenter: parent.horizontalCenter
    }

    CustomDroneMetrics {
        id: metrics
        clip: true

        // 중요: 가로를 꽉 채우고 높이를 명시적으로 부여
        width: parent.width
        height: 200
    }
}

// RowLayout{

//     id: root
//     Layout.fillWidth: true
//     // 높이는 상위 레이아웃(예: CustomFlyView.qml)에서 결정
//     // 여기서는 기본값만 제공
//     Layout.preferredHeight: 200
//     Layout.minimumHeight: 200
//     Layout.maximumHeight: 200

//     spacing: 2
    
//     // 왼쪽: IntegratedCompassAttitude (세로 중앙 정렬)
//     IntegratedCompassAttitude {
//         id: compass
//         clip: true
//         // 70x70 안에 들어오면서도 최대한 크게 보이도록 튜닝
//         attitudeSize: 25
//         attitudeSpacing: 13
//         compassRadius: 55
//         compassBorder: 13
//         Layout.preferredWidth: 200
//         Layout.preferredHeight: 200
//         Layout.alignment: Qt.AlignVCenter
//         // 세로 방향 중앙 정렬
//     }
    
//     // 오른쪽: CustomDroneMetrics
//     /*CustomDroneMetrics {
//         clip: true
//         Layout.fillWidth: true
//         Layout.fillHeight: true
//         Layout.alignment: Qt.AlignVCenter
//     }*/
//     /*TelemetryValuesBar{
//         clip: true
//         Layout.fillWidth: true
//         Layout.fillHeight: true
//         Layout.alignment: Qt.AlignVCenter
//     }*/
// }
