package.path = "./?.lua;./?/init.lua;" .. package.path

local Runtime = require("src.modules.runtime")
local ControlsDef = require("src.modules.controls")
local Properties = require("src.modules.properties")

local function fixture(address)
  local props = { ["Number of Microphones"] = { Value = 1 } }
  local controls, attempts, timers = {}, {}, {}
  for _, definition in ipairs(ControlsDef.native(props)) do
    controls[definition.Name] = {
      String = "", Boolean = false,
      Value = type(definition.DefaultValue) == "number" and definition.DefaultValue or 0,
    }
  end
  controls["IP Address"].String = address
  -- Simulate an existing design whose Connect toggle was saved Off.
  controls.Connect.Boolean = false
  local socket = {
    Connect = function(_, ip, port) attempts[#attempts + 1] = { ip, port } end,
    Disconnect = function() end,
  }
  Runtime.install({
    Controls = controls, PluginProperties = props, Properties = Properties,
    ControlDefinitions = ControlsDef.get(props),
    TcpSocket = { New = function() return socket end },
    Timer = { New = function()
      local timer = { running = false }
      timer.Start = function(self) self.running = true end
      timer.Stop = function(self) self.running = false end
      timers[#timers + 1] = timer
      return timer
    end },
    Commands = require("src.modules.commands"), Protocol = require("src.modules.protocol"),
    State = require("src.modules.state"), Diagnostics = require("src.modules.diagnostics"),
  })
  return controls, socket, attempts, timers
end

local controls, socket, attempts, timers = fixture("192.0.2.10")
assert(controls.Connect.Boolean and #attempts == 1, "Startup must enable and connect")
assert(attempts[1][1] == "192.0.2.10" and attempts[1][2] == 2202)
socket.Closed()
assert(timers[1].running, "Unexpected closure must schedule reconnect")
controls.Connect.Boolean = false
controls.Connect.EventHandler(controls.Connect)
assert(not timers[1].running, "Off must cancel scheduled reconnect")
timers[1].EventHandler()
assert(#attempts == 1, "Stale retry must not reconnect while Off")
controls["IP Address"].String = "192.0.2.11"
controls["IP Address"].EventHandler(controls["IP Address"])
assert(#attempts == 1, "IP edit while Off must not reconnect")
controls.Connect.Boolean = true
controls.Connect.EventHandler(controls.Connect)
assert(#attempts == 2 and attempts[2][1] == "192.0.2.11")
controls.Port.Value = 2203
controls.Port.EventHandler(controls.Port)
assert(#attempts == 3 and attempts[3][2] == 2203, "Port edit must restart enabled connection")

for _, address in ipairs({ "", "  " }) do
  controls, socket, attempts = fixture(address)
  assert(controls.Connect.Boolean and #attempts == 0, "Blank IP must keep Connect On without network activity")
  assert(controls["Connection Status"].String == "Disconnected")
  controls["IP Address"].String = " 192.0.2.12 "
  controls["IP Address"].EventHandler(controls["IP Address"])
  assert(#attempts == 1 and attempts[1][1] == "192.0.2.12", "Setting IP must auto-connect")
end

print("runtime_connection_spec.lua: ok (startup On, automatic connection, empty IP, edits, manual Off)")
