Config = {}
Config.Dictionary = 'handbrake'
Config.Enabled = true
Config.Automatic = true -- Observe GTA's handbrake control; never override brake physics.
Config.Control = 76
Config.DefaultStyle = 'standard' -- 'standard' or 'hydraulic'
Config.DefaultHand = 'auto' -- shifter hand: 'left', 'right', or auto by driver position
Config.LoadTimeoutMs = 10000
Config.Durations = { set = 2100, release = 2000, pull = 1500 }
Config.EnabledClasses = { [0]=true,[1]=true,[2]=true,[3]=true,[4]=true,[5]=true,
    [6]=true,[7]=true,[9]=true,[10]=true,[11]=true,[12]=true,[17]=true,
    [18]=true,[19]=true,[20]=true,[22]=true }
Config.Models = {
    -- [joaat('your_car')] = { style = 'hydraulic', hand = 'right' },
    -- [joaat('car_with_electronic_handbrake')] = false,
}
