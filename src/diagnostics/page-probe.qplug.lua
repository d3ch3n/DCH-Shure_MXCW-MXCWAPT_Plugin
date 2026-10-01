PluginInfo = {
  Name = "DCH~Shure~MXCW-MXCWAPT Diagnostics~03 Page Probe",
  Version = "0.1.0",
  BuildVersion = "0.1.0.0",
  Id = "41d6c23e-d3fb-4b51-a463-b175bd1c74ef",
  Author = "DCH",
  Description = "Single-page MXCW UI probe; no runtime, TCP, timers or exposed pins.",
}

local PropertiesDef = require("src.modules.properties")
local ControlsDef = require("src.modules.controls")
local Layout = require("src.modules.layout")

function GetPrettyName(props)
  return "MXCW Diagnostic - Page Probe"
end

function GetProperties()
  return {
    { Name = "Number of Microphones", Type = "integer", Min = 1, Max = 125, Value = 16 },
    { Name = "Diagnostic Page", Type = "enum", Value = "Setup",
      Choices = { "Setup", "System", "Conference", "Microphones", "Audio", "Dante", "RF", "Voting", "Diagnostics", "Stations", "Battery" } },
    { Name = "Diagnostic Scope", Type = "enum", Value = "Page Controls", Choices = { "Page Controls", "All Controls" } },
    { Name = "Diagnostic Appearance", Type = "enum", Value = "Original", Choices = { "Original", "Plain" } },
  }
end

local function selected_layout(props)
  local target = props and props["Diagnostic Page"] and props["Diagnostic Page"].Value or "Setup"
  local selected = {}
  for name, value in pairs(props or {}) do selected[name] = value end
  selected["Control Pins"] = { Value = "None" }
  selected.page_index = { Value = 1 }
  for index, page in ipairs(Layout.get_pages(selected)) do
    if page.name == target or page.name:match("^(%a+) ") == target then
      selected.page_index = { Value = index }
      break
    end
  end
  return Layout.get_layout(selected)
end

local function all_controls(props)
  return props and props["Diagnostic Scope"] and props["Diagnostic Scope"].Value == "All Controls"
end

local function plain(props)
  return props and props["Diagnostic Appearance"] and props["Diagnostic Appearance"].Value == "Plain"
end

function GetControls(props)
  local visible = selected_layout(props)
  local result = {}
  for _, control in ipairs(ControlsDef.native(props)) do
    if all_controls(props) or visible[control.Name] then
      control.UserPin = false
      result[#result + 1] = control
    end
  end
  return result
end

function GetControlLayout(props)
  local layout, graphics = selected_layout(props)
  if plain(props) then
    graphics = {}
    for _, item in pairs(layout) do
      local reduced = { Style = item.Style, Position = item.Position, Size = item.Size }
      if item.Style == "Button" then
        reduced.ButtonStyle = item.ButtonStyle
        reduced.Legend = item.Legend
      end
      for key in pairs(item) do item[key] = nil end
      for key, value in pairs(reduced) do item[key] = value end
    end
  end
  if all_controls(props) then
    for _, control in ipairs(ControlsDef.native(props)) do
      if not layout[control.Name] then layout[control.Name] = { Style = "None" } end
    end
  end
  return layout, graphics
end
