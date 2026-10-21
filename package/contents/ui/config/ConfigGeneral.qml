import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCMUtils
import "../../data/snapshot.js" as Snapshot
import "../Countdown.js" as CD

KCMUtils.SimpleKCM {
    id: page

    // KConfig entries. The config dialog reads/writes these directly.
    property string cfg_conferencesJson: "[\"AI/acl\"]"
    property string cfg_deadlineTypesJson: "[\"abstract_deadline\",\"deadline\"]"
    property bool cfg_showSeconds: true
    property bool cfg_showConferenceInfo: true
    property bool cfg_showSecondaries: true
    property bool cfg_urgencyColor: true
    property int cfg_refreshHours: 6

    property var allConferences: Snapshot.CCFDDL_CONFERENCES
    property string searchText: ""
    property bool loading: false
    property string loadStatus: ""

    readonly property var selectedKeys: {
        try {
            var parsed = JSON.parse(page.cfg_conferencesJson);
            return Array.isArray(parsed) ? parsed : [];
        } catch (e) {
            return [];
        }
    }

    readonly property var deadlineTypes: {
        try {
            var parsed = JSON.parse(page.cfg_deadlineTypesJson);
            return Array.isArray(parsed) ? parsed : [];
        } catch (e) {
            return [];
        }
    }

    readonly property var filtered: {
        var query = page.searchText.trim().toLowerCase();
        var result = [];
        var source = page.allConferences || [];

        for (var i = 0; i < source.length; i++) {
            var item = source[i];
            if (!query) {
                result.push(item);
                continue;
            }
            var haystack = (item.title + " " + (item.description || "") + " "
                            + (item.conference_key || "") + " " + (item.sub || "")).toLowerCase();
            if (haystack.indexOf(query) >= 0) {
                result.push(item);
            }
        }
        return result;
    }

    function titleFor(key) {
        var source = page.allConferences || [];
        for (var i = 0; i < source.length; i++) {
            if (source[i].conference_key === key) {
                return source[i].title;
            }
        }
        return key;
    }

    function yearOf(conference) {
        var edition = CD.latestEdition(conference);
        return edition ? edition.year : "";
    }

    function metaText(conference) {
        var bits = [];
        if (conference.sub) {
            bits.push(conference.sub);
        }
        if (conference.rank) {
            if (conference.rank.ccf) {
                bits.push("CCF " + conference.rank.ccf);
            }
            if (conference.rank.core) {
                bits.push("CORE " + conference.rank.core);
            }
        }
        return bits.join(" · ");
    }

    function isSelected(key) {
        return page.selectedKeys.indexOf(key) >= 0;
    }

    function setSelected(key, selected) {
        var list = page.selectedKeys.slice();
        var index = list.indexOf(key);
        if (selected && index < 0) {
            list.push(key);
        } else if (!selected && index >= 0) {
            list.splice(index, 1);
        } else {
            return;
        }
        page.cfg_conferencesJson = JSON.stringify(list);
    }

    function clearSelection() {
        page.cfg_conferencesJson = "[]";
    }

    function hasType(type) {
        return page.deadlineTypes.indexOf(type) >= 0;
    }

    function setType(type, selected) {
        var list = page.deadlineTypes.slice();
        var index = list.indexOf(type);
        if (selected && index < 0) {
            list.push(type);
        } else if (!selected && index >= 0) {
            list.splice(index, 1);
        } else {
            return;
        }
        page.cfg_deadlineTypesJson = JSON.stringify(list);
    }

    function fetchLatest() {
        if (page.loading) {
            return;
        }

        page.loading = true;
        page.loadStatus = "正在从 ccfddl.com 获取会议列表…";

        var xhr = new XMLHttpRequest();
        var done = false;

        function fail(message) {
            if (done) {
                return;
            }
            done = true;
            page.loading = false;
            page.loadStatus = message;
        }

        xhr.open("GET", "https://ccfddl.com/conference/initial.json?t=" + Date.now());
        xhr.timeout = 20000;
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE || done) {
                return;
            }
            if (xhr.status < 200 || xhr.status >= 300) {
                fail("更新失败（HTTP " + xhr.status + "）");
                return;
            }
            done = true;
            try {
                var parsed = JSON.parse(xhr.responseText);
                var list = parsed && parsed.conferences
                        ? parsed.conferences
                        : (Array.isArray(parsed) ? parsed : null);
                if (!list || !list.length) {
                    throw new Error("empty");
                }
                page.allConferences = list;
                page.loading = false;
                page.loadStatus = "已更新，共 " + list.length + " 个会议";
            } catch (e) {
                page.loading = false;
                page.loadStatus = "更新失败：数据格式异常";
            }
        };
        xhr.onerror = function () { fail("更新失败：网络错误"); };
        xhr.ontimeout = function () { fail("更新失败：请求超时"); };
        xhr.send();
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.largeSpacing

        // ── Search ───────────────────────────────────────────────────────
        Kirigami.FormLayout {
            Layout.fillWidth: true

            Kirigami.Separator {
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: "会议"
            }

            QQC2.TextField {
                id: searchField
                Kirigami.FormData.label: "搜索："
                Layout.fillWidth: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 20
                placeholderText: "ACL、SIGIR、数据库、AI…"
                onTextChanged: page.searchText = text
            }

            ColumnLayout {
                Kirigami.FormData.label: "数据源："
                spacing: 4

                RowLayout {
                    spacing: Kirigami.Units.smallSpacing

                    QQC2.Button {
                        text: page.loading ? "更新中…" : "从 ccfddl.com 更新列表"
                        enabled: !page.loading
                        onClicked: page.fetchLatest()
                    }

                    QQC2.Label {
                        text: page.loadStatus
                        visible: page.loadStatus !== ""
                        font.pixelSize: 10
                        opacity: 0.7
                        elide: Text.ElideRight
                        Layout.maximumWidth: Kirigami.Units.gridUnit * 18
                    }
                }

                QQC2.Label {
                    text: "主界面会每 " + page.cfg_refreshHours + " 小时自动刷新一次；这里只影响设置里的候选列表。"
                    font.pixelSize: 10
                    opacity: 0.55
                    wrapMode: Text.WordWrap
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 22
                }
            }
        }

        // ── Selected chips ───────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.Label {
                text: "已选 " + page.selectedKeys.length + " 个会议"
                font.weight: Font.DemiBold
            }

            Item {
                Layout.fillWidth: true
            }

            QQC2.Button {
                text: "清空"
                flat: true
                visible: page.selectedKeys.length > 0
                onClicked: page.clearSelection()
            }
        }

        Flow {
            id: chipFlow
            Layout.fillWidth: true
            Layout.preferredHeight: page.selectedKeys.length > 0 ? 30 : 0
            visible: page.selectedKeys.length > 0
            spacing: 4

            Repeater {
                model: page.selectedKeys.length

                Rectangle {
                    id: chip
                    height: 26
                    width: chipRow.implicitWidth + 18
                    radius: 13
                    color: Kirigami.Theme.alternateBackgroundColor
                    border.width: 1
                    border.color: Qt.rgba(Kirigami.Theme.textColor.r,
                                          Kirigami.Theme.textColor.g,
                                          Kirigami.Theme.textColor.b, 0.10)

                    property string chipKey: page.selectedKeys[index]

                    RowLayout {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: 5

                        QQC2.Label {
                            text: page.titleFor(chip.chipKey)
                            font.pixelSize: 10
                            elide: Text.ElideRight
                            Layout.maximumWidth: Kirigami.Units.gridUnit * 10
                        }

                        QQC2.Label {
                            text: "×"
                            font.pixelSize: 12
                            opacity: 0.55

                            TapHandler {
                                cursorShape: Qt.PointingHandCursor
                                onTapped: page.setSelected(chip.chipKey, false)
                            }
                        }
                    }
                }
            }
        }

        // ── Conference list ──────────────────────────────────────────────
        QQC2.Frame {
            Layout.fillWidth: true
            Layout.preferredHeight: 260
            padding: 1

            background: Rectangle {
                radius: 8
                color: Kirigami.Theme.alternateBackgroundColor
                border.width: 1
                border.color: Qt.rgba(Kirigami.Theme.textColor.r,
                                      Kirigami.Theme.textColor.g,
                                      Kirigami.Theme.textColor.b, 0.12)
            }

            Item {
                anchors.fill: parent

                Flickable {
                    anchors.fill: parent
                    clip: true
                    contentHeight: conferenceColumn.height
                    boundsBehavior: Flickable.StopAtBounds

                    QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                        policy: QQC2.ScrollBar.AsNeeded
                    }

                    Column {
                        id: conferenceColumn
                        width: parent.width

                        Repeater {
                            model: page.filtered.length

                            QQC2.ItemDelegate {
                                id: delegate
                                width: conferenceColumn.width
                                implicitHeight: 54
                                leftPadding: 36
                                rightPadding: 8
                                topPadding: 4
                                bottomPadding: 4
                                hoverEnabled: true

                                property var conference: page.filtered[index]
                                onClicked: page.setSelected(delegate.conference.conference_key,
                                                            !page.isSelected(delegate.conference.conference_key))

                                indicator: Rectangle {
                                    implicitWidth: 18
                                    implicitHeight: 18
                                    radius: 5
                                    color: page.isSelected(delegate.conference.conference_key)
                                           ? Kirigami.Theme.highlightColor : "transparent"
                                    border.width: 1.5
                                    border.color: page.isSelected(delegate.conference.conference_key)
                                                  ? Kirigami.Theme.highlightColor
                                                  : Qt.rgba(Kirigami.Theme.textColor.r,
                                                            Kirigami.Theme.textColor.g,
                                                            Kirigami.Theme.textColor.b, 0.35)

                                    QQC2.Label {
                                        anchors.centerIn: parent
                                        visible: page.isSelected(delegate.conference.conference_key)
                                        text: "✓"
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: Kirigami.Theme.highlightedTextColor
                                    }
                                }

                                contentItem: RowLayout {
                                    spacing: 8

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 6

                                            QQC2.Label {
                                                text: delegate.conference.title
                                                font.pixelSize: 12
                                                font.weight: Font.DemiBold
                                            }
                                            QQC2.Label {
                                                text: String(page.yearOf(delegate.conference))
                                                font.pixelSize: 9
                                                opacity: 0.55
                                                Layout.alignment: Qt.AlignBaseline
                                            }
                                            Item {
                                                Layout.fillWidth: true
                                            }
                                        }

                                        QQC2.Label {
                                            Layout.fillWidth: true
                                            text: delegate.conference.description || ""
                                            font.pixelSize: 10
                                            opacity: 0.60
                                            elide: Text.ElideRight
                                        }
                                    }

                                    QQC2.Label {
                                        text: page.metaText(delegate.conference)
                                        font.pixelSize: 9
                                        opacity: 0.60
                                        Layout.maximumWidth: Kirigami.Units.gridUnit * 9
                                        elide: Text.ElideRight
                                        Layout.alignment: Qt.AlignVCenter
                                    }
                                }

                                background: Rectangle {
                                    radius: 6
                                    color: delegate.hovered
                                           ? Qt.rgba(Kirigami.Theme.highlightColor.r,
                                                     Kirigami.Theme.highlightColor.g,
                                                     Kirigami.Theme.highlightColor.b, 0.12)
                                           : "transparent"
                                }
                            }
                        }
                    }
                }

                QQC2.Label {
                    anchors.centerIn: parent
                    visible: page.filtered.length === 0
                    text: "没有匹配的会议"
                    opacity: 0.55
                }
            }
        }

        QQC2.Label {
            text: "提示：可以同时选择多个会议。小组件会把最近截止的会议放大显示，其余会议排在下方。"
            font.pixelSize: 10
            opacity: 0.55
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        // ── Deadline types ───────────────────────────────────────────────
        Kirigami.FormLayout {
            Layout.fillWidth: true

            Kirigami.Separator {
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: "截止类型"
            }

            QQC2.CheckBox {
                text: "摘要截止 (Abstract)"
                checked: page.hasType("abstract_deadline")
                onToggled: page.setType("abstract_deadline", checked)
            }

            QQC2.CheckBox {
                text: "论文截止 (Paper)"
                checked: page.hasType("deadline")
                onToggled: page.setType("deadline", checked)
            }

            QQC2.CheckBox {
                text: "Rebuttal 截止"
                checked: page.hasType("rebuttal_deadline")
                onToggled: page.setType("rebuttal_deadline", checked)
            }

            QQC2.CheckBox {
                text: "录用通知 (Decision)"
                checked: page.hasType("decision_deadline")
                onToggled: page.setType("decision_deadline", checked)
            }

            QQC2.Label {
                text: "小组件会显示所有勾选类型中“下一个到期”的时间。只关心投稿时，保留摘要和论文即可。"
                font.pixelSize: 10
                opacity: 0.55
                wrapMode: Text.WordWrap
                Layout.preferredWidth: Kirigami.Units.gridUnit * 22
            }
        }

        // ── Display / refresh ────────────────────────────────────────────
        Kirigami.FormLayout {
            Layout.fillWidth: true

            Kirigami.Separator {
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: "显示与刷新"
            }

            QQC2.CheckBox {
                text: "倒计时显示秒"
                checked: page.cfg_showSeconds
                onToggled: page.cfg_showSeconds = checked
            }

            QQC2.CheckBox {
                text: "显示会议地点和会期"
                checked: page.cfg_showConferenceInfo
                onToggled: page.cfg_showConferenceInfo = checked
            }

            QQC2.CheckBox {
                text: "在下方显示其他已选会议"
                checked: page.cfg_showSecondaries
                onToggled: page.cfg_showSecondaries = checked
            }

            QQC2.CheckBox {
                text: "临近截止时变成橙色 / 红色"
                checked: page.cfg_urgencyColor
                onToggled: page.cfg_urgencyColor = checked
            }

            QQC2.ComboBox {
                Kirigami.FormData.label: "自动刷新："
                model: ["每 1 小时", "每 3 小时", "每 6 小时", "每 12 小时", "每 24 小时"]
                currentIndex: [1, 3, 6, 12, 24].indexOf(page.cfg_refreshHours)
                onActivated: page.cfg_refreshHours = [1, 3, 6, 12, 24][currentIndex]
            }

            QQC2.Label {
                text: "冷启动时会先用内置数据立即显示，然后在后台从 ccfddl.com 拉取最新数据。断网时继续使用上次的内置快照。"
                font.pixelSize: 10
                opacity: 0.55
                wrapMode: Text.WordWrap
                Layout.preferredWidth: Kirigami.Units.gridUnit * 24
            }
        }
    }
}
