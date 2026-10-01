# DCH Shure MXCW / MXCWAPT Q-SYS Plugin

Q-SYS Designer plugin for Shure Microflex Complete Wireless MXCW systems, using the MXCWAPT access point as the central control endpoint.

The plugin communicates directly with the MXCWAPT over the official Shure command string TCP interface.

Q-SYS Designer plugin name: `DCH~Shure~MXCW-MXCWAPT`, shown under `DCH > Shure > MXCW-MXCWAPT`.

## Supported Equipment

- Shure MXCWAPT Microflex Complete Wireless Access Point
- Shure MXCW640 conference units and MXCW seats exposed through the MXCWAPT command strings

## Shure Documentation Used

- Document: MXCWAPT Microflex Complete Wireless Command Strings
- Official URL: https://www.shure.com/en-US/docs/commandstrings/MXCW
- Shure document ID: `6944`
- Publication ID: `p_31597010-4d03-4506-ab58-811c4f5cda42`
- Publication version: `8.2`
- Publication date code: `2025-F`

## Protocol

- Transport: TCP/IP client connection from Q-SYS to the MXCWAPT
- Default port: `2202`
- Encoding: ASCII command strings
- Framing: angle-bracketed messages, for example `< GET MODEL >`

The parser supports fragmented TCP reads, multiple messages in one packet, asynchronous `REP` messages, `REP ERR`, unknown commands, and braced string payloads such as `{Ana Maria}`.

## Properties

- `Number of Microphones`
  - Type: integer
  - Min: `1`
  - Max: `125`
  - Default: `16`
  - Dynamically controls how many per-station UI controls are created.

- `Debug Print`
  - Choices: `None`, `Tx`, `Rx`, `Tx/Rx`, `All`
  - Prints formatted TX/RX traffic and diagnostics according to the selected level.

## Connection Controls

- `IP Address`
- `Port`
- `Connect`
- `Connected`
- `Connection Status`
- `Last Error`
- `Refresh/Resync`
- `Synchronized`

Connection states are:

- `Disconnected`
- `Connecting`
- `Connected / Synchronizing`
- `Online`
- `Fault`

From version `0.1.7`, `Connect` is always On at runtime startup, including when the design previously saved it Off. The plugin connects automatically when an IP is configured. With an empty IP, it stays disconnected with Connect On; entering an IP starts the connection. Editing IP or port restarts an enabled connection. Turning Connect Off cancels pending retries for the current session.

## Seat Mapping

The plugin does not assume that Q-SYS station index equals Shure Seat Number.

Each station has a `Seat Number N` control. Reports from the MXCWAPT are mapped back from real Seat Number to configured Q-SYS station index. This allows non-sequential seat numbering.

## Pages

- `Setup`
- `System`
- `Conference`
- `Microphones`
- `Audio`
- `Dante`
- `RF`
- `Stations 1-16` and `Battery 1-16` (additional groups of up to 16 as needed)
- `Voting`
- `Diagnostics`

The Microphones page uses a selected-station workflow for detailed controls. Station and battery tables show up to 16 units per page. All pages use a 1008 x 584 pixel canvas with compact 24-pixel fields. Each page returns only its visible controls, and every control is assigned to at least one page.

Version `0.1.5` follows the existing DCH Shure P300 visual model: white background, Shure logo, grey dividers and fields, blue mixer faders, and compact controls. Microphone gain and audio gains use vertical faders; Dante is arranged in ten channel strips. Version `0.1.6` adds the Dechen Technologies logo beside Shure on every page. Both logos are stored in `src/assets/` and embedded in the generated plugin, so installation needs only the `.qplug` file. All pins remain disabled.

## Control Pins

Version `0.1.4` removes all control-pin exposure: every control has `UserPin = false` and `PinStyle = "None"`, `GetPins()` is empty, and the option to enable pins is removed. The plugin keeps its on-screen controls. Debug pins are disabled through `ShowDebug = false`; `RectifyProperties()` also clears and hides `plugin_show_debug`.

Replace or reinsert an existing component after reloading the updated plugin if the design retains previously exposed pins. Save the project before replacing components.

## Building

Generate the installable `.qplug`:

```sh
python3 scripts/build_qplug.py
```

Output:

```text
build/DCH-Shure-MXCWAPT.qplug
```

## Installation

Copy the generated `.qplug` into the Q-SYS Designer `Plugins/DCH/Shure/MXCW-MXCWAPT/` folder and restart Designer to reload plugins.

A copy of the sources, build script, tests, and documentation is saved in `build/source/DCH-Shure-MXCWAPT/`.

## Validation

Local parser and command-matrix tests:

```sh
lua test/parser_spec.lua
lua test/layout_spec.lua
lua test/plugin_load_spec.lua
lua test/runtime_connection_spec.lua
```

The local tests validate:

- 64 official commands represented in the command matrix
- Default port `2202`
- Fragmented TCP messages
- Multiple messages in one TCP read
- Braced string parsing
- Nested index parsing for voting button names
- dB/TPCI conversion helpers
- Dynamic microphone control counts for `1`, `16`, `20`, and `125`
- All pages at `1`, `16`, `17`, `20`, and `125` stations: complete control coverage, no overlapping labels/controls, bounds, valid control styles, and zero pin exposure even with legacy pin properties
- Generated plugin loading without global `package` or `require`, fresh environments for callbacks, bounded design-time execution, no network activity with an empty IP, and simulated report/control handling
- Automatic connection on startup, persisted Off override, blank IP handling, address/port changes, and manual disconnect/retry cancellation

The generated file starts with `PluginInfo` and uses a private module loader. It does not depend on external Lua files or alter `package.preload`. Page layouts include only controls displayed on that page, following the [Q-SYS framework example](https://help.qsys.com/DeveloperHelp/Content/Code_Examples/Basic_Plugin_Framework.htm).

Version `0.1.2` also fixes method lookup in the state and diagnostics constructors. Previously, runtime initialization failed at `state:set_connection()`. Automated tests use a simulated Q-SYS environment. The user confirmed that the main plugin `0.1.4` loads in Designer 10.4.0 after pin exposure was removed; hardware communication remains to be validated.

The temporary Minimal, UI Only, and Page Probe plugins were removed after the successful Designer loading test. The build produces only the main plugin. Parser, layout, and loading tests remain in `test/`.

## Known Limitations

- Hardware validation requires a physical MXCWAPT and registered MXCW conference units.
- Q-SYS Designer API compatibility should be verified in the target Designer version before production deployment.
- The plugin does not simulate web-interface-only features that are not present in the official Command Strings document.
- Meter `SAMPLE` reports are parsed and logged, but detailed audio/RF sample visualization is intentionally minimal in this first release.

## API Coverage

See [MXCW_COMMAND_IMPLEMENTATION.md](MXCW_COMMAND_IMPLEMENTATION.md) for the complete command-by-command implementation matrix.
