local levels = require("levels")

local W, H = 960, 540
local SCALE = 1
local DELAY = 4.0

local COLORS = {
  skyTop = {0.045, 0.040, 0.135},
  skyMid = {0.115, 0.080, 0.230},
  skyLow = {0.260, 0.145, 0.310},
  mountainFar = {0.090, 0.105, 0.210},
  mountainMid = {0.135, 0.160, 0.300},
  mountainNear = {0.120, 0.205, 0.315},
  snow = {0.78, 0.92, 1.00},
  solid = {0.095, 0.120, 0.205},
  solidEdge = {0.42, 0.76, 1.00},
  player = {0.96, 0.98, 1.00},
  playerCoat = {0.96, 0.22, 0.42},
  playerHair = {0.22, 0.12, 0.24},
  playerSkin = {1.00, 0.78, 0.58},
  playerScarf = {0.18, 0.90, 1.00},
  playerBoot = {0.10, 0.12, 0.22},
  playerCore = {0.55, 0.95, 1.00},
  shadow = {0.20, 0.92, 1.00, 0.42},
  buttonOff = {1.00, 0.55, 0.20},
  buttonOn = {1.00, 0.92, 0.22},
  door = {0.08, 0.60, 1.00},
  goal = {0.42, 1.00, 0.68},
  laser = {1.00, 0.10, 0.30},
  panel = {0.055, 0.070, 0.140, 0.86},
  text = {0.90, 0.95, 1.00},
  muted = {0.62, 0.70, 0.90},
}

local state = "menu"
local menuIndex = 1
local selectIndex = 1
local settingsIndex = 1
local pauseIndex = 1
local settingsReturnState = "menu"
local save = {unlocked = 1, completed = {}, lang = "zh"}
local game = nil
local font, bigFont, titleFont
local writeSave

local I18N = {
  en = {
    title = "SHADOW DUET",
    subtitle = "an original pixel time-echo puzzle",
    menuHelp = "Choose Start, press Enter / Space, or click the button",
    start = "Start",
    levelSelect = "Level Select",
    settings = "Settings",
    paused = "Paused",
    resume = "Resume",
    restartLevel = "Restart",
    mainMenu = "Main Menu",
    quit = "Quit",
    controls = "A/D move   Space jump   R retry",
    missionBoard = "Mission Board",
    missionHelp = "Choose a short puzzle mission",
    missionDone = "CLEARED",
    missionOpen = "OPEN",
    tagMove = "MOVE",
    tagShadow = "SHADOW",
    tagButton = "PAD",
    tagDoor = "DOOR",
    tagLaser = "LASER",
    tagCrate = "CRATE",
    choose = "Arrows choose   Enter play   Esc menu",
    pauseHelp = "Esc / P resume   Arrows choose   Enter confirm",
    settingsHelp = "Left / Right switch   Esc back",
    language = "Language",
    languageValue = "English",
    back = "Back",
    locked = "LOCKED ",
    restart = "R restart   P/Esc pause   Tab trail",
    shadowReady = "Shadow: 4s behind",
    shadowForming = "Shadow forming...",
    complete = "Level Complete",
    completeHelp = "Enter: next level    R: replay    Esc: level select",
  },
  zh = {
    title = "影子二重奏",
    subtitle = "原创像素时间回声解谜平台游戏",
    menuHelp = "按 Enter / 空格开始   点选开始游戏",
    start = "开始游戏",
    levelSelect = "关卡选择",
    settings = "设置",
    paused = "暂停",
    resume = "继续",
    restartLevel = "重开关卡",
    mainMenu = "主菜单",
    quit = "退出",
    controls = "A/D 移动   空格 跳跃   R 重试",
    missionBoard = "任务板",
    missionHelp = "选择一个短小解谜任务",
    missionDone = "已完成",
    missionOpen = "可挑战",
    tagMove = "移动",
    tagShadow = "影子",
    tagButton = "按钮",
    tagDoor = "门",
    tagLaser = "激光",
    tagCrate = "箱子",
    choose = "方向键选择   回车开始   Esc 返回",
    pauseHelp = "Esc / P 继续   方向键选择   回车确认",
    settingsHelp = "左右键切换语言   Esc 返回",
    language = "语言",
    languageValue = "中文",
    back = "返回",
    locked = "锁定 ",
    restart = "R 重开   P/Esc 暂停   Tab 轨迹",
    shadowReady = "影子：落后 4 秒",
    shadowForming = "影子生成中...",
    complete = "关卡完成",
    completeHelp = "回车 下一关    R 重玩    Esc 关卡选择",
  },
}

local function tr(key)
  local pack = I18N[save.lang] or I18N.en
  return pack[key] or I18N.en[key] or key
end

local function toggleLanguage()
  save.lang = save.lang == "zh" and "en" or "zh"
  writeSave()
end

local function levelName(level)
  return save.lang == "zh" and (level.nameZh or level.name) or level.name
end

local function levelHint(level)
  return save.lang == "zh" and (level.hintZh or level.hint) or level.hint
end

local function clamp(v, a, b)
  if v < a then return a end
  if v > b then return b end
  return v
end

local function lerp(a, b, t)
  return a + (b - a) * t
end

local function rectsOverlap(a, b)
  return a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h
end

local function copyRect(r)
  local out = {}
  for k, v in pairs(r) do out[k] = v end
  return out
end

local function cloneLevel(src)
  local out = {
    name = src.name,
    nameZh = src.nameZh,
    hint = src.hint,
    hintZh = src.hintZh,
    start = copyRect(src.start),
    goal = copyRect(src.goal),
    solids = {},
    boxes = {},
    buttons = {},
    doors = {},
    lasers = {},
  }
  for _, r in ipairs(src.solids or {}) do table.insert(out.solids, copyRect(r)) end
  for _, r in ipairs(src.boxes or {}) do
    local b = copyRect(r)
    b.vx = b.vx or 0
    table.insert(out.boxes, b)
  end
  for _, r in ipairs(src.buttons or {}) do table.insert(out.buttons, copyRect(r)) end
  for _, r in ipairs(src.doors or {}) do
    local d = copyRect(r)
    d.open = false
    table.insert(out.doors, d)
  end
  for _, r in ipairs(src.lasers or {}) do
    local l = copyRect(r)
    l.blocked = false
    table.insert(out.lasers, l)
  end
  return out
end

local function serialize(v)
  if type(v) == "number" or type(v) == "boolean" then
    return tostring(v)
  elseif type(v) == "string" then
    return string.format("%q", v)
  elseif type(v) == "table" then
    local parts = {"{"}
    for k, val in pairs(v) do
      local key
      if type(k) == "number" then key = "[" .. k .. "]" else key = "[" .. serialize(k) .. "]" end
      table.insert(parts, key .. "=" .. serialize(val) .. ",")
    end
    table.insert(parts, "}")
    return table.concat(parts)
  end
  return "nil"
end

local function loadSave()
  local info = love.filesystem.getInfo("save.lua")
  if not info then return end
  local chunk = love.filesystem.load("save.lua")
  if not chunk then return end
  local ok, data = pcall(chunk)
  if ok and type(data) == "table" then
    save.unlocked = clamp(tonumber(data.unlocked) or 1, 1, #levels)
    save.completed = type(data.completed) == "table" and data.completed or {}
    if data.lang == "zh" or data.lang == "en" then save.lang = data.lang end
  end
end

writeSave = function()
  love.filesystem.write("save.lua", "return " .. serialize(save))
end

local function makePlayer(x, y)
  return {
    x = x, y = y, w = 20, h = 30,
    vx = 0, vy = 0,
    facing = 1,
    onGround = false,
    coyote = 0,
    jumpBuffer = 0,
    dead = false,
    deathTimer = 0,
  }
end

local function makeRecorder(player)
  return {
    time = 0,
    frames = {{time = 0, x = player.x, y = player.y, vx = 0, vy = 0, facing = 1, grounded = false}},
  }
end

local function recordFrame(rec, player)
  table.insert(rec.frames, {
    time = rec.time,
    x = player.x,
    y = player.y,
    vx = player.vx,
    vy = player.vy,
    facing = player.facing,
    grounded = player.onGround,
  })
  if #rec.frames > 2400 then
    table.remove(rec.frames, 1)
  end
end

local function sampleRecorder(rec, targetTime)
  if targetTime < 0 or #rec.frames == 0 then return nil end
  if targetTime <= rec.frames[1].time then return rec.frames[1] end
  for i = #rec.frames - 1, 1, -1 do
    local a, b = rec.frames[i], rec.frames[i + 1]
    if a.time <= targetTime and targetTime <= b.time then
      local denom = b.time - a.time
      local t = denom > 0 and (targetTime - a.time) / denom or 0
      return {
        time = targetTime,
        x = lerp(a.x, b.x, t),
        y = lerp(a.y, b.y, t),
        vx = lerp(a.vx, b.vx, t),
        vy = lerp(a.vy, b.vy, t),
        facing = math.abs(a.facing) >= math.abs(b.facing) and a.facing or b.facing,
        grounded = a.grounded or b.grounded,
      }
    end
  end
  return rec.frames[#rec.frames]
end

local function staticSolids(level)
  local solids = {}
  for _, s in ipairs(level.solids) do table.insert(solids, s) end
  for _, d in ipairs(level.doors) do
    if not d.open then table.insert(solids, d) end
  end
  return solids
end

local function activeSolids(level)
  local solids = staticSolids(level)
  for _, b in ipairs(level.boxes or {}) do table.insert(solids, b) end
  return solids
end

local function resolveAxis(player, solids, axis)
  for _, s in ipairs(solids) do
    if rectsOverlap(player, s) then
      if axis == "x" then
        if player.vx > 0 then player.x = s.x - player.w
        elseif player.vx < 0 then player.x = s.x + s.w end
        player.vx = 0
      else
        if player.vy > 0 then
          player.y = s.y - player.h
          player.onGround = true
        elseif player.vy < 0 then
          player.y = s.y + s.h
        end
        player.vy = 0
      end
    end
  end
end

local function moveBoxX(box, dx, level)
  if dx == 0 then return end
  box.x = box.x + dx
  for _, s in ipairs(staticSolids(level)) do
    if rectsOverlap(box, s) then
      if dx > 0 then box.x = s.x - box.w else box.x = s.x + s.w end
      return
    end
  end
  for _, other in ipairs(level.boxes or {}) do
    if other ~= box and rectsOverlap(box, other) then
      if dx > 0 then box.x = other.x - box.w else box.x = other.x + other.w end
      return
    end
  end
end

local function pushBoxes(actor, level, dt, strength)
  for _, box in ipairs(level.boxes or {}) do
    if rectsOverlap(actor, box) then
      local dir = (actor.vx and math.abs(actor.vx) > 8) and (actor.vx > 0 and 1 or -1) or (actor.facing or 1)
      local push = dir * (strength or 165) * dt
      local oldX = box.x
      moveBoxX(box, push, level)
      if math.abs(box.x - oldX) < 0.01 and actor.w then
        if dir > 0 then actor.x = box.x - actor.w else actor.x = box.x + box.w end
        actor.vx = 0
      end
    end
  end
end

local function movePlayer(player, dt, level)
  local left = love.keyboard.isDown("a", "left")
  local right = love.keyboard.isDown("d", "right")
  local jumpHeld = love.keyboard.isDown("space", "w", "up")
  local input = (right and 1 or 0) - (left and 1 or 0)

  local accel, maxSpeed, friction = 1120, 175, 1450
  local gravity, jumpSpeed = 980, -430

  if input ~= 0 then
    player.vx = player.vx + input * accel * dt
    player.facing = input
  else
    if math.abs(player.vx) <= friction * dt then player.vx = 0
    else player.vx = player.vx - friction * dt * (player.vx > 0 and 1 or -1) end
  end
  player.vx = clamp(player.vx, -maxSpeed, maxSpeed)

  player.coyote = player.onGround and 0.11 or math.max(0, player.coyote - dt)
  player.jumpBuffer = math.max(0, player.jumpBuffer - dt)
  if player.jumpBuffer > 0 and player.coyote > 0 then
    player.vy = jumpSpeed
    player.jumpBuffer = 0
    player.coyote = 0
  end

  if not jumpHeld and player.vy < -115 then
    player.vy = -115
  end

  player.vy = player.vy + gravity * dt
  player.vy = clamp(player.vy, -600, 720)

  player.x = player.x + player.vx * dt
  resolveAxis(player, staticSolids(level), "x")
  pushBoxes(player, level, dt, 175)

  player.onGround = false
  player.y = player.y + player.vy * dt
  resolveAxis(player, activeSolids(level), "y")

  if player.y > H + 80 then
    player.dead = true
  end
end

local function resetLevel(index)
  local level = cloneLevel(levels[index])
  local player = makePlayer(level.start.x, level.start.y)
  game = {
    levelIndex = index,
    level = level,
    player = player,
    recorder = makeRecorder(player),
    shadow = nil,
    completed = false,
    completeTimer = 0,
    time = 0,
    flash = 0,
  }
  state = "play"
end

local function completeLevel()
  if game.completed then return end
  game.completed = true
  game.completeTimer = 0
  save.completed[game.levelIndex] = true
  save.unlocked = math.max(save.unlocked, math.min(#levels, game.levelIndex + 1))
  writeSave()
end

local function killPlayer()
  if game.player.dead then return end
  game.player.dead = true
  game.player.deathTimer = 0
  game.flash = 0.18
end

local function updateShadow()
  local rec = game.recorder
  local sample = sampleRecorder(rec, rec.time - DELAY)
  if sample then
    game.shadow = {x = sample.x, y = sample.y, w = 20, h = 30, vx = sample.vx or 0, facing = sample.facing}
  else
    game.shadow = nil
  end
end

local function shadowBlocksLaser(shadow, laser)
  if not shadow then return false end
  local disruptMargin = laser.disruptMargin or 44
  local horizontallyAligned = shadow.x < laser.x + laser.w + disruptMargin and laser.x - disruptMargin < shadow.x + shadow.w
  local reachesBeam = shadow.y + shadow.h >= laser.y - 4 and shadow.y <= laser.y + laser.h
  return horizontallyAligned and reachesBeam
end

local function updateMechanisms()
  local level = game.level
  local player = game.player
  local shadow = game.shadow
  if shadow then pushBoxes(shadow, level, 1 / 60, 115) end
  for _, b in ipairs(level.buttons) do
    local boxActive = false
    for _, box in ipairs(level.boxes or {}) do
      if rectsOverlap(box, b) then boxActive = true; break end
    end
    b.active = rectsOverlap(player, b) or (shadow and rectsOverlap(shadow, b)) or boxActive or false
  end
  for _, d in ipairs(level.doors) do
    d.open = false
    for _, b in ipairs(level.buttons) do
      if b.target == d.id and b.active then d.open = true end
    end
  end
  for _, l in ipairs(level.lasers) do
    l.blocked = shadowBlocksLaser(shadow, l)
  end
end

local function updatePlay(dt)
  dt = math.min(dt, 1 / 30)
  local player = game.player

  if game.completed then
    game.completeTimer = game.completeTimer + dt
    return
  end

  if game.flash > 0 then game.flash = math.max(0, game.flash - dt) end

  if player.dead then
    player.deathTimer = player.deathTimer + dt
    if player.deathTimer > 0.55 then
      resetLevel(game.levelIndex)
    end
    return
  end

  game.time = game.time + dt
  game.recorder.time = game.recorder.time + dt
  updateShadow()
  updateMechanisms()

  movePlayer(player, dt, game.level)
  recordFrame(game.recorder, player)
  updateShadow()
  updateMechanisms()

  for _, l in ipairs(game.level.lasers) do
    if not l.blocked and rectsOverlap(player, l) then killPlayer() end
  end

  if rectsOverlap(player, game.level.goal) then
    completeLevel()
  end
end

local function drawRect(r, color, mode)
  love.graphics.setColor(color)
  love.graphics.rectangle(mode or "fill", math.floor(r.x), math.floor(r.y), math.floor(r.w), math.floor(r.h))
end

local function mixColor(a, b, t)
  return {
    lerp(a[1], b[1], t),
    lerp(a[2], b[2], t),
    lerp(a[3], b[3], t),
    lerp(a[4] or 1, b[4] or 1, t),
  }
end

local function setColor(c, alpha)
  love.graphics.setColor(c[1], c[2], c[3], alpha or c[4] or 1)
end

local function pixelRect(x, y, w, h, color, alpha)
  setColor(color, alpha)
  love.graphics.rectangle("fill", math.floor(x), math.floor(y), math.floor(w), math.floor(h))
end

local function panel(x, y, w, h, selected)
  love.graphics.setColor(0.01, 0.015, 0.04, 0.52)
  love.graphics.rectangle("fill", x + 8, y + 8, w, h)
  setColor(selected and {0.12, 0.20, 0.36, 0.94} or COLORS.panel)
  love.graphics.rectangle("fill", x, y, w, h)
  love.graphics.setColor(selected and 0.58 or 0.24, selected and 0.92 or 0.42, 1.0, selected and 0.95 or 0.58)
  love.graphics.setLineWidth(3)
  love.graphics.rectangle("line", x + 1, y + 1, w - 2, h - 2)
  love.graphics.setLineWidth(1)
end

local function textShadow(text, x, y, limit, align, f, color)
  love.graphics.setFont(f or font)
  love.graphics.setColor(0.01, 0.02, 0.06, 0.88)
  love.graphics.printf(text, x + 3, y + 3, limit, align or "left")
  setColor(color or COLORS.text)
  love.graphics.printf(text, x, y, limit, align or "left")
end

local function drawMountains(baseY, color, peaks, snowAlpha)
  setColor(color)
  local pts = {0, H}
  for _, p in ipairs(peaks) do
    table.insert(pts, p[1])
    table.insert(pts, p[2] + baseY)
  end
  table.insert(pts, W)
  table.insert(pts, H)
  love.graphics.polygon("fill", pts)
  love.graphics.setColor(0.80, 0.93, 1.00, snowAlpha or 0.22)
  for _, p in ipairs(peaks) do
    love.graphics.polygon("fill", p[1] - 34, p[2] + baseY + 72, p[1], p[2] + baseY, p[1] + 42, p[2] + baseY + 80)
  end
end

local function drawBackground()
  love.graphics.clear(COLORS.skyTop)
  for y = 0, H, 6 do
    local t = y / H
    local c = t < 0.58 and mixColor(COLORS.skyTop, COLORS.skyMid, t / 0.58) or mixColor(COLORS.skyMid, COLORS.skyLow, (t - 0.58) / 0.42)
    setColor(c)
    love.graphics.rectangle("fill", 0, y, W, 6)
  end

  love.graphics.setColor(1.0, 0.86, 0.66, 0.92)
  love.graphics.circle("fill", 795, 88, 34)
  love.graphics.setColor(1.0, 0.72, 0.56, 0.20)
  love.graphics.circle("fill", 795, 88, 54)

  for i = 1, 70 do
    local x = (i * 137) % W
    local y = 22 + ((i * 71) % 210)
    local a = 0.26 + ((i % 5) * 0.10)
    love.graphics.setColor(0.82, 0.94, 1.0, a)
    local s = (i % 4 == 0) and 2 or 1
    love.graphics.rectangle("fill", x, y, s, s)
  end

  drawMountains(182, COLORS.mountainFar, {{-50, 144}, {90, 52}, {205, 125}, {345, 38}, {520, 142}, {670, 76}, {820, 138}, {1005, 48}}, 0.10)
  drawMountains(242, COLORS.mountainMid, {{-20, 126}, {120, 18}, {260, 112}, {410, 42}, {585, 132}, {735, 30}, {895, 122}, {1010, 58}}, 0.18)
  drawMountains(325, COLORS.mountainNear, {{-40, 120}, {90, 52}, {220, 102}, {380, 18}, {530, 112}, {690, 54}, {840, 124}, {1010, 42}}, 0.26)

  love.graphics.setColor(0.75, 0.92, 1.0, 0.08)
  for y = 330, 500, 34 do
    love.graphics.rectangle("fill", 0, y, W, 8)
  end
end

local function drawTrail()
  if not game then return end
  local frames = game.recorder.frames
  love.graphics.setColor(0.2, 0.9, 1.0, 0.10)
  for i = math.max(1, #frames - 260), #frames, 10 do
    local f = frames[i]
    love.graphics.rectangle("fill", f.x + 7, f.y + 10, 6, 6, 3, 3)
  end
  if love.keyboard.isDown("tab") then
    love.graphics.setColor(0.95, 0.95, 1.0, 0.42)
    local startTime = math.max(0, game.recorder.time - DELAY)
    local last = nil
    for step = 0, 32 do
      local sample = sampleRecorder(game.recorder, lerp(startTime, game.recorder.time, step / 32))
      if sample then
        local cx, cy = sample.x + 10, sample.y + 15
        love.graphics.circle("fill", cx, cy, 3)
        if last then love.graphics.line(last.x, last.y, cx, cy) end
        last = {x = cx, y = cy}
      end
    end
  end
end

local function drawPlatform(s)
  love.graphics.setColor(0.018, 0.026, 0.062, 0.50)
  love.graphics.rectangle("fill", s.x + 6, s.y + 7, s.w, s.h)
  pixelRect(s.x, s.y, s.w, s.h, COLORS.solid)
  pixelRect(s.x, s.y, s.w, 5, COLORS.snow)
  love.graphics.setColor(0.26, 0.78, 1.0, 0.55)
  love.graphics.rectangle("line", s.x + 0.5, s.y + 0.5, s.w - 1, s.h - 1)
  love.graphics.setColor(0.54, 0.90, 1.0, 0.34)
  for x = s.x + 12, s.x + s.w - 12, 34 do
    love.graphics.line(x, s.y + 7, x + 10, s.y + s.h - 5)
  end
end

local function drawButton(b)
  local glow = b.active and 0.40 or 0.14
  love.graphics.setColor(1.0, 0.72, 0.18, glow)
  love.graphics.rectangle("fill", b.x - 8, b.y - 12, b.w + 16, b.h + 20)
  pixelRect(b.x, b.y - 4, b.w, b.h + 4, b.active and COLORS.buttonOn or COLORS.buttonOff)
  pixelRect(b.x + 7, b.y - 8, b.w - 14, 4, b.active and {1.0, 1.0, 0.70} or {0.86, 0.32, 0.18})
  love.graphics.setColor(0.30, 0.12, 0.05, 0.45)
  love.graphics.rectangle("line", b.x, b.y - 8, b.w, b.h + 8)
end

local function drawDoor(d)
  if d.open then
    love.graphics.setColor(COLORS.door[1], COLORS.door[2], COLORS.door[3], 0.18)
    love.graphics.rectangle("line", d.x - 3, d.y - 3, d.w + 6, d.h + 6)
    love.graphics.setColor(0.82, 0.95, 1.0, 0.20)
    for y = d.y, d.y + d.h, 14 do love.graphics.line(d.x - 4, y, d.x + d.w + 4, y + 4) end
    return
  end
  love.graphics.setColor(0.04, 0.08, 0.16, 0.72)
  love.graphics.rectangle("fill", d.x + 5, d.y + 5, d.w, d.h)
  pixelRect(d.x, d.y, d.w, d.h, COLORS.door)
  pixelRect(d.x + 5, d.y + 6, d.w - 10, d.h - 12, {0.05, 0.18, 0.40})
  love.graphics.setColor(0.42, 0.88, 1.0, 0.82)
  love.graphics.rectangle("line", d.x + 1, d.y + 1, d.w - 2, d.h - 2)
  for y = d.y + 10, d.y + d.h - 8, 16 do love.graphics.line(d.x + 5, y, d.x + d.w - 5, y + 5) end
end

local function drawGoal(g)
  love.graphics.setColor(COLORS.goal[1], COLORS.goal[2], COLORS.goal[3], 0.24)
  love.graphics.rectangle("fill", g.x - 12, g.y - 12, g.w + 24, g.h + 24)
  pixelRect(g.x, g.y, g.w, g.h, {0.08, 0.45, 0.28})
  pixelRect(g.x + 6, g.y + 6, g.w - 12, g.h - 12, COLORS.goal)
  love.graphics.setColor(0.74, 1.0, 0.82, 0.70)
  love.graphics.rectangle("line", g.x - 4, g.y - 4, g.w + 8, g.h + 8)
end

local function drawLaser(l)
  love.graphics.setColor(COLORS.laser[1], COLORS.laser[2], COLORS.laser[3], l.blocked and 0.16 or 0.36)
  love.graphics.rectangle("fill", l.x - 12, l.y, l.w + 24, l.h)
  love.graphics.setColor(COLORS.laser[1], COLORS.laser[2], COLORS.laser[3], l.blocked and 0.28 or 0.88)
  love.graphics.rectangle("fill", l.x, l.y, l.w, l.h)
  love.graphics.setColor(1.0, 0.75, 0.80, l.blocked and 0.22 or 0.82)
  love.graphics.rectangle("fill", l.x + 5, l.y, math.max(2, l.w - 10), l.h)
end

local function drawBox(b)
  love.graphics.setColor(0.02, 0.02, 0.06, 0.38)
  love.graphics.rectangle("fill", b.x + 5, b.y + 5, b.w, b.h)
  pixelRect(b.x, b.y, b.w, b.h, {0.55, 0.36, 0.22})
  pixelRect(b.x + 4, b.y + 4, b.w - 8, b.h - 8, {0.76, 0.50, 0.28})
  love.graphics.setColor(1.0, 0.82, 0.48, 0.44)
  love.graphics.line(b.x + 5, b.y + 5, b.x + b.w - 5, b.y + b.h - 5)
  love.graphics.line(b.x + b.w - 5, b.y + 5, b.x + 5, b.y + b.h - 5)
  love.graphics.setColor(0.25, 0.12, 0.06, 0.72)
  love.graphics.rectangle("line", b.x + 0.5, b.y + 0.5, b.w - 1, b.h - 1)
end

local function drawCharacter(x, y, facing, ghost)
  local dir = facing >= 0 and 1 or -1
  local sx = math.floor(x - 3)
  local sy = math.floor(y - 4)
  local function px(ox, oy, w, h, c, a)
    pixelRect(sx + ox, sy + oy, w, h, c, a)
  end
  local function pxFace(rightOx, leftOx, oy, w, h, c, a)
    px(dir > 0 and rightOx or leftOx, oy, w, h, c, a)
  end

  if ghost then
    love.graphics.setColor(0.12, 0.92, 1.0, 0.11)
    love.graphics.rectangle("fill", sx - 8, sy - 4, 40, 46)
    love.graphics.setColor(0.18, 0.92, 1.0, 0.20)
    love.graphics.rectangle("line", sx - 5, sy - 1, 33, 39)
    px(5, 4, 17, 11, {0.62, 1.0, 1.0, 0.38})
    px(4, 12, 18, 18, {0.16, 0.82, 1.0, 0.42})
    pxFace(18, 0, 17, 10, 4, {0.10, 0.95, 1.0, 0.30})
    pxFace(-3, 22, 16, 10, 3, {0.35, 1.0, 1.0, 0.28})
    px(6, 30, 5, 5, {0.20, 0.96, 1.0, 0.38})
    px(15, 30, 5, 5, {0.20, 0.96, 1.0, 0.38})
    pxFace(15, 7, 8, 3, 3, {1, 1, 1, 0.46})
    return
  end

  love.graphics.setColor(0.02, 0.02, 0.06, 0.35)
  love.graphics.rectangle("fill", sx + 5, sy + 7, 22, 31)

  -- dark outline
  px(6, 2, 15, 4, {0.035, 0.030, 0.060})
  px(3, 6, 21, 10, {0.035, 0.030, 0.060})
  px(4, 15, 20, 18, {0.035, 0.030, 0.060})
  pxFace(20, -2, 18, 8, 5, {0.035, 0.030, 0.060})
  pxFace(-5, 22, 17, 10, 4, {0.035, 0.030, 0.060})
  px(5, 31, 7, 5, {0.035, 0.030, 0.060})
  px(15, 31, 7, 5, {0.035, 0.030, 0.060})

  -- hair and face
  px(7, 2, 13, 5, COLORS.playerHair)
  px(4, 7, 18, 5, COLORS.playerHair)
  px(5, 10, 16, 8, COLORS.playerSkin)
  px(4, 8, 6, 7, COLORS.playerHair)
  pxFace(16, 7, 11, 3, 3, COLORS.playerCore)
  pxFace(19, 3, 9, 4, 3, COLORS.playerHair)

  -- coat, scarf and arms
  px(5, 18, 18, 13, COLORS.playerCoat)
  px(8, 18, 11, 4, {1.0, 0.44, 0.56})
  pxFace(1, 18, 16, 11, 4, COLORS.playerScarf)
  pxFace(-5, 22, 24, 11, 3, COLORS.playerScarf)
  pxFace(20, -1, 19, 8, 5, {0.95, 0.32, 0.46})

  -- legs and boots
  px(7, 30, 5, 5, COLORS.playerBoot)
  px(15, 30, 5, 5, COLORS.playerBoot)
  px(5, 34, 8, 3, COLORS.playerBoot)
  px(14, 34, 8, 3, COLORS.playerBoot)

  -- highlights
  px(7, 20, 2, 8, {1.0, 0.62, 0.70})
  px(11, 12, 3, 2, {1.0, 0.88, 0.70})
  pxFace(20, 4, 21, 2, 2, {1.0, 0.70, 0.76})
end

local function drawLevel()
  local level = game.level
  drawBackground()
  drawTrail()

  for _, s in ipairs(level.solids) do drawPlatform(s) end

  for _, b in ipairs(level.buttons) do drawButton(b) end

  for _, d in ipairs(level.doors) do drawDoor(d) end

  for _, l in ipairs(level.lasers) do drawLaser(l) end

  drawGoal(level.goal)

  for _, b in ipairs(level.boxes or {}) do drawBox(b) end

  if game.shadow then
    drawCharacter(game.shadow.x, game.shadow.y, game.shadow.facing, true)
  end

  local p = game.player
  drawCharacter(p.x, p.y, p.facing, false)

  love.graphics.setFont(font)
  panel(14, 12, 540, 60, false)
  textShadow(levelName(level), 30, 20, 500, "left", font, COLORS.text)
  love.graphics.setColor(COLORS.muted)
  love.graphics.print(levelHint(level), 30, 43)
  love.graphics.setColor(COLORS.muted)
  love.graphics.print(tr("restart"), 24, H - 32)

  local ready = clamp(game.recorder.time / DELAY, 0, 1)
  panel(W - 255, 14, 220, 50, false)
  love.graphics.setColor(0.07, 0.10, 0.20)
  love.graphics.rectangle("fill", W - 235, 26, 190, 12)
  love.graphics.setColor(0.2, 0.92, 1.0, 0.80)
  love.graphics.rectangle("fill", W - 235, 26, 190 * ready, 12)
  love.graphics.setColor(COLORS.muted)
  love.graphics.print(game.shadow and tr("shadowReady") or tr("shadowForming"), W - 235, 42)

  if p.dead then
    love.graphics.setColor(1, 0.1, 0.18, 0.25)
    love.graphics.rectangle("fill", 0, 0, W, H)
  end

  if game.flash > 0 then
    love.graphics.setColor(1, 0.15, 0.22, game.flash)
    love.graphics.rectangle("fill", 0, 0, W, H)
  end

  if game.completed then
    love.graphics.setColor(0, 0, 0, 0.55)
    love.graphics.rectangle("fill", 0, 0, W, H)
    love.graphics.setFont(bigFont)
    love.graphics.setColor(0.65, 1.0, 0.78)
    love.graphics.printf(tr("complete"), 0, 208, W, "center")
    love.graphics.setFont(font)
    love.graphics.setColor(COLORS.text)
    love.graphics.printf(tr("completeHelp"), 0, 260, W, "center")
  end
end

local function menuOptionBounds(index)
  local y = 232 + index * 58
  return 330, y - 12, 300, 42
end

local function activateMenuOption(index)
  if index == 1 then resetLevel(math.min(save.unlocked, #levels)) end
  if index == 2 then state = "select" end
  if index == 3 then settingsReturnState = "menu"; state = "settings" end
  if index == 4 then love.event.quit() end
end

local function drawMenu()
  drawBackground()
  love.graphics.setColor(0.05, 0.16, 0.26, 0.40)
  for i = 1, 18 do
    local x = 55 + i * 46
    local y = 330 + (i % 3) * 22
    love.graphics.polygon("fill", x, y - 18, x + 14, y, x, y + 18, x - 14, y)
    love.graphics.setColor(0.34, 0.90, 1.0, 0.25)
    love.graphics.line(x, y - 18, x, y + 18)
    love.graphics.setColor(0.05, 0.16, 0.26, 0.40)
  end

  love.graphics.setFont(titleFont)
  love.graphics.setColor(0.02, 0.02, 0.06, 0.88)
  love.graphics.printf(tr("title"), 5, 91, W, "center")
  love.graphics.setColor(0.12, 0.95, 1.0, 0.28)
  love.graphics.printf(tr("title"), -4, 86, W, "center")
  love.graphics.setColor(0.96, 0.98, 1.0)
  love.graphics.printf(tr("title"), 0, 88, W, "center")
  love.graphics.setFont(font)
  textShadow(tr("subtitle"), 0, 156, W, "center", font, COLORS.muted)

  love.graphics.setColor(0.10, 0.22, 0.36, 0.72)
  love.graphics.rectangle("fill", 216, 184, 528, 30, 8, 8)
  love.graphics.setColor(0.34, 0.90, 1.0, 0.48)
  love.graphics.rectangle("line", 216.5, 184.5, 527, 29, 8, 8)
  love.graphics.setColor(0.82, 0.94, 1.0, 0.88)
  love.graphics.printf(tr("menuHelp"), 226, 190, 508, "center")

  local options = {tr("start"), tr("levelSelect"), tr("settings"), tr("quit")}
  for i, text in ipairs(options) do
    local x, y, w, h = menuOptionBounds(i)
    local selected = i == menuIndex
    panel(x, y, w, h, selected)
    love.graphics.setColor(selected and COLORS.player or COLORS.muted)
    love.graphics.printf((selected and "◆  " or "◇  ") .. text, x, y + 12, w, "center")
  end

  love.graphics.setColor(0.76, 0.86, 1.0, 0.58)
  love.graphics.printf(tr("controls"), 0, H - 48, W, "center")
end

local function levelTags(level, index)
  local tags = {}
  if index == 1 then table.insert(tags, tr("tagMove")) end
  if index >= 3 then table.insert(tags, tr("tagShadow")) end
  if #(level.buttons or {}) > 0 then table.insert(tags, tr("tagButton")) end
  if #(level.doors or {}) > 0 then table.insert(tags, tr("tagDoor")) end
  if #(level.lasers or {}) > 0 then table.insert(tags, tr("tagLaser")) end
  if #(level.boxes or {}) > 0 then table.insert(tags, tr("tagCrate")) end
  return tags
end

local function drawChip(text, x, y, selected, disabled)
  local w = 22 + #text * (save.lang == "zh" and 15 or 7)
  love.graphics.setColor(disabled and 0.06 or 0.08, disabled and 0.07 or 0.16, disabled and 0.10 or 0.27, disabled and 0.55 or 0.92)
  love.graphics.rectangle("fill", x, y, w, 18)
  love.graphics.setColor(selected and 0.58 or 0.24, selected and 0.95 or 0.60, 1.0, disabled and 0.20 or 0.72)
  love.graphics.rectangle("line", x + 0.5, y + 0.5, w - 1, 17)
  love.graphics.setColor(disabled and {0.35, 0.38, 0.48, 1} or COLORS.muted)
  love.graphics.print(text, x + 10, y + 1)
  return w
end

local function drawLevelSelect()
  drawBackground()
  textShadow(tr("missionBoard"), 0, 42, W, "center", bigFont, COLORS.text)
  love.graphics.setFont(font)
  textShadow(tr("missionHelp"), 0, 84, W, "center", font, COLORS.muted)
  textShadow(tr("choose"), 0, 112, W, "center", font, COLORS.muted)

  local cols, cellW, cellH = 4, 206, 88
  local startX, startY = 66, 158
  for i, level in ipairs(levels) do
    local col = (i - 1) % cols
    local row = math.floor((i - 1) / cols)
    local x, y = startX + col * cellW, startY + row * cellH
    local unlocked = i <= save.unlocked
    local selected = i == selectIndex

    if selected then
      love.graphics.setColor(0.20, 0.88, 1.0, 0.22)
      love.graphics.rectangle("fill", x - 8, y - 8, 188, 76)
    end
    panel(x, y, 176, 64, selected)

    love.graphics.setColor(unlocked and (selected and 0.20 or 0.10) or 0.05, unlocked and 0.52 or 0.08, unlocked and 0.72 or 0.12, unlocked and 0.92 or 0.55)
    love.graphics.polygon("fill", x + 14, y + 9, x + 36, y + 9, x + 48, y + 21, x + 36, y + 33, x + 14, y + 33, x + 2, y + 21)
    love.graphics.setColor(0.88, 0.97, 1.0, unlocked and 0.95 or 0.35)
    love.graphics.printf(string.format("%02d", i), x + 2, y + 14, 46, "center")

    if not unlocked then
      love.graphics.setColor(0.02, 0.02, 0.05, 0.54)
      love.graphics.rectangle("fill", x, y, 176, 64)
    end

    love.graphics.setColor(unlocked and COLORS.text or {0.42, 0.46, 0.58, 1})
    local title = unlocked and levelName(level) or (tr("locked") .. string.format("%02d", i))
    love.graphics.printf(title, x + 50, y + 10, 116, "left")

    local status = save.completed[i] and tr("missionDone") or tr("missionOpen")
    love.graphics.setColor(save.completed[i] and {0.56, 1.0, 0.70, 1} or COLORS.muted)
    love.graphics.printf(save.completed[i] and ("✓ " .. status) or status, x + 50, y + 34, 116, "left")

    local cx = x + 10
    for _, tag in ipairs(levelTags(level, i)) do
      local w = drawChip(tag, cx, y + 70, selected, not unlocked)
      cx = cx + w + 6
      if cx > x + 158 then break end
    end
  end

  local selectedLevel = levels[selectIndex]
  panel(112, 438, 736, 58, true)
  love.graphics.setColor(COLORS.text)
  love.graphics.printf(levelName(selectedLevel), 132, 449, 210, "left")
  love.graphics.setColor(COLORS.muted)
  love.graphics.printf(levelHint(selectedLevel), 342, 449, 486, "left")
end

local function drawSettings()
  drawBackground()
  textShadow(tr("settings"), 0, 66, W, "center", bigFont, COLORS.text)
  textShadow(tr("settingsHelp"), 0, 112, W, "center", font, COLORS.muted)

  local rows = {
    {label = tr("language"), value = tr("languageValue")},
    {label = tr("back"), value = ""},
  }
  for i, row in ipairs(rows) do
    local y = 206 + i * 70
    local selected = i == settingsIndex
    panel(265, y - 14, 430, 50, selected)
    love.graphics.setColor(selected and COLORS.player or COLORS.text)
    if i == 1 then
      love.graphics.printf(row.label, 290, y, 160, "left")
      love.graphics.printf("◀  " .. row.value .. "  ▶", 455, y, 210, "right")
    else
      love.graphics.printf(row.label, 265, y, 430, "center")
    end
  end
end

local function drawPause()
  if game then drawLevel() else drawBackground() end
  love.graphics.setColor(0.01, 0.015, 0.040, 0.66)
  love.graphics.rectangle("fill", 0, 0, W, H)
  panel(300, 94, 360, 352, false)
  textShadow(tr("paused"), 300, 122, 360, "center", bigFont, COLORS.text)
  textShadow(tr("pauseHelp"), 250, 170, 460, "center", font, COLORS.muted)

  local options = {tr("resume"), tr("restartLevel"), tr("levelSelect"), tr("settings"), tr("mainMenu")}
  for i, text in ipairs(options) do
    local y = 202 + i * 44
    local selected = i == pauseIndex
    panel(350, y - 10, 260, 34, selected)
    love.graphics.setColor(selected and COLORS.player or COLORS.muted)
    love.graphics.printf((selected and "◆  " or "◇  ") .. text, 350, y - 2, 260, "center")
  end
end

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")
  local cjkFont = "assets/fonts/LXGWWenKai-Regular.ttf"
  font = love.graphics.newFont(cjkFont, 15)
  bigFont = love.graphics.newFont(cjkFont, 28)
  titleFont = love.graphics.newFont(cjkFont, 48)
  loadSave()

  local autoshot = os.getenv("SHADOW_DUET_AUTOSHOT")
  if autoshot == "1" or autoshot == "shadow" then
    resetLevel(3)
    local groundY = 450
    game.player.x = 580
    game.player.y = groundY
    game.player.vx = 0
    game.player.vy = 0
    game.player.onGround = true
    game.recorder.time = 5.2
    game.recorder.frames = {
      {time = 1.18, x = 214, y = groundY, vx = 0, vy = 0, facing = 1, grounded = true},
      {time = 1.22, x = 218, y = groundY, vx = 0, vy = 0, facing = 1, grounded = true},
      {time = 5.2, x = 580, y = groundY, vx = 0, vy = 0, facing = 1, grounded = true},
    }
    updateShadow()
    updateMechanisms()
  elseif autoshot == "box" then
    resetLevel(6)
    game.player.x = 455
    game.player.y = 450
    game.player.facing = 1
    if game.level.boxes[1] then game.level.boxes[1].x = 402 end
    updateShadow()
    updateMechanisms()
  end
end

function love.update(dt)
  if state == "play" and game then updatePlay(dt) end
end

function love.draw()
  love.graphics.push()
  love.graphics.scale(SCALE, SCALE)
  if state == "menu" then drawMenu()
  elseif state == "select" then drawLevelSelect()
  elseif state == "settings" then drawSettings()
  elseif state == "pause" then drawPause()
  elseif state == "play" and game then drawLevel() end
  love.graphics.pop()
end

function love.keypressed(key)
  if key == "f11" then
    love.window.setFullscreen(not love.window.getFullscreen())
    return
  end

  if state == "menu" then
    if key == "up" or key == "w" then menuIndex = menuIndex - 1 end
    if key == "down" or key == "s" then menuIndex = menuIndex + 1 end
    menuIndex = ((menuIndex - 1) % 4) + 1
    if key == "return" or key == "space" then
      activateMenuOption(menuIndex)
    end
  elseif state == "select" then
    if key == "escape" then state = "menu" end
    if key == "left" or key == "a" then selectIndex = selectIndex - 1 end
    if key == "right" or key == "d" then selectIndex = selectIndex + 1 end
    if key == "up" or key == "w" then selectIndex = selectIndex - 4 end
    if key == "down" or key == "s" then selectIndex = selectIndex + 4 end
    selectIndex = clamp(selectIndex, 1, #levels)
    if (key == "return" or key == "space") and selectIndex <= save.unlocked then resetLevel(selectIndex) end
  elseif state == "settings" then
    if key == "escape" then state = settingsReturnState end
    if key == "up" or key == "w" then settingsIndex = settingsIndex - 1 end
    if key == "down" or key == "s" then settingsIndex = settingsIndex + 1 end
    settingsIndex = ((settingsIndex - 1) % 2) + 1
    if settingsIndex == 1 and (key == "left" or key == "right" or key == "a" or key == "d" or key == "return" or key == "space") then
      toggleLanguage()
    elseif settingsIndex == 2 and (key == "return" or key == "space") then
      state = settingsReturnState
    end
  elseif state == "pause" and game then
    if key == "escape" or key == "p" then state = "play"; return end
    if key == "up" or key == "w" then pauseIndex = pauseIndex - 1 end
    if key == "down" or key == "s" then pauseIndex = pauseIndex + 1 end
    pauseIndex = ((pauseIndex - 1) % 5) + 1
    if key == "return" or key == "space" then
      if pauseIndex == 1 then state = "play" end
      if pauseIndex == 2 then resetLevel(game.levelIndex) end
      if pauseIndex == 3 then state = "select" end
      if pauseIndex == 4 then settingsReturnState = "pause"; state = "settings" end
      if pauseIndex == 5 then state = "menu" end
    end
  elseif state == "play" and game then
    if key == "escape" or key == "p" then
      if game.completed then state = "select" else pauseIndex = 1; state = "pause" end
    end
    if key == "r" then resetLevel(game.levelIndex) end
    if key == "space" or key == "w" or key == "up" then
      game.player.jumpBuffer = 0.11
    end
    if key == "return" and game.completed then
      local nextIndex = math.min(#levels, game.levelIndex + 1)
      if nextIndex == game.levelIndex then state = "select" else resetLevel(nextIndex) end
    end
  end
end

function love.mousepressed(x, y, button)
  if button ~= 1 or state ~= "menu" then return end
  x, y = x / SCALE, y / SCALE
  for i = 1, 4 do
    local bx, by, bw, bh = menuOptionBounds(i)
    if x >= bx and x <= bx + bw and y >= by and y <= by + bh then
      menuIndex = i
      activateMenuOption(i)
      return
    end
  end
end

function love.touchpressed(_, x, y)
  love.mousepressed(x, y, 1)
end
