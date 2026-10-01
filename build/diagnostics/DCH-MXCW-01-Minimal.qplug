PluginInfo = {
  Name = "DCH~Shure~MXCW-MXCWAPT Diagnostics~01 Minimal",
  Version = "0.1.3",
  BuildVersion = "0.1.3.0",
  Id = "41d6c23e-d3fb-4b51-a463-b175bd1c74ed",
  Author = "DCH",
  Description = "MXCW Designer insertion diagnostic: two controls, one page, no runtime.",
}

function GetPrettyName(props)
  return "MXCW Diagnostic - Minimal"
end

function GetColor(props)
  return { 65, 160, 94 }
end

function GetProperties()
  return {}
end

function GetControls(props)
  return {
    { Name = "Address", ControlType = "Text", Count = 1, UserPin = false },
    { Name = "Enable", ControlType = "Button", ButtonType = "Toggle", Count = 1, UserPin = false },
  }
end

function GetControlLayout(props)
  return {
    Address = { Style = "Text", Position = { 16, 16 }, Size = { 220, 24 } },
    Enable = { Style = "Button", ButtonStyle = "Toggle", Legend = "Enable", Position = { 16, 52 }, Size = { 100, 24 } },
  }, {}
end
