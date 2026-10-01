local Runtime = {}

function Runtime.install(env)
  local Controls = env.Controls
  local TcpSocket = env.TcpSocket
  local Timer = env.Timer
  local Properties = env.Properties
  local Commands = env.Commands
  local Protocol = env.Protocol
  local State = env.State
  local Diagnostics = env.Diagnostics

  local props = env.PluginProperties or {}
  local max_mics = Properties.mic_count(props)
  local state = State.new(max_mics)
  local diag = Diagnostics.new(props["Debug Print"] and props["Debug Print"].Value or "None")
  local parser = Protocol.new_parser()
  local sock = TcpSocket and TcpSocket.New() or nil
  local reconnect_timer = Timer and Timer.New() or nil
  local sync_timer = Timer and Timer.New() or nil
  local reconnect_delay = 5
  local intentional_disconnect = false

  local function ctl(name)
    return Controls and Controls[name]
  end

  for _, definition in ipairs(env.ControlDefinitions or {}) do
    if definition.Choices and ctl(definition.Name) then
      ctl(definition.Name).Choices = definition.Choices
    end
  end

  local function set_string(name, value)
    local c = ctl(name)
    if c then c.String = tostring(value or "") end
  end

  local function set_value(name, value)
    local c = ctl(name)
    if c then c.Value = tonumber(value) or 0 end
  end

  local function set_bool(name, value)
    local c = ctl(name)
    if c then c.Boolean = value == true end
  end

  local function update_connection(status, err)
    state:set_connection(status, err)
    set_string("Connection Status", status)
    set_string("Last Error", err or "")
    set_bool("Connected", status == "Online" or status == "Connected / Synchronizing")
    set_bool("Synchronized", status == "Online")
  end

  local function send_raw(message)
    if not sock then
      update_connection("Fault", "TcpSocket is not available in this runtime")
      return
    end
    diag:tx(message)
    sock:Write(message)
  end

  local function send(verb, command, value, index, second_index)
    send_raw(Protocol.format_command(verb, command, value, index, second_index))
  end

  local function seat_for_station(station)
    return state.station_to_seat[tonumber(station) or 1] or station
  end

  local function selected_station()
    local c = ctl("Selected Station")
    local v = c and tonumber(c.Value) or 1
    if v < 1 then v = 1 end
    if v > max_mics then v = max_mics end
    return math.floor(v)
  end

  local function selected_seat()
    return seat_for_station(selected_station())
  end

  for i = 1, max_mics do
    local seat_control = ctl("Seat Number " .. i)
    if seat_control and tonumber(seat_control.Value) and seat_control.Value >= 1 then
      state:set_station_seat(i, math.floor(seat_control.Value))
    end
  end
  set_value("Selected Seat Number", selected_seat())

  local function apply_global(command, value)
    if command == "GLOBAL_MUTE" then set_bool("Global Mute", Protocol.to_bool(value)) end
    if command == "AUDIO_INPUT_SPEAKLIST" then set_bool("Audio Input Speaklist", Protocol.to_bool(value)) end
    if command == "RF_POWER" then set_string("RF Power", value) end
    if command == "DEVICE_ID" then set_string("Device ID", value) end
    if command == "MODEL" then set_string("Model", value) end
    if command == "OPERATION_MODE" then set_string("Operation Mode", value) end
    if command == "INTERRUPT_MODE" then set_string("Interrupt Mode", value) end
    if command == "MAX_TOTAL_SPEAKERS" then set_value("Max Total Speakers", value) end
    if command == "MAX_DELEGATE_SPEAKERS" then set_value("Max Delegate Speakers", value) end
    if command == "MAX_NUM_REQUESTS" then set_value("Max Num Requests", value) end
    if command == "LOUDSPEAKER_VOLUME" then set_value("Loudspeaker Volume", Protocol.tpci_to_db(value)) end
    if command == "AUX_INPUT_PAD" then set_bool("Aux Input Pad", Protocol.to_bool(value)) end
    if command == "AUX_INPUT_GAIN" then set_value("Aux Input Gain", Protocol.tpci_to_db(value)) end
    if command == "AUX_OUTPUT_GAIN" then set_value("Aux Output Gain", Protocol.tpci_to_db(value)) end
    if command == "AUX_INPUT_AGC" then set_bool("Aux Input AGC", Protocol.to_bool(value)) end
    if command == "AUX_INPUT_MUTE" then set_bool("Aux Input Mute", Protocol.to_bool(value)) end
    if command == "AUX_OUTPUT_MUTE" then set_bool("Aux Output Mute", Protocol.to_bool(value)) end
    if command == "AUDIO_METER_RATE" then set_value("Audio Meter Rate", value) end
    if command == "RF_METER_RATE" then set_value("RF Meter Rate", value) end
    if command == "VOTING_STATE" then set_string("Voting State", value) end
    if command == "VOTING_CONFIGURATION" then set_string("Voting Configuration", value) end
    if command == "WDU_LOCK_WELCOME" then set_bool("WDU Lock Welcome", value == "ENABLED") end
    if command == "RETAIN_SEAT_PERSISTENCE" then set_bool("Retain Seat Persistence", value == "ENABLED") end
  end

  local function apply_indexed(msg)
    local command, value, index = msg.command, msg.value, msg.index
    if command:match("^DANTE_INPUT") then
      local name = command:gsub("_", " "):gsub("(%a)([%w]*)", function(a,b) return a .. b:lower() end)
      if command == "DANTE_INPUT_GAIN" then set_value("Dante Input Gain " .. index, Protocol.tpci_to_db(value)) end
      if command == "DANTE_INPUT_AGC" then set_bool("Dante Input AGC " .. index, Protocol.to_bool(value)) end
      if command == "DANTE_INPUT_MUTE" then set_bool("Dante Input Mute " .. index, Protocol.to_bool(value)) end
      return
    end
    if command:match("^DANTE_OUTPUT") then
      if command == "DANTE_OUTPUT_GAIN" then set_value("Dante Output Gain " .. index, Protocol.tpci_to_db(value)) end
      if command == "DANTE_OUTPUT_MUTE" then set_bool("Dante Output Mute " .. index, Protocol.to_bool(value)) end
      return
    end
    if command == "VOTING_BUTTON_NAME" then set_string("Voting Button Name " .. index, value) return end
    if command == "INTERIM_VOTING_RESULT" then set_string("Interim Voting Result " .. index, value) return end
    if command == "FINAL_VOTING_RESULT" then set_string("Final Voting Result " .. index, value) return end

    local station = state:station_for_seat(index)
    if not station then
      diag:info("Report for unmapped seat " .. tostring(index) .. " command " .. tostring(command))
      return
    end
    if command == "MIC_STATUS" then
      set_bool("Mic Active " .. station, Protocol.to_bool(value))
      if station == selected_station() then set_bool("Selected Mic Status", Protocol.to_bool(value)) end
    end
    if command == "UNIT_AVAILABLE" then set_bool("Mic Online " .. station, value == "AVAILABLE") end
    if command == "SEAT_NAME" then
      set_string("Mic Name " .. station, value)
      set_string("Mic Seat Name " .. station, value)
      if station == selected_station() then set_string("Selected Seat Name", value) end
    end
    if command == "ROLE" then
      set_string("Mic Role " .. station, value)
      set_string("Mic Seat Role " .. station, value)
      if station == selected_station() then set_string("Selected Role", value) end
    end
    if command == "REQUEST_LIST_STATUS" then set_bool("Request List " .. station, value == "IN_LIST") end
    if command == "SPEAK_LIST_STATUS" then set_bool("Speak List " .. station, value == "IN_LIST") end
    if command == "BATT_CHARGE" then set_value("Battery Charge " .. station, value) end
    if command == "BATT_RUN_TIME" then set_string("Battery Runtime " .. station, value) end
    if command == "BATT_HEALTH" then set_value("Battery Health " .. station, value == "255" and 0 or value) end
    if command == "BATT_CYCLE" then set_string("Battery Cycle " .. station, value) end
    if command == "MIC_GAIN" then set_value("Mic Gain " .. station, Protocol.tpci_to_db(value)) end
    if command == "MIC_PRIORITY" then set_value("Mic Priority " .. station, value) end
    if command == "MIC_AGC" then set_bool("Mic AGC " .. station, Protocol.to_bool(value)) end
    if command == "EXCLUSIVE_MUTE" then set_bool("Mic Exclusive Mute " .. station, Protocol.to_bool(value)) end
    if command == "MIC_GAIN" and station == selected_station() then set_value("Selected Mic Gain", Protocol.tpci_to_db(value)) end
    if command == "MIC_PRIORITY" and station == selected_station() then set_value("Selected Mic Priority", value) end
    if command == "MIC_AGC" and station == selected_station() then set_bool("Selected Mic AGC", Protocol.to_bool(value)) end
    if command == "EXCLUSIVE_MUTE" and station == selected_station() then set_bool("Selected Exclusive Mute", Protocol.to_bool(value)) end
    if command == "INTERIM_VOTING_SELECTION" or command == "FINAL_VOTING_SELECTION" then set_string("Voting Selection " .. station, value) end
  end

  local function apply_report(msg)
    state:apply_report(msg)
    if msg.index then apply_indexed(msg) else apply_global(msg.command, msg.value) end
  end

  local function request_initial_state()
    update_connection("Connected / Synchronizing")
    send("GET", "ALL")
    send("GET", "MODEL")
    send("GET", "DEVICE_ID")
    send("GET", "RF_POWER")
    send("GET", "GLOBAL_MUTE")
    send("GET", "OPERATION_MODE")
    send("GET", "INTERRUPT_MODE")
    send("GET", "UNIT_AVAILABLE", nil, 0)
    send("GET", "MIC_STATUS", nil, 0)
    send("GET", "MIC_GAIN", nil, 0)
    send("GET", "MIC_PRIORITY", nil, 0)
    send("GET", "MIC_AGC", nil, 0)
    send("GET", "REQUEST_LIST_STATUS", nil, 0)
    send("GET", "SPEAK_LIST_STATUS", nil, 0)
    send("GET", "ROLE", nil, 0)
    send("GET", "SEAT_NAME", nil, 0)
    send("GET", "BATT_CHARGE", nil, 0)
    send("GET", "BATT_RUN_TIME", nil, 0)
    send("GET", "BATT_HEALTH", nil, 0)
    send("GET", "BATT_CYCLE", nil, 0)
    state.synced = true
    update_connection("Online")
  end

  local function connect()
    if ctl("Connect") and not ctl("Connect").Boolean then return end
    if reconnect_timer then reconnect_timer:Stop() end
    if not sock then return end
    local ip = ctl("IP Address") and ctl("IP Address").String or ""
    ip = ip:match("^%s*(.-)%s*$")
    local port = ctl("Port") and tonumber(ctl("Port").Value) or Commands.DOCUMENT.default_port
    if ip == "" then
      update_connection("Disconnected", "IP Address is empty")
      return
    end
    intentional_disconnect = false
    update_connection("Connecting")
    sock:Connect(ip, port or 2202)
  end

  local function disconnect()
    intentional_disconnect = true
    if reconnect_timer then reconnect_timer:Stop() end
    if sock then sock:Disconnect() end
    update_connection("Disconnected")
  end

  local function schedule_reconnect()
    if intentional_disconnect or not reconnect_timer then return end
    reconnect_timer:Stop()
    reconnect_timer.EventHandler = connect
    reconnect_timer:Start(reconnect_delay)
  end

  if sock then
    sock.Connected = function()
      parser = Protocol.new_parser()
      request_initial_state()
    end
    sock.Reconnect = function()
      update_connection("Connecting")
    end
    sock.Closed = function()
      update_connection("Disconnected")
      schedule_reconnect()
    end
    sock.Error = function(_, err)
      update_connection("Fault", tostring(err or "TCP error"))
      schedule_reconnect()
    end
    sock.Timeout = function()
      update_connection("Fault", "TCP timeout")
      schedule_reconnect()
    end
    sock.Data = function()
      local data = sock:Read(sock.BufferLength)
      diag:rx(data)
      for _, msg in ipairs(Protocol.feed(parser, data)) do
        if msg.verb == "REP" then
          apply_report(msg)
        elseif msg.verb == "ERR" then
          update_connection("Fault", "Device returned ERR")
        elseif msg.error then
          diag:error(msg.error .. ": " .. tostring(msg.raw))
        elseif msg.verb == "SAMPLE" then
          diag:info("SAMPLE " .. tostring(msg.payload))
        else
          diag:info("Unhandled " .. tostring(msg.payload))
        end
      end
    end
  end

  local function on_button(name, fn)
    local c = ctl(name)
    if c then c.EventHandler = function(control) if control.Boolean then fn(control) end end end
  end

  local function on_change(name, fn)
    local c = ctl(name)
    if c then c.EventHandler = function(control) fn(control) end end
  end

  if ctl("Connect") then
    ctl("Connect").EventHandler = function(control)
      if control.Boolean then connect() else disconnect() end
    end
  end
  local function restart_connection()
    if ctl("Connect") and ctl("Connect").Boolean then
      disconnect()
      connect()
    end
  end
  on_change("IP Address", restart_connection)
  on_change("Port", restart_connection)
  on_button("Refresh/Resync", request_initial_state)
  on_button("APT Flash", function() send("SET", "FLASH", "ON") end)
  on_button("All Delegate Mic Off", function() send("SET", "ALL_DELEGATE_MIC_OFF", "TRUE") end)
  on_button("Clear Request List", function() send("SET", "CLEAR_REQUEST_LIST", "TRUE") end)
  on_button("Next Mic On", function() send("SET", "NEXT_MIC_ON", "TRUE") end)
  on_button("WDU Off", function() send("SET", "WDU_OFF", "TRUE") end)
  on_button("Welcome Lock Reset", function() send("SET", "WELCOME_LOCK_RESET", "TRUE") end)
  on_button("Start Vote", function() send("SET", "START_VOTE", math.floor(ctl("Start Vote Configuration").Value or 1)) end)
  on_button("Complete Vote", function() send("SET", "COMPLETE_VOTE", "TRUE") end)
  on_button("Pause Vote", function() send("SET", "PAUSE_VOTE", "TRUE") end)
  on_button("Resume Vote", function() send("SET", "RESUME_VOTE", "TRUE") end)
  on_button("Cancel Vote", function() send("SET", "CANCEL_VOTE", "TRUE") end)
  on_button("Share Voting Results", function() send("SET", "SHARE_VOTING_RESULTS", "TRUE") end)
  on_button("Close Voting Results", function() send("SET", "CLOSE_VOTING_RESULTS", "TRUE") end)

  on_change("Selected Station", function()
    local station = selected_station()
    local seat = seat_for_station(station)
    set_value("Selected Seat Number", seat)
    send("GET", "MIC_STATUS", nil, seat)
    send("GET", "ROLE", nil, seat)
    send("GET", "SEAT_NAME", nil, seat)
    send("GET", "MIC_GAIN", nil, seat)
    send("GET", "MIC_PRIORITY", nil, seat)
    send("GET", "MIC_AGC", nil, seat)
  end)
  on_change("Selected Seat Number", function(control)
    local station = selected_station()
    local seat = math.floor(control.Value or station)
    state:set_station_seat(station, seat)
    set_value("Seat Number " .. station, seat)
  end)

  on_change("Device ID", function(c) send("SET", "DEVICE_ID", c.String) end)
  on_change("RF Power", function(c) send("SET", "RF_POWER", c.String) end)
  on_change("Global Mute", function(c) send("SET", "GLOBAL_MUTE", Protocol.from_bool(c.Boolean)) end)
  on_change("Audio Input Speaklist", function(c) send("SET", "AUDIO_INPUT_SPEAKLIST", Protocol.from_bool(c.Boolean)) end)
  on_change("Operation Mode", function(c) send("SET", "OPERATION_MODE", c.String) end)
  on_change("Interrupt Mode", function(c) send("SET", "INTERRUPT_MODE", c.String) end)
  on_change("Max Total Speakers", function(c) send("SET", "MAX_TOTAL_SPEAKERS", math.floor(c.Value or 1)) end)
  on_change("Max Delegate Speakers", function(c) send("SET", "MAX_DELEGATE_SPEAKERS", math.floor(c.Value or 0)) end)
  on_change("Max Num Requests", function(c) send("SET", "MAX_NUM_REQUESTS", math.floor(c.Value or 0)) end)
  on_change("Loudspeaker Volume", function(c) send("SET", "LOUDSPEAKER_VOLUME", Protocol.db_to_tpci(c.Value)) end)
  on_change("Aux Input Pad", function(c) send("SET", "AUX_INPUT_PAD", Protocol.from_bool(c.Boolean), 1) end)
  on_change("Aux Input Gain", function(c) send("SET", "AUX_INPUT_GAIN", Protocol.db_to_tpci(c.Value), 1) end)
  on_change("Aux Output Gain", function(c) send("SET", "AUX_OUTPUT_GAIN", Protocol.db_to_tpci(c.Value), 1) end)
  on_change("Aux Input AGC", function(c) send("SET", "AUX_INPUT_AGC", Protocol.from_bool(c.Boolean), 1) end)
  on_change("Aux Input Mute", function(c) send("SET", "AUX_INPUT_MUTE", Protocol.from_bool(c.Boolean), 1) end)
  on_change("Aux Output Mute", function(c) send("SET", "AUX_OUTPUT_MUTE", Protocol.from_bool(c.Boolean), 1) end)
  on_change("Audio Meter Rate", function(c) send("SET", "AUDIO_METER_RATE", math.floor(c.Value or 0)) end)
  on_change("RF Meter Rate", function(c) send("SET", "RF_METER_RATE", math.floor(c.Value or 0)) end)

  for i = 1, 10 do
    on_change("Dante Input Gain " .. i, function(c) send("SET", "DANTE_INPUT_GAIN", Protocol.db_to_tpci(c.Value), i) end)
    on_change("Dante Output Gain " .. i, function(c) send("SET", "DANTE_OUTPUT_GAIN", Protocol.db_to_tpci(c.Value), i) end)
    on_change("Dante Input AGC " .. i, function(c) send("SET", "DANTE_INPUT_AGC", Protocol.from_bool(c.Boolean), i) end)
    on_change("Dante Input Mute " .. i, function(c) send("SET", "DANTE_INPUT_MUTE", Protocol.from_bool(c.Boolean), i) end)
    on_change("Dante Output Mute " .. i, function(c) send("SET", "DANTE_OUTPUT_MUTE", Protocol.from_bool(c.Boolean), i) end)
  end

  on_change("Selected Seat Name", function(c) send("SET", "SEAT_NAME", c.String, selected_seat()) end)
  on_change("Selected Role", function(c) send("SET", "ROLE", c.String, selected_seat()) end)
  on_change("Selected Mic Gain", function(c) send("SET", "MIC_GAIN", Protocol.db_to_tpci(c.Value), selected_seat()) end)
  on_change("Selected Mic Priority", function(c) send("SET", "MIC_PRIORITY", math.floor(c.Value or 0), selected_seat()) end)
  on_change("Selected Mic AGC", function(c) send("SET", "MIC_AGC", Protocol.from_bool(c.Boolean), selected_seat()) end)
  on_change("Selected Mic Status", function(c) send("SET", "MIC_STATUS", Protocol.from_bool(c.Boolean), selected_seat()) end)
  on_button("Selected Speak Request", function() send("SET", "SPEAK_REQUEST", "TRUE", selected_seat()) end)
  on_button("Selected Speak Release", function() send("SET", "SPEAK_RELEASE", "TRUE", selected_seat()) end)
  on_change("Selected Exclusive Mute", function(c) send("SET", "EXCLUSIVE_MUTE", Protocol.from_bool(c.Boolean), selected_seat()) end)
  on_button("Selected Flash", function() send("SET", "FLASH", "ON", selected_seat()) end)

  for i = 1, max_mics do
    on_change("Seat Number " .. i, function(c)
      state:set_station_seat(i, math.floor(c.Value or i))
      if i == selected_station() then set_value("Selected Seat Number", seat_for_station(i)) end
    end)
    on_change("Mic Active " .. i, function(c) send("SET", "MIC_STATUS", Protocol.from_bool(c.Boolean), seat_for_station(i)) end)
    on_change("Mic Seat Name " .. i, function(c) send("SET", "SEAT_NAME", c.String, seat_for_station(i)) end)
    on_change("Mic Seat Role " .. i, function(c) send("SET", "ROLE", c.String, seat_for_station(i)) end)
    on_change("Mic Gain " .. i, function(c) send("SET", "MIC_GAIN", Protocol.db_to_tpci(c.Value), seat_for_station(i)) end)
    on_change("Mic Priority " .. i, function(c) send("SET", "MIC_PRIORITY", math.floor(c.Value or 0), seat_for_station(i)) end)
    on_change("Mic AGC " .. i, function(c) send("SET", "MIC_AGC", Protocol.from_bool(c.Boolean), seat_for_station(i)) end)
    on_button("Mic Speak Request " .. i, function() send("SET", "SPEAK_REQUEST", "TRUE", seat_for_station(i)) end)
    on_button("Mic Speak Release " .. i, function() send("SET", "SPEAK_RELEASE", "TRUE", seat_for_station(i)) end)
    on_change("Mic Exclusive Mute " .. i, function(c) send("SET", "EXCLUSIVE_MUTE", Protocol.from_bool(c.Boolean), seat_for_station(i)) end)
    on_button("Mic Flash " .. i, function() send("SET", "FLASH", "ON", seat_for_station(i)) end)
  end

  update_connection("Disconnected")
  set_bool("Connect", true)
  connect()
end

return Runtime
