
registered={};commands={};handlers={};threads={};messages={};events={};now=1000
ped=1;vehicle=10;class=0;occupant=1;seat=-1;seatX=-.35;inside=true;dead=false;loaded=true;playing=true;ragdoll=false
flags={[1]=true};missing=false;driveby=false
exports=setmetatable({}, {__call=function(_,n,f) registered[n]=f end, __index=function() return {IsBusy=function() return otherBusy end} end})
function RegisterCommand(n,f) commands[n]=f end
function RegisterKeyMapping(...) mapped=table.pack(...) end
function AddEventHandler(n,f) handlers[n]=f end
function CreateThread(f) local t=coroutine.create(f);table.insert(threads,t);return t end
function Wait(ms) coroutine.yield(ms) end
function PlayerPedId() return ped end
function IsEntityDead() return dead end
function IsPedInAnyVehicle() return inside end
function GetVehiclePedIsIn() return vehicle end
function GetEntityModel() return 99 end
function GetVehicleClass() return class end
function GetVehicleMaxNumberOfPassengers() return 3 end
function GetPedInVehicleSeat(_,index) return index==seat and occupant or 0 end
function GetEntityCoords() return {x=seatX,y=0,z=0} end
function GetOffsetFromEntityGivenWorldCoords(_,x,y,z) return {x=x,y=y,z=z} end
function DoesEntityExist() return true end
function IsPedRagdoll() return ragdoll end
function IsPedDoingDriveby() return driveby end
function GetGameTimer() return now end
function HasAnimDictLoaded() return loaded end
function RequestAnimDict() requested=true end
function GetAnimDuration() return missing and 0 or 2.4 end
function TaskPlayAnim(...) call=table.pack(...) end
function StopAnimTask() stopped=true end
function IsEntityPlayingAnim() return playing end
function GetPedConfigFlag(p) return flags[p] end
function SetPedConfigFlag(p,_,v) flags[p]=v end
function DisableControlAction(_,control) blocked=control end
function GetCurrentResourceName() return 'handbrake_anim' end
function RemoveAnimDict() removed=true end
function TriggerEvent(name,...)
 if name=='chat:addMessage' then table.insert(messages,({...})[1].args[2])
 else table.insert(events,table.pack(name,...)) end
end
function step(t,delta) now=now+(delta or 0);local ok,e=coroutine.resume(t);assert(ok,e) end
function finish(t) while coroutine.status(t)~='dead' do step(t,100) end end

pressed=false;otherBusy=false
function IsControlPressed() return pressed end
function IsDisabledControlPressed() return false end
function GetResourceState() return otherBusy and 'started' or 'missing' end
