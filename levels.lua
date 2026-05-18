local W, H = 960, 540
local floorY = 480

local function ground()
  return {x = 0, y = floorY, w = W, h = 60}
end

local function box(x, y)
  return {x = x, y = y or floorY - 28, w = 28, h = 28}
end

local function gate(id, x)
  return {id = id, x = x, y = floorY - 150, w = 30, h = 150}
end

local function beam(x)
  return {x = x, y = floorY - 150, w = 18, h = 150}
end

return {
  {
    name = "01 Wake",
    nameZh = "01 醒来",
    hint = "Learn movement: jump across the three ledges and reach the exit",
    hintZh = "学习移动：跳过三段平台，抵达出口",
    start = {x = 54, y = floorY - 30},
    goal = {x = 880, y = floorY - 64, w = 34, h = 64},
    solids = {ground(), {x = 260, y = 420, w = 120, h = 18}, {x = 510, y = 365, w = 120, h = 18}, {x = 720, y = 420, w = 120, h = 18}},
    boxes = {}, buttons = {}, doors = {}, lasers = {},
  },
  {
    name = "02 Door Signal",
    nameZh = "02 门的信号",
    hint = "The gate is too tall to jump. Step on the pad to open it.",
    hintZh = "门太高，跳不过去；踩住按钮打开它",
    start = {x = 54, y = floorY - 30},
    goal = {x = 875, y = floorY - 64, w = 34, h = 64},
    solids = {ground()}, boxes = {},
    buttons = {{id = "b1", x = 500, y = floorY - 10, w = 86, h = 10, target = "d1"}},
    doors = {gate("d1", 530)},
    lasers = {},
  },
  {
    name = "03 First Shadow",
    nameZh = "03 第一个影子",
    hint = "Hold the left pad, wait for the echo, then cross the tall gate",
    hintZh = "守住左侧按钮，等影子接力后穿过高门",
    start = {x = 54, y = floorY - 30},
    goal = {x = 875, y = floorY - 64, w = 34, h = 64},
    solids = {ground()}, boxes = {},
    buttons = {{id = "b1", x = 205, y = floorY - 10, w = 78, h = 10, target = "d1", hold = 1.2}},
    doors = {gate("d1", 540)},
    lasers = {},
  },
  {
    name = "04 Echo Route",
    nameZh = "04 回声路线",
    hint = "Record the pad first, then take the upper route while the echo opens the gate",
    hintZh = "先录下踩按钮，再趁影子开门走上方路线",
    start = {x = 54, y = floorY - 30},
    goal = {x = 880, y = 336, w = 34, h = 64},
    solids = {ground(), {x = 555, y = 400, w = 130, h = 18}, {x = 760, y = 400, w = 160, h = 18}}, boxes = {},
    buttons = {{id = "b1", x = 180, y = floorY - 10, w = 76, h = 10, target = "d1", hold = 1.2}},
    doors = {{id = "d1", x = 700, y = 330, w = 30, h = 150}},
    lasers = {},
  },
  {
    name = "05 Light Block",
    nameZh = "05 挡住光束",
    hint = "The full-height beam blocks running and jumping. Leave an echo beside it.",
    hintZh = "整面光束挡住跑跳；在旁边留下影子再通过",
    start = {x = 54, y = floorY - 30},
    goal = {x = 875, y = floorY - 64, w = 34, h = 64},
    solids = {ground()},
    boxes = {}, buttons = {}, doors = {},
    lasers = {beam(520)},
  },
  {
    name = "06 First Crate",
    nameZh = "06 第一个箱子",
    hint = "A tall gate blocks the road. Push the crate onto the pad.",
    hintZh = "高门挡路，把箱子推到按钮上",
    start = {x = 54, y = floorY - 30},
    goal = {x = 875, y = floorY - 64, w = 34, h = 64},
    solids = {ground()},
    boxes = {box(235)},
    buttons = {{id = "b1", x = 385, y = floorY - 10, w = 72, h = 10, target = "d1"}},
    doors = {gate("d1", 580)},
    lasers = {},
  },
  {
    name = "07 Crate Timing",
    nameZh = "07 箱子时机",
    hint = "Crate opens one gate; your echo must hold the next pad",
    hintZh = "箱子打开第一扇门，影子守住第二个按钮",
    start = {x = 54, y = floorY - 30},
    goal = {x = 875, y = floorY - 64, w = 34, h = 64},
    solids = {ground(), {x = 500, y = 430, w = 100, h = 16}},
    boxes = {box(260)},
    buttons = {{id = "b1", x = 435, y = floorY - 10, w = 76, h = 10, target = "d1"}, {id = "b2", x = 545, y = 420, w = 72, h = 10, target = "d2", hold = 1.2}},
    doors = {gate("d1", 625), gate("d2", 725)},
    lasers = {},
  },
  {
    name = "08 Split Duties",
    nameZh = "08 分工",
    hint = "Crate holds the first gate. Your echo holds the second gate.",
    hintZh = "箱子守第一扇门，影子守第二扇门",
    start = {x = 54, y = floorY - 30},
    goal = {x = 875, y = floorY - 64, w = 34, h = 64},
    solids = {ground()},
    boxes = {box(180)},
    buttons = {{id = "b1", x = 300, y = floorY - 10, w = 72, h = 10, target = "d1"}, {id = "b2", x = 525, y = floorY - 10, w = 72, h = 10, target = "d2", hold = 1.2}},
    doors = {gate("d1", 430), gate("d2", 675)},
    lasers = {},
  },
  {
    name = "09 Beam And Box",
    nameZh = "09 光束与箱子",
    hint = "Crate opens the gate; the echo must dim the full-height beam",
    hintZh = "箱子开门，影子压暗整面光束",
    start = {x = 54, y = floorY - 30},
    goal = {x = 875, y = floorY - 64, w = 34, h = 64},
    solids = {ground()},
    boxes = {box(230)},
    buttons = {{id = "b1", x = 380, y = floorY - 10, w = 72, h = 10, target = "d1"}},
    doors = {gate("d1", 520)},
    lasers = {beam(680)},
  },
  {
    name = "10 Long Gate",
    nameZh = "10 长门",
    hint = "Direct jumps fail here. Hold the pad with your echo and cross the tall gate.",
    hintZh = "直接跳会被挡住；让影子踩按钮再穿过高门",
    start = {x = 54, y = floorY - 30},
    goal = {x = 875, y = floorY - 64, w = 34, h = 64},
    solids = {ground()},
    boxes = {},
    buttons = {{id = "b1", x = 190, y = floorY - 10, w = 76, h = 10, target = "d1", hold = 1.2}},
    doors = {gate("d1", 640)},
    lasers = {},
  },
  {
    name = "11 Double Memory",
    nameZh = "11 双重记忆",
    hint = "First echo opens the gate; the later echo dims the beam",
    hintZh = "第一段影子开门，后面的影子压暗光束",
    start = {x = 54, y = floorY - 30},
    goal = {x = 875, y = floorY - 64, w = 34, h = 64},
    solids = {ground()},
    boxes = {},
    buttons = {{id = "b1", x = 210, y = floorY - 10, w = 76, h = 10, target = "d1", hold = 1.2}},
    doors = {gate("d1", 430)},
    lasers = {beam(660)},
  },
  {
    name = "Finale",
    nameZh = "终章",
    hint = "Crate, echo gate, then echo beam: finish the duet",
    hintZh = "箱子开门，影子开门，再用影子处理光束",
    start = {x = 54, y = floorY - 30},
    goal = {x = 875, y = floorY - 64, w = 34, h = 64},
    solids = {ground()},
    boxes = {box(205)},
    buttons = {{id = "b1", x = 330, y = floorY - 10, w = 72, h = 10, target = "d1"}, {id = "b2", x = 545, y = floorY - 10, w = 72, h = 10, target = "d2", hold = 1.2}},
    doors = {gate("d1", 430), gate("d2", 655)},
    lasers = {beam(755)},
  },
}
