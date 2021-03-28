local ESX, presets, isMissionRunning, runningMissionID = nil, {}, false, nil
local includedPlayers = {}

local function getLicense(source) 
    for k,v in pairs(GetPlayerIdentifiers(source))do      
        if string.sub(v, 1, string.len("license:")) == "license:" then
            return v
        end
    end
    return ""
end

local function updateEventsPresets()
    presets = {}
    MySQL.Async.fetchAll("SELECT * FROM eventsPresets", {}, function(result)
        for k,v in pairs(result) do 
            presets[v.id] = {label = v.label, infos = json.decode(v.presetInfos), id = v.id}
        end
    end) 
end

local function start(id)
    TriggerClientEvent("eventsbuilder_receiveStart", -1, presets[id].infos)
end

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterCommand("missionsbuilder", function(source)
    if source == 0 then return end
    local license = getLicense(source)
    if not Config.allowedLicense[license] then
        if log then print("^1[MissionBuilder] ^7Player ^2".. GetPlayerName(source) .. "^7 attempt to use missionbuilder.") end
        return
    end
    TriggerClientEvent("eventsbuilder_openMenu", source, presets, isMissionRunning)
end, false)

RegisterNetEvent("eventsbuilder_missionDone")
AddEventHandler("eventsbuilder_missionDone", function()
    local source = source
    if not isMissionRunning then
        return
    end
    if not presets[runningMissionID] then
        TriggerClientEvent("esx:showNotification", source, "~r~La mission que vous avez terminé n'existe plus.")
        return
    end
    if not includedPlayers[source] then
        TriggerClientEvent("esx:showNotification", source, "~r~Vous n'êtes pas compris dans l'event")
        return
    end
    local missionInfos = presets[runningMissionID].infos
    local reward = missionInfos.reward
    local type = missionInfos.rewardType

    local xPlayer = ESX.GetPlayerFromId(source)

    if type == 1 then
        xPlayer.addMoney(tonumber(reward))
    elseif type == 2 then
        xPlayer.addAccountMoney("black_money", tonumber(reward))
    else
        xPlayer.addMoney(tonumber(reward))
    end
    TriggerClientEvent("esx:showNotification", source, "~g~Vous avez remporté ~y~"..reward.."$ ~g~pour avoir réussi la mission!")
    includedPlayers[source] = nil
end)

RegisterNetEvent("eventsbuilder_create")
AddEventHandler("eventsbuilder_create", function(builder)
    local source = source
    local license = getLicense(source)
    if not Config.allowedLicense[license] then
        if log then print("^1[MissionBuilder] ^7Player ^2".. GetPlayerName(source) .. "^7 attempt to create a mission") end
        return
    end
    MySQL.Async.execute("INSERT INTO eventsPresets (createdBy, label, presetInfos) VALUES(@a, @b, @c)",
    {
        ['a'] = GetPlayerName(source),
        ['b'] = builder.name,
        ['c'] = json.encode(builder)
    }, function()
        updateEventsPresets()
        TriggerClientEvent("esx:showNotification", source, "~g~La mission ~y~"..builder.name.."~g~ a été créée")
    end)
end)

RegisterNetEvent("eventsbuilder_removemission")
AddEventHandler("eventsbuilder_removemission", function(eventID)
    local source = source
    local license = getLicense(source)
    if not Config.allowedLicense[license] then
        if log then print("^1[MissionBuilder] ^7Player ^2".. GetPlayerName(source) .. "^7 attempt to delete a mission") end
        return
    end
    if presets[eventID] == nil then
        TriggerClientEvent("esx:showNotification", source, "~r~Cette mission n'existe plus :( !")
        return
    end
    MySQL.Async.execute("DELETE FROM eventsPresets WHERE id = @a",
    {
        ['a'] = eventID
    }, function()
        TriggerClientEvent("esx:showNotification", source, "~g~La mission ~y~"..presets[eventID].label.."~g~ a été supprimée")
        updateEventsPresets()
    end)
end)

RegisterNetEvent("eventsbuilder_startmission")
AddEventHandler("eventsbuilder_startmission", function(missionID)
    local source = source
    local license = getLicense(source)
    if not Config.allowedLicense[license] then
        if log then print("^1[MissionBuilder] ^7Player ^2".. GetPlayerName(source) .. "^7 attempt to start a mission") end
        return
    end
    if presets[missionID] == nil then
        TriggerClientEvent("esx:showNotification", source, "~r~Cette mission n'existe plus :( !")
        return
    end
    if isMissionRunning then
        TriggerClientEvent("esx:showNotification", source, "~r~Une mission est déjà en cours !")
        return
    end
    includedPlayers = {}
    for k,v in pairs(ESX.GetPlayers()) do
        includedPlayers[v] = true
    end
    runningMissionID = missionID
    isMissionRunning = true
    TriggerClientEvent("esx:showNotification", source, "~g~Mission démarrée")
    start(missionID)
    -- FAIRE LE RESTE
end)

RegisterNetEvent("eventsbuilder_stopCurrentMission")
AddEventHandler("eventsbuilder_stopCurrentMission", function()
    local source = source
    local license = getLicense(source)
    if not Config.allowedLicense[license] then
        if log then print("^1[MissionBuilder] ^7Player ^2".. GetPlayerName(source) .. "^7 attempt to stop a mission") end
        return
    end
    if isMissionRunning then
        isMissionRunning = false
        runningMissionID = nil
        TriggerClientEvent("esx:showNotification", source, "~g~La mission a été stoppée")
        TriggerClientEvent("eventsbuilder_receiveStop", -1)
        
    else
        TriggerClientEvent("esx:showNotification", source, "~r~Il n'y a aucune mission active!")
    end
end)

MySQL.ready(function()
    updateEventsPresets()
end)