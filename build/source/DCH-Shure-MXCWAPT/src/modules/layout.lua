local Layout = {}

function Layout.get_pages(props)
  return {
    { name = "Setup" },
    { name = "System" },
    { name = "Conference" },
    { name = "Microphones" },
    { name = "Audio" },
    { name = "RF" },
    { name = "Battery" },
    { name = "Voting" },
    { name = "Diagnostics" },
  }
end

local function group(graphics, text, x, y, w, h)
  graphics[#graphics + 1] = {
    Type = "GroupBox",
    Text = text,
    Position = { x, y },
    Size = { w, h },
    Fill = { 245, 245, 245 },
    StrokeWidth = 1,
  }
end

local function label(graphics, text, x, y, w, h)
  graphics[#graphics + 1] = {
    Type = "Text",
    Text = text,
    Position = { x, y },
    Size = { w, h },
    FontSize = 12,
    HTextAlign = "Left",
  }
end

local function style_for(name)
  if name:find("Mute") or name:find("AGC") or name:find("Connect") or name:find("Flash") or name:find("Vote") or name:find("Off") or name:find("Reset") then
    return "Button"
  end
  if name:find("Power") or name:find("Mode") or name:find("Role") then
    return "ComboBox"
  end
  if name:find("Gain") or name:find("Volume") or name:find("Speakers") or name:find("Requests") or name:find("Rate") or name:find("Station") or name:find("Number") then
    return "Knob"
  end
  if name:find("Connected") or name:find("Online") or name:find("List") or name:find("Synchronized") then
    return "Indicator"
  end
  return "Text"
end

local function place(layout, name, x, y, w, h)
  layout[name] = {
    PrettyName = name,
    Style = style_for(name),
    Position = { x, y },
    Size = { w, h },
  }
end

local function add_column(layout, names, x, y)
  for _, name in ipairs(names) do
    place(layout, name, x, y, 190, 28)
    y = y + 34
  end
end

local function current_page(props)
  local pages = Layout.get_pages(props)
  local index = props and props.page_index and props.page_index.Value or 1
  return pages[index] and pages[index].name or "Setup"
end

function Layout.get_layout(props)
  local layout, graphics = {}, {}
  local page = current_page(props)

  group(graphics, page, 5, 5, 690, 445)

  if page == "Setup" then
    add_column(layout, { "IP Address", "Port", "Connect", "Connected", "Connection Status", "Last Error", "Refresh/Resync", "Synchronized" }, 20, 35)
  elseif page == "System" then
    add_column(layout, { "Device ID", "Model", "APT Flash", "RF Power", "WDU Off", "WDU Lock Welcome", "Welcome Lock Reset", "Retain Seat Persistence" }, 20, 35)
  elseif page == "Conference" then
    add_column(layout, { "Global Mute", "Audio Input Speaklist", "All Delegate Mic Off", "Clear Request List", "Next Mic On", "Operation Mode", "Interrupt Mode", "Max Total Speakers", "Max Delegate Speakers", "Max Num Requests" }, 20, 35)
  elseif page == "Microphones" then
    add_column(layout, { "Selected Station", "Selected Seat Number", "Selected Seat Name", "Selected Role", "Selected Mic Status", "Selected Speak Request", "Selected Speak Release", "Selected Exclusive Mute", "Selected Mic Gain", "Selected Mic Priority", "Selected Mic AGC", "Selected Flash" }, 20, 35)
    label(graphics, "Per-station pins are exposed on the component for external Q-SYS logic.", 250, 35, 360, 24)
  elseif page == "Audio" then
    add_column(layout, { "Loudspeaker Volume", "Aux Input Pad", "Aux Input Gain", "Aux Output Gain", "Aux Input AGC", "Aux Input Mute", "Aux Output Mute", "Audio Meter Rate" }, 20, 35)
    for i = 1, 10 do
      place(layout, "Dante Input Gain " .. i, 240, 35 + ((i - 1) * 34), 160, 28)
      place(layout, "Dante Output Gain " .. i, 430, 35 + ((i - 1) * 34), 160, 28)
    end
  elseif page == "RF" then
    add_column(layout, { "RF Power", "RF Meter Rate" }, 20, 35)
  elseif page == "Battery" then
    label(graphics, "Battery pins are exposed per station: charge, runtime, health, and cycle count.", 20, 35, 500, 24)
  elseif page == "Voting" then
    add_column(layout, { "Start Vote Configuration", "Start Vote", "Complete Vote", "Pause Vote", "Resume Vote", "Cancel Vote", "Share Voting Results", "Close Voting Results", "Voting State", "Voting Configuration" }, 20, 35)
    for i = 1, 5 do
      place(layout, "Voting Button Name " .. i, 250, 35 + ((i - 1) * 34), 170, 28)
      place(layout, "Interim Voting Result " .. i, 430, 35 + ((i - 1) * 34), 120, 28)
      place(layout, "Final Voting Result " .. i, 560, 35 + ((i - 1) * 34), 120, 28)
    end
  elseif page == "Diagnostics" then
    add_column(layout, { "Connection Status", "Last Error", "Synchronized" }, 20, 35)
  end

  return layout, graphics
end

return Layout
