local Diagnostics = {}
Diagnostics.__index = Diagnostics

function Diagnostics.new(level)
  return setmetatable({ level = level or "None" }, Diagnostics)
end

function Diagnostics:set_level(level)
  self.level = level or "None"
end

function Diagnostics:enabled(kind)
  if self.level == "All" then return true end
  if kind == "Tx" then return self.level == "Tx" or self.level == "Tx/Rx" end
  if kind == "Rx" then return self.level == "Rx" or self.level == "Tx/Rx" end
  return false
end

function Diagnostics:tx(message)
  if self:enabled("Tx") then print("TX > " .. tostring(message)) end
end

function Diagnostics:rx(message)
  if self:enabled("Rx") then print("RX < " .. tostring(message)) end
end

function Diagnostics:info(message)
  if self.level == "All" then print("MXCW: " .. tostring(message)) end
end

function Diagnostics:error(message)
  if self.level == "All" then print("MXCW ERROR: " .. tostring(message)) end
end

return Diagnostics
