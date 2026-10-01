local Protocol = {}

local function trim(s)
  return (s or ""):match("^%s*(.-)%s*$")
end

function Protocol.new_parser()
  return { buffer = "" }
end

function Protocol.feed(parser, chunk)
  parser.buffer = (parser.buffer or "") .. (chunk or "")
  local messages = {}

  while true do
    local start_pos = parser.buffer:find("<", 1, true)
    if not start_pos then
      parser.buffer = ""
      break
    end
    if start_pos > 1 then
      parser.buffer = parser.buffer:sub(start_pos)
    end

    local end_pos = parser.buffer:find(">", 2, true)
    if not end_pos then
      break
    end

    local raw = parser.buffer:sub(1, end_pos)
    parser.buffer = parser.buffer:sub(end_pos + 1)
    local parsed = Protocol.parse_message(raw)
    if parsed then
      messages[#messages + 1] = parsed
    end
  end

  return messages
end

function Protocol.tokenize(payload)
  local tokens, i, n = {}, 1, #payload
  while i <= n do
    while i <= n and payload:sub(i, i):match("%s") do
      i = i + 1
    end
    if i > n then break end

    local ch = payload:sub(i, i)
    if ch == "{" then
      local j = i + 1
      while j <= n and payload:sub(j, j) ~= "}" do
        j = j + 1
      end
      if j <= n then
        tokens[#tokens + 1] = payload:sub(i + 1, j - 1)
        i = j + 1
      else
        tokens[#tokens + 1] = payload:sub(i + 1)
        i = n + 1
      end
    else
      local j = i
      while j <= n and not payload:sub(j, j):match("%s") do
        j = j + 1
      end
      tokens[#tokens + 1] = payload:sub(i, j - 1)
      i = j
    end
  end
  return tokens
end

function Protocol.parse_message(raw)
  if type(raw) ~= "string" then return nil end
  local payload = raw:match("^%s*<%s*(.-)%s*>%s*$")
  if not payload then
    return { raw = raw, verb = "INVALID", command = nil, args = {}, value = nil, index = nil, error = "bad framing" }
  end

  local tokens = Protocol.tokenize(payload)
  local msg = {
    raw = raw,
    payload = trim(payload),
    verb = tokens[1],
    args = tokens,
    index = nil,
    second_index = nil,
    command = nil,
    value = nil,
  }

  if msg.verb == "ERR" then
    msg.command = "ERR"
    return msg
  end

  if msg.verb == "GET" then
    if tonumber(tokens[2]) and tokens[3] then
      msg.index = tonumber(tokens[2])
      if tonumber(tokens[3]) and tokens[4] then
        msg.second_index = tonumber(tokens[3])
        msg.command = tokens[4]
      else
        msg.command = tokens[3]
      end
    else
      msg.command = tokens[2]
    end
    return msg
  end

  if msg.verb == "SET" or msg.verb == "REP" or msg.verb == "SAMPLE" then
    if tonumber(tokens[2]) and tokens[3] then
      msg.index = tonumber(tokens[2])
      if tonumber(tokens[3]) and tokens[4] then
        msg.second_index = tonumber(tokens[3])
        msg.command = tokens[4]
        msg.value = tokens[5]
      else
        msg.command = tokens[3]
        msg.value = tokens[4]
      end
    else
      msg.command = tokens[2]
      msg.value = tokens[3]
    end
    return msg
  end

  msg.command = tokens[2]
  msg.error = "unknown verb"
  return msg
end

function Protocol.format_command(verb, command, value, index, second_index)
  local parts = { verb }
  if index ~= nil then parts[#parts + 1] = tostring(index) end
  if second_index ~= nil then parts[#parts + 1] = tostring(second_index) end
  parts[#parts + 1] = command
  if value ~= nil then
    local s = tostring(value)
    if s:find("%s") and not s:match("^%b{}$") then
      s = "{" .. s .. "}"
    end
    parts[#parts + 1] = s
  end
  return "< " .. table.concat(parts, " ") .. " >"
end

function Protocol.to_bool(value)
  return value == "ON" or value == "TRUE" or value == "ENABLED" or value == "AVAILABLE" or value == "IN_LIST" or value == "ACTIVE"
end

function Protocol.from_bool(value)
  return value and "ON" or "OFF"
end

function Protocol.tpci_to_db(value)
  local n = tonumber(value)
  if not n then return nil end
  return n - 30
end

function Protocol.db_to_tpci(value)
  local n = tonumber(value) or 0
  return string.format("%03d", math.floor(n + 30 + 0.5))
end

return Protocol
