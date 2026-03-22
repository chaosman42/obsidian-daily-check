# Obsidian Daily Check System

[English](#english) | [中文](#中文)

---

## English

A comprehensive daily self-reflection and habit tracking system for [Obsidian](https://obsidian.md/). Combines checklist-based daily reviews with automated analytics dashboards to help you identify behavioral patterns and build better habits.

### Features

- **Daily Check Template**: 30+ checklist items across 4 categories with mood/health/sleep tracking via YAML frontmatter
- **Trait Review System**: Track which negative behavioral patterns you triggered each day
- **Analytics Dashboard**: 5 Dataview JS panels for streak counting, weekly/monthly trends, weak spot analysis, and trait frequency
- **macOS Reminder**: Automated morning/evening popup reminders via launchd
- **Templater Integration**: Auto-populates date, mood, health, sleep, and intensity via interactive prompts

### System Architecture

```
Daily Template (Templater)
    ├── YAML Frontmatter (date, mood, health, sleep, intensity)
    ├── Pitfall Avoidance (10 items)
    ├── Mental Training (10 items)
    ├── Behavioral Training (10 items)
    └── Trait Review (11 traits, check = triggered today)
            │
            ▼
Dashboard (Dataview JS)
    ├── Streak Counter & Weekly Overview
    ├── Monthly Daily Trend Table
    ├── Weak Spots (lowest completion rate items)
    ├── Trait Trigger Frequency
    └── 14-Day Calendar View
```

### Requirements

| Plugin | Required | Purpose |
|--------|----------|---------|
| [Templater](https://github.com/SilentVoid13/Templater) | Yes | Template variable processing, date/mood prompts |
| [Dataview](https://github.com/blacksmithgu/obsidian-dataview) | Yes | Dashboard analytics, must enable DataviewJS |
| [Advanced URI](https://github.com/Vinzent03/obsidian-advanced-uri) | Optional | For macOS reminder script to open daily note |

### Installation

1. Copy `templates/daily-check-template.md` to your Obsidian template folder
2. Copy `templates/daily-check-dashboard.md` to your vault
3. In the dashboard file, replace `"Diary"` with your diary folder name (appears in all `dv.pages()` calls)
4. Configure Templater to use the template for daily notes
5. Optionally set up the macOS reminder (see below)

### Template Structure

The daily template uses Obsidian callout syntax for clean visual sections:

- `> [!danger]+` Pitfall Avoidance, red callout for things to avoid
- `> [!tip]+` Mental Training, blue callout for thinking patterns
- `> [!success]+` Behavioral Training, green callout for actions to take
- `> [!warning]+` Trait Review, yellow callout for pattern tracking

**Key design decision**: Trait review items start with `**bold text**`. The dashboard uses this pattern to distinguish traits from regular checklist items. Regular items unchecked = not done (bad). Trait items checked = triggered today (bad). This inversion is handled automatically in the analytics.

### Dashboard Panels

| Panel | What it shows |
|-------|---------------|
| **Streak Counter** | Consecutive days with a diary entry |
| **Weekly Overview** | Completion rate bar for current week |
| **Monthly Trend** | Day-by-day completion table with mini progress bars |
| **Weak Spots** | Bottom 10 items by completion rate over 30 days |
| **Trait Frequency** | Which negative traits triggered most often in 30 days |
| **14-Day Calendar** | Visual check/uncheck calendar |

### macOS Reminder Setup (Optional)

```bash
# 1. Copy the script
mkdir -p ~/.local/bin
cp scripts/daily-remind.sh ~/.local/bin/
chmod +x ~/.local/bin/daily-remind.sh

# 2. Edit the script: set your VAULT_ID
nano ~/.local/bin/daily-remind.sh

# 3. Copy the plist, edit your username
cp scripts/com.daily-checklist.plist ~/Library/LaunchAgents/
# Edit the plist: replace YOUR_USERNAME with your macOS username

# 4. Load the scheduled task
launchctl load ~/Library/LaunchAgents/com.daily-checklist.plist
```

You will get a popup at 8:00 AM and 9:00 PM daily with a button to open today's daily note in Obsidian.

### Customization

The template is fully customizable. You can:

- Add/remove/modify checklist items in any section
- Add new trait items (just start with `**Trait Name**`)
- Change the number of sections
- Modify the frontmatter fields
- The dashboard will automatically adapt to your changes

---

## 中文

一套完整的 [Obsidian](https://obsidian.md/) 每日自我反思与习惯追踪系统。将清单式每日回顾与自动化数据分析仪表盘相结合，帮助你识别行为模式、建立更好的习惯。

### 功能特色

- **每日打卡模板**: 4个分类共30+个检查项，YAML 前置数据记录心情、健康、睡眠
- **特质复盘系统**: 追踪每天触发了哪些负面行为模式
- **数据分析仪表盘**: 5个 Dataview JS 面板，包括连续打卡天数、周/月趋势、薄弱项分析、特质触发频率
- **macOS 定时提醒**: 通过 launchd 实现早晚弹窗提醒
- **Templater 集成**: 通过交互式弹窗自动填写日期、心情、健康、睡眠、强度

### 系统架构

```
每日模板 (Templater)
    ├── YAML 前置数据（日期、心情、健康、睡眠、强度）
    ├── 避坑指南（10项）
    ├── 思维修炼（10项）
    ├── 行为修炼（10项）
    └── 错误复盘（11个特质，勾选 = 今天触发了）
            │
            ▼
仪表盘 (Dataview JS)
    ├── 连续打卡天数 & 本周概况
    ├── 本月每日趋势表
    ├── 薄弱项统计（完成率最低的项目）
    ├── 特质触发频率
    └── 14天日历视图
```

### 插件要求

| 插件 | 是否必需 | 用途 |
|------|---------|------|
| [Templater](https://github.com/SilentVoid13/Templater) | 必需 | 模板变量处理、日期/心情弹窗 |
| [Dataview](https://github.com/blacksmithgu/obsidian-dataview) | 必需 | 仪表盘数据分析，需开启 DataviewJS |
| [Advanced URI](https://github.com/Vinzent03/obsidian-advanced-uri) | 可选 | macOS 提醒脚本跳转到当日日记 |

### 安装方法

1. 将 `templates/daily-check-template.md` 复制到你的 Obsidian 模板文件夹
2. 将 `templates/daily-check-dashboard.md` 复制到你的库中
3. 在仪表盘文件中，将所有 `dv.pages()` 中的 `"Diary"` 替换为你的日记文件夹名
4. 配置 Templater 将此模板用于每日笔记
5. 可选：设置 macOS 定时提醒（见下方）

### 模板结构

模板使用 Obsidian callout 语法实现清晰的视觉分区：

- `> [!danger]+` 避坑指南，红色区块，需要避免的事项
- `> [!tip]+` 思维修炼，蓝色区块，思维模式训练
- `> [!success]+` 行为修炼，绿色区块，需要执行的行动
- `> [!warning]+` 错误复盘，黄色区块，特质追踪

**关键设计**: 特质复盘项以 `**加粗文字**` 开头。仪表盘通过此特征区分特质项和普通检查项。普通项未勾选 = 没做到（不好）。特质项勾选 = 今天触发了（不好）。这种反转逻辑在数据分析中自动处理。

### 仪表盘面板

| 面板 | 展示内容 |
|------|---------|
| **连续打卡** | 连续有日记的天数 |
| **本周概况** | 当前周的完成率进度条 |
| **本月趋势** | 逐日完成情况表格，含迷你进度条 |
| **薄弱项** | 30天内完成率最低的10个检查项 |
| **特质频率** | 30天内最常触发的负面特质 |
| **14天日历** | 可视化打卡/未打卡日历 |

### macOS 定时提醒（可选）

```bash
# 1. 复制脚本
mkdir -p ~/.local/bin
cp scripts/daily-remind.sh ~/.local/bin/
chmod +x ~/.local/bin/daily-remind.sh

# 2. 编辑脚本：设置你的 VAULT_ID
nano ~/.local/bin/daily-remind.sh

# 3. 复制 plist，编辑你的用户名
cp scripts/com.daily-checklist.plist ~/Library/LaunchAgents/
# 编辑 plist：将 YOUR_USERNAME 替换为你的 macOS 用户名

# 4. 加载定时任务
launchctl load ~/Library/LaunchAgents/com.daily-checklist.plist
```

每天早上 8:00 和晚上 9:00 会弹出提醒窗口，点击按钮直接跳转到 Obsidian 当日日记。

### 自定义

模板完全可自定义。你可以：

- 在任何分区中添加/删除/修改检查项
- 添加新的特质项（以 `**特质名**` 开头即可）
- 修改分区数量
- 修改前置数据字段
- 仪表盘会自动适应你的修改

---

## License

MIT License. See [LICENSE](LICENSE) for details.
