import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import "../Countdown.js" as CD

// The hero countdown: huge day count + HH:MM:SS cells.
ColumnLayout {
    id: root

    required property var palette
    property double targetEpoch: 0
    property double now: 0
    property bool upcoming: true
    property bool hasEvent: true
    property bool showSeconds: true
    property bool urgencyColor: true
    property string caption: ""

    readonly property var parts: CD.durationParts(root.hasEvent ? root.targetEpoch - root.now : 0)
    readonly property int bigSize: Math.max(52, Math.min(96, root.width * 0.235))

    readonly property color stateColor: {
        if (!root.hasEvent || !root.upcoming) {
            return root.palette.labelTertiary;
        }
        if (!root.urgencyColor) {
            return root.palette.foreground;
        }
        if (root.parts.days <= 2) {
            return root.palette.effectiveLight ? "#D70015" : "#FF453A";
        }
        if (root.parts.days <= 7) {
            return root.palette.effectiveLight ? "#C93400" : "#FF9F0A";
        }
        return root.palette.foreground;
    }

    spacing: 2

    QQC2.Label {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter
        horizontalAlignment: Text.AlignHCenter
        text: root.caption
        font.pixelSize: 12
        font.weight: Font.Medium
        color: root.palette.labelSecondary
        elide: Text.ElideRight
    }

    // Upcoming: the big day number.
    RowLayout {
        visible: root.hasEvent && root.upcoming
        Layout.alignment: Qt.AlignHCenter
        spacing: 7

        QQC2.Label {
            text: root.parts.days
            font.pixelSize: root.bigSize
            font.weight: Font.Light
            font.letterSpacing: -2
            font.features: { "tnum": 1 }
            color: root.stateColor
        }
        QQC2.Label {
            text: "天"
            font.pixelSize: 20
            font.weight: Font.Medium
            color: root.palette.labelSecondary
            Layout.alignment: Qt.AlignBottom
            Layout.bottomMargin: root.bigSize * 0.22
        }
    }

    // The compact HH : MM : SS row.
    RowLayout {
        visible: root.hasEvent && root.upcoming
        Layout.alignment: Qt.AlignHCenter
        spacing: 7

        TimeCell {
            palette: root.palette
            value: root.parts.hours
            label: "时"
        }
        QQC2.Label {
            text: ":"
            font.pixelSize: 17
            color: root.palette.labelTertiary
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: 4
        }
        TimeCell {
            palette: root.palette
            value: root.parts.minutes
            label: "分"
        }
        QQC2.Label {
            visible: root.showSeconds
            text: ":"
            font.pixelSize: 17
            color: root.palette.labelTertiary
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: 4
        }
        TimeCell {
            visible: root.showSeconds
            palette: root.palette
            value: root.parts.seconds
            label: "秒"
        }
    }

    // No deadline (or all deadlines already passed).
    QQC2.Label {
        visible: !root.hasEvent || !root.upcoming
        Layout.alignment: Qt.AlignHCenter
        text: root.hasEvent ? "已截止" : "暂无截止"
        font.pixelSize: 34
        font.weight: Font.Light
        color: root.palette.labelTertiary
    }
}
