"""Made with AI. Offline regression tests; pip install lupa."""
from pathlib import Path
from lupa import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute((Path(__file__).parent/'fixture.lua').read_text())
for name in ['config.lua','client.lua','fxmanifest.lua']:
    source=(ROOT/name).read_text()
    assert lua.eval('function(s) return load(s)~=nil end')(source),name
    if name!='fxmanifest.lua':lua.execute(source)
lua.execute('''
local poll=threads[1]
step(poll)
assert(registered.Play('set'));local t=threads[#threads];step(t)
assert(call[3]=='standard_right_set' and call[5]<0 and call[6]==2100 and call[8]==0 and call[10]==2)
local ok,reason=registered.Play('release');assert(not ok and reason=='busy')
finish(t);assert(not registered.IsBusy())
assert(registered.SetProfile('hydraulic','left'));assert(not registered.Play('set'))
assert(registered.Play('pull'));t=threads[#threads];step(t)
assert(call[3]=='hydraulic_left_pull' and call[6]==1500);finish(t)
assert(not registered.SetProfile('broken','right'));assert(not registered.SetProfile('standard','broken'))
-- Context change clears the session override, and auto chooses the other hand.
vehicle=11;seatX=.35;step(poll)
assert(registered.Play('release'));t=threads[#threads];step(t);assert(call[3]=='standard_left_release')
vehicle=12;step(t,100);assert(not registered.IsBusy())
-- Driver-only and excluded classes/models.
seat=0;assert(not registered.Play('set'));seat=-1
class=8;assert(not registered.Play('set'));class=0
Config.Models[99]=false;assert(not registered.Play('set'));Config.Models[99]=nil
seatX=-.35;step(poll)
-- A quick tap queues exactly one release after the set completes.
pressed=true;step(poll);t=threads[#threads];step(t);assert(call[3]=='standard_right_set')
pressed=false;step(poll);finish(t);local before=#threads;step(poll);assert(#threads==before+1)
t=threads[#threads];step(t);assert(call[3]=='standard_right_release');finish(t);step(poll)
assert(not registered.IsBusy())
-- Re-press during a set coalesces the queued release.
pressed=true;step(poll);t=threads[#threads];step(t)
pressed=false;step(poll);pressed=true;step(poll);finish(t)
before=#threads;step(poll);assert(#threads==before)
registered.SetEnabled(false);pressed=false;step(poll);assert(not registered.Play('set'))
registered.SetEnabled(true)
-- Another restraint gesture blocks new playback.
otherBusy=true;assert(not registered.Play('set'));otherBusy=false
-- Failed tasks, interruptions, death, and missing dictionaries/clip cleanup.
playing=false;assert(registered.Play('set'));finish(threads[#threads]);assert(not registered.IsBusy());playing=true
missing=true;assert(registered.Play('set'));finish(threads[#threads]);assert(not registered.IsBusy());missing=false
loaded=false;assert(registered.Play('set'));t=threads[#threads];step(t);assert(requested)
step(t,11000);assert(not registered.IsBusy());loaded=true
assert(registered.Play('set'));t=threads[#threads];step(t);driveby=true;step(t,100);assert(not registered.IsBusy());driveby=false
assert(registered.Play('set'));t=threads[#threads];step(t);dead=true;step(t,100);assert(not registered.IsBusy());dead=false
assert(registered.Play('set'));t=threads[#threads];step(t)
handlers.onResourceStop('handbrake_anim');assert(stopped and removed and not registered.IsBusy());step(t,100)
''')
print('PASS: handbrake inputs, coalescing, both styles/hands, context changes, failures, timeouts, restraint busy guard and cleanup')
