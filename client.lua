local enabled, override = Config.Enabled, nil
local bound, active, pending = nil, nil, nil
local previousHeld = false
local function message(text)
    print('[handbrake_anim] ' .. text)
    TriggerEvent('chat:addMessage', { args = { 'Handbrake', text } })
end
local function context()
    local ped = PlayerPedId()
    if IsEntityDead(ped) or not IsPedInAnyVehicle(ped, false) then return nil end
    local vehicle = GetVehiclePedIsIn(ped, false)
    if GetPedInVehicleSeat(vehicle, -1) ~= ped or not Config.EnabledClasses[GetVehicleClass(vehicle)] then return nil end
    local model = Config.Models[GetEntityModel(vehicle)]
    if model == false then return nil end
    local settings = override or (type(model) == 'table' and model) or {}
    local style = settings.style or Config.DefaultStyle
    local hand = settings.hand or Config.DefaultHand
    if hand == 'auto' then
        local p = GetEntityCoords(ped)
        local offset = GetOffsetFromEntityGivenWorldCoords(vehicle,p.x,p.y,p.z)
        hand = offset.x > .1 and 'left' or 'right'
    end
    if (style ~= 'standard' and style ~= 'hydraulic') or (hand ~= 'left' and hand ~= 'right') then return nil end
    return { ped=ped, vehicle=vehicle, style=style, hand=hand }
end
local function same(a,b)
    return a and b and a.ped==b.ped and a.vehicle==b.vehicle
end
local function stop()
    if active and DoesEntityExist(active.ped) then StopAnimTask(active.ped,Config.Dictionary,active.clip,4.0) end
    active, pending = nil, nil
end
local function held()
    return IsControlPressed(0,Config.Control) or IsDisabledControlPressed(0,Config.Control)
end
local function sync()
    local current = context()
    if not same(bound,current) then
        stop(); override=nil; current=context(); bound=current; previousHeld=held()
    end
    return current
end
local function busyOther()
    for _,resource in ipairs({'harness_anim','seatbelt_anim'}) do
        if GetResourceState(resource)=='started' then
            local ok,busy=pcall(function() return exports[resource]:IsBusy() end)
            if ok and busy then return true end
        end
    end
    return false
end
local function valid(token)
    return active==token and same(token,context()) and enabled
        and not IsPedRagdoll(token.ped) and not IsPedDoingDriveby(token.ped)
end
local function play(action)
    local current=sync()
    if not current then return false,'not_driver' end
    if not enabled then return false,'disabled' end
    if active then return false,'busy' end
    if busyOther() or IsPedRagdoll(current.ped) or IsPedDoingDriveby(current.ped) then return false,'ped_busy' end
    if (current.style=='hydraulic' and action~='pull') or
       (current.style=='standard' and action~='set' and action~='release') then return false,'invalid_action' end
    local token=current
    token.clip=current.style..'_'..current.hand..'_'..action
    token.action=action;active=token
    CreateThread(function()
        local start,requested=GetGameTimer(),-10000
        while not HasAnimDictLoaded(Config.Dictionary) do
            if not valid(token) then if active==token then stop() end; return end
            if GetGameTimer()-start>Config.LoadTimeoutMs then message('Animation dictionary load timed out.');stop();return end
            if GetGameTimer()-requested>=500 then RequestAnimDict(Config.Dictionary);requested=GetGameTimer() end
            Wait(50)
        end
        if not valid(token) then if active==token then stop() end;return end
        if GetAnimDuration(Config.Dictionary,token.clip)<=0 then message('Missing clip: '..token.clip);stop();return end
        local duration=Config.Durations[action]
        TaskPlayAnim(token.ped,Config.Dictionary,token.clip,8.0,-8.0,duration,48,0.0,false,2,false)
        start=GetGameTimer();Wait(100)
        while true do
            if not valid(token) then if active==token then stop() end;return end
            if not IsEntityPlayingAnim(token.ped,Config.Dictionary,token.clip,3) then
                message('Animation failed or was interrupted.');stop();return
            end
            if GetGameTimer()-start>=duration-80 then break end
            Wait(25)
        end
        StopAnimTask(token.ped,Config.Dictionary,token.clip,4.0);active=nil
    end)
    return true,'started'
end
local function setProfile(style,hand)
    if style~='standard' and style~='hydraulic' then return false end
    hand=hand or 'auto'
    if hand~='auto' and hand~='left' and hand~='right' then return false end
    if not sync() then return false end
    stop();override={style=style,hand=hand};previousHeld=held()
    return true
end
exports('Play',play)
exports('IsBusy',function() sync();return active~=nil end)
exports('SetProfile',setProfile)
exports('SetEnabled',function(value)
    if type(value)~='boolean' then return false end
    enabled=value;stop();previousHeld=held();return true
end)
RegisterCommand('handbrakestyle',function(_,args)
    if args[1]=='reset' then stop();override=nil;previousHeld=held();return end
    if not setProfile(args[1],args[2]) then message('/handbrakestyle standard|hydraulic [auto|left|right] (driver only)')
    else message('Style: '..args[1]..'; hand: '..(args[2] or 'auto')) end
end,false)
RegisterCommand('handbrakeanim',function(_,args)
    local action=args[1]
    if action=='on' or action=='off' then enabled=action=='on';stop();previousHeld=held();message(action);return end
    if action=='status' then local c=sync();message(('Enabled=%s; busy=%s; style=%s; hand=%s'):format(tostring(enabled),tostring(active~=nil),c and c.style or '-',c and c.hand or '-'));return end
    local ok,reason=play(action)
    if not ok then message('Cannot play: '..reason..'. Use /handbrakeanim set|release|pull|on|off|status') end
end,false)
CreateThread(function()
    while true do
        local c=sync()
        if c and enabled and Config.Automatic then
            local down=held()
            if down~=previousHeld then
                previousHeld=down
                local action=c.style=='standard' and (down and 'set' or 'release') or (down and 'pull' or nil)
                if action then
                    if active then
                        -- Coalesce fast taps; never accumulate a delayed backlog.
                        pending=action~=active.action and action or nil
                    else play(action) end
                end
            end
            if pending and not active then local nextAction=pending;pending=nil;play(nextAction) end
        end
        Wait(c and 0 or 200)
    end
end)
AddEventHandler('onResourceStop',function(name)
    if name~=GetCurrentResourceName() then return end
    stop();RemoveAnimDict(Config.Dictionary)
end)
print('[handbrake_anim] Loaded. Made with AI. Observes handbrake input; does not change brake physics.')
