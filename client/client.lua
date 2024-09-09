local QBCore = exports['qb-core']:GetCoreObject()

-- Show NUI
local ShowNUI = function(arg)
  SetNuiFocus(arg, arg)
  SendNUIMessage({ action = 'setVisible', data = arg })
end

local onRadio = false
local inChannel = false
local radioVolume = 50
local radioChannel = 0
local micClicks = true

-- Notify user
local notifyUser = function(description, type)
  QBCore.Functions.Notify(description, type)
end

-- Play audio
local playAudio = function(audioName, audioRef)
  SendNUIMessage({
    transactionType = 'playSound',
    transactionFile = audioRef,
    transactionId = audioName
  })
end

-- Rounding function
local round = function(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- Connect to a specific radio channel
local connectToRadio = function(channel)
  if inChannel then
    exports['pma-voice']:setRadioChannel(0)
    playAudio('Start_Squelch', 'CB_RADIO_SFX')
  else
    inChannel = true
    exports['pma-voice']:setVoiceProperty('radioEnabled', true)
    playAudio('Start_Squelch', 'CB_RADIO_SFX')
  end
  exports['pma-voice']:setRadioChannel(channel)
  radioChannel = channel

  local channelMessage = channel % 1 > 0 and 'Du er nå på frekvens ' .. channel .. ' MHz' or 'Du er nå tilkoblet frekvens ' .. channel .. '0 MHz'
  notifyUser(channelMessage, 'success')
end

-- Leave the current radio channel
local leaveRadio = function()
  if not inChannel then return end

  if radioChannel == 0 then
    notifyUser('Du er ikke koblet til noen kanal', 'error')
    return
  end

  playAudio('End_Squelch', 'CB_RADIO_SFX')
  notifyUser('Du har forlatt radiokanalen', 'error')

  radioChannel = 0
  inChannel = false
  exports['pma-voice']:setVoiceProperty('radioEnabled', false)
  exports['pma-voice']:setRadioChannel(0)
end

-- Handle the power button functionality
local powerButton = function()
  onRadio = not onRadio

  if not onRadio then
    leaveRadio()
  end

  playAudio(onRadio and "On_High" or "Off_High", 'MP_RADIO_SFX')
end

-- Handle animations
local Anim = function(emote)
  exports.scully_emotemenu:playEmoteByCommand(emote)
end

-- NUI callback functions

-- Hide UI and cancel emote
local hideUI = function(_, cb)
  ShowNUI(false)
  exports.scully_emotemenu:cancelEmote()
  cb('ok')
end

-- Toggle radio power
local toggleRadioPower = function(data, cb)
  onRadio = data.isOn
  if not onRadio then
    leaveRadio()
  end
  cb('ok')
end

-- Connect to radio callback
local connectToRadioCallback = function(data, cb)
  if not onRadio then return cb('ok') end

  local rchannel = tonumber(data.channel)
  if not rchannel or type(rchannel) ~= "number" or rchannel > Config.maxFrequency or rchannel < 1 then
    notifyUser("Denne frekvensen er ikke tilgjengelig", 'error')
    return cb('ok')
  end

  rchannel = round(rchannel, Config.decimalPlaces)

  if rchannel == radioChannel then
    notifyUser("Du er allerede koblet til denne radiofrekvensen", 'error')
    return cb('ok')
  end

  local frequency = not Config.whitelistSubChannels and math.floor(rchannel) or rchannel
  if Config.restrictedChannels[frequency] and (not Config.restrictedChannels[frequency][QBCore.Functions.GetPlayerData().job.name] or not QBCore.Functions.GetPlayerData().job.onduty) then
    notifyUser("Du kan ikke koble til denne radiofrekvensen", 'error')
    return cb('ok')
  end

  connectToRadio(rchannel)
  cb('ok')
end

-- Leave radio callback
local leaveRadioCallback = function(_, cb)
  leaveRadio()
  cb('ok')
end

-- Power button callback
local powerButtonCallback = function(_, cb)
  powerButton()
  cb(onRadio and 'on' or 'off')
end

-- Trigger notification callback
local triggerNotification = function(_, cb)
  if onRadio then
    cb('ok')
  else
    cb('not_on_radio')
  end
end

-- Increase volume
local volumeUp = function(_, cb)
  if not onRadio then return cb('ok') end
  if radioVolume > 95 then
    notifyUser('Maksimalt volum nådd', 'error')
    return
  end

  radioVolume = radioVolume + 5
  notifyUser('Nytt volumnivå: ' .. radioVolume, 'success')
  exports['pma-voice']:setRadioVolume(radioVolume)
  cb('ok')
end

-- Decrease volume
local volumeDown = function(_, cb)
  if not onRadio then return cb('ok') end
  if radioVolume < 10 then
    notifyUser('Minimum volume reached', 'error')
    return
  end

  radioVolume = radioVolume - 5
  notifyUser('Nytt volumnivå: ' .. radioVolume, 'success')
  exports['pma-voice']:setRadioVolume(radioVolume)
  cb('ok')
end

-- Toggle mic clicks
local toggleClicks = function(data, cb)
  if not onRadio then return cb('ok') end

  micClicks = data.micClicks or false
  exports['pma-voice']:setVoiceProperty("micClicks", micClicks)
  playAudio(micClicks and "On_High" or "Off_High", 'MP_RADIO_SFX')
  notifyUser('Mic clicks ' .. (micClicks and 'enabled' or 'disabled'), 'success')
  cb('ok')
end

-- Play sound
local playSound = function(data, cb)
  if Config.radioMenuSound then
    local soundName = data.soundName
    if soundName == 'Next' then
      playAudio("On_High", 'MP_RADIO_SFX')
    end
  end
  cb('ok')
end

-- Register NUI callbacks
RegisterNUICallback('hide-ui', hideUI)
RegisterNUICallback('toggleRadioPower', toggleRadioPower)
RegisterNUICallback('connectToRadio', connectToRadioCallback)
RegisterNUICallback('leaveRadio', leaveRadioCallback)
RegisterNUICallback('powerButton', powerButtonCallback)
RegisterNUICallback('triggerNotification', triggerNotification)
RegisterNUICallback('volumeUp', volumeUp)
RegisterNUICallback('volumeDown', volumeDown)
RegisterNUICallback('toggleClicks', toggleClicks)
RegisterNUICallback('playSound', playSound)

-- Event to open the radio interface
RegisterNetEvent('openRadio')
AddEventHandler('openRadio', function(arg)
  ShowNUI(arg)
  Anim('wt')
end)

-- Set mic clicks to default value on player load
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
  exports['pma-voice']:setVoiceProperty("micClicks", true)
end)

-- Reset state on player unload
RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
  powerButton()
end)

-- Check radio item count
AddEventHandler('ox_inventory:itemCount', function(itemName, totalCount)
  if itemName ~= 'radio' then return end
  if totalCount <= 0 and radioChannel ~= 0 then
    powerButton()
  end
end)

-- Handle player death state
if Config.leaveOnDeath then
  AddStateBagChangeHandler('isDead', ('player:%s'):format(cache.serverId), function(_, _, value)
    if value and onRadio and radioChannel ~= 0 then
      leaveRadio()
    end
  end)
end
