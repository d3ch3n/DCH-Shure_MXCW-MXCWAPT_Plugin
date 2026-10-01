# MXCW Command Implementation Matrix

Source: Shure MXCW Command Strings, `docId 6944`, publication version `8.2`, date code `2025-F`.

| Shure Command | Scope | GET | SET | REP | Q-SYS Control | Implemented | Notes |
|---|---|:---:|:---:|:---:|---|:---:|---|
| `MIC_STATUS` | Seat | Yes | Yes | Yes | `Mic Active N`, selected mic status | Yes | `GET 0` syncs online registered seats. |
| `SPEAK_REQUEST` | Seat | No | Yes | No | selected speak request trigger | Yes | Follow-up state arrives as list status report. |
| `SPEAK_RELEASE` | Seat | No | Yes | No | selected speak release trigger | Yes | Follow-up state arrives as list status report. |
| `ALL_DELEGATE_MIC_OFF` | Global | No | Yes | No | trigger | Yes | Result is reflected by per-seat `MIC_STATUS` reports. |
| `EXCLUSIVE_MUTE` | Seat | No | Yes | Yes | selected exclusive mute | Yes | Chairman-only behavior is enforced by MXCWAPT. |
| `GLOBAL_MUTE` | Global | Yes | Yes | Yes | global mute | Yes | Report reflects global mute held by any controller. |
| `REQUEST_LIST_STATUS` | Seat | Yes | No | Yes | `Request List N` | Yes | `GET 0` syncs registered seats. |
| `SPEAK_LIST_STATUS` | Seat | Yes | No | Yes | `Speak List N` | Yes | `GET 0` syncs registered seats. |
| `CLEAR_REQUEST_LIST` | Global | No | Yes | No | trigger | Yes | No response when already empty. |
| `NEXT_MIC_ON` | Global | No | Yes | No | trigger | Yes | Result is reflected by mic/list reports. |
| `MAX_TOTAL_SPEAKERS` | Global | Yes | Yes | Yes | integer knob | Yes | Numeric. |
| `MAX_DELEGATE_SPEAKERS` | Global | Yes | Yes | Yes | integer knob | Yes | Numeric. |
| `MAX_NUM_REQUESTS` | Global | Yes | Yes | Yes | integer knob | Yes | Numeric. |
| `OPERATION_MODE` | Global | Yes | Yes | Yes | combo box | Yes | `AUTO`, `MANUAL`, `FIFO`, `HANDSFREE`. |
| `INTERRUPT_MODE` | Global | Yes | Yes | Yes | combo box | Yes | Official enum values. |
| `MIC_PRIORITY` | Seat | Yes | Yes | Yes | selected mic priority | Yes | Per-seat selected control. |
| `LOUDSPEAKER_VOLUME` | Global | Yes | Yes | Yes | knob | Yes | Converts TPCI offset to dB. |
| `AUX_INPUT_PAD` | Aux input | Yes | Yes | Yes | button | Yes | Index `1`. |
| `AUX_INPUT_GAIN` | Aux input | Yes | Yes | Yes | knob | Yes | Converts TPCI offset to dB. |
| `AUX_OUTPUT_GAIN` | Aux output | Yes | Yes | Yes | knob | Yes | Converts TPCI offset to dB. |
| `MIC_GAIN` | Seat | Yes | Yes | Yes | selected mic gain | Yes | Converts TPCI offset to dB. |
| `DANTE_INPUT_GAIN` | Dante input | Yes | Yes | Yes | `Dante Input Gain 1..10` | Yes | Converts TPCI offset to dB. |
| `DANTE_OUTPUT_GAIN` | Dante output | Yes | Yes | Yes | `Dante Output Gain 1..10` | Yes | Converts TPCI offset to dB. |
| `AUX_INPUT_AGC` | Aux input | Yes | Yes | Yes | button | Yes | Index `1`. |
| `DANTE_INPUT_AGC` | Dante input | Yes | Yes | Yes | `Dante Input AGC 1..10` | Yes | Boolean mapping. |
| `DANTE_INPUT_MUTE` | Dante input | Yes | Yes | Yes | `Dante Input Mute 1..10` | Yes | Boolean mapping. |
| `DANTE_OUTPUT_MUTE` | Dante output | Yes | Yes | Yes | `Dante Output Mute 1..10` | Yes | Boolean mapping. |
| `MIC_AGC` | Seat | Yes | Yes | Yes | selected mic AGC | Yes | Per-seat selected control. |
| `FLASH` | APT or Seat | Yes | Yes | Yes | APT flash, selected flash | Yes | No index flashes APT; indexed flashes station. |
| `ROLE` | Seat | Yes | Yes | Yes | selected role, `Mic Role N` | Yes | Role changes can alter available seats. |
| `SEAT_NAME` | Seat | Yes | Yes | Yes | selected seat name, `Mic Name N` | Yes | Braced UTF-8 strings are parsed. |
| `RF_POWER` | Global | Yes | Yes | Yes | combo box | Yes | Official enum values. |
| `DEVICE_ID` | APT | Yes | Yes | Yes | text | Yes | MXCWAPT validates name rules. |
| `ALL` | Global | Yes | No | Yes | resync/internal | Yes | Used during synchronization. |
| `BATT_CHARGE` | Seat | Yes | No | Yes | `Battery Charge N` | Yes | Percent meter. |
| `BATT_RUN_TIME` | Seat | Yes | No | Yes | `Battery Runtime N` | Yes | Minutes as text. |
| `BATT_CYCLE` | Seat | Yes | No | Yes | `Battery Cycle N` | Yes | Cycle count as text. |
| `BATT_HEALTH` | Seat | Yes | No | Yes | `Battery Health N` | Yes | `255` shown as unknown/0 meter. |
| `UNIT_AVAILABLE` | Seat | Yes | No | Yes | `Mic Online N` | Yes | Availability indicator. |
| `AUDIO_METER_RATE` | Global | Yes | Yes | Yes | integer knob | Yes | SAMPLE visualization is minimal. |
| `RF_METER_RATE` | Global | Yes | Yes | Yes | integer knob | Yes | SAMPLE visualization is minimal. |
| `AUX_INPUT_MUTE` | Aux input | Yes | Yes | Yes | button | Yes | Index `1`. |
| `AUX_OUTPUT_MUTE` | Aux output | Yes | Yes | Yes | button | Yes | Index `1`. |
| `MODEL` | APT | Yes | No | Yes | read-only text | Yes | Documentation lists GET; parser accepts corresponding REP. |
| `START_VOTE` | Voting | No | Yes | No | trigger plus config number | Yes | Uses `Start Vote Configuration`. |
| `COMPLETE_VOTE` | Voting | No | Yes | No | trigger | Yes | Result via `VOTING_STATE`. |
| `PAUSE_VOTE` | Voting | No | Yes | No | trigger | Yes | Result via `VOTING_STATE`. |
| `RESUME_VOTE` | Voting | No | Yes | No | trigger | Yes | Result via `VOTING_STATE`. |
| `CANCEL_VOTE` | Voting | No | Yes | No | trigger | Yes | Result via `VOTING_STATE`. |
| `VOTING_CONFIGURATION` | Voting | Yes | No | Yes | text indicator | Yes | Current configuration. |
| `VOTING_CONFIGURATION_NAME` | Voting config | Yes | No | Yes | text outputs | Yes | Parsed; broad UI display is limited. |
| `VOTING_BUTTON_NAME` | Voting button | Yes | No | Yes | `Voting Button Name 1..5` | Yes | Supports double-index parser form. |
| `VOTING_STATE` | Voting | Yes | No | Yes | `Voting State` | Yes | `INACTIVE`, `PAUSE`, `ACTIVE`, `COMPLETE`. |
| `INTERIM_VOTING_SELECTION` | Seat voting | No | No | Yes | `Voting Selection N` | Yes | Non-secret sessions. |
| `INTERIM_VOTING_RESULT` | Voting button | No | No | Yes | `Interim Voting Result 1..5` | Yes | Numeric text. |
| `FINAL_VOTING_SELECTION` | Seat voting | Yes | No | Yes | `Voting Selection N` | Yes | Final per-seat selection. |
| `FINAL_VOTING_RESULT` | Voting button | Yes | No | Yes | `Final Voting Result 1..5` | Yes | Numeric text. |
| `SHARE_VOTING_RESULTS` | Voting | No | Yes | Yes | trigger/indicator | Yes | Non-secret results can auto-share. |
| `CLOSE_VOTING_RESULTS` | Voting | No | Yes | Yes | trigger/indicator | Yes | Closes results view. |
| `AUDIO_INPUT_SPEAKLIST` | Global | Yes | Yes | Yes | button/output | Yes | Boolean mapping. |
| `WDU_OFF` | Global | No | Yes | Yes | trigger | Yes | Turns conference units off. |
| `WDU_LOCK_WELCOME` | Global | Yes | Yes | Yes | button | Yes | `ENABLED`/`DISABLED`. |
| `WELCOME_LOCK_RESET` | Global | No | Yes | Yes | trigger | Yes | Resets welcome lock. |
| `RETAIN_SEAT_PERSISTENCE` | Global | Yes | Yes | Yes | button | Yes | `ENABLED`/`DISABLED`. |

No official command from the MXCW Command Strings `8.2` inventory is intentionally omitted. Features that exist only in the MXCW web UI and not in this command-string reference are not simulated.
