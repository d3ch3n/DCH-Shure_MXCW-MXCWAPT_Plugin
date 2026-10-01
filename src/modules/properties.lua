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
      Name = "Show Individual Microphones",
      Type = "boolean",
      Value = false,
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

function Properties.individual_microphones(props)
  return props and props["Show Individual Microphones"] and props["Show Individual Microphones"].Value == true or false
end

return Properties
