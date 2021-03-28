menuOpened, menuCat, menus = false, "eventsbuilder", {}

local builder = {
    message = nil,
    name = nil,
    reward = nil,
    vehicleModel = nil,
    from = nil,
    spawns = {},
    dests = {}
}

local function input(type, TextEntry, ExampleText, MaxStringLenght, isValueInt)
    
	AddTextEntry(type, TextEntry) 
	DisplayOnscreenKeyboard(1, type, "", ExampleText, "", "", "", MaxStringLenght) 
	blockinput = true

	while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
		Citizen.Wait(0)
	end
		
	if UpdateOnscreenKeyboard() ~= 2 then
		local result = GetOnscreenKeyboardResult() 
		Citizen.Wait(500) 
		blockinput = false 
        if isValueInt then 
            local isNumber = tonumber(result)
            if isNumber then return result else return nil end
        end

		return result
	else
		Citizen.Wait(500)
		blockinput = false 
		return nil
	end
end

local function subCat(string)
    return menuCat.."_"..string
end

local function addMenu(name)
    RMenu.Add(menuCat, subCat(name), RageUI.CreateMenu("MissionBuilder","~r~Gestion des missions"))
    RMenu:Get(menuCat, subCat(name)).Closed = function()end
    table.insert(menus, name)
end

local function addSubMenu(name, depend)
    RMenu.Add(menuCat, subCat(name), RageUI.CreateSubMenu(RMenu:Get(menuCat, subCat(depend)), "MissionBuilder", "~r~Gestion des missions"))
    RMenu:Get(menuCat, subCat(name)).Closed = function()end
    table.insert(menus, name)
end

local function valueNotDefault(value)
    if not value or value == "" then return "" else return "~s~: ~g~"..tostring(value) end
end

local function okIfDef(value)
    if not value or value == "" then return "" else return "~s~: ~g~Défini" end
end

local function delMenus()
    for k,v in pairs(menus) do 
        RMenu:Delete(menuCat, v)
    end
end

local function canCreateEvent(spawns, from, dests)
    return (#builder.spawns > 0 and builder.from ~= nil and #builder.dests > 0 and builder.name ~= nil and builder.name ~= "" and builder.vehicleModel ~= nil and builder.vehicleModel ~= "" and builder.message ~= nil and builder.message ~= "" and builder.reward ~= nil and tonumber(builder.reward) >= 0)
end

function openMenu(avaiblePresets, missionRunning) 
    local selectedEvent = 1
    local relativeTable = {}
    local avaibleEvents = {}
    for k,v in pairs(avaiblePresets) do
        table.insert(avaibleEvents, "~r~"..v.label.."~s~")
        table.insert(relativeTable, v)
    end
    local rewardTypes = {"~g~Propre~s~", "~r~Sale~s~"}
    local rewardTypeSelected = 1
    local colorVar = "~s~"
    local actualColor = 1
    local colors = {"~p~", "~r~","~o~","~y~","~c~","~g~","~b~"}
    local define = {RightLabel = "~b~Définir ~s~→→"}

    local from = nil
    local spawns = {}
    local dests = {}

    isMenuOpened = true
    addMenu("main")
    addSubMenu("builder", "main")
    RageUI.Visible(RMenu:Get(menuCat, subCat("main")), true)
    Citizen.CreateThread(function()
        while isMenuOpened do
            Wait(800)
            if colorVar == "~s~" then colorVar = "~r~" else colorVar = "~s~" end
        end
    end)

    Citizen.CreateThread(function()
        while isMenuOpened do 
            Wait(500)
            actualColor = actualColor + 1
            if actualColor > #colors then actualColor = 1 end
        end
    end)

    Citizen.CreateThread(function()
        while isMenuOpened do
            local shouldClose = true
            RageUI.IsVisible(RMenu:Get(menuCat,subCat("main")),true,true,true,function()
                shouldClose = false
                if not missionRunning then
                    local total = 0
                    for _,_ in pairs(avaiblePresets) do
                        total = total + 1
                    end
                    if total > 0 then
                        RageUI.Separator("↓ ~y~Démarrer une mission ~s~↓")
                        RageUI.List(colors[actualColor].."→ ~s~Sélection:", avaibleEvents, selectedEvent, nil, {}, true, function(_,_,_,i)
                            selectedEvent = i
                        end)
                        RageUI.ButtonWithStyle(colors[actualColor].."→ ~g~Démarrer la mission", nil, {RightLabel = "→→"}, true, function(_,_,s)
                            if s then
                                shouldClose = true
                                TriggerServerEvent("eventsbuilder_startmission", relativeTable[selectedEvent].id)
                            end
                        end)
                    end
                    RageUI.Separator("↓ ~o~Supprimer une mission ~s~↓")
                    if total <= 0 then
                        RageUI.ButtonWithStyle(colorVar.."Aucun modèle enregistré", nil, {}, true, function() end)
                    else
                        RageUI.List(colors[actualColor].."→ ~s~Sélection:", avaibleEvents, selectedEvent, nil, {}, true, function(_,_,_,i)
                            selectedEvent = i
                        end)
                        RageUI.ButtonWithStyle(colors[actualColor].."→ ~o~Supprimer la mission", nil, {RightLabel = "→→"}, true, function(_,_,s)
                            if s then
                                shouldClose = true
                                TriggerServerEvent("eventsbuilder_removemission", relativeTable[selectedEvent].id)
                            end
                        end)
                    end
                    RageUI.Separator("↓ ~r~Créer une mission ~s~↓")
                    RageUI.ButtonWithStyle(colors[actualColor].."→ ~s~Créer une mission", nil, {RightLabel = "→→"}, true, function(_,_,s)
                    end, RMenu:Get(menuCat, subCat("builder")))
                else
                    RageUI.Separator("↓ ~o~Actions ~s~↓")
                    RageUI.ButtonWithStyle(colors[actualColor].."→ ~r~Stopper la mission", nil, {RightLabel = "→→"}, true, function(_,_,s)
                        if s then
                            shouldClose = true
                            TriggerServerEvent("eventsbuilder_stopCurrentMission")
                        end
                    end)

                end
            end, function()    
            end, 1)

            RageUI.IsVisible(RMenu:Get(menuCat,subCat("builder")),true,true,true,function()
                shouldClose = false

                if builder.from ~= nil then DrawMarker(22, builder.from.x, builder.from.y, builder.from.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 0.45, 0.45, 0.45, 0,255,0, 255, 55555, false, true, 2, false, false, false, false) end
                for k,v in pairs(builder.spawns) do 
                    DrawMarker(22, v.pos.x, v.pos.y, v.pos.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 0.45, 0.45, 0.45, 0,0,255, 255, 55555, false, true, 2, false, false, false, false) 
                end
                for k,v in pairs(builder.dests) do
                    DrawMarker(22, v.x, v.y, v.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 0.45, 0.45, 0.45, 255,0,0, 255, 55555, false, true, 2, false, false, false, false) 

                end
            

                RageUI.Separator("↓ ~g~Informations de base ~s~↓")
                RageUI.ButtonWithStyle(colors[actualColor].."→ ~s~Nom de la mission"..valueNotDefault(builder.name), "~y~Description: ~s~vous permets de définir le nom de votre mission", define, true, function(_,_,s)
                    if s then
                        local result = input("FMMC_KEY_TIP1", "Mission builder", "", 15, false)
                        if result ~= nil then builder.name = result end
                    end
                end)
                RageUI.ButtonWithStyle(colors[actualColor].."→ ~s~Message de la mission"..okIfDef(builder.message), "~y~Description: ~s~vous permets de définir le message qui sera envoyé aux joueurs", define, true, function(_,_,s)
                    if s then
                        local result = input("FMMC_KEY_TIP10", "Mission builder", "", 100, false)
                        if result ~= nil then builder.message = result end
                    end
                end)
                RageUI.ButtonWithStyle(colors[actualColor].."→ ~s~Véhicule de la mission"..valueNotDefault(builder.vehicleModel), "~y~Description: ~s~vous permets de définir le véhicule avec lequel la mission devra s'effectuer", define, true, function(_,_,s)
                    if s then
                        local result = input("FMMC_KEY_TIP1", "Mission builder", "", 20, false)
                        if result ~= nil then
                            local model = GetHashKey(result:lower())
                            if not IsModelValid(model) then
                                ESX.ShowNotification("~r~Ce modèle est invalide !")
                            else
                                builder.vehicleModel = result
                            end
                        end
                    end
                end)
                RageUI.Separator("↓ ~y~Valeurs numériques ~s~↓")
                RageUI.ButtonWithStyle(colors[actualColor].."→ ~s~Récompense"..valueNotDefault(builder.reward), "~y~Description: ~s~vous permets de définir la récompense qui sera octroyée aux joueurs", define, true, function(_,_,s)
                    if s then
                        local result = input("FMMC_KEY_TIP1", "Mission builder", "", 10, true)
                        if result ~= nil then builder.reward = result end
                    end
                end)
                RageUI.List(colors[actualColor].."→ ~s~Récompense de type:", rewardTypes, rewardTypeSelected, nil, {}, true, function(_,_,_,i)
                    rewardTypeSelected = i
                end)
                RageUI.Separator("↓ ~o~Position de départ ~s~↓")

                RageUI.ButtonWithStyle(colors[actualColor].."→ ~s~Récupération du véhicule"..okIfDef(builder.from), "~y~Description: ~s~vous permets de définir le point où les joueurs doivent récuperer le véhicule", define, true, function(_,_,s)
                    if s then
                        local pos = GetEntityCoords(PlayerPedId())
                        builder.from = {x = pos.x, y = pos.y, z = pos.z}
                    end
                end)
                RageUI.Separator("")
                RageUI.ButtonWithStyle(colors[actualColor].."→ ~s~Ajouter un point de spawn", "~y~Description: ~s~vous permets d'ajouter un point de spawn pour le véhicule", define, true, function(_,_,s)
                    if s then
                        local pos = GetEntityCoords(PlayerPedId())
                        table.insert(builder.spawns, {pos = {x = pos.x, y = pos.y, z = pos.z}, heading = GetEntityHeading(PlayerPedId())})
                    end
                end)
                RageUI.ButtonWithStyle(colors[actualColor].."→ ~r~Supprimer les spawns ~s~(~b~"..#builder.spawns.."~s~)", "~y~Description: ~s~vous permets de supprimer les points de spawn", define, true, function(_,_,s)
                    if s then
                        builder.spawns = {}
                    end
                end)
                RageUI.Separator("↓ ~o~Position d'arrivée ~s~↓")
                RageUI.ButtonWithStyle(colors[actualColor].."→ ~s~Ajouter un point d'arrivée", "~y~Description: ~s~vous permets d'ajouter un point d'arrivée pour la mission", define, true, function(_,_,s)
                    if s then
                        local pos = GetEntityCoords(PlayerPedId())
                        table.insert(builder.dests, {x = pos.x, y = pos.y, z = pos.z})
                    end
                end)
                RageUI.ButtonWithStyle(colors[actualColor].."→ ~r~Supprimer les destinations ~s~(~b~"..#builder.dests.."~s~)", "~y~Description: ~s~vous permets de supprimer les points d'arrivée", define, true, function(_,_,s)
                    if s then
                        builder.dests = {}
                    end
                end)
                RageUI.Separator("↓ ~r~ Actions ~s~↓")
                RageUI.ButtonWithStyle(colors[actualColor].."→ ~g~Sauvegarder et appliquer", "~y~Description: ~s~une fois toutes les étapes effectuées, sauvegardez votre mission", {RightLabel = "→→"}, canCreateEvent(spawns, from, dests), function(_,_,s)
                    if s then
                        shouldClose = true
                        ESX.ShowNotification("~o~Création de la mission en cours...")
                        builder.rewardType = rewardTypeSelected
                        TriggerServerEvent("eventsbuilder_create", builder)
                    end
                end)
            end, function()
            end, 1)

            if shouldClose and isMenuOpened then
                isMenuOpened = false
            end

            Wait(0)
        end

        delMenus()
    end)
end