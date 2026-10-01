package.path = "./?.lua;./?/init.lua;" .. package.path
local ControlsDef = require("src.modules.controls")
local Properties = require("src.modules.properties")
local Runtime = require("src.modules.runtime")
local State = require("src.modules.state")

local props = { ["Number of Microphones"] = { Value = 2 }, ["Show Individual Microphones"] = { Value = true } }
local controls, sent = {}, {}
for _, definition in ipairs(ControlsDef.native(props)) do
  controls[definition.Name] = {
    String = "", Boolean = false,
    Value = type(definition.DefaultValue) == "number" and definition.DefaultValue or 0,
  }
  assert(definition.UserPin == false and definition.PinStyle == "None")
end
controls["Seat Number 1"].Value = 7
controls["Seat Number 2"].Value = 42
local payload = ""
local socket = {
  BufferLength = 0,
  Read = function() return payload end,
  Write = function(_, message) sent[#sent + 1] = message end,
  Connect = function() error("Blank address must not connect") end,
}
Runtime.install({
  Controls = controls, PluginProperties = props, Properties = Properties,
  ControlDefinitions = ControlsDef.get(props),
  TcpSocket = { New = function() return socket end },
  Commands = require("src.modules.commands"), Protocol = require("src.modules.protocol"),
  State = State, Diagnostics = require("src.modules.diagnostics"),
})
local function change(name, field, value, expected)
  controls[name][field] = value
  controls[name].EventHandler(controls[name])
  if expected then assert(sent[#sent] == expected, name .. ": " .. tostring(sent[#sent])) end
end

assert(controls["Selected Seat Number"].Value == 7, "Restore configured seat mapping")
change("Mic Gain 2", "Value", -12, "< SET 42 MIC_GAIN 018 >")
change("Mic Seat Name 1", "String", "Ana Maria", "< SET 7 SEAT_NAME {Ana Maria} >")
change("Mic Seat Role 2", "String", "CHAIRMAN", "< SET 42 ROLE CHAIRMAN >")
change("Mic AGC 2", "Boolean", true, "< SET 42 MIC_AGC ON >")
change("Mic Speak Request 2", "Boolean", true, "< SET 42 SPEAK_REQUEST TRUE >")
change("Mic Speak Release 2", "Boolean", true, "< SET 42 SPEAK_RELEASE TRUE >")
change("Mic Exclusive Mute 2", "Boolean", true, "< SET 42 EXCLUSIVE_MUTE ON >")
change("Mic Flash 1", "Boolean", true, "< SET 7 FLASH ON >")
assert(controls["Selected Station"].Value == 1, "Individual pages must not change the selected station")

payload = "< REP 42 MIC_GAIN 022 >< REP 42 MIC_PRIORITY 3 >< REP 42 MIC_AGC ON >" ..
  "< REP 42 ROLE CHAIRMAN >< REP 42 SEAT_NAME {Bruno} >< REP 42 BATT_CHARGE 090 >" ..
  "< REP 7 MIC_STATUS ON >< REP 7 MIC_GAIN 030 >< REP 7 SEAT_NAME {Ana} >"
socket.Data()
assert(controls["Mic Gain 2"].Value == -8 and controls["Mic Priority 2"].Value == 3)
assert(controls["Mic AGC 2"].Boolean and controls["Mic Seat Role 2"].String == "CHAIRMAN")
assert(controls["Mic Seat Name 2"].String == "Bruno" and controls["Battery Charge 2"].Value == 90)
assert(controls["Selected Mic Status"].Boolean and controls["Selected Mic Gain"].Value == 0)
assert(controls["Selected Seat Name"].String == "Ana" and controls["Mic Seat Name 1"].String == "Ana")
change("Selected Seat Number", "Value", 99)
assert(controls["Seat Number 1"].Value == 99, "General page mapping must update individual page")
change("Mic Gain 1", "Value", -3, "< SET 99 MIC_GAIN 027 >")
change("Seat Number 1", "Value", 100)
assert(controls["Selected Seat Number"].Value == 100, "Individual mapping must update general page")

local swapped = State.new(2)
swapped:set_station_seat(1, 2)
swapped:set_station_seat(2, 1)
assert(swapped:station_for_seat(2) == 1 and swapped:station_for_seat(1) == 2, "Swapped seat mapping")
print("individual_microphones_spec.lua: ok (independent controls, feedback, seat mapping, general page sync)")
