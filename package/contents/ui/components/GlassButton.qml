import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

// Minimal glass-friendly icon button, built on Kirigami.Icon so the
// recoloring works regardless of the underlying QQC2 style.
Item {
    id: root

    property string iconName: ""
    property color iconColor: "#ffffff"
    property color hoverColor: Qt.rgba(1, 1, 1, 0.10)
    property string tooltip: ""

    signal clicked()

    implicitWidth: 26
    implicitHeight: 26

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: hover.hovered ? root.hoverColor : "transparent"
    }

    Kirigami.Icon {
        anchors.centerIn: parent
        width: 15
        height: 15
        source: root.iconName
        isMask: true
        color: root.iconColor
        opacity: hover.hovered ? 1.0 : 0.65
        Behavior on opacity {
            NumberAnimation { duration: 120 }
        }
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        onTapped: root.clicked()
    }

    QQC2.ToolTip.visible: hover.hovered && root.tooltip.length > 0
    QQC2.ToolTip.text: root.tooltip
    QQC2.ToolTip.delay: 400
}
