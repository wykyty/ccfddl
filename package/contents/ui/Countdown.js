.pragma library

// Date / deadline helpers for the CCFDDL widget.
//
// CCFDDL stores every deadline as a wall-clock string plus a timezone label,
// for example "2027-01-04 23:59:59" with timezone "UTC-12" or "AoE".
// We convert that pair to a real UTC instant, then let QML render it in the
// user's local timezone.

var TYPE_LABELS = {
    "abstract_deadline": "摘要截止",
    "deadline": "论文截止",
    "rebuttal_deadline": "Rebuttal 截止",
    "decision_deadline": "录用通知"
};

function typeLabel(type) {
    return TYPE_LABELS[type] || type;
}

function pad2(n) {
    n = Math.floor(n);
    return n < 10 ? "0" + n : "" + n;
}

// Nth Sunday of a month (1-based month).
function nthSunday(year, month, n) {
    var firstDay = new Date(Date.UTC(year, month - 1, 1)).getUTCDay();
    return 1 + ((7 - firstDay) % 7) + (n - 1) * 7;
}

// US Pacific DST rules (2007+). Deadlines are almost always late in the day,
// so comparing whole dates is enough here.
function isPDT(year, month, day) {
    var start = Date.UTC(year, 2, nthSunday(year, 3, 2));
    var end = Date.UTC(year, 10, nthSunday(year, 11, 1));
    var current = Date.UTC(year, month - 1, day);
    return current >= start && current < end;
}

// Returns the offset in hours east of UTC (UTC+8 -> 8, UTC-12 -> -12).
function timezoneOffsetHours(tz, year, month, day) {
    if (!tz) {
        return 0;
    }

    tz = String(tz).trim();

    // Anywhere on Earth is UTC-12.
    if (tz === "AoE") {
        return -12;
    }
    if (tz === "UTC" || tz === "GMT" || tz === "UTC+0" || tz === "UTC-0") {
        return 0;
    }

    var fixed = /^(?:UTC|GMT)([+-])(\d{1,2})(?::?(\d{2}))?$/.exec(tz);
    if (fixed) {
        var hours = parseInt(fixed[2], 10);
        var minutes = fixed[3] ? parseInt(fixed[3], 10) : 0;
        var value = hours + minutes / 60;
        return fixed[1] === "-" ? -value : value;
    }

    if (tz === "PT" || tz === "PST" || tz === "PDT") {
        return isPDT(year, month, day) ? -7 : -8;
    }
    if (tz === "ET" || tz === "EST" || tz === "EDT") {
        return isPDT(year, month, day) ? -4 : -5;
    }

    // Unknown label: treat as UTC rather than inventing an offset.
    return 0;
}

function parseDeadline(text, tz) {
    if (!text) {
        return null;
    }

    var m = /^(\d{4})-(\d{1,2})-(\d{1,2})[ T](\d{1,2}):(\d{2})(?::(\d{2}))?/.exec(String(text));
    if (!m) {
        return null;
    }

    var year = parseInt(m[1], 10);
    var month = parseInt(m[2], 10);
    var day = parseInt(m[3], 10);
    var hour = parseInt(m[4], 10);
    var minute = parseInt(m[5], 10);
    var second = m[6] ? parseInt(m[6], 10) : 0;

    var offset = timezoneOffsetHours(tz, year, month, day);
    return Date.UTC(year, month - 1, day, hour, minute, second) - offset * 3600000;
}

function latestEdition(conference) {
    if (!conference || !conference.confs || !conference.confs.length) {
        return null;
    }

    var best = conference.confs[0];
    for (var i = 1; i < conference.confs.length; i++) {
        if ((conference.confs[i].year || 0) > (best.year || 0)) {
            best = conference.confs[i];
        }
    }
    return best;
}

// Build a flat list of deadline events for one edition.
function eventsFor(conf, types) {
    var result = [];

    if (!conf || !conf.timeline || !types) {
        return result;
    }

    for (var i = 0; i < conf.timeline.length; i++) {
        var item = conf.timeline[i];
        var comment = item.comment || "";

        for (var j = 0; j < types.length; j++) {
            var type = types[j];
            var raw = item[type];
            if (!raw) {
                continue;
            }

            var epoch = parseDeadline(raw, conf.timezone);
            if (epoch === null) {
                continue;
            }

            result.push({
                type: type,
                raw: raw,
                comment: comment,
                epoch: epoch,
                timezone: conf.timezone || ""
            });
        }
    }

    result.sort(function (a, b) {
        return a.epoch - b.epoch;
    });

    return result;
}

// Prefer the first event still in the future. If everything has passed,
// return the most recent event so the widget can show an "over" state.
function pickEvent(events, now) {
    if (!events || !events.length) {
        return { event: null, upcoming: false };
    }

    for (var i = 0; i < events.length; i++) {
        if (events[i].epoch > now) {
            return { event: events[i], upcoming: true };
        }
    }

    return { event: events[events.length - 1], upcoming: false };
}

function durationParts(ms) {
    if (!isFinite(ms) || ms < 0) {
        ms = 0;
    }

    var total = Math.floor(ms / 1000);
    return {
        days: Math.floor(total / 86400),
        hours: Math.floor((total % 86400) / 3600),
        minutes: Math.floor((total % 3600) / 60),
        seconds: total % 60,
        totalHours: Math.floor(total / 3600),
        totalMinutes: Math.floor(total / 60)
    };
}

function daysSince(epoch, now) {
    if (!epoch || epoch > now) {
        return 0;
    }
    return Math.floor((now - epoch) / 86400000);
}
