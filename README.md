# 影子二重奏 / Shadow Duet

**影子二重奏** 是一个使用 **LÖVE / Love2D** 制作的 2D 横版时间协作解谜平台游戏原型。

玩家需要和 **4 秒前的自己** 协作：让影子踩按钮、开门、挡激光、推箱子，帮助现在的自己抵达终点。

**Shadow Duet** is a playable 2D time-echo puzzle platformer prototype made with **LÖVE / Love2D**.

You cooperate with your **self from 4 seconds ago**. Your shadow can press pads, open doors, block lasers, push crates, and help the present player reach the exit.

---

## 截图 / Screenshots

### 主菜单 / Main Menu
![中文主菜单 / Chinese main menu](docs/screenshots/menu-zh.png)

### 任务板 / Mission Board
![任务板 / Mission board](docs/screenshots/mission-board-zh.png)

### 影子协作 / Shadow Cooperation
![影子踩按钮开门 / Shadow replay puzzle](docs/screenshots/gameplay-shadow.png)

### 箱子机关 / Crate Puzzle
![箱子压按钮 / Crate pad puzzle](docs/screenshots/gameplay-crate.png)

### 设置与暂停 / Settings & Pause
| Settings | Pause |
|---|---|
| ![English settings](docs/screenshots/settings-en.png) | ![中文暂停菜单 / Chinese pause menu](docs/screenshots/pause-zh.png) |

---

## 功能 / Features

- 4 秒延迟影子回放 / 4-second delayed shadow replay
- 玩家移动、跳跃、土狼时间、跳跃缓存、可变跳高 / Movement, jumping, coyote time, jump buffering, variable jump height
- 影子可踩按钮、挡激光、推箱子 / Shadow can press pads, block lasers, and push crates
- 玩家、影子、箱子都能触发压力按钮 / Pressure pads react to player, shadow, and crates
- 门、激光、箱子、终点机关 / Doors, lasers, crates, and goal triggers
- 12 个短关卡，按 PRD 教学节奏推进 / 12 short PRD-aligned levels
- 任务板式选关 / Mission-board level select
- 设置页中英文切换 / Chinese-English language toggle in Settings
- 暂停菜单 / Pause menu
- 本地存档 / Local save data
- `R` 快速重开 / Fast restart with `R`
- `Tab` 显示最近 4 秒轨迹 / Hold `Tab` to preview the recent 4-second route

---

## 运行 / Run

安装 Love2D 11.x 后运行：

Install Love2D 11.x, then run:

```bash
cd shadow-duet-love2d
love .
```

也可以直接指定目录：

Or run it directly from another directory:

```bash
love /path/to/shadow-duet-love2d
```

---

## 操作 / Controls

| 操作 | 按键 | Action | Key |
|---|---|---|---|
| 移动 | `A/D` 或方向键 | Move | `A/D` or arrow keys |
| 跳跃 | `空格` / `W` / `上` | Jump | `Space` / `W` / `Up` |
| 重开 | `R` | Restart | `R` |
| 暂停 | `Esc` / `P` | Pause | `Esc` / `P` |
| 显示轨迹 | 按住 `Tab` | Show trail | Hold `Tab` |
| 菜单确认 | `回车` | Confirm | `Enter` |
| 全屏 | `F11` | Fullscreen | `F11` |

---

## 核心玩法 / Core Loop

1. 先让玩家踩上按钮。  
   Step on a pressure pad.
2. 玩家离开后，门会关闭。  
   Leave the pad and the door closes.
3. 4 秒后，影子重复刚才的动作。  
   Four seconds later, the shadow repeats your previous action.
4. 影子踩住按钮时，玩家穿过门。  
   Pass through the door while the shadow holds the pad.
5. 后续关卡会加入箱子、激光和多机关组合。  
   Later levels add crates, lasers, and combined timing puzzles.

---

## 项目结构 / Project Structure

```text
shadow-duet-love2d/
├── conf.lua
├── main.lua
├── levels.lua
├── README.md
├── assets/
│   └── fonts/
│       └── LXGWWenKai-Regular.ttf
└── docs/
    └── screenshots/
```

- `conf.lua`：Love2D 窗口与应用配置 / Love2D window and app config
- `main.lua`：游戏循环、物理、录像回放、菜单、渲染 / Game loop, physics, recorder, menus, rendering
- `levels.lua`：关卡数据 / Level data
- `assets/fonts/`：中文字体 / Chinese-capable font
- `docs/screenshots/`：README 截图 / README screenshots

---

## 当前状态 / Status

这是一个可玩的 Prototype / Demo，用于验证“和几秒前的自己合作”的核心机制。

This is a playable prototype/demo focused on validating the core mechanic: cooperating with your past self.

下一步适合继续打磨 Web 版、音效、关卡平衡和正式美术资源。

Good next steps: Web build, sound effects, level balancing, and production-quality art assets.
