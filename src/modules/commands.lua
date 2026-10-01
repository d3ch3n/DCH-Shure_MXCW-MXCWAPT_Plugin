local Commands = {}

Commands.DOCUMENT = {
  title = "MXCWAPT Microflex Complete Wireless Command Strings",
  source_url = "https://www.shure.com/en-US/docs/commandstrings/MXCW",
  doc_id = "6944",
  pub_id = "p_31597010-4d03-4506-ab58-811c4f5cda42",
  pub_version = "8.2",
  pub_date_code = "2025-F",
  default_port = 2202,
}

local function add(name, scope, verbs, values, control, notes)
  Commands[name] = {
    name = name,
    scope = scope,
    get = verbs.get == true,
    set = verbs.set == true,
    rep = verbs.rep == true,
    values = values or "",
    control = control or "",
    notes = notes or "",
  }
end

add("MIC_STATUS", "seat", { get=true, set=true, rep=true }, "OFF, ON, UNKNOWN", "per-seat toggle and output", "GET 0 returns all online registered seats.")
add("SPEAK_REQUEST", "seat", { set=true }, "TRUE, UNKNOWN", "per-seat trigger", "Creates a speak/request list entry depending on operation mode.")
add("SPEAK_RELEASE", "seat", { set=true }, "TRUE, UNKNOWN", "per-seat trigger", "Releases from speaker or request list.")
add("ALL_DELEGATE_MIC_OFF", "global", { set=true }, "TRUE", "trigger", "Turns all delegate microphones off.")
add("EXCLUSIVE_MUTE", "seat", { set=true, rep=true }, "OFF, ON, UNKNOWN", "per-seat toggle/output", "Seat must be a chairman.")
add("GLOBAL_MUTE", "global", { get=true, set=true, rep=true }, "OFF, ON", "toggle/output", "Represents global mute held by one or more controllers.")
add("REQUEST_LIST_STATUS", "seat", { get=true, rep=true }, "NOT_IN_LIST, IN_LIST, UNKNOWN", "per-seat indicator", "GET 0 returns all registered seats.")
add("SPEAK_LIST_STATUS", "seat", { get=true, rep=true }, "NOT_IN_LIST, IN_LIST, UNKNOWN", "per-seat indicator", "GET 0 returns all registered seats.")
add("CLEAR_REQUEST_LIST", "global", { set=true }, "TRUE", "trigger", "No response when list is already empty.")
add("NEXT_MIC_ON", "global", { set=true }, "TRUE", "trigger", "Turns next microphone in request list on.")
add("MAX_TOTAL_SPEAKERS", "global", { get=true, set=true, rep=true }, "numeric, 1 character", "integer control", "")
add("MAX_DELEGATE_SPEAKERS", "global", { get=true, set=true, rep=true }, "numeric, 1 character", "integer control", "")
add("MAX_NUM_REQUESTS", "global", { get=true, set=true, rep=true }, "numeric, 1 character", "integer control", "")
add("OPERATION_MODE", "global", { get=true, set=true, rep=true }, "AUTO, MANUAL, FIFO, HANDSFREE", "combo box", "")
add("INTERRUPT_MODE", "global", { get=true, set=true, rep=true }, "NOT_ALLOWED, HIGHER_PRIORITY, EQUAL_AND_HIGHER_PRIORITY", "combo box", "")
add("MIC_PRIORITY", "seat", { get=true, set=true, rep=true }, "numeric, 1 character, UNKNOWN", "per-seat integer", "GET/SET 0 applies to registered devices.")
add("LOUDSPEAKER_VOLUME", "global", { get=true, set=true, rep=true }, "000..036 offset, actual -30..6 dB", "knob", "TPCI value = dB + 30.")
add("AUX_INPUT_PAD", "aux_input", { get=true, set=true, rep=true }, "OFF, ON", "toggle", "Index 0 or 1 addresses aux input.")
add("AUX_INPUT_GAIN", "aux_input", { get=true, set=true, rep=true }, "000..040 offset, actual -30..10 dB", "knob", "TPCI value = dB + 30.")
add("AUX_OUTPUT_GAIN", "aux_output", { get=true, set=true, rep=true }, "000..030 offset, actual -30..0 dB", "knob", "TPCI value = dB + 30.")
add("MIC_GAIN", "seat", { get=true, set=true, rep=true }, "000..040 offset, actual -30..10 dB, UNKNOWN", "per-seat knob", "AGC can affect behavior.")
add("DANTE_INPUT_GAIN", "dante_input", { get=true, set=true, rep=true }, "000..040 offset, actual -30..10 dB", "10 indexed knobs", "")
add("DANTE_OUTPUT_GAIN", "dante_output", { get=true, set=true, rep=true }, "000..030 offset, actual -30..0 dB", "10 indexed knobs", "")
add("AUX_INPUT_AGC", "aux_input", { get=true, set=true, rep=true }, "OFF, ON", "toggle", "")
add("DANTE_INPUT_AGC", "dante_input", { get=true, set=true, rep=true }, "OFF, ON", "10 indexed toggles", "")
add("DANTE_INPUT_MUTE", "dante_input", { get=true, set=true, rep=true }, "OFF, ON", "10 indexed toggles", "")
add("DANTE_OUTPUT_MUTE", "dante_output", { get=true, set=true, rep=true }, "OFF, ON", "10 indexed toggles", "")
add("MIC_AGC", "seat", { get=true, set=true, rep=true }, "OFF, ON, UNKNOWN", "per-seat toggle", "GET/SET 0 applies to online registered seats.")
add("FLASH", "apt_or_seat", { get=true, set=true, rep=true }, "OFF, ON, UNKNOWN", "APT and per-seat trigger/toggle", "No index flashes APT; seat index flashes conference unit.")
add("ROLE", "seat", { get=true, set=true, rep=true }, "DELEGATE, CHAIRMAN, LISTENER, AMBIENT, REMOTE_CALLER, DUAL_DELEGATE, UNKNOWN", "per-seat combo", "Dual delegate role can change available seat reports.")
add("SEAT_NAME", "seat", { get=true, set=true, rep=true }, "UTF-8 text in braces, max SET 128 bytes", "per-seat text", "NFC card can override reported name.")
add("RF_POWER", "global", { get=true, set=true, rep=true }, "OFF, LOW, MEDIUM, HIGH, MAXIMUM", "combo box", "")
add("DEVICE_ID", "global", { get=true, set=true, rep=true }, "1..31 chars A-Z a-z 0-9 hyphen", "text", "Cannot begin or end with hyphen.")
add("ALL", "global", { get=true, rep=true }, "all supported reports", "resync trigger", "Used for broad synchronization.")
add("BATT_CHARGE", "seat", { get=true, rep=true }, "000..100 percent, UNKNOWN", "per-seat meter", "GET 0 returns all online registered seats.")
add("BATT_RUN_TIME", "seat", { get=true, rep=true }, "00000..65535 minutes, UNKNOWN", "per-seat meter/text", "")
add("BATT_CYCLE", "seat", { get=true, rep=true }, "0000..9999 cycles, UNKNOWN", "per-seat text", "")
add("BATT_HEALTH", "seat", { get=true, rep=true }, "000..100 percent, 255 unknown", "per-seat meter", "")
add("UNIT_AVAILABLE", "seat", { get=true, rep=true }, "AVAILABLE, OFFLINE, NOT_REGISTERED", "per-seat indicator", "GET 0 returns all registered seats.")
add("AUDIO_METER_RATE", "global", { get=true, set=true, rep=true }, "0 off, 100..99999 ms", "integer control", "Enables SAMPLE audio meter reports.")
add("RF_METER_RATE", "global", { get=true, set=true, rep=true }, "0 off, 100..99999 ms", "integer control", "Enables SAMPLE RF meter reports.")
add("AUX_INPUT_MUTE", "aux_input", { get=true, set=true, rep=true }, "OFF, ON", "toggle", "")
add("AUX_OUTPUT_MUTE", "aux_output", { get=true, set=true, rep=true }, "OFF, ON", "toggle", "")
add("MODEL", "global", { get=true, rep=true }, "fixed string, 32 chars", "read-only text", "Documentation lists GET; implementation accepts REP.")
add("START_VOTE", "voting", { set=true }, "1..50 voting configuration", "trigger with config number", "")
add("COMPLETE_VOTE", "voting", { set=true }, "TRUE", "trigger", "")
add("PAUSE_VOTE", "voting", { set=true }, "TRUE", "trigger", "")
add("RESUME_VOTE", "voting", { set=true }, "TRUE", "trigger", "")
add("CANCEL_VOTE", "voting", { set=true }, "TRUE", "trigger", "")
add("VOTING_CONFIGURATION", "voting", { get=true, rep=true }, "01..50", "indicator", "")
add("VOTING_CONFIGURATION_NAME", "voting_config", { get=true, rep=true }, "UTF-8 text in braces, fixed 31 chars", "50 text outputs", "")
add("VOTING_BUTTON_NAME", "voting_button", { get=true, rep=true }, "UTF-8 text in braces, fixed 31 chars", "5 text outputs", "")
add("VOTING_STATE", "voting", { get=true, rep=true }, "INACTIVE, PAUSE, ACTIVE, COMPLETE", "indicator", "")
add("INTERIM_VOTING_SELECTION", "seat", { rep=true }, "voting button index", "per-seat indicator", "Only for non-secret voting.")
add("INTERIM_VOTING_RESULT", "voting_button", { rep=true }, "numeric count", "5 meters/text", "Only for non-secret voting.")
add("FINAL_VOTING_SELECTION", "seat", { get=true, rep=true }, "voting button label/index", "per-seat indicator", "")
add("FINAL_VOTING_RESULT", "voting_button", { get=true, rep=true }, "numeric count", "5 meters/text", "")
add("SHARE_VOTING_RESULTS", "voting", { set=true, rep=true }, "TRUE", "trigger/indicator", "Non-secret results are shared automatically.")
add("CLOSE_VOTING_RESULTS", "voting", { set=true, rep=true }, "TRUE, FALSE", "trigger/indicator", "")
add("AUDIO_INPUT_SPEAKLIST", "global", { get=true, set=true, rep=true }, "OFF, ON", "toggle/output", "")
add("WDU_OFF", "global", { set=true, rep=true }, "TRUE", "trigger", "Turns conference units off.")
add("WDU_LOCK_WELCOME", "global", { get=true, set=true, rep=true }, "DISABLED, ENABLED", "combo/toggle", "")
add("WELCOME_LOCK_RESET", "global", { set=true, rep=true }, "TRUE", "trigger", "")
add("RETAIN_SEAT_PERSISTENCE", "global", { get=true, set=true, rep=true }, "DISABLED, ENABLED", "combo/toggle", "")

Commands.ORDER = {
  "MIC_STATUS", "SPEAK_REQUEST", "SPEAK_RELEASE", "ALL_DELEGATE_MIC_OFF",
  "EXCLUSIVE_MUTE", "GLOBAL_MUTE", "REQUEST_LIST_STATUS", "SPEAK_LIST_STATUS",
  "CLEAR_REQUEST_LIST", "NEXT_MIC_ON", "MAX_TOTAL_SPEAKERS",
  "MAX_DELEGATE_SPEAKERS", "MAX_NUM_REQUESTS", "OPERATION_MODE",
  "INTERRUPT_MODE", "MIC_PRIORITY", "LOUDSPEAKER_VOLUME", "AUX_INPUT_PAD",
  "AUX_INPUT_GAIN", "AUX_OUTPUT_GAIN", "MIC_GAIN", "DANTE_INPUT_GAIN",
  "DANTE_OUTPUT_GAIN", "AUX_INPUT_AGC", "DANTE_INPUT_AGC", "DANTE_INPUT_MUTE",
  "DANTE_OUTPUT_MUTE", "MIC_AGC", "FLASH", "ROLE", "SEAT_NAME", "RF_POWER",
  "DEVICE_ID", "ALL", "BATT_CHARGE", "BATT_RUN_TIME", "BATT_CYCLE",
  "BATT_HEALTH", "UNIT_AVAILABLE", "AUDIO_METER_RATE", "RF_METER_RATE",
  "AUX_INPUT_MUTE", "AUX_OUTPUT_MUTE", "MODEL", "START_VOTE", "COMPLETE_VOTE",
  "PAUSE_VOTE", "RESUME_VOTE", "CANCEL_VOTE", "VOTING_CONFIGURATION",
  "VOTING_CONFIGURATION_NAME", "VOTING_BUTTON_NAME", "VOTING_STATE",
  "INTERIM_VOTING_SELECTION", "INTERIM_VOTING_RESULT", "FINAL_VOTING_SELECTION",
  "FINAL_VOTING_RESULT", "SHARE_VOTING_RESULTS", "CLOSE_VOTING_RESULTS",
  "AUDIO_INPUT_SPEAKLIST", "WDU_OFF", "WDU_LOCK_WELCOME",
  "WELCOME_LOCK_RESET", "RETAIN_SEAT_PERSISTENCE",
}

return Commands
