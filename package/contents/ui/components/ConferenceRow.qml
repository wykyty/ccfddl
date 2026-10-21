import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import "../Countdown.js" as CD

// Compact row for the other tracked conferences.
Item {
    id: root

    // NOTE: no `required` here — Qt 6 auto-populates required delegate
    // properties from model roles, which breaks when the model is a plain
    // array. Plain properties with defaults keep the delegate context intact.
    property var palette: null
    property var entry: null
    property double now: 0

    signal activated()

    implicitHeight: 46

    readonly property var parts: CD.durationParts(root.entry && root.entry.event ? root.entry.event.epoch - root.now : 0)
    readonly property bool urgent: root.entry && root.entry.upcoming && root.entry.event
                                   && (root.entry.event.epoch - root.now) <= 7 * 86400000
    readonly property color urgencyColor: root.palette.effectiveLight ? "#C93400" : "#FF9F0A"
    readonly property string rankText: {
        if (!root.entry || !root.entry.rank) {
            return "";
        }
        var bits = [];
        if (root.entry.rank.ccf) {
            bits.push("CCF " + root.entry.rank.ccf);
        }
        if (root.entry.rank.core) {
            bits.push("CORE " + root.entry.rank.core);
        }
        return bits.join(" / ");
    }

    readonly property string countdownText: {
        if (!root.entry || !root.entry.event) {
            return "—";
        }
        if (!root.entry.upcoming) {
            return "已截止";
        }
        if (root.parts.days > 0) {
            return root.parts.days + "天";
        }
        return CD.pad2(root.parts.hours) + ":" + CD.pad2(root.parts.minutes);
    }

    readonly property string subText: {
        if (!root.entry || !root.entry.event) {
            return "暂无截止日期";
        }
        var bits = [];
        if (root.rankText !== "") {
            bits.push(root.rankText);
        }
        bits.push(CD.typeLabel(root.entry.event.type));
        bits.push(Qt.formatDateTime(new Date(root.entry.event.epoch), "MM-dd HH:mm"));
        return bits.join(" · ");
    }

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: hover.hovered ? Qt.rgba(root.palette.cardBackground.r,
                                       root.palette.cardBackground.g,
                                       root.palette.cardBackground.b,
                                       root.palette.cardHoverOpacity) : "transparent"
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        onTapped: root.activated()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 8

        Rectangle {
            implicitWidth: 6
            implicitHeight: 6
            radius: 3
            color: {
                if (!root.entry || !root.entry.upcoming) {
                    return root.palette.labelTertiary;
                }
                return root.urgent ? root.urgencyColor : root.palette.accent;
            }
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                QQC2.Label {
                    text: root.entry ? root.entry.title : ""
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: root.palette.foreground
                    elide: Text.ElideRight
                }
                QQC2.Label {
                    text: root.entry ? String(root.entry.year) : ""
                    font.pixelSize: 9
                    color: root.palette.labelTertiary
                    Layout.alignment: Qt.AlignBaseline
                }
                Item {
                    Layout.fillWidth: true
                }
            }

            QQC2.Label {
                Layout.fillWidth: true
                text: root.subText
                font.pixelSize: 9
                color: root.palette.labelTertiary
                elide: Text.ElideRight
            }
        }

        ColumnLayout {
            spacing: 1

            QQC2.Label {
                Layout.alignment: Qt.AlignRight
                text: root.countdownText
                font.pixelSize: 15
                font.weight: Font.DemiBold
                font.features: { "tnum": 1 }
                color: root.entry && root.entry.upcoming
                       ? (root.urgent ? root.urgencyColor : root.palette.foreground)
                       : root.palette.labelTertiary
            }

            QQC2.Label {
                Layout.alignment: Qt.AlignRight
                visible: root.entry && root.entry.event && root.entry.upcoming
                text: CD.pad2(root.parts.hours) + ":" + CD.pad2(root.parts.minutes) + ":" + CD.pad2(root.parts.seconds)
                font.pixelSize: 9
                font.features: { "tnum": 1 }
                color: root.palette.labelTertiary
            }
        }
    }
}
