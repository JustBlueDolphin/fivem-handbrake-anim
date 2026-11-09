# Handbrake animations

**Made with AI** — the custom animations and FiveM client script were created with AI assistance.

Standard lever set/release and hydraulic drift-lever pull/return, each with left- and right-hand variants: six native clips. The script observes handbrake input and plays the matching arm gesture. It does not change handling, apply a persistent parking brake or animate the vehicle's actual lever.

[Watch all six animations](previews/handbrake-review-v1.mp4)

## Install and use

Copy `handbrake_anim` into your server resources and add:

```cfg
ensure handbrake_anim
```

On a running server use `refresh`, then `ensure handbrake_anim`. Sit in the driver's seat and use the normal handbrake control. The default is **Space** on keyboard / **RB** on controller ([Cfx controls reference](https://docs.fivem.net/docs/game-references/controls/), control 76). Existing control bindings and brake physics remain unchanged.

Standard style plays `set` on press and `release` on release. A quick tap lets the set gesture finish before one release gesture plays; additional edges are coalesced instead of building a backlog. The brake itself responds immediately through GTA. Hydraulic style plays a complete pull/return cycle on press, with no loop while held; presses during that cycle are ignored.

Choose style and hand for your current vehicle session:

```text
/handbrakestyle standard auto
/handbrakestyle hydraulic right
/handbrakestyle hydraulic left
/handbrakestyle reset
/handbrakeanim set
/handbrakeanim release
/handbrakeanim pull
/handbrakeanim off
/handbrakeanim on
/handbrakeanim status
```

`set`/`release` require standard style; `pull` requires hydraulic style. Test commands play animations only. Profiles reset on vehicle/ped changes. `auto` chooses the shifter hand from the driver's position relative to the vehicle; unusual interiors can override it in `config.lua`.

```lua
Config.Models = {
    [joaat('my_drift_car')] = { style = 'hydraulic', hand = 'right' },
    [joaat('car_with_electronic_handbrake')] = false,
}
```

General road classes are supported; motorcycles, bicycles, boats, aircraft and trains are excluded. Electronic and foot-operated parking brakes should be excluded per model. There is no reliable built-in inference of lever style; standard is the default.

## Integration

Set `Config.Automatic = false` to trigger from another braking resource:

```lua
exports['handbrake_anim']:SetProfile('hydraulic', 'right')
local ok, reason = exports['handbrake_anim']:Play('pull')
local busy = exports['handbrake_anim']:IsBusy()
exports['handbrake_anim']:SetEnabled(false)
```

`Play` returns `true, 'started'` when loading begins. It rejects passengers, invalid actions, disabled playback or a busy ped. Loading times out after 10 seconds. Death, seat/vehicle changes, ragdoll, drive-by and resource stop cancel the gesture. Cleanup stops only this resource's clip.

If `harness_anim` or `seatbelt_anim` is running a gesture, new handbrake gestures are skipped. Other secondary tasks, including gearshift, can still interrupt playback; no global ped IK settings or other resource toggles are changed.

## Validation and credits

The six YCD clips passed CodeWalker save/reload and sampled arm-continuity/end-pose checks. Contact poses were rendered and the hand's reference grip point was checked against the preview lever arc. Offline Lua tests cover automatic edges, quick taps, styles, hands, timeouts, invalid contexts and cleanup (`pip install lupa`, then `python tests/test_client.py`). Actual FiveM playback, MP female positioning and vehicle-specific fit remain unverified. Version 0.1.0 is a prerelease for in-game testing.

Preview ped and Sultan models belong to Rockstar Games and are not AI-created assets. Orange levers are preview guides only, not included vehicle props. The native dictionary contains custom animation tracks, not the third-party reference models.
