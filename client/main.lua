ESX, isMenuOpened = nil, false

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
end)

RegisterNetEvent("eventsbuilder_openMenu")
AddEventHandler("eventsbuilder_openMenu", function(presets, missionRunning)
    if isMenuOpened then return end
    openMenu(presets, missionRunning)
end)