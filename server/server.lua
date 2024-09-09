local QBCore = exports['qb-core']:GetCoreObject()
local restrictedChannels = Config.restrictedChannels

-- Command to open the radio
QBCore.Commands.Add('radio', 'Åpne radio', {}, false, function(source)
    TriggerClientEvent('openRadio', source, true)
end)

-- Make the radio item usable
QBCore.Functions.CreateUseableItem('radio', function(source)
    TriggerClientEvent('openRadio', source, true)
end)

-- If sub-channels are not whitelisted, expand the restricted channels to include decimals
if not Config.whitelistSubChannels then
    for channel, jobs in pairs(restrictedChannels) do
        for i = 1, 99 do
            restrictedChannels[channel + (i / 100)] = jobs
        end
    end
end

-- Add channel check based on job restrictions
for channel, jobs in pairs(restrictedChannels) do
    exports['pma-voice']:addChannelCheck(channel, function(source)
        local player = QBCore.Functions.GetPlayer(source)  -- Get the player data via QBCore
        if player then
            local jobName = player.PlayerData.job.name
            local onDuty = player.PlayerData.job.onduty
            return jobs[jobName] and onDuty  -- Check if the player's job allows access and if they are on duty
        end
        return false  -- Deny access if player data isn't found
    end)
end
