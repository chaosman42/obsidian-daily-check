# 📊 每日检查仪表盘

> 统计来源: ☀️日记本 文件夹中的打卡日记
> 所有日记均带有 `daily-check` 标签，统计时自动排除特质复盘项
> 每篇日记统计 30 个检查项，特质复盘在「特质触发频率」区域单独统计
> 新增: 心情/睡眠/健康趋势分析，本周vs上周对比，睡眠与特质触发关联

---

## 🔥 连续打卡 & 本周概况

```dataviewjs
// 时区安全的日期格式化函数
// 不使用 toISOString() 因为它返回 UTC 时间，在东八区会把日期往前推一天
const pad = n => String(n).padStart(2, '0');
const fmt = d => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;

// 智能获取检查项：新模板统计全部checkbox但排除特质复盘项，旧模板按section过滤
// 新模板通过 daily-check 标签识别，旧模板通过 section heading 过滤杂项
// 特质复盘的 checkbox 文本以 ** 开头（加粗特质名），用此特征排除
const isTraitTask = (t) => t.text.trim().startsWith("**");
const getCheckTasks = (p) => {
    const tags = p.file.tags || [];
    const isNewTemplate = tags.some(t => t === "#daily-check");
    if (isNewTemplate) return p.file.tasks.where(t => !isTraitTask(t));
    // 旧模板：只保留检查清单和避坑指南下的 checkbox
    return p.file.tasks.where(t => {
        const sec = t.section?.subpath || "";
        return sec.includes("避坑") || sec.includes("检查清单") || sec.includes("反思") || sec.includes("修炼");
    });
};

const pages = dv.pages('"☀️日记本"')
    .where(p => /^\d{4}-\d{2}-\d{2}/.test(p.file.name))
    .sort(p => p.file.name, 'desc');

// 用 for 循环构建 Set，避免 DataArray 与 Set 构造器的兼容性问题
const diaryDates = new Set();
for (const p of pages) {
    diaryDates.add(p.file.name.substring(0, 10));
}

const now = new Date();
const todayStr = fmt(now);

// ===== 连续打卡天数 =====
// 如果今天还没写日记，从昨天开始计算，不会因为还没打卡就清零
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
dv.header(3, `🔥 连续打卡: ${streak} 天 ${todayDone ? '(今日已打卡 ✅)' : '(今日未打卡 ⬜)'}`);
dv.paragraph(`📅 共有 ${pages.length} 篇打卡日记`);

// ===== 本周完成率 =====
// 计算本周一到今天的所有日记的 checkbox 完成率
const dayOfWeek = now.getDay();
const mondayOffset = dayOfWeek === 0 ? 6 : dayOfWeek - 1;
const weekStartDate = new Date(now);
weekStartDate.setDate(now.getDate() - mondayOffset);
const weekStartStr = fmt(weekStartDate);

// 使用字符串比较过滤日期范围，避免 new Date() 解析的时区问题
const weekPages = pages.where(p => {
    const dateStr = p.file.name.substring(0, 10);
    return dateStr >= weekStartStr && dateStr <= todayStr;
});

let weekTotal = 0;
let weekDone = 0;
for (const p of weekPages) {
    const tasks = getCheckTasks(p);
    weekTotal += tasks.length;
    weekDone += tasks.where(t => t.completed).length;
}

const weekRate = weekTotal > 0 ? Math.round(weekDone / weekTotal * 100) : 0;
const barFull = Math.round(weekRate / 5);
const barEmpty = 20 - barFull;

dv.header(3, `📊 本周完成率`);
dv.paragraph(`${'█'.repeat(barFull)}${'░'.repeat(barEmpty)} **${weekRate}%** (${weekDone}/${weekTotal})`);
dv.paragraph(`本周已打卡 ${weekPages.length} 天`);
```

---

## 📈 本月每日趋势

```dataviewjs
// 列出本月每天的打卡完成情况
const pad = n => String(n).padStart(2, '0');
const fmt = d => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;

// 智能获取检查项：同上方逻辑，新模板排除特质复盘项，旧模板过滤杂项
// 特质复盘的 checkbox 文本以 ** 开头（加粗特质名），用此特征排除
const isTraitTask = (t) => t.text.trim().startsWith("**");
const getCheckTasks = (p) => {
    const tags = p.file.tags || [];
    const isNewTemplate = tags.some(t => t === "#daily-check");
    if (isNewTemplate) return p.file.tasks.where(t => !isTraitTask(t));
    return p.file.tasks.where(t => {
        const sec = t.section?.subpath || "";
        return sec.includes("避坑") || sec.includes("检查清单") || sec.includes("反思") || sec.includes("修炼");
    });
};

const pages = dv.pages('"☀️日记本"')
    .where(p => /^\d{4}-\d{2}-\d{2}/.test(p.file.name))
    .sort(p => p.file.name, 'desc');

const now = new Date();
const todayStr = fmt(now);
// 本月第一天的日期字符串
const monthStartStr = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-01`;

const monthPages = pages.where(p => {
    const dateStr = p.file.name.substring(0, 10);
    return dateStr >= monthStartStr && dateStr <= todayStr;
});

if (monthPages.length === 0) {
    dv.paragraph("本月暂无打卡记录");
} else {
    const rows = [];
    for (const p of monthPages) {
        const tasks = getCheckTasks(p);
        const total = tasks.length;
        const done = tasks.where(t => t.completed).length;
        const rate = total > 0 ? Math.round(done / total * 100) : 0;
        // 迷你进度条，10格宽度
        const filled = Math.round(rate / 10);
        const miniBar = '█'.repeat(filled) + '░'.repeat(10 - filled);
        rows.push([p.file.link, `${done}/${total}`, `${miniBar} ${rate}%`]);
    }
    dv.table(["日期", "完成数", "完成率"], rows);
}
```

---

## ⚠️ 薄弱项统计 (最近30天)

```dataviewjs
// 找出最近30天内最常被跳过的检查项
// 按完成率从低到高排序，帮助识别需要重点关注的习惯
const pad = n => String(n).padStart(2, '0');
const fmt = d => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;

// 智能获取检查项：同上方逻辑，新模板排除特质复盘项，旧模板过滤杂项
// 特质复盘的 checkbox 文本以 ** 开头（加粗特质名），用此特征排除
const isTraitTask = (t) => t.text.trim().startsWith("**");
const getCheckTasks = (p) => {
    const tags = p.file.tags || [];
    const isNewTemplate = tags.some(t => t === "#daily-check");
    if (isNewTemplate) return p.file.tasks.where(t => !isTraitTask(t));
    return p.file.tasks.where(t => {
        const sec = t.section?.subpath || "";
        return sec.includes("避坑") || sec.includes("检查清单") || sec.includes("反思") || sec.includes("修炼");
    });
};

const pages = dv.pages('"☀️日记本"')
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
    dv.paragraph("最近30天暂无打卡记录");
} else {
    // 统计每个检查项文本的完成次数和出现次数
    const taskStats = {};
    for (const p of recentPages) {
        const tasks = getCheckTasks(p);
        for (const t of tasks) {
            const text = t.text.trim();
            // 跳过空文本和过短的杂项
            if (!text || text.length < 3) continue;
            if (!taskStats[text]) taskStats[text] = { total: 0, done: 0 };
            taskStats[text].total++;
            if (t.completed) taskStats[text].done++;
        }
    }

    // 按完成率从低到高排序，只显示出现2次以上的项
    const weakItems = Object.entries(taskStats)
        .filter(([text, s]) => s.total >= 2)
        .map(([text, s]) => {
            const rate = Math.round(s.done / s.total * 100);
            return [text, s.done, s.total, `${rate}%`];
        })
        .sort((a, b) => parseInt(a[3]) - parseInt(b[3]))
        .slice(0, 10);

    if (weakItems.length === 0) {
        dv.paragraph("数据不足，至少需要2天的打卡记录才能统计");
    } else {
        dv.table(["检查项", "完成", "出现", "完成率"], weakItems);
    }
}
```

---

## 🔍 特质触发频率 (最近30天)

```dataviewjs
// 扫描最近30天日记中已勾选的特质 checkbox，统计每个特质的触发次数
// 特质 checkbox 的文本以 ** 开头（加粗特质名），勾选表示当天触发了该特质
// 按触发频率从高到低排序，帮助识别最顽固的行为模式
const pad = n => String(n).padStart(2, '0');
const fmt = d => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;

const pages = dv.pages('"☀️日记本"')
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
    dv.paragraph("最近30天暂无打卡记录");
} else {
    // 统计每个特质 checkbox 的勾选次数
    const traitStats = {};
    for (const p of recentPages) {
        for (const t of p.file.tasks) {
            const text = t.text.trim();
            // 只统计以 ** 开头的特质 checkbox，且必须已勾选
            if (!text.startsWith("**")) continue;
            if (!t.completed) continue;
            // 提取 **特质名** 中间的文字
            const match = text.match(/^\*\*(.+?)\*\*/);
            if (!match) continue;
            const traitName = match[1];
            if (!traitStats[traitName]) traitStats[traitName] = 0;
            traitStats[traitName]++;
        }
    }

    const traitEntries = Object.entries(traitStats)
        .sort((a, b) => b[1] - a[1]);

    if (traitEntries.length === 0) {
        dv.paragraph("最近30天暂无特质触发记录。在日记的「错误复盘」区域勾选触发的特质即可追踪。");
    } else {
        // 找到最高频率用于计算进度条比例
        const maxCount = traitEntries[0][1];
        const rows = traitEntries.map(([name, count]) => {
            const barLen = Math.max(1, Math.round(count / maxCount * 10));
            const bar = '🟧'.repeat(barLen);
            return [name, bar + ` ${count}次`, `${recentPages.length}天中`];
        });
        dv.table(["特质", "触发次数", "统计范围"], rows);
    }
}
```

---

## 📅 最近打卡日历

```dataviewjs
// 显示最近14天的打卡状态
// 有日记的天标 ✅，没有的标 ⬜
const pad = n => String(n).padStart(2, '0');
const fmt = d => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;

const pages = dv.pages('"☀️日记本"')
    .where(p => /^\d{4}-\d{2}-\d{2}/.test(p.file.name));

const diaryDates = new Set();
for (const p of pages) {
    diaryDates.add(p.file.name.substring(0, 10));
}

const now = new Date();
const dayNames = ["日", "一", "二", "三", "四", "五", "六"];
let calendarRows = [];

for (let i = 13; i >= 0; i--) {
    const d = new Date(now);
    d.setDate(now.getDate() - i);
    const dateStr = fmt(d);
    const dayName = dayNames[d.getDay()];
    const hasEntry = diaryDates.has(dateStr);
    calendarRows.push([
        `${dateStr} (${dayName})`,
        hasEntry ? "✅" : "⬜",
    ]);
}

dv.table(["日期", "状态"], calendarRows);
```

---

## 😊 心情/睡眠/健康趋势 (最近30天)

```dataviewjs
// 从 YAML frontmatter 中读取 mood、sleep、health 数据
// 将文字标签转换为数值，绘制趋势表格，识别状态波动规律
const pad = n => String(n).padStart(2, '0');
const fmt = d => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;

// 数值映射：用于趋势分析和对比
// 心情的映射：正面情绪得分高，负面情绪得分低
const moodMap = {"😊 开心": 5, "🤩 兴奋": 5, "😐 平静": 3, "😤 烦躁": 2, "😔 低落": 1};
const sleepMap = {"😴 充足": 3, "😪 一般": 2, "😵 不足": 1};
const healthMap = {"💪 很好": 3, "🙂 一般": 2, "🤒 不适": 1};

const pages = dv.pages('"☀️日记本"')
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
    dv.paragraph("最近30天暂无打卡记录");
} else {
    // 检查是否有 YAML 数据
    const pagesWithData = recentPages.where(p => p.mood || p.sleep || p.health);

    if (pagesWithData.length === 0) {
        dv.paragraph("暂无心情/睡眠/健康数据。新模板创建的日记会自动包含这些数据。");
    } else {
        // 趋势表格：每天的心情、睡眠、健康状态
        const rows = [];
        for (const p of pagesWithData.sort(p => p.file.name, 'asc')) {
            const dateStr = p.file.name.substring(0, 10);
            const mood = p.mood || "-";
            const sleep = p.sleep || "-";
            const health = p.health || "-";
            rows.push([dateStr, mood, sleep, health]);
        }
        dv.table(["日期", "心情", "睡眠", "健康"], rows);

        // 统计概览
        let moodSum = 0, moodCount = 0;
        let sleepSum = 0, sleepCount = 0;
        let healthSum = 0, healthCount = 0;
        // 统计各分类出现次数
        const moodDist = {};
        const sleepDist = {};

        for (const p of pagesWithData) {
            if (p.mood && moodMap[p.mood] !== undefined) {
                moodSum += moodMap[p.mood];
                moodCount++;
                moodDist[p.mood] = (moodDist[p.mood] || 0) + 1;
            }
            if (p.sleep && sleepMap[p.sleep] !== undefined) {
                sleepSum += sleepMap[p.sleep];
                sleepCount++;
                sleepDist[p.sleep] = (sleepDist[p.sleep] || 0) + 1;
            }
            if (p.health && healthMap[p.health] !== undefined) {
                healthSum += healthMap[p.health];
                healthCount++;
            }
        }

        dv.header(4, "📊 统计概览");
        if (moodCount > 0) {
            const avgMood = (moodSum / moodCount).toFixed(1);
            // 找出最常出现的心情
            const topMood = Object.entries(moodDist).sort((a,b) => b[1] - a[1])[0];
            dv.paragraph(`**心情**: 平均 ${avgMood}/5 | 最常见: ${topMood[0]} (${topMood[1]}天)`);
        }
        if (sleepCount > 0) {
            const avgSleep = (sleepSum / sleepCount).toFixed(1);
            const topSleep = Object.entries(sleepDist).sort((a,b) => b[1] - a[1])[0];
            dv.paragraph(`**睡眠**: 平均 ${avgSleep}/3 | 最常见: ${topSleep[0]} (${topSleep[1]}天)`);
        }
    }
}
```

---

## 📊 本周 vs 上周对比

```dataviewjs
// 对比本周和上周的检查项完成率，用箭头显示趋势
// 帮助你看到自己是在进步还是退步
const pad = n => String(n).padStart(2, '0');
const fmt = d => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;

const isTraitTask = (t) => t.text.trim().startsWith("**");
const getCheckTasks = (p) => {
    const tags = p.file.tags || [];
    const isNewTemplate = tags.some(t => t === "#daily-check");
    if (isNewTemplate) return p.file.tasks.where(t => !isTraitTask(t));
    return p.file.tasks.where(t => {
        const sec = t.section?.subpath || "";
        return sec.includes("避坑") || sec.includes("检查清单") || sec.includes("反思") || sec.includes("修炼");
    });
};

const pages = dv.pages('"☀️日记本"')
    .where(p => /^\d{4}-\d{2}-\d{2}/.test(p.file.name))
    .sort(p => p.file.name, 'desc');

const now = new Date();
const todayStr = fmt(now);

// 计算本周和上周的日期范围
const dayOfWeek = now.getDay();
const mondayOffset = dayOfWeek === 0 ? 6 : dayOfWeek - 1;

// 本周一
const thisMonday = new Date(now);
thisMonday.setDate(now.getDate() - mondayOffset);
const thisMondayStr = fmt(thisMonday);

// 上周一和上周日
const lastMonday = new Date(thisMonday);
lastMonday.setDate(thisMonday.getDate() - 7);
const lastMondayStr = fmt(lastMonday);
const lastSunday = new Date(thisMonday);
lastSunday.setDate(thisMonday.getDate() - 1);
const lastSundayStr = fmt(lastSunday);

// 计算某段日期范围内的完成率
function calcRate(startStr, endStr) {
    const filtered = pages.where(p => {
        const d = p.file.name.substring(0, 10);
        return d >= startStr && d <= endStr;
    });
    let total = 0, done = 0, days = filtered.length;
    for (const p of filtered) {
        const tasks = getCheckTasks(p);
        total += tasks.length;
        done += tasks.where(t => t.completed).length;
    }
    const rate = total > 0 ? Math.round(done / total * 100) : 0;
    return { rate, done, total, days };
}

const thisWeek = calcRate(thisMondayStr, todayStr);
const lastWeek = calcRate(lastMondayStr, lastSundayStr);

// 趋势箭头
let trend = "";
if (lastWeek.rate > 0) {
    const diff = thisWeek.rate - lastWeek.rate;
    if (diff > 5) trend = `⬆️ +${diff}%`;
    else if (diff < -5) trend = `⬇️ ${diff}%`;
    else trend = `➡️ 持平 (${diff >= 0 ? '+' : ''}${diff}%)`;
}

// 本周进度条
const thisFilled = Math.round(thisWeek.rate / 5);
const lastFilled = Math.round(lastWeek.rate / 5);

dv.paragraph(`**本周** (${thisWeek.days}天): ${'█'.repeat(thisFilled)}${'░'.repeat(20 - thisFilled)} **${thisWeek.rate}%** (${thisWeek.done}/${thisWeek.total})`);
dv.paragraph(`**上周** (${lastWeek.days}天): ${'█'.repeat(lastFilled)}${'░'.repeat(20 - lastFilled)} **${lastWeek.rate}%** (${lastWeek.done}/${lastWeek.total})`);

if (trend) {
    dv.paragraph(`**趋势**: ${trend}`);
}

// 特质触发对比
let thisTraits = 0, lastTraits = 0;
for (const p of pages.where(p => {
    const d = p.file.name.substring(0, 10);
    return d >= thisMondayStr && d <= todayStr;
})) {
    for (const t of p.file.tasks) {
        if (t.text.trim().startsWith("**") && t.completed) thisTraits++;
    }
}
for (const p of pages.where(p => {
    const d = p.file.name.substring(0, 10);
    return d >= lastMondayStr && d <= lastSundayStr;
})) {
    for (const t of p.file.tasks) {
        if (t.text.trim().startsWith("**") && t.completed) lastTraits++;
    }
}

let traitTrend = "";
if (thisTraits < lastTraits) traitTrend = `⬆️ 进步（少触发 ${lastTraits - thisTraits} 次）`;
else if (thisTraits > lastTraits) traitTrend = `⬇️ 退步（多触发 ${thisTraits - lastTraits} 次）`;
else traitTrend = "➡️ 持平";

dv.paragraph(`**特质触发**: 本周 ${thisTraits} 次 vs 上周 ${lastTraits} 次 ${traitTrend}`);
```

---

## 😴 睡眠与特质触发关联

```dataviewjs
// 分析睡眠质量与特质触发之间的关系
// 验证"睡不好的时候是不是更容易犯错"这个假设
const pad = n => String(n).padStart(2, '0');
const fmt = d => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;

const pages = dv.pages('"☀️日记本"')
    .where(p => /^\d{4}-\d{2}-\d{2}/.test(p.file.name))
    .sort(p => p.file.name, 'desc');

const now = new Date();
const todayStr = fmt(now);
const thirtyAgo = new Date(now);
thirtyAgo.setDate(now.getDate() - 30);
const thirtyAgoStr = fmt(thirtyAgo);

const recentPages = pages.where(p => {
    const dateStr = p.file.name.substring(0, 10);
    return dateStr >= thirtyAgoStr && dateStr <= todayStr && p.sleep;
});

if (recentPages.length < 3) {
    dv.paragraph("需要至少3天带睡眠数据的记录才能分析关联。");
} else {
    // 按睡眠质量分组，统计每组的平均特质触发数
    const groups = {};
    for (const p of recentPages) {
        const sleep = p.sleep || "未记录";
        if (!groups[sleep]) groups[sleep] = { days: 0, traits: 0 };
        groups[sleep].days++;
        // 计算当天触发了多少个特质
        for (const t of p.file.tasks) {
            if (t.text.trim().startsWith("**") && t.completed) {
                groups[sleep].traits++;
            }
        }
    }

    const rows = Object.entries(groups)
        .map(([sleep, data]) => {
            const avg = (data.traits / data.days).toFixed(1);
            return [sleep, `${data.days} 天`, `${data.traits} 次`, `平均 ${avg} 次/天`];
        });

    dv.table(["睡眠质量", "天数", "特质触发总数", "平均每天触发"], rows);
}
