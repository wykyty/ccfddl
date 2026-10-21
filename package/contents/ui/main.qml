import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import "../data/snapshot.js" as Snapshot
import "Countdown.js" as CD
import "components"

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: (Plasmoid.formFactor === PlasmaCore.Types.Horizontal
                              || Plasmoid.formFactor === PlasmaCore.Types.Vertical)
                             ? compactRepresentation : fullRepresentation

    // ── Data ─────────────────────────────────────────────────────────────
    property var conferenceList: Snapshot.CCFDDL_CONFERENCES
    property var conferenceIndex: ({})
    property bool everFetched: false
    property bool fetching: false
    property string fetchError: ""
    property string dataSource: "内置快照"
    property date lastUpdated: new Date(0)
    property double now: Date.now()
    property var tracked: []

    readonly property string snapshotDate: Snapshot.CCFDDL_SNAPSHOT_DATE
    readonly property var selectedKeys: {
        try {
            var parsed = JSON.parse(plasmoid.configuration.conferencesJson);
            return Array.isArray(parsed) ? parsed : [];
        } catch (e) {
            return [];
        }
    }
    readonly property var deadlineTypes: {
        try {
            var parsed = JSON.parse(plasmoid.configuration.deadlineTypesJson);
            return Array.isArray(parsed) ? parsed : [];
        } catch (e) {
            return [];
        }
    }

    readonly property var primary: tracked.length > 0 ? tracked[0] : null
    readonly property var secondary: tracked.length > 1 ? tracked.slice(1) : []
    readonly property int secondaryRows: Math.min(secondary.length, 3)
    readonly property bool showSecondaryList: plasmoid.configuration.showSecondaries
                                              && secondary.length > 0
    readonly property string primaryCaption: {
        if (!primary) {
            return "";
        }
        if (!primary.event) {
            return "暂无截止日期";
        }
        var label = CD.typeLabel(primary.event.type);
        var text = primary.upcoming ? ("距离" + label + "还有") : (label + "已截止");
        if (primary.event.comment) {
            text += " · " + primary.event.comment;
        }
        return text;
    }
    readonly property string statusText: {
        if (fetching) {
            return "更新中";
        }
        if (fetchError !== "") {
            return "离线";
        }
        if (!everFetched) {
            return "快照";
        }
        return Qt.formatDateTime(lastUpdated, "HH:mm");
    }
    readonly property string statusTooltip: {
        var lines = [];
        lines.push("数据源：" + dataSource);
        lines.push("内置快照：" + snapshotDate);
        if (everFetched) {
            lines.push("上次在线更新：" + Qt.formatDateTime(lastUpdated, "yyyy-MM-dd HH:mm"));
        }
        if (fetchError !== "") {
            lines.push("最近一次更新失败：" + fetchError);
        }
        return lines.join("\n");
    }
    readonly property string compactCountdown: {
        if (!primary) {
            return "";
        }
        if (!primary.event) {
            return "—";
        }
        if (!primary.upcoming) {
            return "已截止";
        }
        var parts = CD.durationParts(primary.event.epoch - now);
        if (parts.days > 0) {
            return parts.days + "天";
        }
        return CD.pad2(parts.hours) + ":" + CD.pad2(parts.minutes);
    }

    MacOSColors {
        id: colors
        styleMode: plasmoid.configuration.styleMode
        appearance: plasmoid.configuration.appearance
    }

    // ── Config / context actions ─────────────────────────────────────────
    PlasmaCore.Action {
        id: refreshAction
        text: "刷新会议数据"
        icon.name: "view-refresh"
        onTriggered: root.refresh(true)
    }
    PlasmaCore.Action {
        id: openAction
        text: "打开 CCFDDL 网站"
        icon.name: "internet-services"
        onTriggered: Qt.openUrlExternally("https://ccfddl.com/")
    }
    Plasmoid.contextualActions: [refreshAction, openAction]

    toolTipMainText: primary
                     ? (primary.title + " " + primary.year)
                     : "CCFDDL 投稿倒计时"
    toolTipSubText: {
        if (!primary) {
            return "在设置中选择要跟踪的会议";
        }
        if (!primary.event) {
            return "暂无截止日期";
        }
        var parts = CD.durationParts(primary.event.epoch - now);
        var state = primary.upcoming
                ? (parts.days + " 天 " + CD.pad2(parts.hours) + ":"
                   + CD.pad2(parts.minutes) + ":" + CD.pad2(parts.seconds))
                : "已截止";
        return CD.typeLabel(primary.event.type) + " · " + primary.event.raw
                + " " + root.tzLabel(primary.timezone) + "\n" + state;
    }

    // ── Timers ───────────────────────────────────────────────────────────
    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.now = Date.now()
    }

    Timer {
        id: refreshTimer
        interval: Math.max(1, plasmoid.configuration.refreshHours) * 3600000
        repeat: true
        running: true
        onTriggered: root.refresh(false)
    }

    // ── Lifecycle ────────────────────────────────────────────────────────
    Component.onCompleted: {
        rebuildIndex();
        rebuildTracked();
        refresh(false);
    }

    onConferenceListChanged: {
        rebuildIndex();
        rebuildTracked();
    }
    onSelectedKeysChanged: rebuildTracked()
    onDeadlineTypesChanged: rebuildTracked()
    onConferenceIndexChanged: rebuildTracked()

    // ── Helpers ──────────────────────────────────────────────────────────
    function rebuildIndex() {
        var index = {};
        if (conferenceList) {
            for (var i = 0; i < conferenceList.length; i++) {
                var item = conferenceList[i];
                if (item && item.conference_key) {
                    index[item.conference_key] = item;
                }
            }
        }
        conferenceIndex = index;
    }

    function rebuildTracked() {
        var list = [];

        if (!conferenceIndex || !selectedKeys || !deadlineTypes) {
            tracked = list;
            return;
        }

        for (var i = 0; i < selectedKeys.length; i++) {
            var key = selectedKeys[i];
            var conference = conferenceIndex[key];
            if (!conference) {
                continue;
            }

            var conf = CD.latestEdition(conference);
            if (!conf) {
                continue;
            }

            var events = CD.eventsFor(conf, deadlineTypes);
            var picked = CD.pickEvent(events, now);

            list.push({
                key: key,
                title: conference.title || key,
                description: conference.description || "",
                sub: conference.sub || "",
                rank: conference.rank || {},
                year: conf.year || "",
                timezone: conf.timezone || "",
                place: conf.place || "",
                dateText: conf.date || "",
                link: conf.link || "https://ccfddl.com/",
                event: picked.event,
                upcoming: picked.upcoming
            });
        }

        list.sort(function (a, b) {
            if (!a.event && !b.event) {
                return 0;
            }
            if (!a.event) {
                return 1;
            }
            if (!b.event) {
                return -1;
            }
            if (a.upcoming !== b.upcoming) {
                return a.upcoming ? -1 : 1;
            }
            if (a.upcoming) {
                return a.event.epoch - b.event.epoch;
            }
            return b.event.epoch - a.event.epoch;
        });

        tracked = list;
    }

    function refresh(manual) {
        if (fetching) {
            return;
        }

        fetching = true;
        fetchError = "";

        var urls = [
            "https://ccfddl.com/conference/initial.json",
            "https://ccfddl.com/conference/allconf.json"
        ];
        var nextIndex = 0;

        function finish(error) {
            fetching = false;
            if (error) {
                fetchError = error;
            } else {
                fetchError = "";
            }
        }

        function attempt() {
            if (nextIndex >= urls.length) {
                finish("无法连接 ccfddl.com");
                return;
            }

            var url = urls[nextIndex++] + "?t=" + Date.now();
            var xhr = new XMLHttpRequest();
            var handled = false;

            function retry() {
                if (handled) {
                    return;
                }
                handled = true;
                attempt();
            }

            xhr.open("GET", url);
            xhr.timeout = 20000;
            xhr.onreadystatechange = function () {
                if (xhr.readyState !== XMLHttpRequest.DONE || handled) {
                    return;
                }
                if (xhr.status < 200 || xhr.status >= 300) {
                    retry();
                    return;
                }
                handled = true;
                try {
                    var parsed = JSON.parse(xhr.responseText);
                    var list = parsed && parsed.conferences
                            ? parsed.conferences
                            : (Array.isArray(parsed) ? parsed : null);
                    if (!list || !list.length) {
                        throw new Error("数据为空");
                    }
                    conferenceList = list;
                    lastUpdated = new Date();
                    everFetched = true;
                    dataSource = "ccfddl.com";
                    rebuildIndex();
                    rebuildTracked();
                    finish("");
                } catch (e) {
                    attempt();
                }
            };
            xhr.onerror = retry;
            xhr.ontimeout = retry;
            xhr.send();
        }

        attempt();
    }

    function tzLabel(tz) {
        if (!tz) {
            return "UTC";
        }
        if (tz === "AoE") {
            return "AoE (UTC-12)";
        }
        return tz;
    }

    function localDateTime(epoch) {
        if (!epoch) {
            return "";
        }
        var date = new Date(epoch);
        // Qt.formatDateTime's "ddd" token is not localized — use the locale
        // directly for the weekday name.
        return Qt.locale().dayName(date.getDay(), Locale.ShortFormat) + " "
                + Qt.formatDateTime(date, "yyyy-MM-dd HH:mm");
    }

    function metaLine(entry) {
        if (!entry) {
            return "";
        }
        var bits = [];
        if (entry.place && entry.place !== "TBD") {
            bits.push(entry.place);
        }
        if (entry.dateText && entry.dateText !== "TBD") {
            bits.push(entry.dateText);
        }
        return bits.join(" · ");
    }

    function openPrimary() {
        Qt.openUrlExternally(primary && primary.link ? primary.link : "https://ccfddl.com/");
    }

    // ── Full representation ──────────────────────────────────────────────
    fullRepresentation: Item {
        id: page

        Layout.preferredWidth: 380
        Layout.preferredHeight: 400
        Layout.minimumWidth: 300
        Layout.minimumHeight: 280

        LiquidGlass {
            id: glass
            anchors.fill: parent
            radius: Math.min(plasmoid.configuration.cornerRadius,
                             Math.min(page.width, page.height) / 2)
            roundness: Math.max(2, plasmoid.configuration.roundnessX10 / 10)
            refractThickness: plasmoid.configuration.refractThickness
            refractIOR: plasmoid.configuration.refractIORx100 / 100
            refractScale: plasmoid.configuration.refractScale
            tint: colors.glassTint
            tintAlpha: plasmoid.configuration.tintAlphaPct / 100
            chromaStrength: plasmoid.configuration.chromaStrengthPct / 100
            specStrength: plasmoid.configuration.specStrengthPct / 100
            blurRadius: plasmoid.configuration.blurRadiusPx
            blurAlgorithm: plasmoid.configuration.blurAlgorithm
            realtimeRefraction: plasmoid.configuration.realtimeRefraction
            fallbackOpacity: colors.glassFallbackOpacity
            solidMode: colors.isSolid
            solidColor: colors.solidBackground
            visibilitySource: page
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 8

            // ── Header ───────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Rectangle {
                    implicitWidth: 6
                    implicitHeight: 6
                    radius: 3
                    color: root.fetching ? "#FF9F0A"
                           : (root.fetchError !== "" ? "#FF453A" : "#30D158")
                    Layout.alignment: Qt.AlignVCenter
                }

                QQC2.Label {
                    text: "CCFDDL"
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.6
                    color: colors.labelTertiary
                }

                QQC2.Label {
                    text: root.statusText
                    font.pixelSize: 9
                    color: colors.labelQuaternary
                    visible: page.width > 340

                    HoverHandler {
                        id: statusHover
                    }
                    QQC2.ToolTip.visible: statusHover.hovered
                    QQC2.ToolTip.text: root.statusTooltip
                    QQC2.ToolTip.delay: 400
                }

                Item {
                    Layout.fillWidth: true
                }

                GlassButton {
                    iconName: "view-refresh"
                    iconColor: colors.labelSecondary
                    hoverColor: Qt.rgba(colors.cardBackground.r, colors.cardBackground.g,
                                        colors.cardBackground.b, colors.cardHoverOpacity)
                    tooltip: "刷新数据"
                    opacity: root.fetching ? 0.45 : 1.0
                    onClicked: root.refresh(true)
                }

                GlassButton {
                    iconName: "configure"
                    iconColor: colors.labelSecondary
                    hoverColor: Qt.rgba(colors.cardBackground.r, colors.cardBackground.g,
                                        colors.cardBackground.b, colors.cardHoverOpacity)
                    tooltip: "设置"
                    onClicked: Plasmoid.internalAction("configure").trigger()
                }
            }

            // ── Empty state ──────────────────────────────────────────────
            ColumnLayout {
                visible: root.tracked.length === 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 10

                Item {
                    Layout.fillHeight: true
                }

                QQC2.Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: "选择要投稿的会议"
                    font.pixelSize: 22
                    font.weight: Font.DemiBold
                    color: colors.foreground
                }

                QQC2.Label {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: "在设置里勾选 ACL、SIGIR 等会议，\n倒计时会自动出现在这里。"
                    font.pixelSize: 11
                    lineHeight: 1.3
                    color: colors.labelTertiary
                    wrapMode: Text.WordWrap
                }

                QQC2.Button {
                    Layout.alignment: Qt.AlignHCenter
                    text: "打开设置"
                    onClicked: Plasmoid.internalAction("configure").trigger()

                    contentItem: QQC2.Label {
                        text: "打开设置"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                    }
                    background: Rectangle {
                        implicitWidth: 96
                        implicitHeight: 30
                        radius: 9
                        color: colors.accent
                    }
                }

                Item {
                    Layout.fillHeight: true
                }
            }

            // ── Primary conference ───────────────────────────────────────
            ColumnLayout {
                id: primaryBlock
                visible: root.primary !== null
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 200
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 7

                    QQC2.Label {
                        Layout.fillWidth: true
                        text: root.primary ? root.primary.title : ""
                        font.pixelSize: Math.max(22, Math.min(30, page.width * 0.068))
                        font.weight: Font.DemiBold
                        color: colors.foreground
                        elide: Text.ElideRight

                        TapHandler {
                            cursorShape: Qt.PointingHandCursor
                            onTapped: root.openPrimary()
                        }
                        HoverHandler {
                            id: titleHover
                            cursorShape: Qt.PointingHandCursor
                        }
                        QQC2.ToolTip.visible: titleHover.hovered
                        QQC2.ToolTip.text: "打开会议官网"
                        QQC2.ToolTip.delay: 500
                    }

                    QQC2.Label {
                        text: root.primary ? String(root.primary.year) : ""
                        font.pixelSize: 13
                        color: colors.labelTertiary
                        Layout.alignment: Qt.AlignBottom
                        Layout.bottomMargin: 4
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    RankBadge {
                        palette: colors
                        ccf: root.primary && root.primary.rank ? (root.primary.rank.ccf || "") : ""
                        core: root.primary && root.primary.rank ? (root.primary.rank.core || "") : ""
                    }
                }

                QQC2.Label {
                    Layout.fillWidth: true
                    visible: root.primary !== null && root.primary.description !== ""
                             && plasmoid.configuration.showConferenceInfo && page.height > 330
                    text: root.primary ? root.primary.description : ""
                    font.pixelSize: 10
                    color: colors.labelTertiary
                    elide: Text.ElideRight
                }

                Item {
                    Layout.fillHeight: true
                }

                CountdownBlock {
                    Layout.fillWidth: true
                    palette: colors
                    targetEpoch: root.primary && root.primary.event ? root.primary.event.epoch : 0
                    now: root.now
                    hasEvent: root.primary !== null && root.primary.event !== null
                    upcoming: root.primary ? root.primary.upcoming : false
                    showSeconds: plasmoid.configuration.showSeconds
                    urgencyColor: plasmoid.configuration.urgencyColor
                    caption: root.primaryCaption
                }

                Item {
                    Layout.fillHeight: true
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    QQC2.Label {
                        Layout.fillWidth: true
                        visible: root.primary !== null && root.primary.event !== null
                        text: root.primary && root.primary.event
                              ? ("截止 " + root.primary.event.raw + " " + root.tzLabel(root.primary.timezone))
                              : ""
                        font.pixelSize: 10
                        color: colors.labelSecondary
                        elide: Text.ElideRight
                    }

                    QQC2.Label {
                        Layout.fillWidth: true
                        visible: root.primary !== null && root.primary.event !== null
                        text: root.primary && root.primary.event
                              ? ("本地 " + root.localDateTime(root.primary.event.epoch))
                              : ""
                        font.pixelSize: 10
                        color: colors.labelTertiary
                        elide: Text.ElideRight
                    }

                    QQC2.Label {
                        Layout.fillWidth: true
                        visible: root.primary !== null
                                 && plasmoid.configuration.showConferenceInfo
                                 && root.metaLine(root.primary) !== ""
                        text: root.metaLine(root.primary)
                        font.pixelSize: 9
                        color: colors.labelQuaternary
                        elide: Text.ElideRight
                    }
                }
            }

            // ── Other tracked conferences ────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                Layout.topMargin: 2
                visible: root.showSecondaryList
                color: colors.separator
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                visible: root.showSecondaryList

                Repeater {
                    model: root.secondaryRows

                    ConferenceRow {
                        Layout.fillWidth: true
                        palette: colors
                        entry: root.secondary[index]
                        now: root.now
                        onActivated: Qt.openUrlExternally((entry && entry.link) || "https://ccfddl.com/")
                    }
                }

                QQC2.Label {
                    Layout.fillWidth: true
                    visible: root.secondary.length > root.secondaryRows
                    horizontalAlignment: Text.AlignHCenter
                    text: "还有 " + (root.secondary.length - root.secondaryRows) + " 个会议未展开（可在设置中精简选择）"
                    font.pixelSize: 9
                    color: colors.labelQuaternary
                }
            }
        }
    }

    // ── Panel representation ─────────────────────────────────────────────
    compactRepresentation: Item {
        Layout.minimumWidth: 96
        Layout.minimumHeight: 24
        Layout.preferredWidth: compactRow.implicitWidth + 14
        Layout.preferredHeight: 26

        RowLayout {
            id: compactRow
            anchors.centerIn: parent
            spacing: 5

            Rectangle {
                implicitWidth: 6
                implicitHeight: 6
                radius: 3
                color: {
                    var parts = root.primary && root.primary.event
                            ? CD.durationParts(root.primary.event.epoch - root.now) : null;
                    if (root.primary && root.primary.upcoming && parts && parts.days <= 7) {
                        return "#FF9F0A";
                    }
                    return root.primary && root.primary.upcoming
                           ? Kirigami.Theme.highlightColor : Kirigami.Theme.disabledTextColor;
                }
            }

            QQC2.Label {
                text: root.primary
                      ? (root.primary.title + " " + root.compactCountdown)
                      : "CCFDDL"
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: Kirigami.Theme.textColor
            }

            QQC2.Label {
                text: root.primary ? String(root.primary.year) : ""
                font.pixelSize: 9
                color: Kirigami.Theme.disabledTextColor
            }
        }
    }
}
