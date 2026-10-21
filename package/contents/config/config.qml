import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: "会议"
        icon: "view-calendar"
        source: "config/ConfigGeneral.qml"
    }
    ConfigCategory {
        name: "外观"
        icon: "preferences-desktop-theme"
        source: "config/ConfigAppearance.qml"
    }
}
