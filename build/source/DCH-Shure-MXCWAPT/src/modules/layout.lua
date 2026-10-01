local Properties = require("src.modules.properties")
local ControlsDef = require("src.modules.controls")
local Layout = { WIDTH = 700, HEIGHT = 540 }
local BANK_SIZE = 16

function Layout.get_pages(props)
  local pages = {}
  for _, name in ipairs({ "Setup", "System", "Conference", "Microphones", "Audio", "Dante", "RF", "Voting", "Diagnostics" }) do
    pages[#pages + 1] = { name = name }
  end
  local n = Properties.mic_count(props)
  for _, category in ipairs({ "Stations", "Battery" }) do
    for first = 1, n, BANK_SIZE do
      local last = math.min(first + BANK_SIZE - 1, n)
      pages[#pages + 1] = { name = category .. " " .. first .. "-" .. last }
    end
  end
  return pages
end

local function label(graphics, text, x, y, w, h, bold)
  graphics[#graphics + 1] = {
    Type = "Label", Text = text, Position = { x, y }, Size = { w, h },
    FontSize = 11, IsBold = bold == true, HTextAlign = "Left",
    VTextAlign = "Center", StrokeWidth = 0, Color = { 40, 40, 40 },
  }
end

function Layout.get_layout(props)
  local layout, graphics, definitions = {}, {}, {}
  -- Absent controls need explicit hidden layouts to prevent automatic placement.
  for _, control in ipairs(ControlsDef.get(props)) do
    definitions[control.Name] = control
    layout[control.Name] = { Style = "None", Position = { 0, 0 }, Size = { 1, 1 }, PrettyName = control.Name }
  end
  local pages = Layout.get_pages(props)
  local index = tonumber(props and props.page_index and props.page_index.Value) or 1
  local page = pages[index] and pages[index].name or "Setup"
  graphics[#graphics + 1] = {
    Type = "GroupBox", Position = { 0, 0 }, Size = { Layout.WIDTH, Layout.HEIGHT },
    Fill = { 242, 244, 245 }, StrokeWidth = 0, ZOrder = -1,
  }
  label(graphics, "MXCW-MXCWAPT / " .. page, 16, 10, 668, 24, true)

  local function place(name, x, y, w, legend)
    local def = assert(definitions[name], "Unknown layout control: " .. name)
    local style = "Text"
    if def.ControlType == "Button" then style = "Button"
    elseif def.Choices then style = "ComboBox"
    elseif def.IndicatorType == "Led" then style = "Led" end
    local item = {
      PrettyName = name, Style = style, Position = { x, y }, Size = { w, 24 },
      FontSize = 11, HTextAlign = "Center", Margin = 0, Radius = 2,
      IsReadOnly = def.PinStyle == "Output", StrokeWidth = 1,
    }
    if style == "Button" then
      item.ButtonStyle = def.ButtonType
      item.ButtonVisualStyle = "Flat"
      item.Legend = legend or name
      item.Color = { 65, 160, 94 }
    elseif style == "Led" then
      item.Size = { 18, 18 }
      item.Position = { x + math.floor((w - 18) / 2), y + 3 }
      item.Color = { 65, 160, 94 }
    end
    layout[name] = item
  end

  local function fields(names, x, y)
    for _, entry in ipairs(names) do
      local name = type(entry) == "table" and entry[1] or entry
      local caption = type(entry) == "table" and entry[2] or entry
      local def = definitions[name]
      label(graphics, caption, x, y, 160, 24)
      if def.ControlType == "Button" then
        place(name, x + 168, y, 152, def.ButtonType == "Toggle" and "On" or "Execute")
      else
        place(name, x + 168, y, 152)
      end
      y = y + 32
    end
  end

  if page == "Setup" then
    fields({ "IP Address", "Port", "Connect", "Refresh/Resync" }, 16, 52)
    fields({ "Connected", "Synchronized", "Connection Status" }, 364, 52)
    label(graphics, "Last Error", 16, 204, 160, 24)
    place("Last Error", 16, 236, 668)
  elseif page == "System" then
    fields({ "Device ID", "Model", "APT Flash" }, 16, 52)
    fields({ "WDU Off", "WDU Lock Welcome", "Welcome Lock Reset", "Retain Seat Persistence" }, 364, 52)
  elseif page == "Conference" then
    fields({ "Operation Mode", "Interrupt Mode", "Max Total Speakers", "Max Delegate Speakers", "Max Num Requests" }, 16, 52)
    fields({ "Global Mute", "Audio Input Speaklist", "All Delegate Mic Off", "Clear Request List", "Next Mic On" }, 364, 52)
  elseif page == "Microphones" then
    fields({ { "Selected Station", "Station" }, { "Selected Seat Number", "Seat number" },
      { "Selected Seat Name", "Seat name" }, { "Selected Role", "Role" },
      { "Selected Mic Gain", "Gain (dB)" }, { "Selected Mic Priority", "Priority" } }, 16, 52)
    fields({ { "Selected Mic Status", "Microphone active" }, { "Selected Speak Request", "Request to speak" },
      { "Selected Speak Release", "Release microphone" }, { "Selected Exclusive Mute", "Exclusive mute" },
      { "Selected Mic AGC", "AGC" }, { "Selected Flash", "Identify unit" } }, 364, 52)
  elseif page == "Audio" then
    fields({ "Loudspeaker Volume", "Aux Input Gain", "Aux Output Gain", "Audio Meter Rate" }, 16, 52)
    fields({ "Aux Input Pad", "Aux Input AGC", "Aux Input Mute", "Aux Output Mute" }, 364, 52)
  elseif page == "Dante" then
    local columns = {
      { "Input gain (dB)", "Dante Input Gain", 70, 116 }, { "AGC", "Dante Input AGC", 202, 62 },
      { "Input mute", "Dante Input Mute", 280, 96 }, { "Output gain (dB)", "Dante Output Gain", 398, 130 },
      { "Output mute", "Dante Output Mute", 548, 120 },
    }
    label(graphics, "CH", 16, 48, 38, 24, true)
    for _, col in ipairs(columns) do label(graphics, col[1], col[3], 48, col[4], 24, true) end
    for i = 1, 10 do
      local y = 80 + (i - 1) * 28
      label(graphics, tostring(i), 16, y, 38, 24)
      for _, col in ipairs(columns) do place(col[2] .. " " .. i, col[3], y, col[4], col[1] == "AGC" and "AGC" or "Mute") end
    end
  elseif page == "RF" then
    fields({ "RF Power", "RF Meter Rate" }, 16, 52)
  elseif page == "Voting" then
    fields({ "Start Vote Configuration", "Start Vote", "Complete Vote", "Pause Vote", "Resume Vote" }, 16, 52)
    fields({ "Cancel Vote", "Share Voting Results", "Close Voting Results", "Voting State", "Voting Configuration" }, 364, 52)
    label(graphics, "Option", 16, 244, 320, 24, true)
    label(graphics, "Interim", 364, 244, 144, 24, true)
    label(graphics, "Final", 540, 244, 144, 24, true)
    for i = 1, 5 do
      local y = 276 + (i - 1) * 28
      place("Voting Button Name " .. i, 16, y, 320)
      place("Interim Voting Result " .. i, 364, y, 144)
      place("Final Voting Result " .. i, 540, y, 144)
    end
  elseif page == "Diagnostics" then
    fields({ "Connection Status", "Synchronized" }, 16, 52)
    label(graphics, "Last Error", 16, 132, 160, 24)
    place("Last Error", 16, 164, 668)
  else
    local category, first, last = page:match("^(%a+) (%d+)%-(%d+)$")
    first, last = tonumber(first), tonumber(last)
    local columns
    if category == "Stations" then
      columns = {
        { "Seat", "Seat Number", 56, 68 }, { "Name", "Mic Name", 132, 184 },
        { "Role", "Mic Role", 324, 112 }, { "Mic", "Mic Active", 444, 52 },
        { "Online", "Mic Online", 504, 52 }, { "Request", "Request List", 564, 56 },
        { "Speak", "Speak List", 628, 56 },
      }
    else
      columns = {
        { "Charge (%)", "Battery Charge", 56, 102 }, { "Runtime", "Battery Runtime", 170, 126 },
        { "Health (%)", "Battery Health", 308, 102 }, { "Cycles", "Battery Cycle", 422, 102 },
        { "Vote", "Voting Selection", 536, 148 },
      }
    end
    label(graphics, "#", 16, 48, 32, 24, true)
    for _, col in ipairs(columns) do label(graphics, col[1], col[3], 48, col[4], 24, true) end
    for i = first, last do
      local y = 80 + (i - first) * 28
      label(graphics, tostring(i), 16, y, 32, 24)
      for _, col in ipairs(columns) do place(col[2] .. " " .. i, col[3], y, col[4], "On") end
    end
  end
  return layout, graphics
end

return Layout
