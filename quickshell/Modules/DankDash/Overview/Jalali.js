// Jalali.js — Gregorian <-> Jalali (Solar Hijri) conversion.
// Faithful port of jalaali-js (Birashk algorithm, MIT) to QML JS.
// Used by CalendarOverviewCard for Persian date display.

.pragma library

var MONTHS = ["فروردین", "اردیبهشت", "خرداد", "تیر", "مرداد", "شهریور",
              "مهر", "آبان", "آذر", "دی", "بهمن", "اسفند"];
// Persian week starts Saturday: index 0 = شنبه
var DAYS_SHORT = ["شنبه", "یکشنبه", "دوشنبه", "سه‌شنبه", "چهارشنبه", "پنجشنبه", "جمعه"];
var PERSIAN_DIGITS = ["۰", "۱", "۲", "۳", "۴", "۵", "۶", "۷", "۸", "۹"];

function div(a, b) {
    return ~~(a / b);
}

function mod(a, b) {
    return a - ~~(a / b) * b;
}

function toPersianDigits(n) {
    return String(n).replace(/[0-9]/g, function(d) {
        return PERSIAN_DIGITS[~~d];
    });
}

// Gregorian calendar date to Julian day number
function g2d(gy, gm, gd) {
    var d = div((gy + div(gm - 8, 6) + 100100) * 1461, 4)
          + div(153 * mod(gm + 9, 12) + 2, 5)
          + gd - 34840408;
    d = d - div(div(gy + 100100 + div(gm - 8, 6), 100) * 3, 4) + 752;
    return d;
}

// Julian day number to Gregorian calendar date
function d2g(jdn) {
    var j = 4 * jdn + 139361631;
    j = j + div(div(4 * jdn + 183187720, 146097) * 3, 4) * 4 - 3908;
    var i = div(mod(j, 1461), 4) * 5 + 308;
    var gd = div(mod(i, 153), 5) + 1;
    var gm = mod(div(i, 153), 12) + 1;
    var gy = div(j, 1461) - 100100 + div(8 - gm, 6);
    return { gy: gy, gm: gm, gd: gd };
}

// Jalali calendar date to Julian day number
function j2d(jy, jm, jd) {
    var r = jalCal(jy, false);
    return g2d(r.gy, 3, r.march) + (jm - 1) * 31 - div(jm, 7) * (jm - 7) + jd - 1;
}

// Julian day number to Jalali calendar date
function d2j(jdn) {
    var gy = d2g(jdn).gy; // N.B. only year is needed
    var jy = gy - 621;
    var r = jalCal(jy, false);
    var jdn1f = g2d(gy, 3, r.march);
    var jd, jm, k;

    k = jdn - jdn1f;
    if (k >= 0) {
        if (k <= 185) {
            // The first 6 months
            jm = 1 + div(k, 31);
            jd = mod(k, 31) + 1;
            return { jy: jy, jm: jm, jd: jd };
        } else {
            // The remaining months
            k -= 186;
        }
    } else {
        // Previous Jalaali year
        jy -= 1;
        k += 179;
        if (r.leap === 1)
            k += 1;
    }
    jm = 7 + div(k, 30);
    jd = mod(k, 30) + 1;
    return { jy: jy, jm: jm, jd: jd };
}

// Calculates the Jalaali (Persian) calendar year and its start in the
// Gregorian calendar. Internal helper of jalaali-js.
function jalCal(jy, withoutLeap) {
    var breaks = [ -61, 9, 38, 199, 426, 686, 756, 818, 1111, 1181, 1210,
                   1635, 1701, 1866, 2020, 2449 ];
    var bl = breaks.length;
    var gy = jy + 621;
    var leapJ = -14;
    var jp = breaks[0];
    var jm, jump, leap, leapG, march, n, i;

    if (jy < jp || jy >= breaks[bl - 1])
        throw new Error("Invalid Jalaali year " + jy);

    // Find the limiting years for the Jalaali year jy
    for (i = 1; i < bl; i += 1) {
        jm = breaks[i];
        jump = jm - jp;
        if (jy < jm)
            break;
        leapJ = leapJ + div(jump, 33) * 8 + div(mod(jump, 33), 4);
        jp = jm;
    }
    n = jy - jp;

    // Find the number of leap years from AD 621 to the beginning of the
    // current Jalaali year in the Persian calendar
    leapJ = leapJ + div(n, 33) * 8 + div(mod(n, 33) + 3, 4);
    if (mod(jump, 33) === 4 && jump - n === 4)
        leapJ += 1;

    // And the same in the Gregorian calendar (until the year gy)
    leapG = div(gy, 4) - div((div(gy, 100) + 1) * 3, 4) - 150;

    // Determine the Gregorian date of Farvardin the 1st
    march = 20 + leapJ - leapG;

    // Return how many years are passed since the last leap year
    if (!withoutLeap) {
        if (jump - n < 6)
            n = n - jump + div(jump + 4, 33) * 33;
        leap = mod(mod(n + 1, 33) - 1, 4);
        if (leap === -1) {
            leap = 4;
        }
    }

    return { leap: leap, gy: gy, march: march };
}

// Public API -----------------------------------------------------------

// Gregorian (gy, gm 1-12, gd) -> Jalali {jy, jm 1-12, jd}
function toJalaali(gy, gm, gd) {
    return d2j(g2d(gy, gm, gd));
}

// Jalali {jy, jm, jd} -> Gregorian {gy, gm, gd}
function toGregorian(jy, jm, jd) {
    return d2g(j2d(jy, jm, jd));
}

// JS Date (local time) -> Jalali {jy, jm, jd}
function fromDate(date) {
    return toJalaali(date.getFullYear(), date.getMonth() + 1, date.getDate());
}

// Jalali {jy, jm, jd} -> JS Date at local midnight
function toDate(j) {
    var g = toGregorian(j.jy, j.jm, j.jd);
    return new Date(g.gy, g.gm - 1, g.gd);
}

// Display helpers (Persian digits throughout)

function monthName(jm) {
    return MONTHS[jm - 1];
}

// "مهر ۱۴۰۵"
function formatMonthYear(date) {
    var j = fromDate(date);
    return monthName(j.jm) + " " + toPersianDigits(j.jy);
}

// "۱۴ مهر"
function formatDayMonth(date) {
    var j = fromDate(date);
    return toPersianDigits(j.jd) + " " + monthName(j.jm);
}

// "۱۴ مهر ۱۴۰۵"
function formatFull(date) {
    var j = fromDate(date);
    return toPersianDigits(j.jd) + " " + monthName(j.jm) + " " + toPersianDigits(j.jy);
}

// Weekday name for a JS Date; index 0 = شنبه (Saturday)
function dayName(date) {
    return DAYS_SHORT[(date.getDay() + 1) % 7];
}

// Weekday short labels starting from a given JS day-of-week
// (jsStart: 0=Sunday..6=Saturday, matching Qt firstDayOfWeek % 7)
function dayNamesFrom(jsStart) {
    var out = [];
    for (var i = 0; i < 7; i++)
        out.push(DAYS_SHORT[(jsStart + 1 + i) % 7]);
    return out;
}

// True if two JS dates fall on the same Jalali day
function sameJalaliDay(a, b) {
    var ja = fromDate(a);
    var jb = fromDate(b);
    return ja.jy === jb.jy && ja.jm === jb.jm && ja.jd === jb.jd;
}
