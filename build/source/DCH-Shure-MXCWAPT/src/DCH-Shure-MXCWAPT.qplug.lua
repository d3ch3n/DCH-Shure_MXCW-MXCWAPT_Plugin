PluginInfo = {
  Name = "DCH~Shure~MXCW-MXCWAPT",
  Version = "0.1.1",
  BuildVersion = "0.1.1.0",
  Id = "dch.shure.mxcwapt.control",
  Author = "DCH",
  Description = "Q-SYS plugin for Shure Microflex Complete Wireless MXCW systems with MXCWAPT central device.",
}

local PropertiesDef = require("src.modules.properties")
local ControlsDef = require("src.modules.controls")
local Layout = require("src.modules.layout")

function GetProperties()
  return PropertiesDef.get()
end

function GetControls(props)
  return ControlsDef.get(props)
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
