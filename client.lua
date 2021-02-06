ESX = nil
local PlayerData = {}
local invopen = false
-- hsn inventory Hasan.#7803
Citizen.CreateThread(function()
    while ESX == nil do
        ESX = exports['es_extended']:getSharedObject()
        Citizen.Wait(10)
    end
    while ESX.GetPlayerData().job == nil do
        Citizen.Wait(10)
    end
    PlayerData = ESX.GetPlayerData()
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    PlayerData.job = job
end)

local Drops = {}
local currentDrop = nil
local curweaponSlot = nil
local keys = {
    157, 158, 160, 164, 165
}
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(3)
        DisableControlAction(0, 37, true)
        for i = 19, 20 do 
            HideHudComponentThisFrame(i) -- remove tab etc.
        end
        DisableControlAction(0, 157, true) -- 1
        DisableControlAction(0, 158, true) -- 2
        DisableControlAction(0, 160, true) -- 3
        DisableControlAction(0, 164, true) -- 4
        DisableControlAction(0, 165, true) -- 5
        DisableControlAction(0, 289, true) -- F2
        if not invopen then
            if IsDisabledControlJustPressed(1,289) then
                TriggerEvent("randPickupAnim")
                TriggerServerEvent("hsn-inventory:server:openInventory",{type = 'drop',id = currentDrop})
            end
            for k, v in pairs(keys) do
                if IsDisabledControlJustReleased(0, v) then
                    TriggerServerEvent("hsn-inventory:server:useItemfromSlot",k)
                end
            end
        end
        if IsPedInAnyVehicle(PlayerPedId(), false) then
           if IsControlJustPressed(1,47) then -- [G]lovebox
               local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
               local plate = GetVehicleNumberPlateText(vehicle)
               OpenGloveBox(plate)
            end
       else
            if IsControlJustPressed(1,48) then
                local vehicle = ESX.Game.GetClosestVehicle()
                local pos = GetEntityCoords(PlayerPedId())
                local trunkpos = GetOffsetFromEntityInWorldCoords(vehicle, 0, -2.5, 0)
                if (GetDistanceBetweenCoords(pos.x, pos.y, pos.z, trunkpos) < 2.0) and not IsPedInAnyVehicle(PlayerPedId()) then
                    if GetVehicleDoorLockStatus(vehicle) ~= 2 then
                        local plate = GetVehicleNumberPlateText(vehicle)
                        OpenTrunk(plate)
                    else
                       TriggerEvent('notification','This vehicle is locked',2)
                    end
                end
            end
        end
    end
end)

OpenGloveBox = function(gloveboxid)
    TriggerServerEvent("hsn-inventory:server:openInventory",{type = 'glovebox',id = 'glovebox-'..gloveboxid})
end
OpenTrunk = function(trunkid)
    TriggerServerEvent("hsn-inventory:server:openInventory",{type = 'trunk',id = 'trunk-'..trunkid})
end
RegisterNetEvent("hsn-inventory:client:openInventory")
AddEventHandler("hsn-inventory:client:openInventory",function(inventory,other)
    invopen = true
    -- some players dupe while taskbar on screen
    -- local check = exports["progressBars"]:onScreen()
    -- if check then
    --     return
    -- end
    SendNUIMessage({
        message = 'openinventory',
        inventory = inventory,
        slots = Config.PlayerSlot,
        name = GetPlayerName(PlayerId())..' ['..GetPlayerServerId()..']',
        maxweight = ESX.GetConfig().MaxWeight,
        rightinventory = other
    })
    TriggerServerEvent("hsn-inventory:setcurrentInventory",other)
    if other == nil then movement = true else movement = false end
    SetNuiFocusAdvanced(true, true, movement)
end)



RegisterNetEvent("hsn-inventory:client:closeInventory")
AddEventHandler("hsn-inventory:client:closeInventory",function(id)
    invopen = false
    SendNUIMessage({
        message = 'close',
    })
    SetNuiFocusAdvanced(false,false)
    TriggerServerEvent("hsn-inventory:removecurrentInventory",id)
end)

 RegisterCommand("teststash",function()
     TriggerServerEvent("hsn-inventory:server:openStash", {name = 'Hasqaws',slots = 15, type = 'stash'})
 end)

RegisterNetEvent("hsn-inventory:client:refreshInventory")
AddEventHandler("hsn-inventory:client:refreshInventory",function(inventory)
    SendNUIMessage({
        message = 'refresh',
        inventory = inventory,
        slots = Config.PlayerSlot,
        name = GetPlayerName(PlayerId())..' ['..GetPlayerServerId()..']',
        maxweight = ESX.GetConfig().MaxWeight,
    })
end)


RegisterNUICallback("exit",function(data)
    SetNuiFocusAdvanced(false,false)
    TriggerServerEvent('hsn-inventory:server:saveInventory',data)
    TriggerServerEvent("hsn-inventory:removecurrentInventory",data.invid)
end)
--- thread
Citizen.CreateThread(function()
    while true do
        local wait = 1000
        for k,v in pairs(Drops) do
            distance = #(GetEntityCoords(PlayerPedId()) - vector3(v.coords.x,v.coords.y,v.coords.z))
            if distance <= 10.0 then
                wait = 1
                DrawMarker(2, v.coords.x,v.coords.y,v.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.2, 0.15, 200, 0, 0, 222, false, false, false, true, false, false, false)
                if distance <= 1.0 then
                    currentDrop = v.dropid
                else
                    currentDrop = nil
                end
            end
        end
        Citizen.Wait(wait)
    end
end)

RegisterNetEvent("hsn-inventory:client:addItemNotify")
AddEventHandler("hsn-inventory:client:addItemNotify",function(item,text)
    SendNUIMessage({
        message = 'notify',
        item = item,
        text = text
    })
end)


function DrawText3Ds(x,y,z, text)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x,_y)
    local factor = (string.len(text)) / 370
	DrawRect(_x,_y+0.0125, 0.015+ factor, 0.03, 41, 11, 41, 68)
	ClearDrawOrigin()
end

Citizen.CreateThread(function()
    while true do
        while not PlayerData.job do Citizen.Wait(0) end
        Citizen.Wait(2)
        for i = 1, #Config.Shops do
            distance = #(GetEntityCoords(PlayerPedId()) - Config.Shops[i].coords)
            if distance <= 2.5 and (not Config.Shops[i].job or Config.Shops[i].job == PlayerData.job.name) then
                DrawMarker(2, Config.Shops[i].coords.x,Config.Shops[i].coords.y,Config.Shops[i].coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.15, 0.2, 30, 150, 30, 100, false, false, false, true, false, false, false)
                if IsControlJustPressed(1,38) and distance <= 1 then
                    OpenShop(Config.Shops[i])
                end
            end
        end

    end
end)

Citizen.CreateThread(function()
    while not PlayerData.job do Citizen.Wait(0) end
    for k,v in pairs(Config.Shops) do
        if (not Config.Shops[k].job or Config.Shops[k].job == PlayerData.job.name) then
            local blip = AddBlipForCoord(v.coords.x, v.coords.y, v.coords.z)
            SetBlipSprite(blip, v.blip.id or 1)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, v.blip.scale or 0.5)
            SetBlipColour(blip, v.blip.color or 1)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(v.blip.name or 'Shop')
            EndTextCommandSetBlipName(blip)
        end
    end
end)




OpenShop = function(id)
    TriggerServerEvent("hsn-inventory:server:openInventory",{type = 'shop',id = id})
end

OpenStash = function(id)
    TriggerServerEvent("hsn-inventory:server:openStash", {name = id.name, slots = id.slots, type = 'stash'})
end

RegisterNetEvent("hsn-inventory:Client:addnewDrop")
AddEventHandler("hsn-inventory:Client:addnewDrop",function(PlayerId,drop)
    local coords = GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(PlayerId)))
    local forward = GetEntityForwardVector(GetPlayerPed(GetPlayerFromServerId(PlayerId)))
	local x, y, z = table.unpack(coords + forward * 0.5)
    Drops[drop] = {
        dropid = drop,
        coords = {
            x = x,
            y = y,
            z = z - 0.3,
        },
    }
end)

function loadAnimDict( dict )
    while ( not HasAnimDictLoaded( dict ) ) do
        RequestAnimDict( dict )
        Citizen.Wait( 5 )
    end
end

RegisterNetEvent('randPickupAnim')
AddEventHandler('randPickupAnim', function()
    loadAnimDict('pickup_object')
    TaskPlayAnim(PlayerPedId(),'pickup_object', 'putdown_low',5.0, 1.5, 1.0, 48, 0.0, 0, 0, 0)
    Wait(1000)
    ClearPedSecondaryTask(PlayerPedId())
end)


RegisterNetEvent("hsn-inventory:client:removeDrop")
AddEventHandler("hsn-inventory:client:removeDrop",function(dropid)
    Drops[dropid] = nil
    currentDrop = nil
end)

RegisterNUICallback("UseItem", function(data, cb)
    if data.inv ~= "Playerinv" then
        return
    end
    TriggerServerEvent("hsn-inventory:server:useItem",data.item)
end)

RegisterNUICallback("saveinventorydata",function(data)
    TriggerServerEvent('hsn-inventory:server:saveInventoryData',data)
end)

RegisterNUICallback("notification", function(data)
    TriggerEvent('notification',data.message,data.type)
end)

RegisterNetEvent("hsn-inventory:client:weapon")
AddEventHandler("hsn-inventory:client:weapon",function(item)
    local curweapon = GetSelectedPedWeapon(PlayerPedId())
    if curweapon ==  GetHashKey(item.name) then
        RemoveWeaponFromPed(PlayerPedId(), GetHashKey(item.name))
        SetCurrentPedWeapon(PlayerPedId(), "WEAPON_UNARMED", true)
        curweaponSlot = nil
    elseif curweapon ~= GetHashKey(item.name) then
        curweaponSlot = item.slot
        GiveWeaponToPed(PlayerPedId(), GetHashKey(item.name), item.metadata.ammo, false, false)
        SetCurrentPedWeapon(PlayerPedId(), GetHashKey(item.name), true)
        local str = item.metadata.weaponlicense
        if str:find('POL') then
            SetPedWeaponTintIndex(PlayerPedId(), item.name, 5)
            if item.name:find('PISTOL') then component = GetHashKey('COMPONENT_AT_PI_FLSH') end
            if component then GiveWeaponComponentToPed(PlayerPedId(), GetHashKey(item.name), component) end
        end
        SetPedAmmo(PlayerPedId(), GetHashKey(item.name), item.metadata.ammo)
    end
end)

RegisterNetEvent("hsn-inventory:addAmmo")
AddEventHandler("hsn-inventory:addAmmo",function(item, name)
    local playerPed = PlayerPedId()
    local weapon
    local found, currentWeapon = GetCurrentPedWeapon(playerPed, true) -- thanks https://github.com/DiscworldZA/gta-resources/blob/master/disc-ammo/client/main.lua
    if found then
        for _, v in pairs(item.weapons) do
            if currentWeapon == v then
                weapon = v
                break
            end
        end
        if weapon ~= nil then
            local pedAmmo = GetAmmoInPedWeapon(playerPed, weapon)
            local newAmmo = pedAmmo + item.count
            ClearPedTasks(playerPed)
            local found, maxAmmo = GetMaxAmmo(playerPed, weapon)
            if newAmmo < maxAmmo then
                TriggerServerEvent("hsn-inventory:server:addweaponAmmo",curweaponSlot,item.count)
                TaskReloadWeapon(playerPed)
                SetPedAmmo(playerPed, weapon, newAmmo)
                TriggerEvent("notification","Reloaded", 1)
                TriggerServerEvent("hsn-inventory:client:removeItem",name,1)
            else
                TriggerEvent("notification","Max Ammo")
            end
        end
    end
end)


RegisterNetEvent("hsn-inventory:client:checkweapon")
AddEventHandler("hsn-inventory:client:checkweapon",function(item)
    local curweapon = GetSelectedPedWeapon(PlayerPedId())
    if curweapon ==  GetHashKey(item.name) then
        RemoveWeaponFromPed(PlayerPedId(), GetHashKey(item.name))
        SetCurrentPedWeapon(PlayerPedId(), "WEAPON_UNARMED", true)
        curweaponSlot = nil
    end
end)

RegisterNetEvent("hsn-inventory:clientweaponnotify")
AddEventHandler("hsn-inventory:clientweaponnotify",function(item)
    local curweapon = GetSelectedPedWeapon(PlayerPedId())
    if curweapon ==  GetHashKey(item.name) then
        TriggerEvent("hsn-inventory:client:addItemNotify",item,'Equip 1x')
    else
        TriggerEvent("hsn-inventory:client:addItemNotify",item,'Holster 1x')
    end
end)

RegisterNetEvent("hsn-inventory:client:esxUseItem")
AddEventHandler("hsn-inventory:client:esxUseItem",function(item)
    TriggerServerEvent("esx:useItem", item.name)
end)

RegisterCommand("robplayer",function()
    local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
    if closestPlayer ~= -1 and closestDistance <= 3.0 then
        TriggerServerEvent("hsn-inventory:server:robPlayer",GetPlayerServerId(GetClosestPlayer))
    else
        TriggerEvent("notification",'There is nobody nearby')
    end
end)



Citizen.CreateThread(function()
    while true do
        Citizen.Wait(3)
        if IsPedShooting(PlayerPedId()) then
            if curweaponSlot ~= nil then
                TriggerServerEvent("hsn-inventory:server:decrasedurability",curweaponSlot)
            end
        end
    end
end)

local nui_focus = {false, false}
function SetNuiFocusAdvanced(hasFocus, hasCursor, allowMovement)
    SetNuiFocus(hasFocus, hasCursor)
    SetNuiFocusKeepInput(hasFocus)
    nui_focus = {hasFocus, hasCursor}
    TriggerEvent("nui:focus", hasFocus, hasCursor)

    if nui_focus[1] then
        Citizen.CreateThread(function()
            local ticks = 0
            while true do
                Citizen.Wait(0)
                DisableAllControlActions(0)
                if not nui_focus[2] then
                    EnableControlAction(0, 1, true)
                    EnableControlAction(0, 2, true)
                end
                EnableControlAction(0, 249, true) -- N for PTT
                EnableControlAction(0, 20, true) -- Z for proximity
                if allowMovement then
                    EnableControlAction(0, 30, true) -- movement
                    EnableControlAction(0, 31, true) -- movement
                end
                if not nui_focus[1] then
                    ticks = ticks + 1
                    if (IsDisabledControlJustReleased(0, 200, true) or ticks > 20) then
                        invopen = false
                        break
                    end
                end
            end
        end)
    end
end
--[[ Disabled by default, remove comment block to use mythic_notify for notifications
RegisterNetEvent("notification")
AddEventHandler("notification",function(message, mtype)
    if mtype == 1 then mtype = { ['background-color'] = 'rgba(55,55,175)', ['color'] = 'white' }
    elseif not mtype or mtype == 2 then mtype = { ['background-color'] = 'rgba(175,55,55)', ['color'] = 'white' }
    end
    TriggerEvent('mythic_notify:client:SendAlert', {type = 'inform', text = message, length = 2500,style = mtype})
end)
]]

RegisterCommand('closeinv', function()
        TriggerEvent("hsn-inventory:client:closeInventory")
end, false)
