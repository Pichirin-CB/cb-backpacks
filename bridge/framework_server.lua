Bridge.Framework = Bridge.DetectFramework()

-- Unique, persistent player identifier used as the owner of the equipped state.
function Bridge.GetIdentifier(source)
    source = tonumber(source)

    if not source then
        return nil
    end

    if Bridge.Framework == 'qbx' then
        local player = exports.qbx_core:GetPlayer(source)

        if player and player.PlayerData and player.PlayerData.citizenid then
            return tostring(player.PlayerData.citizenid)
        end
    elseif Bridge.Framework == 'qb' then
        local QBCore = exports['qb-core']:GetCoreObject()
        local player = QBCore.Functions.GetPlayer(source)

        if player and player.PlayerData and player.PlayerData.citizenid then
            return tostring(player.PlayerData.citizenid)
        end
    elseif Bridge.Framework == 'esx' then
        local ESX = exports.es_extended:getSharedObject()
        local player = ESX.GetPlayerFromId(source)

        if player and player.identifier then
            return tostring(player.identifier)
        end
    end

    return GetPlayerIdentifierByType(source, 'license2')
        or GetPlayerIdentifierByType(source, 'license')
end