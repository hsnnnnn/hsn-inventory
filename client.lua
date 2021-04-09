ESX = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj)
			ESX = obj
		end)
		Citizen.Wait(10)
	end
	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end
	StartInventory()
end)

function clearWeapons()
	SetCurrentPedWeapon(playerPed, `WEAPON_UNARMED`, true)
	for k,v in pairs(Config.DurabilityDecreaseAmount) do
		local hash = GetHashKey(k)
		SetPedAmmo(playerPed, hash, 0)
	end
	RemoveAllPedWeapons(playerPed, true)
	SetPedCanSwitchWeapon(playerPed, false)
end

function StartInventory()
	PlayerData, playerID, playerPed, invOpen, isDead, isCuffed, isBusy, currentWeapon = nil, nil, nil, false, false, false, false, nil
	ESX.TriggerServerCallback('hsn-inventory:getData',function(data)
		playerName = data.name
		oneSync = data.oneSync
		PlayerData = ESX.GetPlayerData()
		playerID = GetPlayerServerId(PlayerId())
		playerPed = PlayerPedId()
		clearWeapons()
	end)
end

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	PlayerData.job = job
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(job)
	StartInventory()
end)

local Drops = {}
local currentDrop = nil
local currentDropCoords = nil
local keys = {
	157, 158, 160, 164, 165
}


AddEventHandler('esx:onPlayerSpawn', function(spawn)
	isDead = false
end)


RegisterNetEvent('esx_ambulancejob:setDeathStatus')
AddEventHandler('esx_ambulancejob:setDeathStatus', function(status)
	isDead = status
end)


RegisterNetEvent('esx_policejob:handcuff')
AddEventHandler('esx_policejob:handcuff', function()
	isCuffed = not isCuffed
end)

RegisterNetEvent('esx_policejob:unrestrain')
AddEventHandler('esx_policejob:unrestrain', function()
	isCuffed = false
end)


AddEventHandler('hsn-inventory:currentWeapon',function(weapon)
	currentWeapon = weapon
end)

local weaponTimer = 0
AddEventHandler('hsn-inventory:usedWeapon',function(weapon)
	weaponTimer = (100 * 3)
end)

Citizen.CreateThread(function()
	local wait = false
	while true do
		Citizen.Wait(3)
		playerPed = PlayerPedId()
		playerCoords = GetEntityCoords(playerPed)
		DisableControlAction(0, 37, true)  -- tab
		DisableControlAction(0, 157, true) -- 1
		DisableControlAction(0, 158, true) -- 2
		DisableControlAction(0, 160, true) -- 3
		DisableControlAction(0, 164, true) -- 4
		DisableControlAction(0, 165, true) -- 5
		DisableControlAction(0, 289, true) -- F2
		for i = 19, 20 do 
			HideHudComponentThisFrame(i) -- remove tab etc.
		end
		if isBusy then
			DisableControlAction(0, 24, true)
			DisableControlAction(0, 25, true)
			DisableControlAction(0, 142, true)
			DisableControlAction(0, 257, true)
		end
		if not invOpen then
			for k, v in pairs(keys) do
				if IsDisabledControlJustReleased(0, v) and CanOpenInventory() then
					TriggerServerEvent('hsn-inventory:server:useItemfromSlot',k)
				end
			end
			--[[if IsDisabledControlJustReleased(0, 37) and not isDead and not isCuffed then -- show hotbar
				ESX.TriggerServerCallback('hsn-inventory:server:gethottbarItems',function(data)
					if data then
						SendNUIMessage({
							message = 'hsn-hotbar',
							items = data
						})
					end
				end)
			end]]
		end
		if currentWeapon then
			if weaponTimer == 3 then
				TriggerServerEvent('hsn-inventory:server:updateWeapon', currentWeapon.item)
				weaponTimer = 0
			elseif weaponTimer > 3 then weaponTimer = weaponTimer - 3 end
			SetPedCurrentWeaponVisible(playerPed, true, false, false, false)
			if IsPedArmed(ped, 6) then
				DisableControlAction(1, 140, true)
				DisableControlAction(1, 141, true)
				DisableControlAction(1, 142, true)
			end
			usingWeapon = IsPedShooting(playerPed)
			if usingWeapon then
				local ammo = GetAmmoInPedWeapon(playerPed, currentWeapon.hash)
				if (currentWeapon.item.name == 'WEAPON_FIREEXTINGUISHER' or currentWeapon.item.name == 'WEAPON_PETROLCAN') and not wait then
					if currentWeapon.item.metadata.durability then currentWeapon.item.metadata.durability = currentWeapon.item.metadata.durability - 0.1 end
					if currentWeapon.item.metadata.durability <= 0 then
						Citizen.CreateThread(function()
							wait = true
							ClearPedTasks(playerPed)
							SetCurrentPedWeapon(playerPed, currentWeapon.hash, true)
							TriggerServerEvent('hsn-inventory:client:removeItem', currentWeapon.item.name, 1, currentWeapon.item.metadata, currentWeapon.item.slot)
							Citizen.Wait(200)
							SetCurrentPedWeapon(playerPed, `WEAPON_UNARMED`, true)
							currentWeapon = nil
							wait = false
						end)
					end
				elseif currentWeapon.item.metadata.serial and currentWeapon.item.metadata.ammo then
					currentWeapon.item.metadata.ammo = ammo
					if ammo == 0 then
						weaponTimer = 0
						ClearPedTasks(playerPed)
						SetCurrentPedWeapon(playerPed, currentWeapon.hash, false)
						SetPedCurrentWeaponVisible(playerPed, true, false, false, false)
						TriggerServerEvent('hsn-inventory:server:reloadWeapon', currentWeapon)
					else TriggerEvent('hsn-inventory:usedWeapon', currentWeapon) end
				end
			elseif currentWeapon.item.metadata.throwable and not wait and IsControlJustReleased(0, 24) then
				usingWeapon = true
				Citizen.CreateThread(function()
					wait = true
					Citizen.Wait(800)
					TriggerServerEvent('hsn-inventory:client:removeItem', currentWeapon.item.name, 1, currentWeapon.item.metadata, currentWeapon.item.slot)
					SetCurrentPedWeapon(playerPed, `WEAPON_UNARMED`, true)
					currentWeapon = nil
					wait = false
				end)
			elseif Config.Melee[currentWeapon.item.name] and not wait and IsPedInMeleeCombat(playerPed) and IsControlPressed(0, 24) then
				usingWeapon = true
				Citizen.CreateThread(function()
					wait = true
					TriggerServerEvent('hsn-inventory:server:decreasedurability', playerID, currentWeapon.item.slot, currentWeapon.item.name, 1)
					TriggerEvent('hsn-inventory:usedWeapon', currentWeapon)
					Citizen.Wait(400)
					wait = false
				end)
			else usingWeapon = false end
		end
	end
end)


RegisterCommand('vehinv', function()
	if not playerID then return end
	if isBusy or invOpen then TriggerEvent('hsn-inventory:notification','You can\'t open your inventory right now',2) return end 
	if not CanOpenInventory() then return end
	if not isDead and not isCuffed and not IsPedInAnyVehicle(playerPed, false) then -- trunk
		local vehicle = ESX.Game.GetClosestVehicle()
		local coords = GetEntityCoords(playerPed)
		CloseToVehicle = false
		lastVehicle = nil
		if not IsPedInAnyVehicle(playerPed) then
			if GetVehicleDoorLockStatus(vehicle) ~= 2 then
				local vehHash = GetEntityModel(vehicle)
				local checkVehicle = Config.VehicleStorage[vehHash]
				if checkVehicle == 1 then open, vehBone = 4, GetEntityBoneIndexByName(vehicle, 'bonnet')
				elseif checkVehicle == nil then open, vehBone = 5, GetEntityBoneIndexByName(vehicle, 'boot') elseif checkVehicle == 2 then open, vehBone = 5, GetEntityBoneIndexByName(vehicle, 'boot') else --[[no vehicle nearby]] return end
				
				if vehBone == -1 then
					vehBone = GetEntityBoneIndexByName(vehicle, 'wheel_rr')
				end
				
				local vehiclePos = GetWorldPositionOfEntityBone(vehicle, vehBone)
				local pedDistance = #(coords - vehiclePos)
				if (open == 5 and checkVehicle == nil) then if pedDistance < 2.0 then CloseToVehicle = true end elseif (open == 5 and checkVehicle == 2) then if pedDistance < 2.0 then CloseToVehicle = true end elseif open == 4 then if pedDistance < 2.0 then CloseToVehicle = true end end	
				if CloseToVehicle then
					local plate = GetVehicleNumberPlateText(vehicle)
					local class = GetVehicleClass(vehicle)
					TaskTurnPedToFaceCoord(playerPed, vehiclePos)
					OpenTrunk(plate, class)
					local timeout = 20
					while true do
						if currentInventory and currentInventory.type == 'trunk' then break end
						if timeout == 0 then
							CloseToVehicle = false
							lastVehicle = nil
							return
						end
						Citizen.Wait(50) timeout = timeout - 1
					end
					SetVehicleDoorOpen(vehicle, open, false, false)
					local animDict = 'anim@heists@prison_heiststation@cop_reactions'
					local anim = 'cop_b_idle'
					RequestAnimDict(animDict)
					while not HasAnimDictLoaded(animDict) do
						Citizen.Wait(100)
					end
					Citizen.Wait(200)
					TaskPlayAnim(playerPed, animDict, anim, 3.0, 3.0, -1, 49, 0, 0, 0, 0)
					Citizen.Wait(100)
					lastVehicle = vehicle
					while true do
						Citizen.Wait(50)
						if CloseToVehicle and invOpen then
							coords = GetEntityCoords(playerPed)
							local vehiclePos = GetWorldPositionOfEntityBone(vehicle, vehBone)
							local pedDistance = #(coords - vehiclePos)
							local isClose = false
							if pedDistance < 2.0 then isClose = true end
							if not DoesEntityExist(vehicle) or not isClose then
								break
							end
							TaskTurnPedToFaceCoord(playerPed, vehiclePos)
						else
							break
						end
					end
					TriggerEvent('hsn-inventory:client:closeInventory', currentInventory)
					return
				end
			else
				TriggerEvent('hsn-inventory:notification','Vehicle is locked',2)
			end
		end
	elseif not isDead and not isCuffed and IsPedInAnyVehicle(playerPed, false) then -- glovebox
		local vehicle = GetVehiclePedIsIn(playerPed, false)
		local plate = GetVehicleNumberPlateText(vehicle)
		local class = GetVehicleClass(vehicle)
		OpenGloveBox(plate, class)
		while true do
			Citizen.Wait(100)
			if not IsPedInAnyVehicle(playerPed, false) then
				TriggerEvent('hsn-inventory:client:closeInventory', currentInventory)
				return
			elseif not invOpen then return end
		end
	end
end, false)

CanOpenInventory = function()
	if playerName and not isBusy and not isShooting and not isDead and not isCuffed and not IsPedDeadOrDying(playerPed, 1) and not IsPauseMenuActive() then return true end
	return false
end
	
RegisterCommand('inv', function()
	if isBusy or isBusy then TriggerEvent('hsn-inventory:notification','You can\'t open your inventory right now',2) return end 
	if CanOpenInventory() then
		TriggerEvent('randPickupAnim')
		TriggerServerEvent('hsn-inventory:server:openInventory',{type = 'drop',id = currentDrop, coords = currentDropCoords })
	end
end, false)
		
RegisterKeyMapping('inv', 'Open player inventory', 'keyboard', Config.InventoryKey)
RegisterKeyMapping('vehinv', 'Open vehicle inventory', 'keyboard', Config.VehicleInventoryKey)

OpenGloveBox = function(gloveboxid, class)
	local slots = {
		[0] = 11, -- compact
		[1] = 11, -- sedan
		[2] = 11, -- suv
		[3] = 11, -- coupe
		[4] = 11, -- muscle
		[5] = 11, -- sports classic
		[6] = 11, -- sports
		[7] = 11, -- super
		[8] = 5, -- motorcycle
		[9] = 11, -- offroad
		[10] = 11, -- industrial
		[11] = 11, -- utility
		[12] = 11, -- van
		[14] = 31, -- boat
		[15] = 31, -- helicopter
		[16] = 51, -- plane
		[17] = 11, -- service
		[18] = 11, -- emergency
		[19] = 11, -- military
		[20] = 11, -- commercial (trucks)
	}
	local storage = slots[class]
	if not storage then return end
	TriggerServerEvent('hsn-inventory:server:openInventory',{type = 'glovebox',id = 'glovebox-'..gloveboxid, slots=storage})
end
OpenTrunk = function(trunkid, class)
	local slots = {
		[0] = 21, -- compact
		[1] = 41, -- sedan
		[2] = 51, -- suv
		[3] = 31, -- coupe
		[4] = 41, -- muscle
		[5] = 31, -- sports classic
		[6] = 31, -- sports
		[7] = 21, -- super
		[8] = 5, -- motorcycle
		[9] = 51, -- offroad
		[10] = 51, -- industrial
		[11] = 41, -- utility
		[12] = 61, -- van
		--[14] = 21, -- boat		no trunk
		--[15] = 21, -- helicopter	no trunk
		--[16] = 21, -- plane		no trunk
		[17] = 41, -- service
		[18] = 41, -- emergency
		[19] = 41, -- military
		[20] = 61, -- commercial
	}
	local storage = slots[class]
	if not storage then return end
	TriggerServerEvent('hsn-inventory:server:openInventory',{type = 'trunk',id = 'trunk-'..trunkid, slots=storage})
end

RegisterNetEvent('hsn-inventory:client:openInventory')
AddEventHandler('hsn-inventory:client:openInventory',function(inventory,other)
	movement = false
	if not playerID then return end
	invOpen = true
	SendNUIMessage({
		message = 'openinventory',
		inventory = inventory,
		slots = Config.PlayerSlot,
		name = playerName..' ['.. playerID ..']',
		maxweight = Config.MaxWeight,
		rightinventory = other
	})
	if not other then movement = true else TriggerServerEvent('hsn-inventory:setcurrentInventory',other) movement = false end
	SetNuiFocusAdvanced(true, true, movement)
	currentInventory = other
end)

function CloseVehicle(veh)
	local animDict = 'anim@heists@fleeca_bank@scope_out@return_case'
	local anim = 'trevor_action'
	RequestAnimDict(animDict)
	while not HasAnimDictLoaded(animDict) do
		Citizen.Wait(100)
	end
	ClearPedTasks(playerPed)
	Citizen.Wait(100)
	TaskPlayAnimAdvanced(playerPed, animDict, anim, GetEntityCoords(playerPed, true), 0, 0, GetEntityHeading(playerPed), 1.0, 1.0, 1000, 49, 0.25, 0, 0)
	Citizen.Wait(1000)
	ClearPedTasks(playerPed)
	SetVehicleDoorShut(veh, open, false)
	CloseToVehicle = false
	lastVehicle = nil
end

RegisterNetEvent('hsn-inventory:client:closeInventory')
AddEventHandler('hsn-inventory:client:closeInventory',function(id)
	SendNUIMessage({
		message = 'close',
	})
	TriggerServerEvent('hsn-inventory:removecurrentInventory',id)
end)

RegisterNetEvent('hsn-inventory:client:refreshInventory')
AddEventHandler('hsn-inventory:client:refreshInventory',function(inventory)
	if not playerID then return end
	SendNUIMessage({
		message = 'refresh',
		inventory = inventory,
		slots = Config.PlayerSlot,
		name = playerName..' ['.. playerID ..']',
		maxweight = Config.MaxWeight
	})
end)

RegisterNUICallback('BuyFromShop', function(data)
    TriggerServerEvent('hsn-inventory:buyItem', data)
end)

RegisterNUICallback('exit',function(data)
	invOpen = false
	TriggerScreenblurFadeOut(0)
	if lastVehicle then
		CloseVehicle(lastVehicle)
	end
	currentInventory = nil
	SetNuiFocusAdvanced(false,false)
	TriggerServerEvent('hsn-inventory:server:saveInventory',data)
	TriggerServerEvent('hsn-inventory:removecurrentInventory',data.invid)
end)

--- thread
Citizen.CreateThread(function()
	while true do
		while not playerID do Citizen.Wait(10) end
		local wait = 1000
		for k,v in pairs(Drops) do
			local distance = #(playerCoords - vector3(v.coords.x,v.coords.y,v.coords.z))
			if (invOpen and distance <= 1.2) or distance <= 10.0 then
				wait = 1
				DrawMarker(2, v.coords.x,v.coords.y,v.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.2, 0.15, 150, 30, 30, 222, false, false, false, true, false, false, false)
				if distance <= 1.2 then
					currentDrop = v.dropid
					currentDropCoords = vector3(v.coords.x,v.coords.y,v.coords.z)
					break
				else
					currentDrop = nil
					currentDropCoords = nil
				end
			end
		end
		if currentInventory and currentInventory.name and string.find(currentInventory.name, 'Player') then
			local str = string.sub(currentInventory.name, 7)
			local id = GetPlayerFromServerId(tonumber(str))
			local ped = GetPlayerPed(id)
			local pedCoords = GetEntityCoords(ped)
			local dist = #(playerCoords - pedCoords)
			if not id or dist > 1.5 or not CanOpenTarget(ped) then
				TriggerEvent('hsn-inventory:client:closeInventory', currentInventory)
				TriggerEvent('hsn-inventory:notification','No longer able to access this inventory',2)
			end
		elseif not lastVehicle and currentInventory and currentInventory.coords then
			local dist = #(playerCoords - currentInventory.coords)
			if dist > 2 or CanOpenTarget(playerPed) then
				TriggerEvent('hsn-inventory:client:closeInventory', currentInventory)
				TriggerEvent('hsn-inventory:notification','No longer able to access this inventory',2)
			end
		end
		Citizen.Wait(wait)
	end
end)

RegisterNetEvent('hsn-inventory:client:addItemNotify')
AddEventHandler('hsn-inventory:client:addItemNotify',function(item,text)
	SendNUIMessage({
		message = 'notify',
		item = item,
		text = text
	})
	TriggerServerEvent('hsn-inventory:server:refreshInventory')
end)


DrawText3D = function(coords, text)
	SetDrawOrigin(coords)
	SetTextScale(0.35, 0.35)
	SetTextFont(4)
	SetTextEntry('STRING')
	SetTextCentre(1)
	AddTextComponentString(text)
	DrawText(0.0, 0.0)
	DrawRect(0.0, 0.0125, 0.015 + text:gsub('~.-~', ''):len() / 370, 0.03, 45, 45, 45, 150)
	ClearDrawOrigin()
end

Citizen.CreateThread(function()
	while true do
		while not playerID do Citizen.Wait(10) end
		local sleepThread = 1000
		if CanOpenInventory() then
			for i = 1, #Config.Shops do
				local text = Config.Shops[i].name
				local distance = #(playerCoords - Config.Shops[i].coords)

				if distance <= 5.5 and (not Config.Shops[i].job or Config.Shops[i].job == PlayerData.job.name) then
					sleepThread = 5
					DrawMarker(2, Config.Shops[i].coords.x,Config.Shops[i].coords.y,Config.Shops[i].coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.15, 0.2, 30, 150, 30, 100, false, false, false, true, false, false, false)
					if not invOpen then
						if distance <= 1.5 then
							text = '[~g~E~s~] ' .. Config.Shops[i].name

							if IsControlJustPressed(1,38) then
								OpenShop(Config.Shops[i], i)
							end
						end

						DrawText3D(Config.Shops[i].coords, text)
					end
				end
			end

			for i = 1, #Config.Stashes do
				local text = Config.Stashes[i].name
				local distance = #(playerCoords - Config.Stashes[i].coords)

				if distance <= 5.5 and (not Config.Stashes[i].job or Config.Stashes[i].job == PlayerData.job.name) then
					sleepThread = 5
					DrawMarker(2, Config.Stashes[i].coords.x,Config.Stashes[i].coords.y,Config.Stashes[i].coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.15, 0.2, 30, 30, 150, 100, false, false, false, true, false, false, false)
					
					if not invOpen then
						if distance <= 1.5 then
							text = '[~g~E~s~] ' .. Config.Stashes[i].name

							if IsControlJustPressed(1,38) then
								OpenStash(Config.Stashes[i])
							end
						end   

						DrawText3D(Config.Stashes[i].coords, text)
					end
				end
			end

			if Config.WeaponsLicense then
				local coords = vector3(12.42198, -1105.82, 29.7854)
				local text = "Weapons License"
				local distance = #(playerCoords - coords)
				local license = 'weapon'

				if distance <= 5.5 then
					sleepThread = 5
					DrawMarker(2, coords, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.15, 0.2, 30, 150, 30, 100, false, false, false, true, false, false, false)
					
					if not invOpen then
						if distance <= 1.5 then
							text = '[~g~E~s~] Purchase license'

							if IsControlJustPressed(1,38) then
								ESX.TriggerServerCallback('esx_license:checkLicense', function(hasWeaponLicense)
									if hasWeaponLicense then
										TriggerEvent('hsn-inventory:notification',"You already have a weapon's license")
									else
										ESX.TriggerServerCallback('hsn-inventory:buyLicense', function(bought)
											if bought then
												TriggerEvent('hsn-inventory:notification',"You have purchased a weapon's license",1)
											else
												TriggerEvent('hsn-inventory:notification', "You can not afford a weapon's license")
											end
										end, license)
									end
									Citizen.Wait(1000)
								end, playerID, license)
							end
						end   

						DrawText3D(coords, text)
					end
				end
			end

		else sleepThread = 50 end
		Citizen.Wait(sleepThread)
	end
end)

Citizen.CreateThread(function()
	while not playerID do Citizen.Wait(10) end
	for k,v in pairs(Config.Shops) do
		if (not Config.Shops[k].job or Config.Shops[k].job == PlayerData.job.name) then
			local blip = AddBlipForCoord(v.coords.x, v.coords.y, v.coords.z)
			SetBlipSprite(blip, v.blip.id or 1)
			SetBlipDisplay(blip, 4)
			SetBlipScale(blip, v.blip.scale or 0.5)
			SetBlipColour(blip, v.blip.color or 1)
			SetBlipAsShortRange(blip, true)
			BeginTextCommandSetBlipName('STRING')
			AddTextComponentString(v.blip.name or 'Shop')
			EndTextCommandSetBlipName(blip)
		end
	end
end)

OpenShop = function(id, index)
	if CanOpenTarget(playerPed) then return end
	TriggerServerEvent('hsn-inventory:server:openInventory',{type = 'shop',id = id, index = index})
end

OpenStash = function(id)
	if CanOpenTarget(playerPed) then return end
	TriggerServerEvent('hsn-inventory:server:OpenStash', {id = id, slots = id.slots, type = 'stash'})
end

RegisterNetEvent('hsn-inventory:Client:addnewDrop')
AddEventHandler('hsn-inventory:Client:addnewDrop',function(coords, drop, src)
	if not oneSync then -- Receive coords as an entity if not running OneSync
		local entity = GetPlayerPed(GetPlayerFromServerId(coords))
		local pos = GetEntityCoords(entity)
		local offset = GetOffsetFromEntityInWorldCoords(entity, 0, 0.5, 0)
		coords = offset
	end
	Drops[drop] = {
		dropid = drop,
		coords = {
			x = coords.x,
			y = coords.y,
			z = coords.z - 0.3,
		},
	}
	Citizen.Wait(0)
	if src == playerID then
		currentInventory = {type = 'drop',id = drop, coords = coords }
		TriggerServerEvent('hsn-inventory:server:openInventory',{type = 'drop',id = drop, coords = coords })
	end
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
	TaskPlayAnim(playerPed,'pickup_object', 'putdown_low',5.0, 1.5, 1.0, 48, 0.0, 0, 0, 0)
	Wait(1000)
	ClearPedSecondaryTask(playerPed)
end)


RegisterNetEvent('hsn-inventory:client:removeDrop')
AddEventHandler('hsn-inventory:client:removeDrop',function(dropid)
	Drops[dropid] = nil
	currentDrop = nil
	currentDropCoords = nil
end)

RegisterNUICallback('UseItem', function(data, cb)
	if data.inv ~= 'Playerinv' then
		return
	end
	TriggerServerEvent('hsn-inventory:server:useItem',data.item)
end)

RegisterNUICallback('saveinventorydata',function(data)
	TriggerServerEvent('hsn-inventory:server:saveInventoryData',data)
end)

RegisterNUICallback('notification', function(data)
	TriggerEvent('hsn-inventory:notification',data.message,data.type)
end)

RegisterNetEvent('hsn-inventory:weapondraw')
AddEventHandler('hsn-inventory:weapondraw', function(item)
	ClearPedSecondaryTask(playerPed)
	if PlayerData.job.name == 'police' then
		loadAnimDict('reaction@intimidation@cop@unarmed')
		TaskPlayAnimAdvanced(playerPed, 'reaction@intimidation@cop@unarmed', 'intro', GetEntityCoords(playerPed, true), 0, 0, GetEntityHeading(playerPed), 8.0, 3.0, -1, 50, 1, 0, 0)
	else
		loadAnimDict('reaction@intimidation@1h')
		TaskPlayAnimAdvanced(playerPed, 'reaction@intimidation@1h', 'intro', GetEntityCoords(playerPed, true), 0, 0, GetEntityHeading(playerPed), 8.0, 3.0, -1, 50, 0, 0, 0)
		Citizen.Wait(800)
	end
	if currentWeapon then SetPedAmmo(playerPed, currentWeapon.hash, 0)
		SetCurrentPedWeapon(playerPed, `WEAPON_UNARMED`, true)
		Citizen.Wait(0)
		RemoveWeaponFromPed(playerPed, currentWeapon.hash)
	end
	Citizen.Wait(800)
	isBusy = false
end)

RegisterNetEvent('hsn-inventory:weaponaway')
AddEventHandler('hsn-inventory:weaponaway', function()
	local hash = currentWeapon.hash
	ClearPedSecondaryTask(playerPed)
	loadAnimDict('reaction@intimidation@1h')
	TaskPlayAnimAdvanced(playerPed, 'reaction@intimidation@1h', 'outro', GetEntityCoords(playerPed, true), 0, 0, GetEntityHeading(playerPed), 8.0, 3.0, -1, 50, 0, 0, 0)
	SetPedAmmo(playerPed, hash, 0)
	Citizen.Wait(1600)
	SetCurrentPedWeapon(playerPed, `WEAPON_UNARMED`, true)
	Citizen.Wait(0)
	RemoveWeaponFromPed(playerPed, hash)
	SetPedCurrentWeaponVisible(playerPed, false, false, false, false)
	ClearPedSecondaryTask(playerPed)
	if IsPedUsingActionMode(playerPed) then
		SetPedUsingActionMode(playerPed, -1, -1, 1)
	end
	isBusy = false
end)

RegisterNetEvent('hsn-inventory:client:updateWeapon')
AddEventHandler('hsn-inventory:client:updateWeapon',function(data)
	if currentWeapon then currentWeapon.item.metadata = data end
end)

RegisterNetEvent('hsn-inventory:client:weapon')
AddEventHandler('hsn-inventory:client:weapon',function(item)
	if isBusy then return end
	isBusy = true
	if currentWeapon then TriggerServerEvent('hsn-inventory:server:updateWeapon', currentWeapon.item) end
	TriggerEvent('hsn-inventory:client:closeInventory', currentInventory)
	local newWeapon = item.metadata.serial
	local found, wepHash = GetCurrentPedWeapon(playerPed, true)
	if wepHash == -1569615261 then currentWeapon = nil end
	wepHash = GetHashKey(item.name)
	if currentWeapon and currentWeapon.item.metadata.serial == newWeapon then
		if not currentWeapon.item.name == 'WEAPON_FIREEXTINGUISHER' or currentWeapon.item.name == 'WEAPON_PETROLCAN' then
			currentWeapon.item.metadata.ammo = GetAmmoInPedWeapon(playerPed, currentWeapon.hash)
		end
		TriggerEvent('hsn-inventory:weaponaway')
		Citizen.Wait(1600)
		currentWeapon = nil
		TriggerEvent('hsn-inventory:client:addItemNotify',item,'Holstered')
	else
		TriggerEvent('hsn-inventory:weapondraw',item)
		GiveWeaponToPed(playerPed, wepHash, 0, true, false)
		if PlayerData.job.name == 'police' then Citizen.Wait(800) else Citizen.Wait(1600) end
		currentWeapon = {}
		currentWeapon.item = item
		currentWeapon.hash = wepHash
		currentWeapon.ammo = GetAmmoType(currentWeapon.item.name)
		if item.metadata.throwable then item.metadata.ammo = 1 end
		SetCurrentPedWeapon(playerPed, wepHash, true)
		SetPedCurrentWeaponVisible(playerPed, true, false, false, false)
		if item.metadata.weapontint then SetPedWeaponTintIndex(playerPed, item.name, item.metadata.weapontint) end
		if item.metadata.components then
			for k,v in pairs(item.metadata.components) do
				local componentHash = ESX.GetWeaponComponent(item.name, v).hash
				if componentHash then GiveWeaponComponentToPed(playerPed, wepHash, componentHash) end
			end
		end
		TriggerEvent('hsn-inventory:client:addItemNotify',item,'Equipped')
		SetAmmoInClip(playerPed, currentWeapon.hash, item.metadata.ammo)
		if currentWeapon.item.name == 'WEAPON_FIREEXTINGUISHER' or currentWeapon.item.name == 'WEAPON_PETROLCAN' then SetAmmoInClip(playerPed, currentWeapon.hash, 10000) end
	end
	TriggerEvent('hsn-inventory:currentWeapon', currentWeapon)
	Citizen.Wait(100)
	ClearPedSecondaryTask(playerPed)
	isBusy = false
end)

RegisterNetEvent('hsn-inventory:addAmmo')
AddEventHandler('hsn-inventory:addAmmo',function(ammo)
	if not currentWeapon then return end
	if currentWeapon.ammo ~= ammo.name then
		TriggerEvent('hsn-inventory:notification',('You can\'t load the %s with %s ammo'):format(currentWeapon.item.label, ammo.label) )
		return
	end
	ammo.count = ESX.Round(ammo.count)
	if currentWeapon and ammo.count > 0 then
		local weapon = currentWeapon.hash
		local maxAmmo = GetWeaponClipSize(weapon)
		local curAmmo = GetAmmoInPedWeapon(playerPed, weapon)
		if curAmmo > maxAmmo then
			SetPedAmmo(playerPed, weapon, maxAmmo)
		elseif curAmmo == maxAmmo then
			return
		else
			local newAmmo = 0
			if curAmmo < maxAmmo then missingAmmo = maxAmmo - curAmmo end
			if missingAmmo > ammo.count then
				newAmmo = ammo.count + curAmmo removeAmmo = ammo.count - curAmmo
			else
				newAmmo = tonumber(maxAmmo) removeAmmo = missingAmmo
			end
			if newAmmo < 0 then newAmmo = 0 end
			SetPedAmmo(playerPed, weapon, newAmmo)
			MakePedReload(playerPed)
			TriggerServerEvent('hsn-inventory:server:addweaponAmmo',currentWeapon.item,currentWeapon.ammo,removeAmmo,newAmmo)
		end
	end
end)


RegisterNetEvent('hsn-inventory:client:checkweapon')
AddEventHandler('hsn-inventory:client:checkweapon',function(item)
	if currentWeapon and currentWeapon.item.metadata.serial == item.metadata.serial then
		currentWeapon.item.metadata.ammo = GetAmmoInPedWeapon(playerPed, currentWeapon.hash)
		RemoveWeaponFromPed(playerPed, GetHashKey(item.name))
		SetCurrentPedWeapon(playerPed, `WEAPON_UNARMED`, true)
		TriggerServerEvent('hsn-inventory:server:updateWeapon', currentWeapon.item)
		TriggerEvent('hsn-inventory:currentWeapon', nil)
	end
end)

RegisterCommand('steal',function()
	local ped = playerPed
	if not IsPedInAnyVehicle(playerPed, true) and not invOpen and CanOpenInventory() then	 
		openTargetInventory()
	end
end)

function CanOpenTarget(searchPlayerPed)
	if IsPedDeadOrDying(searchPlayerPed, 1)
	or IsEntityPlayingAnim(searchPlayerPed, 'random@mugging3', 'handsup_standing_base', 3)
	or IsEntityPlayingAnim(searchPlayerPed, 'missminuteman_1ig_2', 'handsup_base', 3)
	or IsEntityPlayingAnim(searchPlayerPed, 'dead', 'dead_a', 3)
	or IsEntityPlayingAnim(searchPlayerPed, 'mp_arresting', 'idle', 3)
	then return true
	else return false end
end

function openTargetInventory()
	local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
	if closestPlayer ~= -1 and closestDistance <= 1.0 then
		local searchPlayerPed = GetPlayerPed(closestPlayer)
		if CanOpenTarget(searchPlayerPed) then
			TriggerServerEvent('hsn-inventory:server:openTargetInventory', GetPlayerServerId(closestPlayer))
		else
			TriggerEvent('hsn-inventory:notification','You can not open this inventory')
		end
	else
		TriggerEvent('hsn-inventory:notification','There is nobody nearby')
	end
end

local nui_focus = {false, false}
function SetNuiFocusAdvanced(hasFocus, hasCursor, allowMovement)
	SetNuiFocus(hasFocus, hasCursor)
	SetNuiFocusKeepInput(hasFocus)
	nui_focus = {hasFocus, hasCursor}
	TriggerEvent('nui:focus', hasFocus, hasCursor)

	if nui_focus[1] then
		if Config.EnableBlur then TriggerScreenblurFadeIn(0) end
		Citizen.CreateThread(function()
			local ticks = 0
			while true do
				Citizen.Wait(2)
				DisableAllControlActions(0)
				if not nui_focus[2] then
					EnableControlAction(0, 1, true)
					EnableControlAction(0, 2, true)
				end
				EnableControlAction(0, 249, true) -- N for PTT
				EnableControlAction(0, 20, true) -- Z for proximity
				if allowMovement and not currentInventory then
					EnableControlAction(0, 30, true) -- movement
					EnableControlAction(0, 31, true) -- movement
				end
				if not nui_focus[1] then
					ticks = ticks + 1
					if (IsDisabledControlJustReleased(0, 200, true) or ticks > 20) then
						invOpen = false
						currentInventory = nil
						if Config.EnableBlur then TriggerScreenblurFadeOut(0) end
						break
					end
				end
			end
		end)
	end
end

RegisterNetEvent('hsn-inventory:notification')
AddEventHandler('hsn-inventory:notification',function(message, mtype)
	if message then
		if mtype == 1 then mtype = { ['background-color'] = 'rgba(55,55,175)', ['color'] = 'white' }
		elseif not mtype or mtype == 2 then mtype = { ['background-color'] = 'rgba(175,55,55)', ['color'] = 'white' }
		end
		TriggerEvent('mythic_notify:client:SendAlert', {type = 'inform', text = message, length = 2500,style = mtype})
	end
end)

RegisterCommand('-nui', function()
		TriggerEvent('hsn-inventory:client:closeInventory', currentInventory)
end, false)

AddEventHandler('onResourceStop', function(resourceName)
	if (GetCurrentResourceName() == resourceName) then
		TriggerScreenblurFadeOut(0)
		SetNuiFocusAdvanced(false, false)
		clearWeapons()
	end
end)

RegisterNUICallback('devtool', function()
	TriggerServerEvent('hsn-inventory:devtool')
end)

AddEventHandler('hsn-inventory:busy',function(busy)
	isBusy = busy
	if isBusy and invOpen then TriggerEvent('hsn-inventory:client:closeInventory', currentInventory) end
end)

RegisterNetEvent('hsn-inventory:useItem')
AddEventHandler('hsn-inventory:useItem',function(item)
	if not CanOpenInventory() then return end
	ESX.TriggerServerCallback('hsn-inventory:getItem',function(xItem)
		if xItem then
			local data = Config.ItemList[xItem.name]
			if not data or not next(data) then return end
			if xItem.closeonuse then TriggerEvent('hsn-inventory:client:closeInventory', currentInventory) end
			if not data.animDict then data.animDict = 'pickup_object' end
			if not data.anim then data.anim = 'putdown_low' end
			if not data.flags then data.flags = 48 end

			-- Trigger effects before the progress bar
			if data.component then
				if not currentWeapon then return end
				local result, esxWeapon = ESX.GetWeapon(currentWeapon.item.name)
				
				for k,v in ipairs(esxWeapon.components) do
					for k2, v2 in pairs(data.component) do
						if v.hash == v2 then
							component = {name = v.name, hash = v2}
							break
						end
					end
				end
				if not component then TriggerEvent('hsn-inventory:notification','This weapon is incompatible with '..xItem.label,2) return end
				if HasPedGotWeaponComponent(playerPed, currentWeapon.hash, component.hash) then
					TriggerEvent('hsn-inventory:notification','This weapon already has a '..xItem.label,2) return
				end
			end

			if xItem.name == 'lockpick' then
				TriggerEvent('esx_lockpick:onUse')
				TriggerEvent('lockpick:vehicleUse')
			end

			------------------------------------------------------------------------------------------------
			if data.useTime and data.useTime >= 0 then
				isBusy = true
				exports['mythic_progbar']:Progress({
					name = 'useitem',
					duration = data.useTime,
					label = 'Using '..xItem.label,
					useWhileDead = false,
					canCancel = false,
					controlDisables = { disableMovement = data.disableMove, disableCarMovement = false, disableMouse = false, disableCombat = true },
					animation = { animDict = data.animDict, anim = data.anim, flags = data.flags },
					prop = { model = data.model, coords = data.coords, rotation = data.rotation }
				}, function() isBusy = false end)
			else isBusy = false end
			while isBusy do Citizen.Wait(10) end

			if data.hunger then
				if data.hunger > 0 then TriggerEvent('esx_status:add', 'hunger', data.hunger)
				else TriggerEvent('esx_status:remove', 'hunger', data.hunger) end
			end
			if data.thirst then
				if data.thirst > 0 then TriggerEvent('esx_status:add', 'thirst', data.thirst)
				else TriggerEvent('esx_status:remove', 'thirst', data.thirst) end
			end
			if data.stress then
				if data.stress > 0 then TriggerEvent('esx_status:add', 'stress', data.stress)
				else TriggerEvent('esx_status:remove', 'stress', data.stress) end
			end
			if data.drunk then
				if data.drunk > 0 then TriggerEvent('esx_status:add', 'drunk', data.drunk)
				else TriggerEvent('esx_status:remove', 'drunk', data.drunk) end
			end
			if data.consume then TriggerServerEvent('hsn-inventory:client:removeItem', xItem.name, data.consume, xItem.metadata) end
			isBusy = false
			------------------------------------------------------------------------------------------------

				if data.component then
					GiveWeaponComponentToPed(playerPed, currentWeapon.item.name, component.hash)
					table.insert(currentWeapon.item.metadata.components, component.name)
					TriggerServerEvent('hsn-inventory:server:updateWeapon', currentWeapon.item, component.name)
				end
				

				if xItem.name == 'bandage' then
					local maxHealth = 200
					local health = GetEntityHealth(playerPed)
					local newHealth = math.min(maxHealth, math.floor(health + maxHealth / 16))
					SetEntityHealth(playerPed, newHealth)
					TriggerEvent('mythic_hospital:client:FieldTreatBleed')
				end


			------------------------------------------------------------------------------------------------
		end
	end, item.name, item.metadata)
end)
