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

local probe_env = setmetatable({
  Controls = {},
  TcpSocket = { New = function() error("Probe opens sockets") end },
  Timer = { New = function() error("Probe creates timers") end },
}, { __index = _G })
assert(loadfile("build/diagnostics/DCH-MXCW-03-Page-Probe.qplug", "t", probe_env))()
assert(probe_env.GetPages == nil, "Probe must have one default page")
local props = {}
local page_choices
for _, property in ipairs(probe_env.GetProperties()) do
  props[property.Name] = { Value = property.Value }
  if property.Name == "Diagnostic Page" then page_choices = property.Choices end
end
assert(#probe_env.GetControls(props) == 8, "Default probe must contain only Setup controls")
for _, n in ipairs({ 1, 16, 125 }) do
  props["Number of Microphones"].Value = n
  for _, page in ipairs(page_choices) do
    props["Diagnostic Page"].Value = page
    for _, scope in ipairs({ "Page Controls", "All Controls" }) do
      props["Diagnostic Scope"].Value = scope
      for _, appearance in ipairs({ "Original", "Plain" }) do
        props["Diagnostic Appearance"].Value = appearance
        local controls = probe_env.GetControls(props)
        local layout, graphics = probe_env.GetControlLayout(props)
        local count = 0
        for _ in pairs(layout) do count = count + 1 end
        assert(count == #controls, page .. ": layout/control mismatch")
        for _, control in ipairs(controls) do
          assert(not control.UserPin and layout[control.Name])
        end
        if appearance == "Plain" then assert(#graphics == 0) end
      end
    end
  end
end
print("page probe: ok (single-page subsets, scopes and appearances, 1/16/125 units)")
