local path = "build/DCH-Shure-MXCWAPT.qplug"
local file = assert(io.open(path, "r"))
local source = file:read("*a")
file:close()
assert(source:match("^PluginInfo = %{"), "PluginInfo must be first")
assert(not source:find("package.preload", 1, true), "Bundle must not mutate the shared module registry")
assert(not source:find("__SHURE_LOGO_BASE64__", 1, true), "Logo asset was not embedded")

local function environment()
  return {
    assert = assert, error = error, ipairs = ipairs, pairs = pairs, next = next,
    tonumber = tonumber, tostring = tostring, type = type, select = select,
    setmetatable = setmetatable,
    math = math, string = string, table = table,
    print = function() end,
    -- No package, global require, filesystem, sockets or timers during design time.
  }
end

local function with_budget(fn)
  local ticks = 0
  debug.sethook(function()
    ticks = ticks + 1
    assert(ticks < 5000, "Design-time instruction budget exceeded")
  end, "", 10000)
  local ok, err = pcall(fn)
  debug.sethook()
  assert(ok, err)
end

local function properties(env, count)
  local props = {}
  for _, property in ipairs(env.GetProperties()) do props[property.Name] = { Value = property.Value } end
  props["Number of Microphones"].Value = count
  return props
end

for _, count in ipairs({ 1, 16, 17, 20, 125 }) do
  with_budget(function()
    local env = environment()
    assert(load(source, "@" .. path, "t", env))()
    assert(env.package == nil and env.require == nil, "Bundle polluted global module state")
    local props = properties(env, count)
    local controls = env.GetControls(props)
    assert(#env.GetPins(props) == 0 and env.PluginInfo.ShowDebug == false)
    props.plugin_show_debug = { Value = true }
    env.RectifyProperties(props)
    assert(not props.plugin_show_debug.Value and props.plugin_show_debug.IsHidden)
    local pages = env.GetPages(props)
    local seen = {}
    assert(#controls > 0 and #pages > 0)
    for index in ipairs(pages) do
      props.page_index = { Value = index }
      local layout = env.GetControlLayout(props)
      for _, control in ipairs(controls) do
        local item = layout[control.Name]
        if item then seen[control.Name] = true end
        assert(not control.UserPin, "Pins must be disabled by default")
        assert(control.PinStyle == "None" and control.ReadOnly == nil, "Native control exposes pins or private metadata")
        assert(control.Choices == nil, "Choices is not a native GetControls property")
        assert(not item or item.Style ~= "None", "Do not repeat hidden controls on every page")
      end
    end
    for _, control in ipairs(controls) do assert(seen[control.Name], "Orphan control: " .. control.Name) end
  end)
end

-- Designer callbacks can execute in separate Lua environments.
for _, callback in ipairs({ "GetProperties", "GetControls", "GetPages", "GetControlLayout" }) do
  with_budget(function()
    local env = environment()
    assert(load(source, "@" .. path, "t", env))()
    assert(type(env[callback]) == "function")
    assert(type(env[callback](properties(env, 16))) == "table")
  end)
end

-- Emulation initializes handlers but must not connect or send on insertion.
with_budget(function()
  local env = environment()
  assert(load(source, "@" .. path, "t", env))()
  env.Properties = properties(env, 16)
  env.Controls = {}
  for _, control in ipairs(env.GetControls(env.Properties)) do
    env.Controls[control.Name] = { Value = control.DefaultValue or 0, String = "", Boolean = false }
  end
  env.TcpSocket = { New = function()
    return {
      Connect = function() error("Unexpected connection at insertion") end,
      Write = function() error("Unexpected send at insertion") end,
    }
  end }
  env.Timer = { New = function()
    return { Start = function() error("Unexpected timer at insertion") end, Stop = function() end }
  end }
  assert(load(source, "@" .. path, "t", env))()
  assert(env.Controls["Connection Status"].String == "Disconnected")
  assert(type(env.Controls["Connect"].EventHandler) == "function")
  assert(env.Controls["RF Power"].Choices[1] == "OFF")

  local socket = { BufferLength = 0 }
  socket.Read = function() return "< REP GLOBAL_MUTE ON >< REP 1 UNIT_AVAILABLE AVAILABLE >" end
  socket.Write = function(_, message) assert(message:match("^< SET ")) end
  socket.Connect = function() end
  socket.Disconnect = function() end
  env.TcpSocket.New = function() return socket end
  assert(load(source, "@" .. path, "t", env))()
  socket.Data()
  assert(env.Controls["Global Mute"].Boolean)
  assert(env.Controls["Mic Online 1"].Boolean)
  env.Controls["Global Mute"].EventHandler(env.Controls["Global Mute"])
end)

print("plugin_load_spec.lua: ok (restricted environment, fresh callbacks, all pages, idle runtime)")
