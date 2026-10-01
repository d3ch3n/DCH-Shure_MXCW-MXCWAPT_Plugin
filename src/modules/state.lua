local State = {}

function State.new(max_mics)
  local self = {
    max_mics = max_mics or 16,
    connection = "Disconnected",
    synced = false,
    last_error = "",
    seats = {},
    globals = {},
    dante_inputs = {},
    dante_outputs = {},
    voting_buttons = {},
    voting_configs = {},
    station_to_seat = {},
    seat_to_station = {},
  }
  for i = 1, self.max_mics do
    self.station_to_seat[i] = i
    self.seat_to_station[i] = i
    self.seats[i] = { seat_number = i }
  end
  for i = 1, 10 do
    self.dante_inputs[i] = {}
    self.dante_outputs[i] = {}
  end
  for i = 1, 5 do
    self.voting_buttons[i] = {}
  end
  for i = 1, 50 do
    self.voting_configs[i] = {}
  end
  return self
end

function State:set_connection(status, err)
  self.connection = status
  self.last_error = err or self.last_error or ""
end

function State:set_station_seat(station, seat)
  station, seat = tonumber(station), tonumber(seat)
  if not station or station < 1 or station > self.max_mics or not seat then return end
  local old = self.station_to_seat[station]
  if old then self.seat_to_station[old] = nil end
  self.station_to_seat[station] = seat
  self.seat_to_station[seat] = station
  self.seats[seat] = self.seats[seat] or { seat_number = seat }
end

function State:station_for_seat(seat)
  return self.seat_to_station[tonumber(seat)]
end

function State:apply_report(msg)
  if not msg or msg.verb ~= "REP" then return nil end
  if msg.command == "ERR" then
    self.last_error = "Device returned ERR"
    return "error"
  end

  local command = msg.command
  local idx = msg.index
  local value = msg.value

  if idx then
    local target
    if command and command:match("^DANTE_INPUT") then
      target = self.dante_inputs[idx] or {}
      self.dante_inputs[idx] = target
    elseif command and command:match("^DANTE_OUTPUT") then
      target = self.dante_outputs[idx] or {}
      self.dante_outputs[idx] = target
    elseif command == "VOTING_CONFIGURATION_NAME" then
      target = self.voting_configs[idx] or {}
      self.voting_configs[idx] = target
    elseif command == "VOTING_BUTTON_NAME" or command == "INTERIM_VOTING_RESULT" or command == "FINAL_VOTING_RESULT" then
      target = self.voting_buttons[idx] or {}
      self.voting_buttons[idx] = target
    else
      target = self.seats[idx] or { seat_number = idx }
      self.seats[idx] = target
    end
    target[command] = value
  else
    self.globals[command] = value
  end

  return command
end

return State
