Bridge.Framework = Bridge.DetectFramework()

-- Calls cb whenever the character is ready (used to restore the backpack).
function Bridge.OnPlayerLoaded(cb)
    local events = {
        'qbx_core:client:playerLoaded',
        'QBCore:Client:OnPlayerLoaded',
        'esx:playerLoaded',
        'playerSpawned',
    }

    for i = 1, #events do
        AddEventHandler(events[i], cb)
    end
end