import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import "../Countdown.js" as CD

// One small rounded time box (hours / minutes / seconds).
ColumnLayout {
    id: root

    required property var palette
    property int value: 0
    property string label: ""

    spacing: 3

    Rectangle {
        implicitWidth: 42
        implicitHeight: 30
        radius: 8
        color: Qt.rgba(root.palette.cardBackground.r,
                       root.palette.cardBackground.g,
                       root.palette.cardBackground.b,
                       root.palette.cardBackgroundOpacity)
        border.width: 1
        border.color: Qt.rgba(root.palette.foreground.r,
                              root.palette.foreground.g,
                              root.palette.foreground.b, 0.07)

        QQC2.Label {
            anchors.centerIn: parent
            text: CD.pad2(root.value)
            font.pixelSize: 18
            font.weight: Font.Medium
            font.features: { "tnum": 1 }
            color: root.palette.foreground
        }
    }

    QQC2.Label {
        Layout.alignment: Qt.AlignHCenter
        text: root.label
        font.pixelSize: 8
        color: root.palette.labelTertiary
    }
}
