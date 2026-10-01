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
  - Dynamically controls how many per-station controls and pins are created.

- `Debug Print`
  - Choices: `None`, `Tx`, `Rx`, `Tx/Rx`, `All`
  - Prints formatted TX/RX traffic and diagnostics according to the selected level.

- `Control Pins`
  - Choices: `None`, `Microphones`, `All`
  - Default: `None`; no pins are exposed.
  - `Microphones` enables only per-station active and online pins.
  - `All` enables the integration pins listed below.

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

The Microphones page uses a selected-station workflow for detailed controls. Station and battery tables show up to 16 units per page. All pages use a 700 x 540 pixel canvas with compact 24-pixel fields. Each page returns only its visible controls, and every control is assigned to at least one page.

## Pins and Control Groups

Pins are disabled by default. With `Control Pins` set to `All`, the plugin offers connection status, global controls, conference controls, per-station mic active state, per-station online state, request/speak-list states, battery data, seat names, and voting states.

Important per-station pins include:

- `Seat Number N`
- `Mic Active N`
- `Mic Online N`
- `Mic Name N`
- `Request List N`
- `Speak List N`
- `Battery Charge N`

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
lua test/diagnostics_spec.lua
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
- All pages at `1`, `16`, `17`, `20`, and `125` stations: complete control coverage, no overlapping labels/controls, bounds, valid control styles, and pin modes
- Generated plugin loading without global `package` or `require`, fresh environments for callbacks, bounded design-time execution, no network activity during runtime initialization, and simulated report/control handling

The generated file starts with `PluginInfo` and uses a private module loader. It does not depend on external Lua files or alter `package.preload`. Page layouts include only controls displayed on that page, following the [Q-SYS framework example](https://help.qsys.com/DeveloperHelp/Content/Code_Examples/Basic_Plugin_Framework.htm).

Version `0.1.2` also fixes method lookup in the state and diagnostics constructors. Previously, runtime initialization failed at `state:set_connection()`. These tests use a simulated Q-SYS environment; insertion and rendering in Designer 10.4.0 still require validation in Designer. After updating, restart Designer and test the new version in a blank design before updating an existing project.

## Designer Freeze Diagnostics

The Designer 10.4.0 freeze persisted with `0.1.2`; its cause has not yet been confirmed. Version `0.1.3` removes repeated hidden layouts, defines battery percentages as numeric controls, exports only native control properties, and initializes combo choices in runtime.

The build also creates two separate diagnostic plugins in `build/diagnostics/` with distinct IDs and names:

1. `DCH-MXCW-01-Minimal.qplug`: two controls, a single default page, no modules, no runtime.
2. `DCH-MXCW-02-UI-Only.qplug`: the complete UI and properties, without protocol, sockets, timers, or runtime code.

Test the minimal plugin first in a blank design, then the UI-only plugin, then the full plugin. Record which step freezes. If the minimal plugin freezes, the complete MXCW UI/runtime is not needed to trigger it. If only the UI-only version freezes, investigate native control/layout conversion. If both diagnostics load and only the full version freezes, investigate the runtime/loading path. These diagnostics do not operate the Shure equipment and should not replace the production plugin.

## Known Limitations

- Hardware validation requires a physical MXCWAPT and registered MXCW conference units.
- Q-SYS Designer API compatibility should be verified in the target Designer version before production deployment.
- The plugin does not simulate web-interface-only features that are not present in the official Command Strings document.
- Meter `SAMPLE` reports are parsed and logged, but detailed audio/RF sample visualization is intentionally minimal in this first release.

## API Coverage

See [MXCW_COMMAND_IMPLEMENTATION.md](MXCW_COMMAND_IMPLEMENTATION.md) for the complete command-by-command implementation matrix.
