for _, path in ipairs({ "build/diagnostics/DCH-MXCW-01-Minimal.qplug", "build/diagnostics/DCH-MXCW-02-UI-Only.qplug" }) do
  local env = setmetatable({
    Controls = {},
    TcpSocket = { New = function() error("Diagnostic opens sockets") end },
    Timer = { New = function() error("Diagnostic creates timers") end },
  }, { __index = _G })
  assert(loadfile(path, "t", env))()
  local props = {}
  for _, property in ipairs(env.GetProperties()) do props[property.Name] = { Value = property.Value } end
  local controls = env.GetControls(props)
  local pages = env.GetPages and env.GetPages(props) or { { name = "Default" } }
  for index in ipairs(pages) do
    props.page_index = { Value = index }
    local layout, graphics = env.GetControlLayout(props)
    assert(type(layout) == "table" and type(graphics) == "table")
  end
  for _, control in ipairs(controls) do assert(not control.UserPin) end
  assert(env.PluginInfo.Id ~= "dch.shure.mxcwapt.control")
end
print("diagnostics_spec.lua: ok (minimal and full UI, no sockets/timers)")
