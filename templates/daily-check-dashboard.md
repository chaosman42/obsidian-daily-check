# 📊 Daily Check Dashboard

> Source: diary files in the diary folder
> All entries tagged with `daily-check`, trait review items are excluded from main stats
> Each diary tracks 30 check items, trait review is tracked separately

---

## 🔥 Streak & Weekly Overview

```dataviewjs
const pad = n => String(n).padStart(2, '0');
const fmt = d => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;

// Smart task filter: exclude trait review items (text starts with **)
const isTraitTask = (t) => t.text.trim().startsWith("**");
const getCheckTasks = (p) => {
    const tags = p.file.tags || [];
    const isNewTemplate = tags.some(t => t === "#daily-check");
    if (isNewTemplate) return p.file.tasks.where(t => !isTraitTask(t));
    return p.file.tasks.where(t => {
        const sec = t.section?.subpath || "";
        return sec.includes("Pitfall") || sec.includes("Training") || sec.includes("Review");
    });
};

// CHANGE THIS to your diary folder name
const pages = dv.pages('"Diary"')
    .where(p => /^\d{4}-\d{2}-\d{2}/.test(p.file.name))
    .sort(p => p.file.name, 'desc');

const diaryDates = new Set();
for (const p of pages) {
    diaryDates.add(p.file.name.substring(0, 10));
}

const now = new Date();
const todayStr = fmt(now);

let streak = 0;
let checkDate = new Date(now);
if (!diaryDates.has(fmt(checkDate))) {
    checkDate.setDate(checkDate.getDate() - 1);
}
while (diaryDates.has(fmt(checkDate))) {
    streak++;
    checkDate.setDate(checkDate.getDate() - 1);
}

const todayDone = diaryDates.has(todayStr);
dv.header(3, `🔥 Streak: ${streak} days ${todayDone ? '(Today ✅)' : '(Today ⬜)'}`);
dv.paragraph(`📅 Total ${pages.length} diary entries`);

const dayOfWeek = now.getDay();
const mondayOffset = dayOfWeek === 0 ? 6 : dayOfWeek - 1;
const weekStartDate = new Date(now);
weekStartDate.setDate(now.getDate() - mondayOffset);
const weekStartStr = fmt(weekStartDate);

const weekPages = pages.where(p => {
    const dateStr = p.file.name.substring(0, 10);
    return dateStr >= weekStartStr && dateStr <= todayStr;
});

let weekTotal = 0, weekDone = 0;
for (const p of weekPages) {
    const tasks = getCheckTasks(p);
    weekTotal += tasks.length;
    weekDone += tasks.where(t => t.completed).length;
}

const weekRate = weekTotal > 0 ? Math.round(weekDone / weekTotal * 100) : 0;
const barFull = Math.round(weekRate / 5);
dv.header(3, `📊 Weekly Completion Rate`);
dv.paragraph(`${'█'.repeat(barFull)}${'░'.repeat(20 - barFull)} **${weekRate}%** (${weekDone}/${weekTotal})`);
```

---

## 📈 Monthly Daily Trend

```dataviewjs
const pad = n => String(n).padStart(2, '0');
const fmt = d => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
const isTraitTask = (t) => t.text.trim().startsWith("**");
const getCheckTasks = (p) => {
    const tags = p.file.tags || [];
    const isNewTemplate = tags.some(t => t === "#daily-check");
    if (isNewTemplate) return p.file.tasks.where(t => !isTraitTask(t));
    return p.file.tasks.where(t => {
        const sec = t.section?.subpath || "";
        return sec.includes("Pitfall") || sec.includes("Training") || sec.includes("Review");
    });
};

const pages = dv.pages('"Diary"')
    .where(p => /^\d{4}-\d{2}-\d{2}/.test(p.file.name))
    .sort(p => p.file.name, 'desc');

const now = new Date();
const todayStr = fmt(now);
const monthStartStr = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-01`;
const monthPages = pages.where(p => {
    const dateStr = p.file.name.substring(0, 10);
    return dateStr >= monthStartStr && dateStr <= todayStr;
});

if (monthPages.length === 0) {
    dv.paragraph("No entries this month");
} else {
    const rows = [];
    for (const p of monthPages) {
        const tasks = getCheckTasks(p);
        const total = tasks.length;
        const done = tasks.where(t => t.completed).length;
        const rate = total > 0 ? Math.round(done / total * 100) : 0;
        const filled = Math.round(rate / 10);
        rows.push([p.file.link, `${done}/${total}`, `${'█'.repeat(filled)}${'░'.repeat(10 - filled)} ${rate}%`]);
    }
    dv.table(["Date", "Done", "Rate"], rows);
}
```

---

## ⚠️ Weak Spots (Last 30 Days)

```dataviewjs
const pad = n => String(n).padStart(2, '0');
const fmt = d => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
const isTraitTask = (t) => t.text.trim().startsWith("**");
const getCheckTasks = (p) => {
    const tags = p.file.tags || [];
    const isNewTemplate = tags.some(t => t === "#daily-check");
    if (isNewTemplate) return p.file.tasks.where(t => !isTraitTask(t));
    return p.file.tasks.where(t => {
        const sec = t.section?.subpath || "";
        return sec.includes("Pitfall") || sec.includes("Training") || sec.includes("Review");
    });
};

const pages = dv.pages('"Diary"')
    .where(p => /^\d{4}-\d{2}-\d{2}/.test(p.file.name))
    .sort(p => p.file.name, 'desc');

const now = new Date();
const todayStr = fmt(now);
const thirtyAgo = new Date(now);
thirtyAgo.setDate(now.getDate() - 30);
const thirtyAgoStr = fmt(thirtyAgo);

const recentPages = pages.where(p => {
    const dateStr = p.file.name.substring(0, 10);
    return dateStr >= thirtyAgoStr && dateStr <= todayStr;
});

if (recentPages.length === 0) {
    dv.paragraph("No entries in last 30 days");
} else {
    const taskStats = {};
    for (const p of recentPages) {
        const tasks = getCheckTasks(p);
        for (const t of tasks) {
            const text = t.text.trim();
            if (!text || text.length < 3) continue;
            if (!taskStats[text]) taskStats[text] = { total: 0, done: 0 };
            taskStats[text].total++;
            if (t.completed) taskStats[text].done++;
        }
    }
    const weakItems = Object.entries(taskStats)
        .filter(([, s]) => s.total >= 2)
        .map(([text, s]) => [text, s.done, s.total, `${Math.round(s.done / s.total * 100)}%`])
        .sort((a, b) => parseInt(a[3]) - parseInt(b[3]))
        .slice(0, 10);
    if (weakItems.length === 0) dv.paragraph("Need at least 2 days of data");
    else dv.table(["Item", "Done", "Total", "Rate"], weakItems);
}
```

---

## 🔍 Trait Trigger Frequency (Last 30 Days)

```dataviewjs
const pad = n => String(n).padStart(2, '0');
const fmt = d => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;

const pages = dv.pages('"Diary"')
    .where(p => /^\d{4}-\d{2}-\d{2}/.test(p.file.name))
    .sort(p => p.file.name, 'desc');

const now = new Date();
const todayStr = fmt(now);
const thirtyAgo = new Date(now);
thirtyAgo.setDate(now.getDate() - 30);
const thirtyAgoStr = fmt(thirtyAgo);

const recentPages = pages.where(p => {
    const dateStr = p.file.name.substring(0, 10);
    return dateStr >= thirtyAgoStr && dateStr <= todayStr;
});

if (recentPages.length === 0) {
    dv.paragraph("No entries in last 30 days");
} else {
    const traitStats = {};
    for (const p of recentPages) {
        for (const t of p.file.tasks) {
            const text = t.text.trim();
            if (!text.startsWith("**") || !t.completed) continue;
            const match = text.match(/^\*\*(.+?)\*\*/);
            if (!match) continue;
            const traitName = match[1];
            if (!traitStats[traitName]) traitStats[traitName] = 0;
            traitStats[traitName]++;
        }
    }
    const entries = Object.entries(traitStats).sort((a, b) => b[1] - a[1]);
    if (entries.length === 0) {
        dv.paragraph("No traits triggered. Check traits in the Trait Review section of your daily diary.");
    } else {
        const max = entries[0][1];
        const rows = entries.map(([name, count]) => {
            const bar = '🟧'.repeat(Math.max(1, Math.round(count / max * 10)));
            return [name, `${bar} ${count}x`, `in ${recentPages.length} days`];
        });
        dv.table(["Trait", "Triggers", "Period"], rows);
    }
}
```

---

## 📅 Recent 14-Day Calendar

```dataviewjs
const pad = n => String(n).padStart(2, '0');
const fmt = d => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;

const pages = dv.pages('"Diary"')
    .where(p => /^\d{4}-\d{2}-\d{2}/.test(p.file.name));

const diaryDates = new Set();
for (const p of pages) diaryDates.add(p.file.name.substring(0, 10));

const now = new Date();
const dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
let rows = [];
for (let i = 13; i >= 0; i--) {
    const d = new Date(now);
    d.setDate(now.getDate() - i);
    const dateStr = fmt(d);
    rows.push([`${dateStr} (${dayNames[d.getDay()]})`, diaryDates.has(dateStr) ? "✅" : "⬜"]);
}
dv.table(["Date", "Status"], rows);
```
