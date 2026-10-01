local Properties = require("src.modules.properties")
local ControlsDef = require("src.modules.controls")
local Assets = require("src.modules.assets")
local Layout = { WIDTH = 1008, HEIGHT = 584 }
local Colors = {
  White = { 255, 255, 255 }, Grey = { 232, 232, 232 }, Black = { 0, 0, 0 },
  Stroke = { 156, 171, 175 }, FaderBlue = { 50, 90, 117 }, Green = { 65, 160, 94 },
}
local BANK_SIZE = 16

local function x_pos(x) return 20 + math.floor((x - 16) * 1.44) end
local function width(w) return math.floor(w * 1.44) end

function Layout.get_pages(props)
  local pages = {}
  for _, name in ipairs({ "Setup", "System", "Conference", "Microphones", "Audio", "Dante", "RF", "Voting", "Diagnostics" }) do
    pages[#pages + 1] = { name = name }
  end
  local n = Properties.mic_count(props)
  if Properties.individual_microphones(props) then
    for i = 1, n do pages[#pages + 1] = { name = "Microphone " .. i } end
  end
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
    Type = "Label", Text = text, Position = { x_pos(x), y + 32 }, Size = { width(w), h },
    FontSize = 11, IsBold = bold == true, HTextAlign = "Left",
    VTextAlign = "Center", StrokeWidth = 0, Color = Colors.Black,
  }
end

function Layout.get_layout(props)
  local layout, graphics, definitions = {}, {}, {}
  for _, control in ipairs(ControlsDef.get(props)) do
    definitions[control.Name] = control
  end
  local pages = Layout.get_pages(props)
  local index = tonumber(props and props.page_index and props.page_index.Value) or 1
  local page = pages[index] and pages[index].name or "Setup"
  local microphone = tonumber(page:match("^Microphone (%d+)$"))
  graphics[#graphics + 1] = {
    Type = "GroupBox", Position = { 4, 4 }, Size = { Layout.WIDTH - 8, Layout.HEIGHT - 8 },
    Fill = Colors.White, StrokeColor = Colors.Stroke, StrokeWidth = 1, ZOrder = -1,
  }
  label(graphics, "DCH / Shure MXCW-MXCWAPT", 16, -20, 480, 20, true)
  label(graphics, page, 16, 2, 480, 18)
  graphics[#graphics + 1] = {
    Type = "Image", Name = "Dechen logo", Image = Assets.DechenLogo,
    Position = { 736, 16 }, Size = { 144, 36 },
  }
  graphics[#graphics + 1] = {
    Type = "Image", Name = "Shure logo", Image = Assets.ShureLogo, Position = { 900, 14 }, Size = { 87, 44 },
  }
  graphics[#graphics + 1] = {
    Type = "GroupBox", Position = { 9, 64 }, Size = { 990, 1 },
    Fill = Colors.Stroke, StrokeWidth = 0,
  }

  local function place(name, x, y, w, legend)
    local def = assert(definitions[name], "Unknown layout control: " .. name)
    local style = "Text"
    if def.ControlType == "Button" then style = "Button"
    elseif def.Choices then style = "ComboBox"
    elseif def.IndicatorType == "Led" then style = "Led" end
    local item = {
      PrettyName = name, Style = style, Position = { x_pos(x), y + 32 }, Size = { width(w), 24 },
      FontSize = 11, HTextAlign = "Center", Margin = 0, Radius = 2,
      IsReadOnly = def.ReadOnly, StrokeWidth = 1, StrokeColor = Colors.Stroke,
      Color = Colors.Grey, TextColor = Colors.Black,
    }
    if style == "Button" then
      item.ButtonStyle = def.ButtonType
      item.ButtonVisualStyle = "Flat"
      item.Legend = legend or name
      item.Color = Colors.FaderBlue
      item.TextColor = Colors.White
    elseif style == "Led" then
      item.Size = { 18, 18 }
      item.Position = { x_pos(x) + math.floor((width(w) - 18) / 2), y + 35 }
      item.Color = Colors.Green
    end
    layout[name] = item
  end

  local function fader(name, x, y, w, h)
    place(name, x, y, w)
    local item = layout[name]
    item.Style, item.Size[2] = "Fader", h
    item.Color, item.ShowTextbox = Colors.FaderBlue, true
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
      { "Selected Mic Priority", "Priority" } }, 16, 52)
    fields({ { "Selected Mic Status", "Microphone active" }, { "Selected Speak Request", "Request to speak" },
      { "Selected Speak Release", "Release microphone" }, { "Selected Exclusive Mute", "Exclusive mute" },
      { "Selected Mic AGC", "AGC" }, { "Selected Flash", "Identify unit" } }, 364, 52)
    label(graphics, "Microphone gain (dB)", 16, 224, 180, 24, true)
    fader("Selected Mic Gain", 64, 256, 32, 180)
  elseif microphone then
    local i = microphone
    fields({ { "Seat Number " .. i, "Seat number" }, { "Mic Seat Name " .. i, "Seat name" },
      { "Mic Seat Role " .. i, "Role" }, { "Mic Priority " .. i, "Priority" },
      { "Mic Online " .. i, "Online" }, { "Request List " .. i, "Request list" },
      { "Speak List " .. i, "Speak list" } }, 16, 52)
    fields({ { "Mic Active " .. i, "Microphone active" }, { "Mic Speak Request " .. i, "Request to speak" },
      { "Mic Speak Release " .. i, "Release microphone" }, { "Mic Exclusive Mute " .. i, "Exclusive mute" },
      { "Mic AGC " .. i, "AGC" }, { "Mic Flash " .. i, "Identify unit" } }, 364, 52)
    label(graphics, "Battery / Voting", 16, 284, 180, 24, true)
    fields({ { "Battery Charge " .. i, "Charge (%)" }, { "Battery Runtime " .. i, "Runtime (min)" },
      { "Battery Health " .. i, "Health (%)" }, { "Battery Cycle " .. i, "Cycle count" },
      { "Voting Selection " .. i, "Voting selection" } }, 16, 316)
    label(graphics, "Microphone gain (dB)", 364, 256, 180, 24, true)
    fader("Mic Gain " .. i, 420, 288, 32, 180)
  elseif page == "Audio" then
    fields({ "Aux Input Pad", "Aux Input AGC", "Aux Input Mute", "Aux Output Mute", "Audio Meter Rate" }, 364, 52)
    for i, name in ipairs({ "Loudspeaker Volume", "Aux Input Gain", "Aux Output Gain" }) do
      local x = 24 + (i - 1) * 112
      label(graphics, name, x, 52, 108, 24, true)
      label(graphics, "dB", x, 84, 108, 20)
      fader(name, x + 36, 116, 32, 180)
    end
  elseif page == "Dante" then
    for i = 1, 10 do
      local x = 22 + (i - 1) * 66
      label(graphics, "CH " .. i, x, 52, 60, 24, true)
      label(graphics, "Input / dB", x, 84, 60, 20)
      fader("Dante Input Gain " .. i, x + 14, 112, 32, 100)
      place("Dante Input AGC " .. i, x + 4, 224, 52, "AGC")
      place("Dante Input Mute " .. i, x + 4, 252, 52, "Mute")
      label(graphics, "CH " .. i, x, 288, 60, 24, true)
      label(graphics, "Output / dB", x, 320, 60, 20)
      fader("Dante Output Gain " .. i, x + 14, 348, 32, 100)
      place("Dante Output Mute " .. i, x + 4, 460, 52, "Mute")
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
