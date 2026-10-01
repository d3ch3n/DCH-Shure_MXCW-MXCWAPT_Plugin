local Properties = {}

function Properties.get()
  return {
    {
      Name = "Number of Microphones",
      Type = "integer",
      Min = 1,
      Max = 125,
      Value = 16,
    },
    {
      Name = "Control Pins",
      Type = "enum",
      Choices = { "None", "Microphones", "All" },
      Value = "None",
    },
    {
      Name = "Debug Print",
      Type = "enum",
      Choices = { "None", "Tx", "Rx", "Tx/Rx", "All" },
      Value = "None",
    },
  }
end

function Properties.mic_count(props)
  local value = props and props["Number of Microphones"] and props["Number of Microphones"].Value
  value = tonumber(value) or 16
  if value < 1 then return 1 end
  if value > 125 then return 125 end
  return math.floor(value)
end

return Properties
