package.path = "./?.lua;./?/init.lua;" .. package.path

local Protocol = require("src.modules.protocol")
local Commands = require("src.modules.commands")
local Properties = require("src.modules.properties")
local Controls = require("src.modules.controls")

local function assert_eq(actual, expected, label)
  if actual ~= expected then
    error((label or "assertion") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
  end
end

local function count_order()
  local seen = {}
  for _, name in ipairs(Commands.ORDER) do
    if seen[name] then error("duplicate command in ORDER: " .. name) end
    seen[name] = true
    if not Commands[name] then error("missing command definition: " .. name) end
  end
  return #Commands.ORDER
end

assert_eq(count_order(), 64, "official command count")
assert_eq(Commands.DOCUMENT.default_port, 2202, "default port")

local parser = Protocol.new_parser()
local messages = Protocol.feed(parser, "< REP 1 MIC_STATUS ON >< REP GLOBAL_MUTE OFF >")
assert_eq(#messages, 2, "concatenated message count")
assert_eq(messages[1].verb, "REP", "first verb")
assert_eq(messages[1].index, 1, "first index")
assert_eq(messages[1].command, "MIC_STATUS", "first command")
assert_eq(messages[1].value, "ON", "first value")
assert_eq(messages[2].command, "GLOBAL_MUTE", "second command")

parser = Protocol.new_parser()
messages = Protocol.feed(parser, "< REP 10 SE")
assert_eq(#messages, 0, "fragment before completion")
messages = Protocol.feed(parser, "AT_NAME {Ana Maria} >< REP ERR >")
assert_eq(#messages, 2, "fragment after completion")
assert_eq(messages[1].command, "SEAT_NAME", "fragmented command")
assert_eq(messages[1].value, "Ana Maria", "braced string value")
assert_eq(messages[2].verb, "REP", "err verb")
assert_eq(messages[2].command, "ERR", "err command")

local nested = Protocol.parse_message("< REP 3 2 VOTING_BUTTON_NAME {Abstain Vote} >")
assert_eq(nested.index, 3, "nested first index")
assert_eq(nested.second_index, 2, "nested second index")
assert_eq(nested.command, "VOTING_BUTTON_NAME", "nested command")
assert_eq(nested.value, "Abstain Vote", "nested value")

assert_eq(Protocol.format_command("SET", "SEAT_NAME", "Ana Maria", 2), "< SET 2 SEAT_NAME {Ana Maria} >", "format braced")
assert_eq(Protocol.tpci_to_db("030"), 0, "tpci to db")
assert_eq(Protocol.db_to_tpci(-12), "018", "db to tpci")

for _, n in ipairs({ 1, 16, 20, 125 }) do
  local props = { ["Number of Microphones"] = { Value = n } }
  local controls = Controls.get(props)
  local mic_active = 0
  for _, control in ipairs(controls) do
    if control.Name:match("^Mic Active %d+$") then mic_active = mic_active + 1 end
  end
  assert_eq(mic_active, n, "dynamic mic controls " .. n)
end

print("parser_spec.lua: ok")
