import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCMUtils

KCMUtils.SimpleKCM {
    id: page

    property alias cfg_styleMode: styleCombo.currentIndex
    property alias cfg_appearance: appearanceCombo.currentIndex
    property alias cfg_cornerRadius: radiusField.value
    property alias cfg_roundnessX10: roundnessField.value
    property alias cfg_tintAlphaPct: tintField.value
    property alias cfg_refractThickness: thicknessField.value
    property alias cfg_refractIORx100: iorField.value
    property alias cfg_refractScale: scaleField.value
    property alias cfg_chromaStrengthPct: chromaField.value
    property alias cfg_specStrengthPct: specField.value
    property alias cfg_blurRadiusPx: blurRadiusField.value
    property alias cfg_blurAlgorithm: blurAlgorithmCombo.currentIndex
    property alias cfg_realtimeRefraction: realtimeCheck.checked

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.largeSpacing

        Kirigami.FormLayout {
            Layout.fillWidth: true

            Kirigami.Separator {
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: "样式"
            }

            QQC2.ComboBox {
                id: styleCombo
                Kirigami.FormData.label: "背景样式："
                model: ["液态玻璃", "纯色"]
                currentIndex: 0
            }

            QQC2.ComboBox {
                id: appearanceCombo
                Kirigami.FormData.label: "明暗外观："
                model: ["深色", "浅色", "跟随系统"]
                currentIndex: 0
            }

            SliderField {
                id: radiusField
                Kirigami.FormData.label: "圆角半径："
                from: 0
                to: 100
                value: 36
                format: (v) => v + " px"
            }

            SliderField {
                id: roundnessField
                Kirigami.FormData.label: "圆角平滑度："
                from: 20
                to: 100
                value: 80
                format: (v) => (v / 10).toFixed(1)
            }

            SliderField {
                id: tintField
                Kirigami.FormData.label: "玻璃着色："
                from: 0
                to: 50
                value: 12
                format: (v) => v + "%"
            }

            Kirigami.Separator {
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: "折射与高光"
            }

            SliderField {
                id: thicknessField
                Kirigami.FormData.label: "边缘折射宽度："
                from: 0
                to: 80
                value: 35
                format: (v) => v + " px"
            }

            SliderField {
                id: iorField
                Kirigami.FormData.label: "折射率 (IOR)："
                from: 100
                to: 250
                value: 170
                format: (v) => (v / 100).toFixed(2)
            }

            SliderField {
                id: scaleField
                Kirigami.FormData.label: "折射强度："
                from: 0
                to: 120
                value: 65
                format: (v) => String(v)
            }

            SliderField {
                id: chromaField
                Kirigami.FormData.label: "色散强度："
                from: 0
                to: 100
                value: 30
                format: (v) => v + "%"
            }

            SliderField {
                id: specField
                Kirigami.FormData.label: "高光强度："
                from: 0
                to: 100
                value: 70
                format: (v) => v + "%"
            }

            Kirigami.Separator {
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: "模糊与性能"
            }

            SliderField {
                id: blurRadiusField
                Kirigami.FormData.label: "背景模糊半径："
                from: 0
                to: 32
                value: 6
                format: (v) => v === 0 ? "关闭" : (v + " px")
            }

            QQC2.ComboBox {
                id: blurAlgorithmCombo
                Kirigami.FormData.label: "模糊算法："
                model: ["Dual Kawase（快）", "Gaussian（更平滑）"]
                currentIndex: 0
            }

            QQC2.CheckBox {
                id: realtimeCheck
                text: "实时采样桌面背景（视频壁纸需要，耗电更高）"
                checked: false
            }

            QQC2.Label {
                text: "液态玻璃会采样小部件背后的桌面壁纸并做折射。静态壁纸不需要实时采样。"
                font.pixelSize: 10
                opacity: 0.55
                wrapMode: Text.WordWrap
                Layout.preferredWidth: Kirigami.Units.gridUnit * 24
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.Button {
                text: "恢复默认外观"
                onClicked: {
                    styleCombo.currentIndex = 0;
                    appearanceCombo.currentIndex = 0;
                    radiusField.value = 36;
                    roundnessField.value = 80;
                    tintField.value = 12;
                    thicknessField.value = 35;
                    iorField.value = 170;
                    scaleField.value = 65;
                    chromaField.value = 30;
                    specField.value = 70;
                    blurRadiusField.value = 6;
                    blurAlgorithmCombo.currentIndex = 0;
                    realtimeCheck.checked = false;
                }
            }

            Item {
                Layout.fillWidth: true
            }
        }
    }
}
