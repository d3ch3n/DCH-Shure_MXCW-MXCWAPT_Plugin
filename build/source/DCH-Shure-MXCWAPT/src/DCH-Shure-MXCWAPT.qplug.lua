PluginInfo = {
  Name = "DCH~Shure~MXCW-MXCWAPT",
  Version = "0.1.6",
  BuildVersion = "0.1.6.0",
  ShowDebug = false,
  Id = "dch.shure.mxcwapt.control",
  Author = "DCH",
  Description = "Q-SYS plugin for Shure Microflex Complete Wireless MXCW systems with MXCWAPT central device.",
}

local PropertiesDef = require("src.modules.properties")
local ControlsDef = require("src.modules.controls")
local Layout = require("src.modules.layout")

function GetColor(props)
  return { 255, 255, 255 }
end

function GetPrettyName(props)
  return "DCH - Shure MXCW-MXCWAPT, version " .. PluginInfo.Version
end

function GetProperties()
  return PropertiesDef.get()
end

function GetPins(props)
  return {}
end

function RectifyProperties(props)
  if props.plugin_show_debug then
    props.plugin_show_debug.Value = false
    props.plugin_show_debug.IsHidden = true
  end
  return props
end

function GetControls(props)
  return ControlsDef.native(props)
end

function GetPages(props)
  return Layout.get_pages(props)
end

function GetControlLayout(props)
  return Layout.get_layout(props)
end

if Controls then
  local Commands = require("src.modules.commands")
  local Protocol = require("src.modules.protocol")
  local State = require("src.modules.state")
  local Diagnostics = require("src.modules.diagnostics")
  local Runtime = require("src.modules.runtime")

  Runtime.install({
    Controls = Controls,
    ControlDefinitions = ControlsDef.get(Properties),
    TcpSocket = TcpSocket,
    Timer = Timer,
    PluginProperties = Properties,
    Properties = PropertiesDef,
    Commands = Commands,
    Protocol = Protocol,
    State = State,
    Diagnostics = Diagnostics,
  })
end
