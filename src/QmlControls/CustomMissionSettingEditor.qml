import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Controls
<<<<<<< HEAD
=======
import QGroundControl.FactControls
>>>>>>> f9dfdbd69 (commit (clean))
import QGroundControl.Palette

Rectangle {
    id:          valuesRect
<<<<<<< HEAD
    width:       availableWidth
    height:      valuesColumn.height + (_margin * 2)
    color:       qgcPal.windowShadeDark
    visible:     missionItem.isCurrentItem
    radius:      _radius

    // 필수 QGC 프로퍼티 및 팔레트
    property real _margin:      ScreenTools.defaultFontPixelWidth / 2
    property real _fieldWidth:  ScreenTools.defaultFontPixelWidth * 16
=======
    width:       Math.max(availableWidth, _minContentWidth)
    height:      Math.max(valuesColumn.height + (_margin * 2), _minContentHeight)
    color:       qgcPal.windowShadeDark
    // visible:     missionItem.isCurrentItem
    radius:      _radius

    property real _margin:           ScreenTools.defaultFontPixelWidth / 2
    property real _fieldWidth:       ScreenTools.defaultFontPixelWidth * 16
    property real _radius:           ScreenTools.defaultFontPixelWidth / 2

    readonly property real _minContentHeight: ScreenTools.defaultFontPixelHeight * 10
    readonly property real _minContentWidth:  ScreenTools.defaultFontPixelWidth * 20
>>>>>>> f9dfdbd69 (commit (clean))
    QGCPalette { id: qgcPal }

    ColumnLayout {
        id:                 valuesColumn
        anchors.margins:    _margin
        anchors.left:       parent.left
        anchors.right:      parent.right
        anchors.top:        parent.top
        spacing:            _margin

<<<<<<< HEAD
        // --- 섹션 1: 제목 및 기본 설정 ---
        QGCLabel {
            text:           qsTr("Mission Start") // 원하는 제목으로 수정
            font.pointSize: ScreenTools.smallFontPointSize
            font.bold:      true
        }

        // --- 섹션 2: 입력 필드 (예시) ---
        GridLayout {
            Layout.fillWidth:   true
            columns:            2
            columnSpacing:      _margin

            QGCLabel { text: qsTr("설정 항목 1") }
            FactTextField {
                Layout.fillWidth: true
                // fact: missionItem.someProperty (실제 데이터 바인딩)
            }

            QGCLabel { text: qsTr("설정 항목 2") }
            FactTextField {
                Layout.fillWidth: true
            }
        }

        // --- 섹션 3: 구분선 또는 헤더 ---
        SectionHeader {
            id:             customSectionHeader
            Layout.fillWidth: true
            text:           qsTr("Advanced Options")
            checked:        false // 기본으로 접어두기
        }

        // --- 섹션 4: 확장 영역 (SectionHeader가 체크되었을 때만 표시) ---
        ColumnLayout {
            Layout.fillWidth: true
            visible:          customSectionHeader.checked
            spacing:          _margin

            QGCCheckBox {
                text: qsTr("옵션 활성화")
            }

            // 추가적인 커스텀 컨트롤들 배치
        }

        // 하단 여백 확보를 위한 공간
=======
        QGCLabel {
            text:           "미션 시작"
            font.pointSize:  ScreenTools.smallFontPointSize
            font.bold:       true
        }

        RowLayout {
            Layout.fillWidth:   true
            spacing:            _margin

            QGCLabel {
                text:                   "초기 고도"
                font.pointSize:         ScreenTools.smallFontPointSize
                Layout.preferredWidth: _fieldWidth * 0.6
                Layout.minimumWidth:   ScreenTools.defaultFontPixelWidth * 6
            }

            FactTextField {
                fact:                   QGroundControl.settingsManager.appSettings.defaultMissionItemAltitude
                Layout.fillWidth:       true
                Layout.minimumWidth:    ScreenTools.defaultFontPixelWidth * 8
                Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 2
            }
        }
        RowLayout{

            Layout.fillWidth:   true
            spacing:            _margin

            QGCCheckBox{
                id: flightSpeedCheckBox
                text: qsTr("비행 속도")
                visible: true
                checked:    missionItem.speedSection.specifyFlightSpeed
                onClicked:   missionItem.speedSection.specifyFlightSpeed = checked
            }

            FactTextField {
                Layout.fillWidth:   true
                fact:               missionItem.speedSection.flightSpeed
                visible:            true
                enabled:            flightSpeedCheckBox.checked
            }

        }

>>>>>>> f9dfdbd69 (commit (clean))
        Item { Layout.preferredHeight: _margin }
    }
}
