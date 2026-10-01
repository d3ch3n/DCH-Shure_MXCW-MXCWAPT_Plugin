package.path = "./?.lua;./?/init.lua;" .. package.path

local Controls = require("src.modules.controls")
local Layout = require("src.modules.layout")

local function overlaps(a, b)
  return a.Position[1] < b.Position[1] + b.Size[1] and
    b.Position[1] < a.Position[1] + a.Size[1] and
    a.Position[2] < b.Position[2] + b.Size[2] and
    b.Position[2] < a.Position[2] + a.Size[2]
end

for _, n in ipairs({ 1, 16, 17, 20, 125 }) do
  for _, show in ipairs({ false, true }) do
  local props = { ["Number of Microphones"] = { Value = n }, ["Show Individual Microphones"] = { Value = show } }
  local definitions, seen = {}, {}
  for _, control in ipairs(Controls.get(props)) do
    assert(not control.UserPin, "Default pin exposed: " .. control.Name)
    definitions[control.Name] = control
    assert(control.ControlType ~= "Meter", "Invalid Q-SYS control type")
    if control.ControlType == "Indicator" then assert(control.IndicatorType) end
    if control.ControlType == "Knob" then
      assert(control.ControlUnit and control.Min < control.Max, control.Name .. " invalid numeric definition")
    end
  end
  for index, page in ipairs(Layout.get_pages(props)) do
    props.page_index = { Value = index }
    local layout, graphics = Layout.get_layout(props)
    if page.name == "Dante" then
      for channel = 1, 10 do
        local row_labels = 0
        for _, graphic in ipairs(graphics) do
          if graphic.Type == "Label" and graphic.Text == "CH " .. channel then
            row_labels = row_labels + 1
          end
        end
        assert(row_labels == 2, "Dante channel must be identified in both rows: " .. channel)
      end
    end
    local visible = {}
    for name, definition in pairs(definitions) do
      local item = layout[name]
      if item and item.Style ~= "None" then
        seen[name] = true
        visible[#visible + 1] = { name = name, item = item }
        if definition.ControlType == "Button" then
          assert(item.Style == "Button" and item.ButtonStyle == definition.ButtonType, name)
        elseif definition.Choices then assert(item.Style == "ComboBox", name)
        elseif definition.IndicatorType == "Led" then assert(item.Style == "Led", name)
        else assert(item.Style == "Text" or (item.Style == "Fader" and definition.ControlUnit == "dB"), name) end
      end
    end
    for _, graphic in ipairs(graphics) do
      assert(graphic.Type == "Label" or graphic.Type == "GroupBox" or graphic.Type == "Image", "Invalid graphic type")
      if graphic.Type == "Label" then visible[#visible + 1] = { name = graphic.Text, item = graphic } end
      if graphic.Type == "Image" then visible[#visible + 1] = { name = graphic.Name, item = graphic } end
    end
    for i, element in ipairs(visible) do
      local item = element.item
      assert(item.Position[1] >= 0 and item.Position[2] >= 0 and
        item.Position[1] + item.Size[1] <= Layout.WIDTH and
        item.Position[2] + item.Size[2] <= Layout.HEIGHT, page.name .. ": out of bounds " .. element.name)
      assert(item.Size[2] <= 24 or item.Style == "Fader" or item.Type == "Image", page.name .. ": oversized " .. element.name)
      for j = i + 1, #visible do
        assert(not overlaps(item, visible[j].item), page.name .. ": overlap " .. element.name .. " / " .. visible[j].name)
      end
    end
  end
  for name in pairs(definitions) do assert(seen[name], "Control never displayed: " .. name) end
  local individual_pages = 0
  for _, page in ipairs(Layout.get_pages(props)) do
    if page.name:match("^Microphone %d+$") then individual_pages = individual_pages + 1 end
  end
  assert(individual_pages == (show and n or 0), "Individual page count")
  assert((definitions["Mic Gain 1"] ~= nil) == show, "Optional controls must match property")
  for _, mode in ipairs({ "Microphones", "All" }) do
    props["Control Pins"] = { Value = mode }
    for _, control in ipairs(Controls.get(props)) do
      assert(control.UserPin == false and control.PinStyle == "None", "Legacy property exposed pin: " .. control.Name)
    end
  end
  end
end

print("layout_spec.lua: ok (all pages, 1/16/17/20/125 stations, geometry, coverage, no pins)")
