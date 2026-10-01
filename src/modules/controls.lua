local Properties = require("src.modules.properties")

local ControlsDef = {}

local function ctl(list, name, control_type, direction, opts)
  opts = opts or {}
  local qsys_control_type = control_type == "ComboBox" and "Text" or
    (control_type == "Meter" and "Knob" or control_type)
  local item = {
    Name = name,
    ControlType = qsys_control_type,
    UserPin = false,
    PinStyle = "None",
    ReadOnly = direction == "Output",
    Count = 1,
  }
  if opts.count then item.Count = opts.count end
  if opts.min then item.Min = opts.min end
  if opts.max then item.Max = opts.max end
  if opts.choices then item.Choices = opts.choices end
  if opts.default ~= nil then item.DefaultValue = opts.default end
  if qsys_control_type == "Indicator" then
    item.IndicatorType = "Led"
  end
  if qsys_control_type == "Knob" then
    item.ControlUnit = (name:find("Gain") or name:find("Volume")) and "dB" or "Integer"
    if control_type == "Meter" then
      item.ControlUnit, item.Min, item.Max = "Percent", 0, 100
    end
    if item.Min == item.Max then item.Max = item.Min + 1 end
  end
  if qsys_control_type == "Button" then
    local momentary = name:find("Refresh") or name:find("Flash") or name:find("Off") or
      name:find("Reset") or name:find("Request") or name:find("Release") or
      name:find("Vote") or name:find("Clear") or name:find("Next") or
      name:find("Delegate Mic Off")
    item.ButtonType = opts.button_type or (momentary and "Momentary" or "Toggle")
  end
  list[#list + 1] = item
end

function ControlsDef.get(props)
  local n = Properties.mic_count(props)
  local list = {}

  ctl(list, "IP Address", "Text", "Input")
  ctl(list, "Port", "Knob", "Input", { min = 1, max = 65535, default = 2202 })
  ctl(list, "Connect", "Button", "Input")
  ctl(list, "Refresh/Resync", "Button", "Input")
  ctl(list, "Connected", "Indicator", "Output")
  ctl(list, "Connection Status", "Text", "Output")
  ctl(list, "Last Error", "Text", "Output")
  ctl(list, "Synchronized", "Indicator", "Output")

  ctl(list, "Device ID", "Text", "Input")
  ctl(list, "Model", "Text", "Output")
  ctl(list, "APT Flash", "Button", "Input")
  ctl(list, "RF Power", "ComboBox", "Input", { choices = { "OFF", "LOW", "MEDIUM", "HIGH", "MAXIMUM" } })
  ctl(list, "Global Mute", "Button", "Input")
  ctl(list, "Audio Input Speaklist", "Button", "Input")
  ctl(list, "All Delegate Mic Off", "Button", "Input")
  ctl(list, "Clear Request List", "Button", "Input")
  ctl(list, "Next Mic On", "Button", "Input")
  ctl(list, "WDU Off", "Button", "Input")
  ctl(list, "Welcome Lock Reset", "Button", "Input")
  ctl(list, "Retain Seat Persistence", "Button", "Input")
  ctl(list, "WDU Lock Welcome", "Button", "Input")

  ctl(list, "Operation Mode", "ComboBox", "Input", { choices = { "AUTO", "MANUAL", "FIFO", "HANDSFREE" } })
  ctl(list, "Interrupt Mode", "ComboBox", "Input", { choices = { "NOT_ALLOWED", "HIGHER_PRIORITY", "EQUAL_AND_HIGHER_PRIORITY" } })
  ctl(list, "Max Total Speakers", "Knob", "Input", { min = 1, max = 8 })
  ctl(list, "Max Delegate Speakers", "Knob", "Input", { min = 0, max = 8 })
  ctl(list, "Max Num Requests", "Knob", "Input", { min = 0, max = 8 })
  ctl(list, "Loudspeaker Volume", "Knob", "Input", { min = -30, max = 6 })

  ctl(list, "Aux Input Pad", "Button", "Input")
  ctl(list, "Aux Input Gain", "Knob", "Input", { min = -30, max = 10 })
  ctl(list, "Aux Output Gain", "Knob", "Input", { min = -30, max = 0 })
  ctl(list, "Aux Input AGC", "Button", "Input")
  ctl(list, "Aux Input Mute", "Button", "Input")
  ctl(list, "Aux Output Mute", "Button", "Input")
  ctl(list, "Audio Meter Rate", "Knob", "Input", { min = 0, max = 99999 })
  ctl(list, "RF Meter Rate", "Knob", "Input", { min = 0, max = 99999 })

  for i = 1, 10 do
    ctl(list, "Dante Input Gain " .. i, "Knob", "Input", { min = -30, max = 10 })
    ctl(list, "Dante Output Gain " .. i, "Knob", "Input", { min = -30, max = 0 })
    ctl(list, "Dante Input AGC " .. i, "Button", "Input")
    ctl(list, "Dante Input Mute " .. i, "Button", "Input")
    ctl(list, "Dante Output Mute " .. i, "Button", "Input")
  end

  ctl(list, "Selected Station", "Knob", "Input", { min = 1, max = n, default = 1 })
  ctl(list, "Selected Seat Number", "Knob", "Input", { min = 1, max = 65535, default = 1 })
  ctl(list, "Selected Seat Name", "Text", "Input")
  ctl(list, "Selected Role", "ComboBox", "Input", { choices = { "DELEGATE", "CHAIRMAN", "LISTENER", "AMBIENT", "REMOTE_CALLER", "DUAL_DELEGATE" } })
  ctl(list, "Selected Mic Gain", "Knob", "Input", { min = -30, max = 10 })
  ctl(list, "Selected Mic Priority", "Knob", "Input", { min = 0, max = 5 })
  ctl(list, "Selected Mic AGC", "Button", "Input")
  ctl(list, "Selected Mic Status", "Button", "Input")
  ctl(list, "Selected Speak Request", "Button", "Input")
  ctl(list, "Selected Speak Release", "Button", "Input")
  ctl(list, "Selected Exclusive Mute", "Button", "Input")
  ctl(list, "Selected Flash", "Button", "Input")

  for i = 1, n do
    ctl(list, "Seat Number " .. i, "Knob", "Input", { min = 1, max = 65535, default = i })
    ctl(list, "Mic Active " .. i, "Button", "Input")
    ctl(list, "Mic Online " .. i, "Indicator", "Output")
    ctl(list, "Mic Name " .. i, "Text", "Output")
    ctl(list, "Mic Role " .. i, "Text", "Output")
    ctl(list, "Request List " .. i, "Indicator", "Output")
    ctl(list, "Speak List " .. i, "Indicator", "Output")
    ctl(list, "Battery Charge " .. i, "Meter", "Output")
    ctl(list, "Battery Runtime " .. i, "Text", "Output")
    ctl(list, "Battery Health " .. i, "Meter", "Output")
    ctl(list, "Battery Cycle " .. i, "Text", "Output")
    ctl(list, "Voting Selection " .. i, "Text", "Output")
  end

  ctl(list, "Start Vote Configuration", "Knob", "Input", { min = 1, max = 50, default = 1 })
  ctl(list, "Start Vote", "Button", "Input")
  ctl(list, "Complete Vote", "Button", "Input")
  ctl(list, "Pause Vote", "Button", "Input")
  ctl(list, "Resume Vote", "Button", "Input")
  ctl(list, "Cancel Vote", "Button", "Input")
  ctl(list, "Share Voting Results", "Button", "Input")
  ctl(list, "Close Voting Results", "Button", "Input")
  ctl(list, "Voting State", "Text", "Output")
  ctl(list, "Voting Configuration", "Text", "Output")
  for i = 1, 5 do
    ctl(list, "Voting Button Name " .. i, "Text", "Output")
    ctl(list, "Interim Voting Result " .. i, "Text", "Output")
    ctl(list, "Final Voting Result " .. i, "Text", "Output")
  end

  return list
end

function ControlsDef.native(props)
  local list = ControlsDef.get(props)
  for _, control in ipairs(list) do
    control.Choices = nil
    control.ReadOnly = nil
  end
  return list
end

return ControlsDef
