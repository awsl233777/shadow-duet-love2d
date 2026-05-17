# Shadow Duet - Love2D Prototype

A playable LÖVE / Love2D prototype for **影子二重奏**.

## Features

- Player movement with acceleration, friction, coyote time, jump buffering, and variable jump height
- 4-second delayed shadow replay based on recorded player state
- Shadow can press buttons, block lasers, and push crates
- Pressure buttons can be triggered by player, shadow, or crates
- Doors, lasers, crates, goal triggers
- 12 short PRD-aligned tutorial/prototype levels
- Level select, settings, pause menu, and simple Love2D save file
- Chinese / English language toggle in Settings
- Fast restart with `R`
- Pause with `Esc` / `P`
- Shadow trail preview with `Tab`

## Run

Install Love2D 11.x, then run:

```bash
cd shadow-duet-love2d
love .
```

From the workspace root:

```bash
love /home/moltbot/clawd/shadow-duet-love2d
```

## Controls

- Move: `A/D` or arrow keys
- Jump: `Space`, `W`, or `Up`
- Restart: `R`
- Show recent 4-second route: hold `Tab`
- Pause: `Esc` / `P`
- Menu navigation: arrow keys + `Enter`
- Fullscreen: `F11`

## Prototype goal

The playable loop is expanded from the PRD:

1. Step on a button.
2. Leave before the door closes.
3. Four seconds later, the shadow repeats the button press.
4. Pass through the door while the shadow holds it open.
5. Push crates onto pads for persistent activation.
6. Combine crates, shadow timing, doors, and lasers in later levels.

## Files

- `conf.lua` - Love2D window/app config
- `main.lua` - game loop, physics, recorder, menus, rendering
- `levels.lua` - prototype level data
