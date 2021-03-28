local isEverActive = false
local entities, blips = {}, {}

local function eventNotif(sender, subject, msg, textureDict, iconType)
    SetAudioFlag("LoadMPData", 1)
    PlaySoundFrontend(-1, "Boss_Message_Orange", "GTAO_Boss_Goons_FM_Soundset", 1)
	AddTextEntry('AutoEventAdvNotif', msg)
	BeginTextCommandThefeedPost('AutoEventAdvNotif')
	EndTextCommandThefeedPostMessagetext(textureDict, textureDict, false, iconType, sender, subject)
end

local function addBlip(blip)
    table.insert(blips, blip)
end

local function addEntity(entity)
    table.insert(entities, entity)
end

local function startMission(mission)
    isEverActive = true
    local model = GetHashKey(mission.vehicleModel)
    local plate = nil
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(1) end
    if not isEverActive then return end


    local interactionDone = false
    eventNotif("~r~Événement RolePlay", "~o~Livraison de véhicule", "~y~Description~s~: "..mission.message, "CHAR_BIKESITE", 1)

    local blip1 = AddBlipForCoord(mission.from.x, mission.from.y, mission.from.z)
    SetBlipScale(blip1, 0.8)
    SetBlipSprite(blip1, 161)
    SetBlipColour(blip1, 47)
    PulseBlip(blip1)

    local blip2 = AddBlipForCoord(mission.from.x, mission.from.y, mission.from.z)
    SetBlipScale(blip2, 0.8)
    SetBlipSprite(blip2, 611)
    SetBlipColour(blip2, 47)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString("~y~Mission: ~s~"..mission.name)
    EndTextCommandSetBlipName(blip2)

    addBlip(blip1)
    addBlip(blip2)

    local vehicleOut = vector3(mission.from.x, mission.from.y, mission.from.z)
    Citizen.CreateThread(function()
        local interval = 0
        while isEverActive and not interactionDone do
            local pCords = GetEntityCoords(PlayerPedId())
            local dist = GetDistanceBetweenCoords(pCords, vehicleOut, true)
            if dist <= 60 then
                interval = 0
                DrawMarker(22, vehicleOut, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 0.45, 0.45, 0.45, 255,0,0, 255, 55555, false, true, 2, false, false, false, false) 
                if dist <= 1.0 then
                    AddTextEntry("MISSION", "Appuyez sur ~INPUT_CONTEXT~ pour sortir le véhicule de la mission")
                    DisplayHelpTextThisFrame("MISSION", 0)
                    if IsControlJustPressed(0, 51) then
                        interactionDone = true
                    end
                end
            else
                interval = 250
            end 
            Wait(interval)
        end
        if not isEverActive then return end
        print("^1Passe ICI")
        local spawn = mission.spawns[math.random(1, #mission.spawns)]
        local vehicle = CreateVehicle(model, spawn.pos.x, spawn.pos.y, spawn.pos.z, spawn.heading, true, false)
        plate = GetVehicleNumberPlateText(vehicle)
        SetVehicleEngineOn(vehicle, true, true, false)
        addEntity(vehicle)
        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)

        RemoveBlip(blip1)
        RemoveBlip(blip2)
        
        local arrival = mission.dests[math.random(1, #mission.dests)]
        local blip3 = AddBlipForCoord(arrival.x, arrival.y, arrival.z)
        SetBlipScale(blip3, 0.8)
        SetBlipSprite(blip3, 103)
        SetBlipColour(blip3, 47)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString("~y~Arrivée de mission: ~s~"..mission.name)
        EndTextCommandSetBlipName(blip3)
        SetBlipRoute(blip3, true)

        interactionDone = false
        interval = 0
        arrival = vector3(arrival.x, arrival.y, arrival.z)
        while isEverActive and not interactionDone do
            local pCords = GetEntityCoords(PlayerPedId())
            local dist = GetDistanceBetweenCoords(pCords, arrival, true)
            if dist <= 60 then
                interval = 0
                DrawMarker(22, arrival, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 0.45, 0.45, 0.45, 255,0,0, 255, 55555, false, true, 2, false, false, false, false) 
                if dist <= 1.0 then
                    AddTextEntry("MISSION", "Appuyez sur ~INPUT_CONTEXT~ pour récupérer votre récompense")
                    DisplayHelpTextThisFrame("MISSION", 0)
                    if IsControlJustPressed(0, 51) then
                        if IsPedInAnyVehicle(PlayerPedId(), false) then
                            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                            if GetPedInVehicleSeat(vehicle, -1) == PlayerPedId() then
                                local vehPlate = GetVehicleNumberPlateText(vehicle)
                                if vehPlate == plate then
                                    interactionDone = true
                                    DeleteEntity(vehicle)
                                    RemoveBlip(blip3)
                                else
                                    ESX.ShowNotification("~r~Il ne s'agit pas du même véhicule qu'au début")
                                end
                            else
                                ESX.ShowNotification("~r~Vous devez être le conducteur du véhicue !")
                            end
                        else
                            ESX.ShowNotification("~r~Vous devez être dans un véhicule")
                        end
                    end
                end
            else
                interval = 250
            end 
            Wait(interval)
        end
        if not isEverActive then return end
        TriggerServerEvent("eventsbuilder_missionDone")
    end)
end


RegisterNetEvent("eventsbuilder_receiveStart")
AddEventHandler("eventsbuilder_receiveStart", function(infos)
    startMission(infos)
end)

RegisterNetEvent("eventsbuilder_receiveStop")
AddEventHandler("eventsbuilder_receiveStop", function(receiveStop)
    isEverActive = false
    for k,v in pairs(blips) do
        if DoesBlipExist(v) then RemoveBlip(v) end
    end
    for k,v in pairs(entities) do
        if v ~= nil then DeleteEntity(v) end
    end
    eventNotif("~r~Événement RolePlay", "~o~Livraison de véhicule", "L'événement est ~r~terminé~s~, j'espère que tu as eu le temps de le faire...", "CHAR_BIKESITE", 1)
end)