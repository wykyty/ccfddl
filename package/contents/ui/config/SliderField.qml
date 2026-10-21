import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Slider + live value label, adapted from liquidglass-kde-widgets (GPL-3.0).
RowLayout {
    id: field

    property int value: 0
    property int from: 0
    property int to: 100
    property int stepSize: 1
    property var format: (v) => String(v)

    spacing: Kirigami.Units.largeSpacing
    Layout.fillWidth: true

    QQC2.Slider {
        id: slider
        Layout.fillWidth: true
        Layout.minimumWidth: Kirigami.Units.gridUnit * 6
        Layout.preferredWidth: Kirigami.Units.gridUnit * 10
        from: field.from
        to: field.to
        stepSize: field.stepSize
        snapMode: QQC2.Slider.SnapAlways
        value: field.value
        onMoved: field.value = Math.round(value)
    }

    QQC2.Label {
        id: valueLabel
        text: field.format(field.value)
        horizontalAlignment: Text.AlignRight
        font.features: { "tnum": 1 }
        Layout.minimumWidth: Math.max(Kirigami.Units.gridUnit * 3.5,
                                      widest.advanceWidth, widestFrom.advanceWidth)

        TextMetrics {
            id: widest
            font: valueLabel.font
            text: field.format(field.to)
        }
        TextMetrics {
            id: widestFrom
            font: valueLabel.font
            text: field.format(field.from)
        }
    }
}
