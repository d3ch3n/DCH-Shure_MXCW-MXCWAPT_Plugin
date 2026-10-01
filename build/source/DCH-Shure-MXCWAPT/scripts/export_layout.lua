assert(loadfile("build/DCH-Shure-MXCWAPT.qplug"))()
local props = {}
for _, property in ipairs(GetProperties()) do props[property.Name] = { Value = property.Value } end
local function row(values)
  for index, value in ipairs(values) do values[index] = '"' .. tostring(value):gsub('"', '""') .. '"' end
  print(table.concat(values, "\t"))
end
row({ "page", "type", "x", "y", "w", "h", "text", "font", "color", "fill" })
for index, page in ipairs(GetPages(props)) do
  props.page_index = { Value = index }
  local layout, graphics = GetControlLayout(props)
  local function emit(item, name)
    local function color(value) return value and table.concat(value, ",") or "" end
    row({ page.name, item.Style or item.Type, item.Position[1], item.Position[2], item.Size[1], item.Size[2],
      item.Text or item.Legend or name or "", item.FontSize or 11,
      color(item.TextColor or item.Color), color(item.Fill or item.Color) })
  end
  for _, item in ipairs(graphics) do emit(item) end
  for name, item in pairs(layout) do emit(item, name) end
end
