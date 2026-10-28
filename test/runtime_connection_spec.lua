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
    payload = "", sent = {},
    Write = function(self, message) self.sent[#self.sent + 1] = message end,
    Read = function(self) return self.payload end,
    Connect = function(_, ip, port) attempts[#attempts + 1] = { ip, port } end,
    Disconnect = function() end,
  }
  Runtime.install({
    Controls = controls, PluginProperties = props, Properties = Properties,
    ControlDefinitions = ControlsDef.get(props),
    TcpSocket = { New = function() return socket end },
    Timer = { New = function()
      local timer = { running = false }
      timer.Start = function(self, interval)
        self.running = true
        self.interval = interval
        self.starts = (self.starts or 0) + 1
      end
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
assert(controls["Connection Status"].Value == 5, "Connecting uses native blue status")
socket.Connected()
assert(controls["Connection Status"].String == "Connected / Synchronizing")
assert(not controls.Synchronized.Boolean, "Sending queries is not proof of synchronization")
socket.payload = "< REP MODEL {MXCWAPT} >"
socket.Data()
assert(controls["Connection Status"].String == "OK" and controls.Connected.Boolean)
assert(controls.Synchronized.Boolean)
assert(controls["Connection Status"].Value == 0, "OK uses native green status")
assert(timers[2].running and timers[2].interval == 15)
assert(timers[3].running and timers[3].interval == 5)
local starts = timers[2].starts
socket.Data()
assert(timers[2].starts == starts + 1, "Each MODEL reply renews the response deadline")
socket.payload = "< REP GLOBAL_MUTE OFF >"
socket.Data()
assert(timers[2].starts == starts + 1, "Unrelated traffic must not renew the MODEL deadline")
socket.payload = "< REP MODEL {MXCWAPT} >"
timers[3].EventHandler()
assert(socket.sent[#socket.sent] == "< GET MODEL >", "Poll the device while TCP is idle")
controls["Mic Online 1"].Boolean = true
timers[2].EventHandler()
assert(controls["Connection Status"].String == "Missing", "Silent cable loss must become Missing")
assert(controls["Connection Status"].Value == 4, "Missing uses native red status")
assert(not controls.Connected.Boolean and not controls.Synchronized.Boolean and not controls["Mic Online 1"].Boolean)
assert(not timers[2].running and not timers[3].running and timers[1].running)
socket.Data()
assert(controls["Connection Status"].String == "Missing", "Late reports must not restore a dead session")
timers[1].EventHandler()
assert(controls["Connection Status"].String == "Reconnecting" and controls["Connection Status"].Value == 5,
  "Reconnect attempt uses native blue status")
assert(not controls.Connected.Boolean and not controls.Synchronized.Boolean)
socket.Connected()
socket.Data()
assert(controls["Connection Status"].String == "OK", "Valid reply after reconnect restores OK")
local baseline = #attempts
socket.Closed()
assert(controls["Connection Status"].String == "Missing")
assert(timers[1].running, "Unexpected closure must schedule reconnect")
controls.Connect.Boolean = false
controls.Connect.EventHandler(controls.Connect)
assert(not timers[1].running, "Off must cancel scheduled reconnect")
timers[1].EventHandler()
assert(#attempts == baseline, "Stale retry must not reconnect while Off")
assert(not timers[2].running and not timers[3].running)
assert(controls["Connection Status"].String == "Disconnected")
controls["IP Address"].String = "192.0.2.11"
controls["IP Address"].EventHandler(controls["IP Address"])
assert(#attempts == baseline, "IP edit while Off must not reconnect")
controls.Connect.Boolean = true
controls.Connect.EventHandler(controls.Connect)
assert(#attempts == baseline + 1 and attempts[#attempts][1] == "192.0.2.11")
controls.Port.Value = 2203
controls.Port.EventHandler(controls.Port)
assert(#attempts == baseline + 2 and attempts[#attempts][2] == 2203, "Port edit must restart enabled connection")

for _, event in ipairs({ "Error", "Timeout" }) do
  local c, s = fixture("192.0.2.10")
  s[event](s, "network failure")
  assert(c["Connection Status"].String == "Missing", event .. " must set Missing")
end

do
  local c, s = fixture("192.0.2.10")
  s.Reconnect()
  assert(c["Connection Status"].Value == 5 and c["Connection Status"].String == "Reconnecting")
  assert(not c.Connected.Boolean and not c.Synchronized.Boolean)
end

for _, address in ipairs({ "", "  " }) do
  controls, socket, attempts = fixture(address)
  assert(controls.Connect.Boolean and #attempts == 0, "Blank IP must keep Connect On without network activity")
  assert(controls["Connection Status"].String == "Disconnected")
  controls["IP Address"].String = " 192.0.2.12 "
  controls["IP Address"].EventHandler(controls["IP Address"])
  assert(#attempts == 1 and attempts[1][1] == "192.0.2.12", "Setting IP must auto-connect")
end

print("runtime_connection_spec.lua: ok (startup On, confirmed OK, heartbeat, silent loss, Missing, recovery, manual Off)")
