import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

// Small CCF / CORE ranking pill, e.g. "CCF A · CORE A*".
Item {
    id: root

    required property var palette
    property string ccf: ""
    property string core: ""

    visible: ccf !== "" || core !== ""
    implicitWidth: row.implicitWidth + 14
    implicitHeight: 20

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: Qt.rgba(root.palette.cardBackground.r,
                       root.palette.cardBackground.g,
                       root.palette.cardBackground.b,
                       root.palette.cardBackgroundOpacity)
        border.width: 1
        border.color: Qt.rgba(root.palette.foreground.r,
                              root.palette.foreground.g,
                              root.palette.foreground.b, 0.08)
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 4

        QQC2.Label {
            visible: root.ccf !== ""
            text: "CCF"
            font.pixelSize: 8
            font.letterSpacing: 0.4
            color: root.palette.labelTertiary
        }
        QQC2.Label {
            visible: root.ccf !== ""
            text: root.ccf
            font.pixelSize: 10
            font.weight: Font.DemiBold
            color: root.palette.foreground
        }
        QQC2.Label {
            visible: root.ccf !== "" && root.core !== ""
            text: "·"
            font.pixelSize: 8
            color: root.palette.labelTertiary
        }
        QQC2.Label {
            visible: root.core !== ""
            text: "CORE"
            font.pixelSize: 8
            font.letterSpacing: 0.3
            color: root.palette.labelTertiary
        }
        QQC2.Label {
            visible: root.core !== ""
            text: root.core
            font.pixelSize: 10
            font.weight: Font.DemiBold
            color: root.palette.foreground
        }
    }
}
