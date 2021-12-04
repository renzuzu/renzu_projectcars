spawnprojectcars = {}
spawnprojectshell = {}
ESX = nil
QBCore = nil
fetchdone = false
PlayerData = {}
playerLoaded = false
currentobject = nil
Useitem = {}
ChopPart = {}
success = false
refresh = false
blips = {}
inzone = false
chop = {}
choppedvehicles = {}
chopping = false
spraying = false
donechop = true
inwarehouse = nil
Citizen.CreateThread(function()
	Framework()
	SetJob()
	Playerloaded()
	while GlobalState.ProjectCars == nil do Wait(1000) end
	while true do
		while spraying do Wait(100) end
		SpawnProjectCars(GlobalState.ProjectCars)
		Wait(1000)
	end
end)

local junker = {}
CreateEntity = function(hash, coords, id)
	if junker[id] then return end
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(5)
    end
    local x,y,z = table.unpack(coords)
    ped = CreatePed(4, hash, x,y,z, false, false)
    Wait(10)
    NetworkFadeInEntity(ped,true)
    TaskTurnPedToFaceEntity(ped,PlayerPedId(),-1)
    SetEntityAsMissionEntity(ped, true, true)
    --FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
	SetEntityInvincible(ped, true)
    ResetEntityAlpha(ped)
	junker[id] =ped
    return ped
end

VehicleBlip = function(data)
	if blips[data.plate] == nil then
		local blip = AddBlipForCoord(data.coord.x, data.coord.y, data.coord.z)
		SetBlipSprite (blip, 562)
		SetBlipDisplay(blip, 4)
		SetBlipScale  (blip, 0.3)
		SetBlipColour (blip, 81)
		SetBlipAsShortRange(blip, true)
		BeginTextCommandSetBlipName('STRING')
		AddTextComponentSubstringPlayerName("Project Car : "..data.model.." - "..data.plate)
		EndTextCommandSetBlipName(blip)
		blips[data.plate] = blip
	end
end

CreateBlips = function()
	for k,v in pairs(Config.JunkShop) do
        local blip = AddBlipForCoord(v.coord.x, v.coord.y, v.coord.z)
        SetBlipSprite (blip, v.blip)
        SetBlipDisplay(blip, 4)
        SetBlipScale  (blip, 0.8)
        SetBlipColour (blip, 81)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(""..v.label.."")
        EndTextCommandSetBlipName(blip)
    end
	if Config.EnableZoneOnly then
		for k,v in pairs(Config.BuildZone) do
			local blip = AddBlipForCoord(v.coord.x, v.coord.y, v.coord.z)
			SetBlipSprite (blip, v.blip)
			SetBlipDisplay(blip, 4)
			SetBlipScale  (blip, 0.8)
			SetBlipColour (blip, 81)
			SetBlipAsShortRange(blip, true)
			BeginTextCommandSetBlipName('STRING')
			AddTextComponentSubstringPlayerName(""..v.label.."")
			EndTextCommandSetBlipName(blip)
		end
	end
	if Config.EnableChopShop then
		for k,v in pairs(Config.ChopShop) do
			local blip = AddBlipForCoord(v.coord.x, v.coord.y, v.coord.z)
			SetBlipSprite (blip, v.blip)
			SetBlipDisplay(blip, 4)
			SetBlipScale  (blip, 0.8)
			SetBlipColour (blip, 81)
			SetBlipAsShortRange(blip, true)
			BeginTextCommandSetBlipName('STRING')
			AddTextComponentSubstringPlayerName(""..v.label.."")
			EndTextCommandSetBlipName(blip)
		end
	end
	if Config.EnableBuilderJob then
		for k,v in pairs(Config.BuilderJobs) do
			local blip = AddBlipForCoord(v.coord.x, v.coord.y, v.coord.z)
			SetBlipSprite (blip, v.blip)
			SetBlipDisplay(blip, 4)
			SetBlipScale  (blip, 0.8)
			SetBlipColour (blip, 81)
			SetBlipAsShortRange(blip, true)
			BeginTextCommandSetBlipName('STRING')
			AddTextComponentSubstringPlayerName(""..v.label.."")
			EndTextCommandSetBlipName(blip)
		end
	end
end

GetModelName = function(vehicle)
	local modelhash = GetEntityModel(vehicle)
	local name = nil
	for k,v in pairs(Config.Vehicles) do
		local model = GetHashKey(k)
		if IsModelInCdimage(model) and model == modelhash then
			name = k
			break
		end
	end
	return name or false
end

RegisterNetEvent('renzu_projectcars:Notify')
AddEventHandler('renzu_projectcars:Notify', function(msg)
	Notify(msg)
end)

Citizen.CreateThread(function()
	if LocalPlayer.state ~= nil then
		LocalPlayer.state:set('buildzone',false,true)
	else
		print("ONE SYNC ENABLE IS REQUIRED")
	end
	while PlayerData.identifier == nil do Wait(100) end
	CreateBlips()
	while true do
		local ped = PlayerPedId()
		local coord = GetEntityCoords(ped)
		for k,v in pairs(Config.JunkShop) do
			local dis = #(coord - v.coord)
			if Config.jobonly and PlayerData.job and Config.carbuilderjob == PlayerData.job.name and dis < 45 or not Config.jobonly and dis < 45 then
				CreateEntity(v.model, v.coord,k)
				if dis < 55 and not refresh then
					while dis < 55 and not refresh do
						Wait(1)
						if dis < 4 then
							local table = {
								['key'] = 'E', -- key
								['event'] = v.event,
								['title'] = 'Press [E] Open '..v.label,
								['server_event'] = false, -- server event or client
								['unpack_arg'] = false, -- send args as unpack 1,2,3,4 order
								['fa'] = '<i class="fal fa-store"></i>',
								['custom_arg'] = Config.MetaInventory and {Config.Vehicles} or nil, -- example: {1,2,3,4}
							}
							TriggerEvent('renzu_popui:drawtextuiwithinput',table)
							Wait(500)
							while dis < 55 and not refresh do
								Wait(100)
								coord = GetEntityCoords(ped)
								dis = #(coord - v.coord)
							end
							break
						end
						DrawMarker(21, v.coord.x,v.coord.y,v.coord.z-0.5, 0, 0, 0, 0, 0, 0, 0.7, 0.7, 0.7, 200, 255, 255, 255, 0, 0, 1, 1, 0, 0, 0)
						coord = GetEntityCoords(ped)
						dis = #(coord - v.coord)
					end
					TriggerEvent('renzu_popui:closeui')
				end
			end
		end

		-- GARAGE
		local garage <const> = Config.Garage
		for k2,v2 in pairs(garage) do
			for k,v in pairs(v2) do
				local dis = 50
				local showdist = 15
				local coordtemp = nil
				if k == 'spawn' or k == 'exit' then
					local vec = vec3(0.1,0.1,0.1)
					if not GlobalState.GarageInside[PlayerData.identifier] and k == 'exit' then
						vec = vec3(0.0,100.0,-1000.0)
					end
					coordtemp = vector3(v.coord.x,v.coord.y,v.coord.z) + vec
					dis = #(coord - coordtemp)
					showdist = 1
				else
					coordtemp = v.coord
					dis = #(coord - coordtemp)
				end
				if dis < 45 then
					if k == 'buy' then
						CreateEntity(v.model, coordtemp,k)
					end
					if dis < showdist and not refresh then
						while dis < showdist and not refresh do
							Wait(1)
							if dis < 4 then
								local table = {
									['key'] = 'E', -- key
									['event'] = 'renzu_projectcars:garage',
									['title'] = 'Press [E] '..v.label,
									['server_event'] = true, -- server event or client
									['unpack_arg'] = true, -- send args as unpack 1,2,3,4 order
									['fa'] = '<i class="fal fa-garage"></i>',
									['custom_arg'] = {k,v2}, -- example: {1,2,3,4}
								}
								TriggerEvent('renzu_popui:drawtextuiwithinput',table)
								Wait(500)
								while dis < 4 and not refresh do
									Wait(100)
									coord = GetEntityCoords(ped)
									dis = #(coord - coordtemp)
								end
								TriggerEvent('renzu_popui:closeui')
								break
							end
							DrawMarker(21, coordtemp.x,coordtemp.y,coordtemp.z, 0, 0, 0, 0, 0, 0, 0.7, 0.7, 0.7, 200, 255, 255, 255, 0, 0, 1, 1, 0, 0, 0)
							coord = GetEntityCoords(ped)
							dis = #(coord - coordtemp)
						end
						TriggerEvent('renzu_popui:closeui')
					end
				end
			end
		end

		-- ZONE
		if Config.EnableZoneOnly then
			for k,v in pairs(Config.BuildZone) do
				if #(coord - v.coord) < v.radius then
					LocalPlayer.state:set('buildzone',true,true)
					while #(GetEntityCoords(ped) - v.coord) < v.radius do Wait(1000) end
					LocalPlayer.state:set('buildzone',false,true)
				end
			end
		end

		-- Builder Job
		if Config.EnableBuilderJob then
			for k,v in pairs(Config.BuilderJobs) do
				local loc = v.coord
				local name = 'enter'
				dis = #(coord - loc)
				if dis > 300 then
					loc = v.exit
					dis = #(coord - loc)
					name = 'exit'
				end
				if k == PlayerData.job.name and dis < 55 and not refresh then
					while dis < 55 and not refresh and k == PlayerData.job.name do
						Wait(1)
						if dis < 4 then
							local table = {
								['key'] = 'E', -- key
								['event'] = v.event,
								['title'] = 'Press [E] '..name:upper()..' '..v.label,
								['server_event'] = false, -- server event or client
								['unpack_arg'] = true, -- send args as unpack 1,2,3,4 order
								['fa'] = '<i class="fal fa-garage"></i>',
								['custom_arg'] = {name,v,k}, -- example: {1,2,3,4}
							}
							TriggerEvent('renzu_popui:drawtextuiwithinput',table)
							Wait(500)
							while k == PlayerData.job.name and dis < 4 and not refresh do
								Wait(100)
								coord = GetEntityCoords(ped)
								dis = #(coord - loc)
							end
							TriggerEvent('renzu_popui:closeui')
							break
						end
						DrawMarker(21, loc.x,loc.y,loc.z, 0, 0, 0, 0, 0, 0, 0.7, 0.7, 0.7, 200, 255, 255, 255, 0, 0, 1, 1, 0, 0, 0)
						coord = GetEntityCoords(ped)
						dis = #(coord - loc)
					end
					TriggerEvent('renzu_popui:closeui')
				end
			end
		end

		-- Chop Shop
		if Config.EnableChopShop then
			for k,v in pairs(Config.ChopShop) do
				if #(coord - v.coord) < 100 then
					local vehicle = getveh()
					local dis = #(coord - GetEntityCoords(vehicle))
					if dis < 5 then
						chop = GlobalState.ChopVehicles
						plate = GetVehicleNumberPlateText(vehicle)
						plate = string.gsub(tostring(plate), '^%s*(.-)%s*$', '%1')
						if IsPedInAnyVehicle(PlayerPedId()) and GetModelName(vehicle) then
							local t = {
								['key'] = 'F', -- key
								['event'] = 'renzu_projectcars:dummy',
								['title'] = 'Get out the vehicle to Chop this',
								['invehicle_title'] = 'Get out the vehicle to Chop this',
								['server_event'] = false, -- server event or client
								['unpack_arg'] = false, -- send args as unpack 1,2,3,4 order
								['fa'] = '<i class="fal fa-car-crash"></i>',
								['custom_arg'] = {}, -- example: {1,2,3,4}
							}
							TriggerEvent('renzu_popui:drawtextuiwithinput',t)
							while not refresh do Wait(200) end
						end
						if not IsPedInAnyVehicle(PlayerPedId()) and dis < 5 and chop[plate] == nil and GetModelName(vehicle) and GetVehiclePedIsIn(PlayerPedId(),true) == vehicle  then
							local wheels = {}
							local brakes = {}
							--
							for tireid = 0, GetVehicleNumberOfWheels(vehicle) -1 do
								wheels[tireid] = 1
								brakes[tireid] = 1
							end
							local data = {
								plate = plate,
								doors = GetNumberOfVehicleDoors(vehicle),
								seat = GetNumSeat(vehicle),
								trunk = GetEntityBoneIndexByName(vehicle,'boot') ~= -1 and 1 or 0,
								exhaust = GetEntityBoneIndexByName(vehicle,'exhaust') ~= -1 and 1 or 0,
								bonnet = GetEntityBoneIndexByName(vehicle,'bonnet') ~= -1 and 1 or 0,
								wheel = wheels,
								brake = brakes,
								model = GetModelName(vehicle),
								coord = GetEntityCoords(vehicle),
								heading = GetEntityHeading(vehicle),
								frontman = PlayerData.identifier,
								net = VehToNet(vehicle)
							}
							local table = {
								['key'] = 'E', -- key
								['event'] = 'renzu_projectcars:registerchop',
								['title'] = 'Press [E] Register Chop Vehicle ['..plate..']',
								['invehicle_title'] = 'Press [E] Register Chop Vehicle ['..plate..']',
								['server_event'] = true, -- server event or client
								['unpack_arg'] = false, -- send args as unpack 1,2,3,4 order
								['fa'] = '<i class="fal fa-car-crash"></i>',
								['custom_arg'] = {data}, -- example: {1,2,3,4}
							}
							TriggerEvent('renzu_popui:drawtextuiwithinput',table)
							while dis < 5 and not refresh and GlobalState.ChopVehicles[data.plate] == nil do
								Wait(500)
								coord = GetEntityCoords(ped)
								dis = #(coord - v.coord)
							end
							TriggerEvent('renzu_popui:closeui')
							Wait(1000)
						end
						while not IsPedStopped(PlayerPedId()) do Wait(200) TriggerEvent('renzu_popui:closeui') end
						if not IsPedInAnyVehicle(PlayerPedId()) and GlobalState.ChopVehicles[plate] then
							local ent = Entity(vehicle).state
							local choppedvehicles = ent.chopped
							ent:set('frontman',GlobalState.ChopVehicles[plate].frontman,true)
							if choppedvehicles == nil then choppedvehicles= {} end
							if IsPedStopped(PlayerPedId()) then
								SendNUIMessage({show = true,type = "project_status", status = GlobalState.ChopVehicles[plate].status, info = Config.Vehicles[GlobalState.ChopVehicles[plate].model]})
							end
							chop_parts = {}
							if choppedvehicles['bonnet'] then
								chop_parts['engine'] = GetEntityBoneIndexByName(vehicle,'engine') ~= -1 and GetEntityBoneIndexByName(vehicle,'engine') or GetEntityBoneIndexByName(vehicle,'boot')
								chop_parts['transmition'] = GetEntityBoneIndexByName(vehicle,'engine') ~= -1 and GetEntityBoneIndexByName(vehicle,'engine') or GetEntityBoneIndexByName(vehicle,'boot')
							end
							chop_parts['trunk'] = GetEntityBoneIndexByName(vehicle,'boot')
							chop_parts['exhaust'] = GetEntityBoneIndexByName(vehicle,'exhaust')
							chop_parts['bonnet'] = GetEntityBoneIndexByName(vehicle,'bonnet')
							chop_parts['wheel_lf'] = GetEntityBoneIndexByName(vehicle,'wheel_lf')
							chop_parts['wheel_rf'] = GetEntityBoneIndexByName(vehicle,'wheel_rf')
							chop_parts['wheel_lr'] = GetEntityBoneIndexByName(vehicle,'wheel_lr')
							chop_parts['wheel_rr'] = GetEntityBoneIndexByName(vehicle,'wheel_rr')
							chop_parts['brake_0'] = GetEntityBoneIndexByName(vehicle,'wheel_lf')
							chop_parts['brake_1'] = GetEntityBoneIndexByName(vehicle,'wheel_rf')
							chop_parts['brake_2'] = GetEntityBoneIndexByName(vehicle,'wheel_lr')
							chop_parts['brake_3'] = GetEntityBoneIndexByName(vehicle,'wheel_rr')
							local door = {}
							local seat = {}
							for i = 0, 3 do
								local doors = GetEntryPositionOfDoor(vehicle,i)
								--
								if doors.x ~= 0.0 then
									--
									local var = 'doors_'..i..''
									chop_parts['doors_'..i..''] = doors
									if choppedvehicles['doors_'..i] then
										chop_parts['seat_'..i..''] = doors
									end
									--
								end
								--
							end
							local dist = -1
							local part = ''
							local partcoord = {}
							--while true do
							local neg = false
							for k,v in pairs(chop_parts) do
								--local x,y,z = table.unpack(GetWorldPositionOfEntityBone(vehicle, bone))
								--
								local mycoord = GetEntityCoords(PlayerPedId())
								local worldcoord = GetWorldPositionOfEntityBone(vehicle, v)
								if k == 'engine' then
									worldcoord = worldcoord
								end
								if k == 'bonnet' then
									worldcoord = worldcoord
								end
								if k == 'trunk' then
									worldcoord = worldcoord
								end
								if not choppedvehicles['doors_0'] and string.find(k, 'seat_0') then
									worldcoord = worldcoord-vec3(1000.0,0.0,0.0)
								end
								if not choppedvehicles['doors_1'] and string.find(k, 'seat_1') then
									worldcoord = worldcoord-vec3(1000.0,0.0,0.0)
								end
								if not choppedvehicles['doors_2'] and string.find(k, 'seat_2') then
									worldcoord = worldcoord-vec3(1000.0,0.0,0.0)
									--
								end
								if not choppedvehicles['doors_3'] and string.find(k, 'seat_3') then
									worldcoord = worldcoord-vec3(1000.0,0.0,0.0)
								end

								if not choppedvehicles['wheel_lf'] and string.find(k, 'brake_0') then
									worldcoord = worldcoord-vec3(1000.0,0.0,0.0)
								end
								if not choppedvehicles['wheel_rf'] and string.find(k, 'brake_1') then
									worldcoord = worldcoord-vec3(1000.0,0.0,0.0)
								end
								if not choppedvehicles['wheel_lr'] and string.find(k, 'brake_2') then
									worldcoord = worldcoord-vec3(1000.0,0.0,0.0)
								end
								if not choppedvehicles['wheel_rr'] and string.find(k, 'brake_3') then
									worldcoord = worldcoord-vec3(1000.0,0.0,0.0)
								end

								if choppedvehicles['wheel_lf'] and string.find(k, 'brake_0') and not choppedvehicles['brake_0'] then
									--worldcoord = worldcoord+vec3(0.0,0.0,5.0)
									mycoord = GetEntityCoords(PlayerPedId())-vec3(0.0,0.0,5.0)
									--
								end
								if choppedvehicles['wheel_rf'] and string.find(k, 'brake_1') and not choppedvehicles['brake_1'] then
									mycoord = GetEntityCoords(PlayerPedId())-vec3(0.0,0.0,5.0)
								end
								if choppedvehicles['wheel_lr'] and string.find(k, 'brake_2') and not choppedvehicles['brake_2'] then
									mycoord = GetEntityCoords(PlayerPedId())-vec3(0.0,0.0,5.0)
								end
								if choppedvehicles['wheel_rr'] and string.find(k, 'brake_3') and not choppedvehicles['brake_3'] then
									mycoord = GetEntityCoords(PlayerPedId())-vec3(0.0,0.0,5.0)
								end

								local coord = tonumber(v) and worldcoord or v
								local dis = #(mycoord - coord)
								--
								if not choppedvehicles[k] and dist == -1 and dis < 4 or not choppedvehicles[k] and dist >= dis then
									dist = dis
									neg = string.find(k, 'brake') and k or false
									--part = v == tonumber(v) and GetWorldPositionOfEntityBone(vehicle, v) or v
									part = k
									--
								end
								--DrawText3Ds(coord,k)
								--DrawMarker(27, coord.x,coord.y,coord.z-0.8, 0, 0, 0, 0, 0, 0, 0.7, 0.7, 0.7, 200, 255, 255, 255, 0, 0, 1, 1, 0, 0, 0)
							end
								--Wait(0)
							--end
							--
							local coord = tonumber(chop_parts[part]) and GetWorldPositionOfEntityBone(vehicle, chop_parts[part]) ~= -1 and GetWorldPositionOfEntityBone(vehicle, chop_parts[part]) or not tonumber(chop_parts[part]) and chop_parts[part] or GetEntityCoords(PlayerPedId())
							if part == 'engine' then
								coord = coord
							end
							if part == 'bonnet' then
								coord = coord
							end
							if part == 'trunk' then
								coord = coord
							end
							mycoord = GetEntityCoords(PlayerPedId())
							neg = neg == part
							--
							if neg then
								mycoord = mycoord-vec3(0.0,0.0,5.0)
							end
							dis = #(mycoord - coord)-1
							--
							if dis <= dist+0.2 and not chopping and IsPedStopped(PlayerPedId()) then
								refresh = true
								TriggerEvent('renzu_popui:closeui')
								while refresh do Wait(1) end
								local table = {
									['key'] = 'E', -- key
									['event'] = 'renzu_projectcars:chop_parts',
									['title'] = 'Press [E] Remove '..part:upper(),
									['server_event'] = false, -- server event or client
									['unpack_arg'] = true, -- send args as unpack 1,2,3,4 order
									['fa'] = '<i class="far fa-car-mechanic"></i>',
									['custom_arg'] = {part,plate,vehicle,coord}, -- example: {1,2,3,4}
								}
								TriggerEvent('renzu_popui:drawtextuiwithinput',table)
							end
							donechop = false
							while not chopping and not donechop and dis <= dist+0.2 do
								--
								part = (part:gsub("^%l", string.upper))
								DrawText3Ds(coord,'[~g~E~w~] 🔧 - '..part:gsub('_',' '))
								mycoord = GetEntityCoords(PlayerPedId())
								if neg then
									mycoord = mycoord-vec3(0.0,0.0,5.0)
								end
								dis = #(mycoord - coord)
								Wait(0)
							end
							TriggerEvent('renzu_popui:closeui')
							SendNUIMessage({show = false,type = "project_status", status = {}})
							--Wait(1000)
						end
					end
				end
			end
		end
		Wait(1000)
	end
end)

RegisterNetEvent('renzu_projectcars:gotowarehouse')
AddEventHandler('renzu_projectcars:gotowarehouse', function(name,data,job)
	DoScreenFadeOut(0)
	if name == 'enter' then
		SetEntityCoords(PlayerPedId(),data.exit.x,data.exit.y,data.exit.z)
		inwarehouse = job
	else
		SetEntityCoords(PlayerPedId(),data.coord.x,data.coord.y,data.coord.z)
		inwarehouse = nil
	end
	while not HasCollisionLoadedAroundEntity(PlayerPedId()) do Wait(1) end
	Wait(1000)
	DoScreenFadeIn(500)
	while inwarehouse do
		local brand = data.brands
		local brands = brand
		local coord = GetEntityCoords(PlayerPedId())
		local sleep = 1000
		for k,v in pairs(data['warehouse']) do
			local loc = vector3(v.coord.x,v.coord.y,v.coord.z)

			local name = 'enter'
			local dis = #(coord - loc)
			if dis < 55 and not refresh then
				sleep = 1
					--while dis < 15 and not refresh do
					if dis < 4 then
						local t = {
							['key'] = 'E', -- key
							['event'] = v.event,
							['title'] = 'Press [E] Open '..v.label,
							['invehicle_title'] = k == 'garage' and 'Store Vehicle',
							['server_event'] = false, -- server event or client
							['unpack_arg'] = true, -- send args as unpack 1,2,3,4 order
							['fa'] = '<i class="fal fa-garage"></i>',
							['custom_arg'] = {brands,job}, -- example: {1,2,3,4}
						}
						TriggerEvent('renzu_popui:drawtextuiwithinput',t)
						Wait(500)
						while dis < 4 and not refresh do
							Wait(100)
							coord = GetEntityCoords(PlayerPedId())
							dis = #(coord - vector3(v.coord.x,v.coord.y,v.coord.z))
						end
						TriggerEvent('renzu_popui:closeui')
					end
					DrawMarker(21, loc.x,loc.y,loc.z, 0, 0, 0, 0, 0, 0, 0.7, 0.7, 0.7, 200, 255, 255, 255, 0, 0, 1, 1, 0, 0, 0)
					--end
			end
		end
		Wait(sleep)
	end
end)

RegisterNetEvent('renzu_projectcars:stockroom')
AddEventHandler('renzu_projectcars:stockroom', function(data)
	local localmultimenu = {}
    local openmenu = false
    for k,v in pairs(Config.Vehicles) do
		local brand = v.brand or 'Imports'
        local name = brand
		if data[name:lower()] and IsModelInCdimage(GetHashKey(v.model)) then
			if localmultimenu[name] == nil then
				openmenu = true
				localmultimenu[name] = {}
				localmultimenu[name].main_fa = '<img style="border-radius:40px;height: auto;margin-left: -20px;margin-top: -10px;position: relative;max-width: 45px;max-height:40px;float: left;" src="https://cfx-nui-renzu_projectcars/html/brands/'..brand..'.png">'
			end
			local img = GlobalState.VehicleImages and GlobalState.VehicleImages[tostring(GetHashKey(v.model))] or 'https://i.imgur.com/NHB74QX.png'
			localmultimenu[name][v.name] = {
				['title'] = v.name..' - Part List',
				['fa'] = '<img style="height: auto;position: absolute;max-width: 50px;left:2%;top:20%;" src="'.. img ..'">',
				['type'] = 'event', -- event / export
				['content'] = 'renzu_projectcars:openpartlist',
				['variables'] = {server = false, send_entity = false, onclickcloseui = true, custom_arg = v, arg_unpack = false},
			}
		end
    end
    if openmenu then
        TriggerEvent('renzu_contextmenu:insertmulti',localmultimenu,"Vehicle List",false,"<i class='fas fa-car'></i> Auto Parts Catalogue")
        TriggerEvent('renzu_contextmenu:show')
    end
end)

RegisterNetEvent('renzu_projectcars:buildermenu')
AddEventHandler('renzu_projectcars:buildermenu', function(data)
	local multimenu = {}
	firstmenu = {
		['Create Job'] = {
			['title'] = 'Start New Build',
			['fa'] = '<i class="fad fa-question-square"></i>',
			['type'] = 'event', -- event / export
			['content'] = 'renzu_projectcars:buildlist',
			['variables'] = {server = false, send_entity = false, onclickcloseui = true, custom_arg = {data}, arg_unpack = true},
		},
	}
	multimenu['Create Job'] = firstmenu
	secondmenu = {
		['Order Lists'] = {
			['title'] = 'Request New',
			['fa'] = '<i class="fad fa-question-square"></i>',
			['type'] = 'event', -- event / export
			['content'] = 'renzu_projectcars:requestorderlist',
			['variables'] = {server = true, send_entity = false, onclickcloseui = true, custom_arg = {}, arg_unpack = true},
		},
	}
	for k,v in pairs(GlobalState.ProjectOrders) do
		if k == PlayerData.job.name then
			for k,v in pairs(v) do
				--secondmenu[k] = v
				secondmenu[v.name] = {
					['title'] = v.name..' '..v.category,
					['fa'] = '<i class="fad fa-question-square"></i>',
					['type'] = 'event', -- event / export
					['content'] = 'renzu_projectcars:releasejoborder',
					['variables'] = {server = true, send_entity = false, onclickcloseui = true, custom_arg = {k,v}, arg_unpack = true},
				}
			end
		end
	end
	multimenu['Order Lists'] = secondmenu
	local projectcars = GlobalState.ProjectCars
	local ongoings = {}
	for k,v in pairs(projectcars) do
		local coord = json.decode(v.coord)
		local dist = #(GetEntityCoords(PlayerPedId()) - vector3(coord.x,coord.y,coord.z))
		if dist < 300 then
			ongoings[v.model..' : Distance - '..dist] = {
				['title'] = v.model..' : Distance - '..dist,
				['fa'] = '<i class="fad fa-question-square"></i>',
				['type'] = 'event', -- event / export
				['content'] = 'renzu_garage:a',
				['variables'] = {server = true, send_entity = false, onclickcloseui = true, custom_arg = {garage,share,true}, arg_unpack = true},
			}
		end
	end
	multimenu['Ongoing Jobs'] = ongoings
	-- bossmenu = {
	-- 	['Boss Menu'] = {
	-- 		['title'] = 'Boss Menu',
	-- 		['fa'] = '<i class="fad fa-question-square"></i>',
	-- 		['type'] = 'event', -- event / export
	-- 		['content'] = 'renzu_garage:a',
	-- 		['variables'] = {server = true, send_entity = false, onclickcloseui = true, custom_arg = {garage,share,true}, arg_unpack = true},
	-- 	},
	-- }
	-- multimenu['Boss Menu'] = bossmenu
	TriggerEvent('renzu_contextmenu:insertmulti',multimenu,"Builder Menu",false,'Builder Menu')
	TriggerEvent('renzu_contextmenu:show')
end)

GetVehicleInfoFromModel = function(hash)
	local result = {}
	for k,v in pairs(Config.Vehicles) do
		if hash == GetHashKey(v.model) then
			result = v
			return result
		end
	end
	return result
end

RegisterNetEvent('renzu_projectcars:garagemenu')
AddEventHandler('renzu_projectcars:garagemenu', function(data,job)
	local multimenu = {}
	if not IsPedInAnyVehicle(PlayerPedId()) then
		local garage = GlobalState.JobGarage or {}
		local list = {}
		for k,v in pairs(garage) do
			if k == job then
				for k,v in pairs(v) do
					local info = GetVehicleInfoFromModel(v.props.model)
					list[info.name] = {
						['title'] = '['..v.props.plate..'] : '..info.name..' '..info.category,
						['fa'] = '<i class="fad fa-question-square"></i>',
						['type'] = 'event', -- event / export
						['content'] = 'renzu_projectcars:changestate',
						['variables'] = {server = true, send_entity = false, onclickcloseui = true, custom_arg = {v.props.plate,job,{},false,v.props.model}, arg_unpack = true},
					}
				end
			end
		end
		multimenu['Open Garage'] = list
	else
		local vehicle = GetVehiclePedIsIn(PlayerPedId())
		local vplate = string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1')
		local props = GetVehicleProperties(vehicle)
		firstmenu = {
			['Store Vehicle'] = {
				['title'] = 'Store Vehicle',
				['invehicle_title'] = 'Store Vehicle',
				['fa'] = '<i class="fad fa-question-square"></i>',
				['type'] = 'event', -- event / export
				['content'] = 'renzu_projectcars:changestate',
				['variables'] = {server = true, send_entity = false, onclickcloseui = true, custom_arg = {vplate,job,props,true,{},VehToNet(vehicle)}, arg_unpack = true},
			},
		}
		multimenu['Store Vehicle'] = firstmenu
	end
	TriggerEvent('renzu_contextmenu:insertmulti',multimenu,"Garage Menu",false,'Garage Menu')
	TriggerEvent('renzu_contextmenu:show')
end)

RegisterNetEvent('renzu_projectcars:buildlist')
AddEventHandler('renzu_projectcars:buildlist', function(data)
	Wait(1000)
	local localmultimenu = {}
    local openmenu = false
    for k,v in pairs(Config.Vehicles) do
		local brand = v.brand or 'Imports'
        local name = brand
		local model = GetHashKey(v.model)
		if data[name:lower()] and IsModelInCdimage(model) then
			if Config.job_AllShopFree and Config.jobonly and PlayerData.job and Config.carbuilderjob == PlayerData.job.name then
				v.price = 0
			end
			if localmultimenu[name] == nil then
				openmenu = true
				localmultimenu[name] = {}
				localmultimenu[name].input = true
				localmultimenu[name].main_fa = '<img style="border-radius:40px;height: auto;margin-left: -20px;margin-top: -10px;position: relative;max-width: 45px;max-height:40px;float: left;" src="https://cfx-nui-renzu_projectcars/html/brands/'..brand..'.png">'
			end
			local img = GlobalState.VehicleImages and GlobalState.VehicleImages[tostring(model)] or 'https://i.imgur.com/NHB74QX.png'
			localmultimenu[name][v.name] = {
				['title'] = v.name..' - '..v.category..' <br stlye="margin-top:5px;"> <span style="padding-top:10px;margin-top:20px;">Price: <span style="color:lime;">'..v.price..'</span></span>',
				['fa'] = '<img style="height: auto;position: absolute;max-width: 50px;left:2%;top:20%;" src="'.. img ..'">',
				['type'] = 'event', -- event / export
				['content'] = 'renzu_projectcars:spawnshell',
				['variables'] = {server = true, send_entity = false, onclickcloseui = true, custom_arg = v, arg_unpack = false},
			}
		end
    end
    if openmenu then
        TriggerEvent('renzu_contextmenu:insertmulti',localmultimenu,"Vehicle List",false,"<i class='fas fa-car'></i> List of Handle Brand Vehicles")
        TriggerEvent('renzu_contextmenu:show')
    end
end)

RegisterNetEvent('renzu_projectcars:chop_parts')
AddEventHandler('renzu_projectcars:chop_parts', function(part,plate,vehicle,coord)
	
	local t = {
		['wheel_rf'] = 1,
		['wheel_lf'] = 0,
		['wheel_lr'] = 2,
		['wheel_rr'] = 3,
		['brake_1'] = 1,
		['brake_0'] = 0,
		['brake_2'] = 2,
		['brake_3'] = 3,
		['doors_0'] = 0,
		['doors_1'] = 1,
		['doors_2'] = 2,
		['doors_3'] = 3,
		['seat_0'] = -1,
		['seat_1'] = 0,
		['seat_2'] = 1,
		['seat_3'] = 2,
	}
	if Config.EnableInteraction then
		TaskTurnPedToFaceCoord(PlayerPedId(),coord.x,coord.y,coord.z,5000)
		Wait(1000)
	end
	if Interaction(part) then
		local data = {
			net = VehToNet(vehicle),
			part = part,
			plate = plate,
			t = t[part],
			seat = GetNumSeat(vehicle)
		}
		TriggerServerEvent('renzu_projectcars:updatechopcar',data)
	end
end)

RegisterNetEvent('renzu_projectcars:updatechopcar')
AddEventHandler('renzu_projectcars:updatechopcar', function(part,net,choppped,plate,sender)
	
	local vehicle = NetToVeh(net)
	local ent = Entity(vehicle).state
	if DoesEntityExist(vehicle) then
		if type(part) == 'table' then
			for k,v in pairs(part) do
				ChopPart[k](vehicle,v,sender == PlayerData.identifier)
			end
		else
			ChopPart[part](vehicle,0,sender == PlayerData.identifier)
		end
		local ent = Entity(vehicle).state
		local choppedvehicles = ent.chopped
		if not choppedvehicles then
			choppedvehicles = {}
		end
		if choppedvehicles[chopped] == nil then
			choppedvehicles[choppped] = true
		end
		ent:set('chopped',choppedvehicles,false)
	end
	Wait(2000)
	donechop = true
	TriggerEvent('renzu_popui:closeui')
end)

local localshell = {}
RegisterNetEvent('renzu_projectcars:newchop') -- freeze entity and set fuel to zero avoid player having a collision with the vehicle that can messed up with the wheel coords
AddEventHandler('renzu_projectcars:newchop', function(net,plate)
	while GlobalState.ChopVehicles[plate] == nil do Wait(1000) end
	local vehicle = NetToVeh(net)
	if DoesEntityExist(vehicle) and GlobalState.ChopVehicles[plate] then
		for i = 0, 3 do
			local ped = GetPedInVehicleSeat(vehicle,i-1)
			TaskLeaveVehicle(ped,vehicle,1)
		end
		Wait(2000)
		FreezeEntityPosition(vehicle,true)
		SetVehicleFixed(vehicle)
		SetVehicleFuelLevel(vehicle,0.0)
		SetEntityCompletelyDisableCollision(vehicle,false,false)
		local model = GetEntityModel(vehicle)
		shell = CreateObject(model,GetEntityCoords(vehicle), false, true)
		localshell[plate] = shell
		SetEntityHeading(shell,GetEntityHeading(vehicle))
		FreezeEntityPosition(shell,true)
		SetEntityCompletelyDisableCollision(shell,true,false)
		SetEntityCanBeDamaged(shell,false)
		SetEntityInvincible(shell,true)
		SetEntityAlpha(shell,0,false)
	end
end)

ChopLoop = function()
	chopping = true
	while chopping do
		for k,v in pairs(Config.ChopShop) do
			local dist = #(GetEntityCoords(PlayerPedId()) - v.store)
			while dist < 80 and chopping do
				DrawText3Ds(v.store,'⬇️')
				DrawMarker(27, v.store.x,v.store.y,v.store.z-0.8, 0, 0, 0, 0, 0, 0, 0.7, 0.7, 0.7, 200, 255, 255, 255, 0, 0, 1, 1, 0, 0, 0)
				if dist < 2 and IsControlPressed(0,38) then
					chopping = false
					DeleteObject(currentobject)
					ClearPedTasks(PlayerPedId())
					Wait(100)
					break
				end
				dist = #(GetEntityCoords(PlayerPedId()) - v.store)
				Wait(0)
			end
		end
		Wait(1000)
	end
end

ChopPart['bonnet'] = function(vehicle,v,owner)
	SetVehicleDoorBroken(vehicle, 4, true)
	if owner then
		SpawnBonnet()
		ChopLoop()
	end
end

ChopPart['trunk'] = function(vehicle,v,owner)
	SetVehicleDoorBroken(vehicle, 5, true)
	SpawnTrunk()
	ChopLoop()
end

ChopPart['engine'] = function(vehicle,v,owner)
	SetVehicleDoorBroken(vehicle, 5, true)
	if owner then
		SpawnEngine(true,true)
	end
end

ChopPart['transmition'] = function(vehicle,v,owner)
	SetVehicleDoorBroken(vehicle, 5, true)
	if owner then
		SpawnEngine(false,true)
	end
end

ChopPart['wheel'] = function(vehicle,v,owner)
	SetVehicleWheelTireColliderSize(vehicle, tonumber(v), -5.0)
	if owner then
		SpawnWheel()
		ChopLoop()
	end
end

ChopPart['door'] = function(vehicle,v,owner)
	SetVehicleDoorBroken(vehicle, tonumber(v), true)
	if owner then
		SpawnDoor()
		ChopLoop()
	end
end

ChopPart['seat'] = function(vehicle,v,owner)
	if owner then
		SpawnSeat()
		ChopLoop()
	end
end

ChopPart['brake'] = function(vehicle,v,owner)
	if owner then
		SpawnBrake()
		ChopLoop()
	end
end

ChopPart['exhaust'] = function(vehicle,v,owner)
	if owner then
		SpawnExhaust()
		ChopLoop()
	end
end

RegisterNetEvent('renzu_projectcars:deletechopped')
AddEventHandler('renzu_projectcars:deletechopped', function(plate)
	for k,v in ipairs(GetGamePool('CVehicle')) do
		local vplate = string.gsub(GetVehicleNumberPlateText(v), '^%s*(.-)%s*$', '%1')
		if vplate == plate then
			DeleteEntity(v)
			if DoesEntityExist(localshell[vplate] or 0) then
				DeleteEntity(localshell[vplate])
			end
			break
		end
	end
end)

DrawText3Ds = function(pos, text)
	local onScreen,_x,_y=World3dToScreen2d(pos.x,pos.y,pos.z)

	if onScreen then
		SetTextScale(0.55, 0.55)
		SetTextFont(4)
		SetTextProportional(1)
		SetTextColour(255, 255, 255, 215)
		SetTextEntry("STRING")
		SetTextCentre(1)
		AddTextComponentString(text)
		DrawText(_x,_y)
	end
end

RegisterNetEvent('renzu_projectcars:openautoshop')
AddEventHandler('renzu_projectcars:openautoshop', function(shop)
    local localmultimenu = {}
    local openmenu = false
    for k,v in pairs(shop) do
		local brand = v.brand or 'Imports'
        local name = brand
		local model = GetHashKey(v.model)
		if IsModelInCdimage(model) then
			if localmultimenu[name] == nil then
				openmenu = true
				localmultimenu[name] = {}
				localmultimenu[name].main_fa = '<img style="border-radius:40px;height: auto;margin-left: -20px;margin-top: -10px;position: relative;max-width: 45px;max-height:40px;float: left;" src="https://cfx-nui-renzu_projectcars/html/brands/'..brand..'.png">'
			end
			local img = GlobalState.VehicleImages and GlobalState.VehicleImages[tostring(model)] or 'https://i.imgur.com/NHB74QX.png'
			localmultimenu[name][v.name] = {
				['title'] = v.name..' - Part List',
				['fa'] = '<img style="height: auto;position: absolute;max-width: 50px;left:2%;top:20%;" src="'.. img ..'">',
				['type'] = 'event', -- event / export
				['content'] = 'renzu_projectcars:openpartlist',
				['variables'] = {server = false, send_entity = false, onclickcloseui = true, custom_arg = v, arg_unpack = false},
			}
		end
    end
    if openmenu then
        TriggerEvent('renzu_contextmenu:insertmulti',localmultimenu,"Vehicle List",false,"<i class='fas fa-car'></i> Auto Parts Catalogue")
        TriggerEvent('renzu_contextmenu:show')
    end
end)

RegisterNetEvent('renzu_projectcars:openshop')
AddEventHandler('renzu_projectcars:openshop', function(shop)
    local localmultimenu = {}
	if shop == nil then shop = Config.Vehicles end
    local openmenu = false
    for k,v in pairs(shop) do
		local model = GetHashKey(v.model)
		if IsModelInCdimage(model) then
			local brand = v.brand or 'Imports'
			local name = brand
			if Config.job_AllShopFree and Config.jobonly and PlayerData.job and Config.carbuilderjob == PlayerData.job.name then
				v.price = 0
			end
			if localmultimenu[name] == nil then
				openmenu = true
				localmultimenu[name] = {}
				localmultimenu[name].input = true
				localmultimenu[name].main_fa = '<img style="border-radius:40px;height: auto;margin-left: -20px;margin-top: -10px;position: relative;max-width: 45px;max-height:40px;float: left;" src="https://cfx-nui-renzu_projectcars/html/brands/'..brand..'.png">'
			end
			local img = GlobalState.VehicleImages and GlobalState.VehicleImages[tostring(GetHashKey(v.model))] or 'https://i.imgur.com/NHB74QX.png'
			localmultimenu[name][v.name] = {
				['title'] = v.name..' - '..v.category..' <br stlye="margin-top:5px;"> <span style="padding-top:10px;margin-top:20px;">Price: <span style="color:lime;">'..v.price * Config.PercentShellPrice..'</span></span>',
				['fa'] = '<img style="height: auto;position: absolute;max-width: 50px;left:2%;top:20%;" src="'.. img ..'">',
				['type'] = 'event', -- event / export
				['content'] = 'renzu_projectcars:buyshell',
				['variables'] = {server = true, send_entity = false, onclickcloseui = true, custom_arg = v, arg_unpack = false},
			}
		end
    end
    if openmenu then
        TriggerEvent('renzu_contextmenu:insertmulti',localmultimenu,"Vehicle List",false,"<i class='fas fa-car'></i> Junk Vehicles")
        TriggerEvent('renzu_contextmenu:show')
    end
end)

RegisterNetEvent('renzu_projectcars:openpartlist')
AddEventHandler('renzu_projectcars:openpartlist', function(data)
	Wait(1000)
	TriggerEvent('renzu_popui:closeui')
	if data == nil then data = {} data.name = 'Auto Parts' end
    local localmultimenu = {}
    local openmenu = false
    for k,v in pairs(Config.parts) do
		local parts = v.label
		local event = 'renzu_projectcars:buyparts'
		local price = data and data.model and Config.Vehicles[data.model] and Config.Vehicles[data.model].price * v.metaprice or v.price
		if not Config.MetaInventory then
			price = v.price
		end
		local string = '<span style="padding-top:10px;margin-top:20px;">Price: <span style="color:lime;">'..price..'</span></span>'
		local var = data
		if inwarehouse == PlayerData.job.name then
			v.price = 0
			string = ''
			event = 'renzu_projectcars:useparts'
			var = data.model
		end
        local name = parts
        if localmultimenu[name] == nil then
            openmenu = true
            localmultimenu[name] = {}
			localmultimenu[name].input = true
			localmultimenu[name].main_fa = '<img style="border-radius:40px;height: auto;margin-left: -20px;margin-top: -10px;position: relative;max-width: 45px;max-height:40px;float: left;" src="https://cfx-nui-renzu_projectcars/html/parts/'..k..'.png">'
        end
		local img = 'https://cfx-nui-renzu_projectcars/html/parts/'..k..'.png'
		
		localmultimenu[name][v.label] = {
			['title'] = v.label..' <br stlye="margin-top:5px;"> '..string,
			['fa'] = '<img style="height: auto;position: absolute;max-width: 50px;left:2%;top:20%;" src="'.. img ..'">',
			['type'] = 'event', -- event / export
			['content'] = v.func ~= nil and v.func or event,
			['variables'] = {server =  not inwarehouse and v.func == nil, send_entity = false, onclickcloseui = inwarehouse, 
			custom_arg = v.func == nil and {k,var or {}} or data, arg_unpack = inwarehouse ~= nil},
		}
    end
    if openmenu then
		local name = data ~= nil and data.name and data.name:upper() or 'Auto'
        TriggerEvent('renzu_contextmenu:insertmulti',localmultimenu,"Vehicle List",false,"<i class='fas fa-car'></i> "..name .." Parts")
        TriggerEvent('renzu_contextmenu:show')
    end
	Wait(1000)
	TriggerEvent('renzu_popui:closeui')
end)

SprayParticles = function(ped,dict,n,vehicle,m)
    local dict = "scr_recartheft"
    local ped = PlayerPedId()
    local fwd = GetEntityForwardVector(ped)
    local coords = GetEntityCoords(ped) + fwd * 0.5 + vector3(0.0, 0.0, -0.5)

    RequestNamedPtfxAsset(dict)
    -- Wait for the particle dictionary to load.
    while not HasNamedPtfxAssetLoaded(dict) do
        Citizen.Wait(0)
    end
    local pointers = {}
    local color = Config.Paint[n].color
    local heading = GetEntityHeading(ped)
    UseParticleFxAssetNextCall(dict)
    SetParticleFxNonLoopedColour(color[1] / 255, color[2] / 255, color[3] / 255)
    SetParticleFxNonLoopedAlpha(1.0)
    local spray = StartNetworkedParticleFxNonLoopedAtCoord("scr_wheel_burnout", coords.x, coords.y, coords.z + 1.5, 0.0, 0.0, heading, 0.7, 0.0, 0.0, 0.0)
end

spraycan = nil
PaintCar = function(n,vehicle)
    local ped = PlayerPedId()
    spraying = true
    custompaint = true
    local n = n:lower()
    CreateThread(function()
        local min = 255
        while spraying do
            local sleep = 3000
            min = min - (min/sleep) * 1000
            SprayParticles(ped,dict,n,vehicle,min)
            Wait(3000)
        end
    end)
    while not custompaint do Wait(100) end
    RemoveNamedPtfxAsset(dict)
    while ( not HasAnimDictLoaded( 'anim@amb@business@weed@weed_inspecting_lo_med_hi@' ) ) do
        RequestAnimDict( 'anim@amb@business@weed@weed_inspecting_lo_med_hi@' )
        Citizen.Wait( 1 )
    end
    TaskPlayAnim(ped, 'anim@amb@business@weed@weed_inspecting_lo_med_hi@', 'weed_spraybottle_stand_spraying_01_inspector', 1.0, 1.0, -1, 16, 0, 0, 0, 0 )
    local min = 255
    local r,g,b = table.unpack(Config.Paint[n].color)
    local rd,gd,bd = 255,255,255
    DeleteEntity(spraycan or 0)
    Wait(100)
    spraycan = CreateObject(GetHashKey('ng_proc_spraycan01b'),0.0, 0.0, 0.0,true, false, false)
    AttachEntityToEntity(spraycan, ped, GetPedBoneIndex(ped, 57005), 0.072, 0.041, -0.06,33.0, 38.0, 0.0, true, true, false, true, 1, true)
    SetOwned(vehicle)
    while spraying do
        while rd ~= r or gd ~= g or bd ~= b do
            if rd ~= r then
                rd = rd - 1
            end
            if gd ~= g then
                gd = gd - 1
            end
            if bd ~= b then
                bd = bd - 1
            end
            SetVehicleCustomPrimaryColour(vehicle,rd,gd,bd)
            Wait(100)
        end
		SetVehicleCustomPrimaryColour(vehicle,r,g,b)
		SetVehicleDirtLevel(vehicle,0.0)
		SetVehicleEnveffScale(vehicle,0.0)
        spraying = false
        Wait(100)
    end
    spraying = false
    DeleteEntity(spraycan)
    ClearPedTasks(ped)
	local plate = GetVehicleNumberPlateText(vehicle)
	plate = string.gsub(tostring(plate), '^%s*(.-)%s*$', '%1')
	if GlobalState.ProjectCars[plate] then
		SetVehicleUpdate('paint',0)
	end
end

RegisterNetEvent('renzu_projectcars:usepaint')
AddEventHandler('renzu_projectcars:usepaint', function(color)
	PaintCar(color,getveh())
end)

RegisterNetEvent('renzu_projectcars:openpaint')
AddEventHandler('renzu_projectcars:openpaint', function(data)
	
	Wait(2000)
    local localmultimenu = {}
    local openmenu = false
    for k,v in pairs(Config.Paint) do
		
        local name = k:upper()
        if localmultimenu[name] == nil then
            openmenu = true
            localmultimenu[name] = {}
			localmultimenu[name].input = true
			localmultimenu[name].main_fa = '<img style="border-radius:40px;height: auto;margin-left: -20px;margin-top: -10px;position: relative;max-width: 45px;max-height:40px;float: left;" src="https://i.imgur.com/NHB74QX.png">'
        end
		
		local img = 'https://i.imgur.com/NHB74QX.png'
		localmultimenu[name][name] = {
			['title'] = name..' <br stlye="margin-top:5px;"> <span style="padding-top:10px;margin-top:20px;">Price: <span style="color:lime;">'..v.price..'</span></span>',
			['fa'] = '<img style="height: auto;position: absolute;max-width: 50px;left:2%;top:20%;" src="'.. img ..'">',
			['type'] = 'event', -- event / export
			['content'] = 'renzu_projectcars:buyparts',
			['variables'] = {server = true, send_entity = false, onclickcloseui = false, custom_arg = {v,data or {}}, arg_unpack = false},
		}
    end
    if openmenu then
        TriggerEvent('renzu_contextmenu:insertmulti',localmultimenu,"Vehicle List",false,"<i class='fas fa-car'></i> Paint Shop")
        TriggerEvent('renzu_contextmenu:show')
    end
end)

RegisterNetEvent('renzu_projectcars:openblueprints')
AddEventHandler('renzu_projectcars:openblueprints', function(shop)
    local localmultimenu = {}
    local openmenu = false
    for k,v in pairs(shop) do
		local brand = v.brand or 'Imports'
        local name = brand
        if localmultimenu[name] == nil then
            openmenu = true
            localmultimenu[name] = {}
			localmultimenu[name].main_fa = '<img style="border-radius:40px;height: auto;margin-left: -20px;margin-top: -10px;position: relative;max-width: 45px;max-height:40px;float: left;" src="https://cfx-nui-renzu_projectcars/html/brands/'..brand..'.png">'
        end
		local img = GlobalState.VehicleImages and GlobalState.VehicleImages[tostring(GetHashKey(v.model))] or 'https://i.imgur.com/NHB74QX.png'
		localmultimenu[name][v.name] = {
			['title'] = v.name..' - '..v.category,
			['fa'] = '<img style="height: auto;position: absolute;max-width: 50px;left:2%;top:20%;" src="'.. img ..'">',
			['type'] = 'event', -- event / export
			['content'] = 'renzu_projectcars:spawnshell',
			['variables'] = {server = true, send_entity = false, onclickcloseui = true, custom_arg = v, arg_unpack = false},
		}
    end
    if openmenu then
        TriggerEvent('renzu_contextmenu:insertmulti',localmultimenu,"Vehicle List",false,"<i class='fas fa-car'></i> Junk Vehicles")
        TriggerEvent('renzu_contextmenu:show')
    end
end)

RegisterNetEvent('renzu_projectcars:useparts')
AddEventHandler('renzu_projectcars:useparts', function(part,model)
	Useitem[part](model)
	Wait(500)
	TriggerEvent('renzu_popui:closeui')
end)

AddEventHandler('renzu_contextmenu:close', function()
    refresh = true
	Wait(2000)
	refresh = false
end)

AddEventHandler('renzu_popui:closeui', function()
    refresh = true
	Wait(2000)
	refresh = false
end)

RestoreItem = function(use,model,matched)
	DeleteObject(currentobject)
	ClearPedTasks(PlayerPedId())
	UseBusy = false
	if use and success then
		TriggerServerEvent('renzu_projectcars:removeitem',use,model)
		if Config.RenzuNotify then
			TriggerEvent('renzu_notify:Notify', 'success','ProjectCars', Locale[Config.Locale].installsuccess)
		else
			Notify(Locale[Config.Locale].installsuccess)
		end
	elseif not matched and Config.MetaInventory then
		if Config.RenzuNotify then
			TriggerEvent('renzu_notify:Notify', 'warning','ProjectCars', Locale[Config.Locale].partnotmatched)
		else
			Notify(Locale[Config.Locale].partnotmatched)
		end
	else
		if Config.RenzuNotify then
			TriggerEvent('renzu_notify:Notify', 'info','ProjectCars', Locale[Config.Locale].partscancel)
		else
			Notify(Locale[Config.Locale].partscancel)
		end
	end
end

ProjectCount = function()
	local c = 0
	for k,v in pairs(GlobalState.ProjectCars) do
		c = c + 1
	end
	return c
end

UseBusy = false
Useitem['bonnet'] = function(model)
	if UseBusy then return end
	UseBusy = true
	SpawnBonnet()
	local install = true
	local use = false
    local projectcars = GlobalState.ProjectCars
	local data = nil
	local dist = -1
	local radius = 8
	if inwarehouse then
		radius = 300
	end
	local vehicle = nil
	CreateThread(function()
		while install do
			Wait(300)
			dist, data = GetNearestProjectCar(projectcars)
			vehicle = getveh() 
		end
		return
	end)
    while install and ProjectCount() > 0 do
		dist, data = GetNearestProjectCar()
		if data and dist ~= -1 and dist < radius and install then
			while data and dist < radius and install do
				if dist < 4 then
					local bone = GetEntityBoneIndexByName(vehicle,'engine')
					local coordbone = GetWorldPositionOfEntityBone(vehicle, bone)
					DrawText3Ds(coordbone, '[~b~E~w~] - Install Bonnet') 
					if IsControlPressed(0,38) then
						if not Config.MetaInventory and Interaction('bonnet') or Config.MetaInventory and Interaction('bonnet') and data.model == model then
							InstallBonnet()
						end
						install = false
						use = 'bonnet'
						DeleteObject(currentobject)
						Wait(100)
						break
					end
				end
				if IsControlPressed(0,73) then
					install = false
					Wait(100)
					break
				end
				dist = #(GetEntityCoords(PlayerPedId()) - data.coord)
				Wait(0)
			end
		end
		install = false
		Wait(1000)
	end
	RestoreItem(use,model,data and data.model == model)
end

Useitem['trunk'] = function(model)
	if UseBusy then return end
	UseBusy = true
	SpawnTrunk()
	local install = true
	local use = false
    local projectcars = GlobalState.ProjectCars
	local data = nil
	local dist = -1
	local radius = 8
	if inwarehouse then
		radius = 300
	end
	local vehicle = nil
	CreateThread(function()
		while install do
			Wait(300)
			dist, data = GetNearestProjectCar(projectcars)
			vehicle = getveh() 
		end
		return
	end)
    while install and ProjectCount() > 0 do
		dist, data = GetNearestProjectCar()
		if data and dist < radius and install then
			while dist < radius and install do
				dist, data = GetNearestProjectCar()
				if dist < 4 then
					local bone = GetEntityBoneIndexByName(vehicle,'taillight_l')
					local coordbone = GetWorldPositionOfEntityBone(vehicle, bone)
					DrawText3Ds(coordbone, '[~b~E~w~] - Install Trunk '..bone)
					if IsControlPressed(0,38) then
						if not Config.MetaInventory and Interaction('trunk') or Config.MetaInventory and Interaction('trunk') and data.model == model then
							InstallTrunk()
						end
						install = false
						use = 'trunk'
						DeleteObject(currentobject)
						Wait(100)
						break
					end
				end
				if IsControlPressed(0,73) then
					install = false
					Wait(100)
					break
				end
				dist = #(GetEntityCoords(PlayerPedId()) - data.coord)
				Wait(0)
			end
		end
		install = false
		Wait(1000)
	end
	RestoreItem(use,model,data and data.model == model)
end

Useitem['door'] = function(model)
	if UseBusy then return end
	UseBusy = true
	SpawnDoor()
	local install = true
	local use = false
	local projectcars = GlobalState.ProjectCars
	local data = nil
	local dist = -1
	local radius = 8
	if inwarehouse then
		radius = 300
	end
	local vehicle = nil
	CreateThread(function()
		while install do
			Wait(300)
			dist, data = GetNearestProjectCar(projectcars)
			vehicle = getveh() 
		end
		return
	end)
    while install and ProjectCount() > 0 do
		dist, data = GetNearestProjectCar()
		if data and dist < radius and install then
			local doors = {
				'seat_dside_f',
				'seat_dside_r',
				'seat_pside_f',
				'seat_pside_r'
			}
			while data and dist < radius and install do
				if dist < 4 then
					for k,v in pairs(doors) do
						local bone = GetEntityBoneIndexByName(vehicle,v)
						local coordbone = GetWorldPositionOfEntityBone(vehicle, bone)
						if bone ~= -1 then
							DrawText3Ds(coordbone, '[~b~E~w~] - Install Door')
						end
					end
					if IsControlPressed(0,38) then
						if not Config.MetaInventory and Interaction('door') or Config.MetaInventory and Interaction('door') and data.model == model then
							InstallDoor()
						end
						install = false
						use = 'door'
						DeleteObject(currentobject)
						Wait(100)
						break
					end
				end
				if IsControlPressed(0,73) then
					install = false
					Wait(100)
					break
				end
				dist = #(GetEntityCoords(PlayerPedId()) - data.coord)
				Wait(0)
			end
		end
		install = false
		Wait(1000)
	end
	RestoreItem(use,model,data and data.model == model)
end

Useitem['wheel'] = function(model)
	if UseBusy then return end
	UseBusy = true
	SpawnWheel()
	local install = true
	local use = false
    local projectcars = GlobalState.ProjectCars
	local data = nil
	local dist = -1
	local radius = 8
	if inwarehouse then
		radius = 300
	end
	local vehicle = nil
	CreateThread(function()
		while install do
			Wait(300)
			dist, data = GetNearestProjectCar(projectcars)
			vehicle = getveh() 
		end
		return
	end)
    while install and ProjectCount() > 0 do
		dist, data = GetNearestProjectCar()
		if data and dist < radius and install then
			local doors = {
				'wheel_lf',
				'wheel_rf',
				'wheel_lr',
				'wheel_rr'
			}
			while dist < radius and install do
				if dist < 4 then
					for k,v in pairs(doors) do
						local bone = GetEntityBoneIndexByName(vehicle,v)
						local coordbone = GetWorldPositionOfEntityBone(vehicle, bone)
						if bone ~= -1 then
							DrawText3Ds(coordbone+vec3(0.0,0.0,5.5), '[~b~E~w~] - Install Wheel')
						end
					end
					if IsControlPressed(0,38) then
						if not Config.MetaInventory and Interaction('wheel') or Config.MetaInventory and Interaction('wheel') and data.model == model then
							InstallWheel()
						end
						install = false
						DeleteObject(currentobject)
						use = 'wheel'
						Wait(100)
						break
					end
				end
				if IsControlPressed(0,73) then
					install = false
					Wait(100)
					break
				end
				dist = #(GetEntityCoords(PlayerPedId()) - data.coord)
				Wait(0)
			end
		end
		install = false
		Wait(1000)
	end
	RestoreItem(use,model,data and data.model == model)
end

Useitem['exhaust'] = function(model)
	if UseBusy then return end
	UseBusy = true
	SpawnExhaust()
	local install = true
	local use = false
    local projectcars = GlobalState.ProjectCars
	local data = nil
	local dist = -1
	local radius = 8
	if inwarehouse then
		radius = 300
	end
	local vehicle = nil
	CreateThread(function()
		while install do
			Wait(300)
			dist, data = GetNearestProjectCar(projectcars)
			vehicle = getveh() 
		end
		return
	end)
    while install and ProjectCount() > 0 do
		dist, data = GetNearestProjectCar()
		if data and dist < radius and install then
			local doors = {
				'exhaust',
			}
			while dist < radius and install do
				if dist < 4 then
					for k,v in pairs(doors) do
						local bone = GetEntityBoneIndexByName(vehicle,v)
						local coordbone = GetWorldPositionOfEntityBone(vehicle, bone)
						if bone ~= -1 then
							DrawText3Ds(coordbone, '[~b~E~w~] - Install Exhaust')
						end
					end
					if IsControlPressed(0,38) then
						if not Config.MetaInventory and Interaction('exhaust') or Config.MetaInventory and Interaction('exhaust') and data.model == model then
							InstallExhaust()
						end
						install = false
						DeleteObject(currentobject)
						use = 'exhaust'
						Wait(100)
						break
					end
				end
				if IsControlPressed(0,73) then
					install = false
					Wait(100)
					break
				end
				dist = #(GetEntityCoords(PlayerPedId()) - data.coord)
				Wait(0)
			end
		end
		install = false
		Wait(1000)
	end
	RestoreItem(use,model,data and data.model == model)
end

Useitem['brake'] = function(model)
	if UseBusy then return end
	UseBusy = true
	SpawnBrake()
	local install = true
	local use = false
    local projectcars = GlobalState.ProjectCars
	local data = nil
	local dist = -1
	local radius = 8
	if inwarehouse then
		radius = 300
	end
	local vehicle = nil
	CreateThread(function()
		while install do
			Wait(300)
			dist, data = GetNearestProjectCar(projectcars)
			vehicle = getveh() 
		end
		return
	end)
    while install and ProjectCount() > 0 do
		dist, data = GetNearestProjectCar()
		if data and dist < radius and install then
			local doors = {
				'wheel_lf',
				'wheel_rf',
				'wheel_lr',
				'wheel_rr'
			}
			while dist < radius and install do
				if dist < 4 then
					for k,v in pairs(doors) do
						local bone = GetEntityBoneIndexByName(vehicle,v)
						local coordbone = GetWorldPositionOfEntityBone(vehicle, bone)
						if bone ~= -1 then
							DrawText3Ds(coordbone+vec3(0.0,0.0,5.5), '[~b~E~w~] - Install Brake')
						end
					end
					if IsControlPressed(0,38) then
						if not Config.MetaInventory and Interaction('brake') or Config.MetaInventory and Interaction('brake') and data.model == model then
							InstallBrake()
						end
						install = false
						DeleteObject(currentobject)
						use = 'brake'
						Wait(100)
						break
					end
				end
				if IsControlPressed(0,73) then
					install = false
					Wait(100)
					break
				end
				dist = #(GetEntityCoords(PlayerPedId()) - data.coord)
				Wait(0)
			end
		end
		install = false
		Wait(1000)
	end
	RestoreItem(use,model,data and data.model == model)
end

Useitem['seat'] = function(model)
	if UseBusy then return end
	UseBusy = true
	SpawnSeat()
	local install = true
	local use = false
    local projectcars = GlobalState.ProjectCars
	local data = nil
	local dist = -1
	local radius = 8
	if inwarehouse then
		radius = 300
	end
	local vehicle = nil
	CreateThread(function()
		while install do
			Wait(300)
			dist, data = GetNearestProjectCar(projectcars)
			vehicle = getveh() 
		end
	end)
    while install and ProjectCount() > 0 do
		dist, data = GetNearestProjectCar()
		if data and dist < radius and install then
			local doors = {
				'seat_dside_f',
				'seat_dside_r',
				'seat_pside_f',
				'seat_pside_r'
			}
			while dist < radius and install do
				if dist < 4 then
					for k,v in pairs(doors) do
						local bone = GetEntityBoneIndexByName(vehicle,v)
						local coordbone = GetWorldPositionOfEntityBone(vehicle, bone)
						if bone ~= -1 then
							DrawText3Ds(coordbone, '[~b~E~w~] - Install Seat')
						end
					end
					if IsControlPressed(0,38) then
						if not Config.MetaInventory and Interaction('seat') or Config.MetaInventory and Interaction('seat') and data.model == model then
							InstallSeat()
						end
						install = false
						DeleteObject(currentobject)
						use = 'seat'
						Wait(100)
						break
					end
				end
				if IsControlPressed(0,73) then
					install = false
					Wait(100)
					break
				end
				dist = #(GetEntityCoords(PlayerPedId()) - data.coord)
				Wait(0)
			end
		end
		install = false
		Wait(1000)
	end
	RestoreItem(use,model,data and data.model == model)
end

Useitem['transmition'] = function(model)
	if UseBusy then return end
	UseBusy = true
	local radius = 8
	local projectcars = GlobalState.ProjectCars or {}
	local dist, data = GetNearestProjectCar()
	local vehicle = nil
	local install = true
	CreateThread(function()
		while install do
			Wait(300)
			dist, data = GetNearestProjectCar(projectcars)
			vehicle = getveh() 
		end
		return
	end)
	if inwarehouse then
		SpawnTranny()
		while install do
			dist, data = GetNearestProjectCar()
			radius = 300
			install = true
			while install do
				if dist < 4 then
					local bone = GetEntityBoneIndexByName(vehicle,'engine')
					local coordbone = GetWorldPositionOfEntityBone(vehicle, bone)
					if bone ~= -1 then
						DrawText3Ds(coordbone, '[~b~E~w~] - Prepare Install')
					end
					if IsControlPressed(0,38) then
						Wait(100)
						DeleteEntity(currentobject)
						install = false
						break
					end
				end
				if IsControlPressed(0,73) then
					install = false
					Wait(100)
					break
				end
				dist = #(GetEntityCoords(PlayerPedId()) - data.coord)
				Wait(0)
			end
			Wait(500)
		end
	end
	if data and dist < radius then
		if not Config.MetaInventory or Config.MetaInventory and data.model == model then
			SpawnEngine(false)
			TriggerServerEvent('renzu_projectcars:removeitem','engine',model)
			if Config.RenzuNotify then
				TriggerEvent('renzu_notify:Notify', 'success','ProjectCars', Locale[Config.Locale].installsuccess)
			else
				Notify(Locale[Config.Locale].installsuccess)
			end
		end
	end
	UseBusy = false
end

Useitem['engine'] = function(model)
	if UseBusy then return end
	UseBusy = true
	local radius = 8
	local projectcars = GlobalState.ProjectCars or {}
	local dist, data = GetNearestProjectCar()
	install = true
	local vehicle = nil
	CreateThread(function()
		while install do
			Wait(100)
			dist, data = GetNearestProjectCar(projectcars)
			vehicle = getveh() 
		end
		return
	end)
	if inwarehouse then
		SpawnEngine2()
		while install do
			dist, data = GetNearestProjectCar()
			radius = 300
			while install do
				if dist < 4 then
					if not vehicle then vehicle = getveh() end
					local bone = GetEntityBoneIndexByName(vehicle,'engine')
					local coordbone = GetWorldPositionOfEntityBone(vehicle, bone)
					if bone ~= -1 then
						DrawText3Ds(coordbone, '[~b~E~w~] - Prepare Install')
					end
					if IsControlPressed(0,38) then
						Wait(100)
						DeleteEntity(currentobject)
						install = false
						break
					end
				else
					vehicle = nil
				end
				if IsControlPressed(0,73) then
					install = false
					Wait(100)
					break
				end
				dist = #(GetEntityCoords(PlayerPedId()) - data.coord)
				Wait(0)
			end
			Wait(500)
		end
	end
	if data and dist < radius then
		if not Config.MetaInventory or Config.MetaInventory and data.model == model then
			SpawnEngine(true)
			TriggerServerEvent('renzu_projectcars:removeitem','engine',model)
			if Config.RenzuNotify then
				TriggerEvent('renzu_notify:Notify', 'success','ProjectCars', Locale[Config.Locale].installsuccess)
			else
				Notify(Locale[Config.Locale].installsuccess)
			end
		end
	end
	UseBusy = false
end

Interaction = function(type)
	local o = {
        --scenario = 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', -- uncomment this if scenario
        dict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@",
        name = "machinic_loop_mechandplayer",
        flag = 0,
    }
	if Config.EnableInteraction and Config.Interaction == 'progress' then
		local prog = exports.renzu_progressbar:CreateProgressBar(10,'<i class="fas fa-tools"></i>',o)
		return prog
	elseif Config.EnableInteraction and Config.Interaction == 'actionbar' then
		local ret = exports.renzu_lockgame:CreateGame(1,o,true)
		return ret
	elseif not Config.EnableInteraction then
		return true
	end
end

RegisterNetEvent('renzu_projectcars:updateprojectable')
AddEventHandler('renzu_projectcars:updateprojectable', function(plate)
	DeleteEntity(spawnprojectcars[plate] or 0)
	DeleteEntity(spawnprojectshell[plate] or 0)
	if blips[plate] and DoesBlipExist(blips[plate] or 0) then
		RemoveBlip(blips[plate])
	end
end)

RegisterNetEvent('renzu_projectcars:spawnfinishproject')
AddEventHandler('renzu_projectcars:spawnfinishproject', function(data,props)
	local coord = json.decode(data.coord)
	local props = props
	local vehicle = IsAnyVehicleNearPoint(coord.x,coord.y,coord.z,1.1)
	if vehicle then
		if spawnprojectshell[data.plate] and DoesEntityExist(spawnprojectshell[data.plate]) then
			DeleteEntity(spawnprojectshell[data.plate])
		end
		if spawnprojectcars[data.plate] and DoesEntityExist(spawnprojectcars[data.plate]) then
			DeleteEntity(spawnprojectcars[data.plate])
		end
	end
	local hash = props.model
	--local offset = GetOffsetFromEntityInWorldCoords(ped, 0.1, 1.0, 0.1)
	RequestModel(hash)
	while not HasModelLoaded(hash) do
		RequestModel(hash)
		Citizen.Wait(1)
	end
	if GlobalState.GarageInside[PlayerData.identifier] then
		local coord = Config.Garage[1].spawn.coord
		vehicle = CreateVehicle(hash,vector3(coord.x,coord.y,coord.z),coord.w, true, true)
		while not DoesEntityExist(vehicle) do
			Wait(0)
		end
		SetPedIntoVehicle(PlayerPedId(),vehicle,-1)
	else
		vehicle = CreateVehicle(hash,vector3(coord.x,coord.y,coord.z),coord.w, true, true)
	end
	SetVehicleOnGroundProperly(vehicle)
	SetVehicleNumberPlateText(vehicle,props.plate)
	SetVehicleProp(vehicle,props)
	TriggerEvent(Config.KeySystemEvent, GetVehicleNumberPlateText(vehicle))
end)

RegisterNetEvent('renzu_projectcars:updatelocalproject')
AddEventHandler('renzu_projectcars:updatelocalproject', function(data)
	local coord = json.decode(data.coord)
	local vehicle = IsAnyVehicleNearPoint(coord.x,coord.y,coord.z,1.1)
	if vehicle then
		local data = {
			status = json.decode(data.status),
			coord = vector3(coord.x,coord.y,coord.z),
			heading = coord.w,
			model = data.model,
			plate = data.plate
		}
		UpdateProjectcar(data)
	end
	success = true
	Wait(3000)
	success = false
end)

RegisterNetEvent('renzu_projectcars:spawnnewproject')
AddEventHandler('renzu_projectcars:spawnnewproject', function(model)
    DoScreenFadeIn(100)
	local ped = PlayerPedId()
	--
	--SetFocusPosAndVel(233.95951843262,-752.58807373047,35.046501159668, 0.00, 0.00, 0.00) -- garage legion square
	local hash = GetHashKey(model)
	--local offset = GetOffsetFromEntityInWorldCoords(ped, 0.1, 1.0, 0.1)
	RequestModel(hash)
	while not HasModelLoaded(hash) do
		RequestModel(hash)
		Citizen.Wait(1)
	end
	local spawn = GetEntityCoords(PlayerPedId())+vec3(0,5.0,0)
	if inwarehouse then
		spawn = Config.BuilderJobs[inwarehouse].spawn
	end
	local appliance = CreateObject(hash,spawn, false, true)
	while not DoesEntityExist(appliance) do Wait(0) end
	local moveSpeed = 0.001
	SetEntityHeading(prop, 200.0)
	PlaceObjectOnGroundProperly(appliance)
	FreezeEntityPosition(appliance, true)
	SetEntityAlpha(appliance, 200, true)
	spawnedcar = appliance
	--SetFocusPosAndVel(GetEntityCoords(PlayerPedId()), 0.00, 0.00, 0.00)

	local t = {
		['key'] = 'F', -- key
		['event'] = 'renzu_projectcars:dummy',
		['title'] = '<span style="font-size:12px;">[<span style="color:lime">NUM4</span>] - Left [<span style="color:lime">NUM6</span>] - right <br> [<span style="color:lime">NUM5</span>] - Forward [<span style="color:lime">NUM8</span>] - Downward <br> [<span style="color:lime">Mouse Scroll</span>] - Height [<span style="color:lime">CAPS</span>] - Speed <br></span>',
		['server_event'] = false, -- server event or client
		['unpack_arg'] = false, -- send args as unpack 1,2,3,4 order
		['fa'] = '<i class="fas fa-gamepad-alt"></i>',
		['custom_arg'] = {}, -- example: {1,2,3,4}
	}
	TriggerEvent('renzu_popui:drawtextuiwithinput',t)
	while spawnedcar ~= nil do
		Citizen.Wait(1)
		--HelpText1(Config.Strings.frnHelp1)
		--HelpText2(Config.Strings.frnHelp2)
		DisableControlAction(0, 51)
		DisableControlAction(0, 96)
		DisableControlAction(0, 97)
		for i = 108, 112 do
			DisableControlAction(0, i)
		end
		DisableControlAction(0, 117)
		DisableControlAction(0, 118)
		DisableControlAction(0, 171)
		DisableControlAction(0, 254)
		if IsDisabledControlPressed(0, 171) then -- caps
			moveSpeed = moveSpeed + 0.001
		end
		if IsDisabledControlPressed(0, 254) then -- L shift
			moveSpeed = moveSpeed - 0.001
		end
		if moveSpeed > 1.0 or moveSpeed < 0.001 then
			moveSpeed = 0.001
		end
		HudWeaponWheelIgnoreSelection()
		for i = 123, 128 do
			DisableControlAction(0, i)
		end
		DrawMarker(36, GetEntityCoords(spawnedcar)+vec3(0,0.0,1.5), 0, 0, 0, 0, 0, 0.0, 0.7, 0.7, 0.7, 200, 255, 255, 255, 0, 0, 1, 1, 0, 0, 0)
		if IsDisabledControlJustPressed(0, 51) then
			FreezeEntityPosition(spawnedcar,true)
			SetEntityAlpha(spawnedcar,255,true)
			TriggerServerCallback_("renzu_projectcars:GenPlate",function(plate)
				local coord = GetEntityCoords(spawnedcar)
				local heading = GetEntityHeading(spawnedcar)
				DeleteEntity(spawnedcar)
				vehicle = CreateVehicle(hash,coord,heading, false, true)
				SetEntityCompletelyDisableCollision(vehicle,false,false)
				shell = CreateObject(hash,coord, false, true)
				SetEntityHeading(shell,heading)
				SetEntityCompletelyDisableCollision(shell,true,false)
				SetEntityCanBeDamaged(shell,false)
				SetEntityInvincible(shell,true)
				SetEntityAlpha(shell,0,false)
				SetVehicleEngineOn(vehicle,false,true,true)
				SetVehicleFuelLevel(vehicle,0.0)
				for i = 0, 7 do
					SetVehicleWheelTireColliderSize(vehicle, i, -5.0)
					SetVehicleDoorBroken(vehicle, i, true)
				end
				FreezeEntityPosition(vehicle,true)
				FreezeEntityPosition(shell,true)
				SetVehicleOnGroundProperly(vehicle)
				SetVehicleNumberPlateText(vehicle,plate)
				plate = string.gsub(tostring(plate), '^%s*(.-)%s*$', '%1')
				local wheels = {}
				local brakes = {}
				
				for tireid = 0, GetVehicleNumberOfWheels(vehicle) -1 do
					wheels[tireid] = 1
					brakes[tireid] = 1
				end
				local data = {
					plate = plate,
					doors = GetNumberOfVehicleDoors(vehicle),
					seat = GetNumSeat(vehicle),
					trunk = GetEntityBoneIndexByName(vehicle,'boot') ~= -1 and 1 or 0,
					exhaust = GetEntityBoneIndexByName(vehicle,'exhaust') ~= -1 and 1 or 0,
					bonnet = GetEntityBoneIndexByName(vehicle,'bonnet') ~= -1 and 1 or 0,
					wheel = wheels,
					brake = brakes,
					model = model,
					coord = coord,
					heading = heading,
					paint = table.pack(GetVehicleCustomPrimaryColour(vehicle))
				}
				TriggerServerEvent('renzu_projectcars:newproject',data)
				spawnprojectcars[plate] = vehicle
				spawnprojectshell[plate] = shell
				TriggerEvent('renzu_popui:closeui')
			end)
			break
		end
		if IsDisabledControlPressed(0, 96) then -- wheel scroll
			SetEntityCoords(spawnedcar, GetOffsetFromEntityInWorldCoords(spawnedcar, 0.0, 0.0, moveSpeed))
		end
		if IsDisabledControlPressed(0, 97) then -- wheel scroll
			SetEntityCoords(spawnedcar, GetOffsetFromEntityInWorldCoords(spawnedcar, 0.0, 0.0, -moveSpeed))
		end
		if IsDisabledControlPressed(0, 108) then -- num4
			SetEntityHeading(spawnedcar, GetEntityHeading(spawnedcar) + 0.5)
		end
		if IsDisabledControlPressed(0, 109) then -- num6
			SetEntityHeading(spawnedcar, GetEntityHeading(spawnedcar) - 0.5)
		end
		if IsDisabledControlPressed(0, 111) then
			SetEntityCoords(spawnedcar, GetOffsetFromEntityInWorldCoords(spawnedcar, 0.0, -moveSpeed, 0.0))
		end
		if IsDisabledControlPressed(0, 110) then
			SetEntityCoords(spawnedcar, GetOffsetFromEntityInWorldCoords(spawnedcar, 0.0, moveSpeed, 0.0))
		end
		if IsDisabledControlPressed(0, 117) then
			SetEntityCoords(spawnedcar, GetOffsetFromEntityInWorldCoords(spawnedcar, moveSpeed, 0.0, 0.0))
		end
		if IsDisabledControlPressed(0, 118) then
			SetEntityCoords(spawnedcar, GetOffsetFromEntityInWorldCoords(spawnedcar, -moveSpeed, 0.0, 0.0))
		end
	end
end)

GetNumSeat = function(vehicle)
    local c = 0
    for i=0-1, 7 do
        if IsVehicleSeatFree(vehicle,i) then
            c = c + 1
        end
    end
    return c
end

SetOwned = function(vehicle)
    local attempt = 0
	if NetworkHasControlOfEntity(vehicle) then return end
    SetEntityAsMissionEntity(vehicle,true,true)
    NetworkRequestControlOfEntity(vehicle)
    while not NetworkHasControlOfEntity(vehicle) and attempt < 500 and DoesEntityExist(vehicle) do
        NetworkRequestControlOfEntity(vehicle)
        Citizen.Wait(0)
        attempt = attempt + 1
    end
end

local nuiopen = false
local near = false

GetNearestProjectCar = function(projectcar)
	local projectcars = projectcar or GlobalState.ProjectCars
	local nearestdist,data = -1, nil
	for k,v in pairs(projectcars) do
		local coord = json.decode(v.coord)
		local t = {
			status = json.decode(v.status),
			coord = vector3(coord.x,coord.y,coord.z),
			heading = coord.w,
			model = v.model,
			paint = v.paint,
			plate = v.plate
		}
		local dist = #(GetEntityCoords(PlayerPedId()) - vector3(coord.x,coord.y,coord.z))
		if nearestdist == -1 and dist < 300 or nearestdist >= dist then
			nearestdist = dist
			data = t
		end
	end
	return nearestdist,data
end

local inground = {}
SpawnProjectCars = function(projectcars)
	--success = false
	local mycoord = GetEntityCoords(PlayerPedId())
	local nearest, datas = -1, nil
	for k,v in pairs(projectcars) do
		local coord = json.decode(v.coord)
		local data = {
			status = json.decode(v.status),
			coord = vector3(coord.x,coord.y,coord.z),
			heading = coord.w,
			model = v.model,
			paint = v.paint,
			plate = v.plate
		}
		local dis = #(mycoord - vector3(coord.x,coord.y,coord.z))
		if v.identifier == PlayerData.identifier then
			VehicleBlip({model = data.model, coord = vector3(coord.x,coord.y,coord.z), plate = data.plate})
		end
		if dis < 50 then
			if not spawnprojectcars[data.plate] then
				SpawnNewProject(data)
			else
				local status = data.status
				for i = 0, 3 do
					local i = tonumber(i)
					
					local paint = json.decode(data.paint or '[]') or {}
					--SetVehicleStrong(spawnprojectcars[data.plate],true)
					if paint and data.status['paint'] == 0 then
						SetVehicleColours(spawnprojectcars[data.plate],0,0)
						SetVehicleExtraColours(vehicle,0,0)
						SetVehicleDirtLevel(spawnprojectcars[data.plate], 0.0)
						SetVehicleRudderBroken(spawnprojectcars[data.plate],false)
						SetVehicleEnveffScale(spawnprojectcars[data.plate],0.0)
						SetVehicleCustomPrimaryColour(spawnprojectcars[data.plate], paint['1'], paint['2'], paint['3'])
					else
						SetVehicleColours(spawnprojectcars[data.plate],117,117)
						SetVehicleDirtLevel(spawnprojectcars[data.plate], 15.0)
						SetVehicleRudderBroken(spawnprojectcars[data.plate],true)
						SetVehicleEnveffScale(spawnprojectcars[data.plate],1.0)
					end
					if not inground[data.plate] then
						SetVehicleOnGroundProperly(spawnprojectcars[data.plate])
						inground[data.plate] = true
					end
					SetEntityCompletelyDisableCollision(spawnprojectcars[data.plate],false,false)
					--
					SetVehicleWheelTireColliderSize(spawnprojectcars[data.plate],i,0.4)
					--
					if status.wheel[tostring(i)] and status.wheel[tostring(i)] >= 1 then
						SetVehicleWheelTireColliderSize(spawnprojectcars[data.plate], i, -5.0)
					end
				end
			end
		else
			near = false
			if spawnprojectcars[data.plate] then
				DeleteEntity(spawnprojectcars[data.plate])
				spawnprojectcars[data.plate] = nil
				DeleteEntity(spawnprojectshell[data.plate])
				spawnprojectshell[data.plate] = nil
			end
		end
		if nearest == -1 and dis < 10 or nearest >= dis then
			nearest = dis
			datas = data
		end
	end
	local dis, data = nearest, datas
	if data then
		SetOwned(spawnprojectcars[data.plate])
		local status = data.status
		if dis < 3 then
			SetVehicleFuelLevel(spawnprojectcars[data.plate],0.0)
			nuiopen = true
			near = true
			SendNUIMessage({show = true,type = "project_status", status = data.status, info = Config.Vehicles[data.model]})
			while not success and dis < 10 do Wait(100) dis = #(GetEntityCoords(PlayerPedId()) - datas.coord) if not IsPedStopped(PlayerPedId()) then Wait(2000) if not IsPedStopped(PlayerPedId()) then break end end end
			nuiopen = false
			Wait(100)
			SendNUIMessage({show = false,type = "project_status", status = data.status, info = Config.Vehicles[data.model]})
		end
	end
end

UpdateProjectcar = function(data,netid)
	local status = data.status
	
	local vehicle = spawnprojectcars[data.plate] or getveh()
	
	SetVehicleFixed(vehicle)
	for i = 0, 7 do
		if status.door[tostring(i)] and status.door[tostring(i)] ~= 0 then
			SetVehicleDoorBroken(vehicle, i, true)
		end
		if i == 4 and status.bonnet ~= 0 then
			SetVehicleDoorBroken(vehicle, i, true)
		end
		if i == 5 and status.trunk ~= 0 then
			SetVehicleDoorBroken(vehicle, i, true)
		end
	end
	for i = 0, 3 do
		local i = tonumber(i)
		SetVehicleWheelTireColliderSize(vehicle,i,0.4)
		--
		if status.wheel[tostring(i)] and status.wheel[tostring(i)] >= 1 then
			SetVehicleWheelTireColliderSize(vehicle, i, -5.0)
			
		end
	end
end

SpawnNewProject = function(data)
	local hash = GetHashKey(data.model)
	if not HasModelLoaded(hash) then
		RequestModel(hash)
		while not HasModelLoaded(hash) do
			RequestModel(hash)
			Citizen.Wait(1)
		end
	end
	local status = data.status
	vehicle = CreateVehicle(hash,vector3(data.coord.x,data.coord.y,data.coord.z+0.7),data.heading, false, true)
	SetEntityCompletelyDisableCollision(vehicle,false,false)
	shell = CreateObject(hash,vector3(data.coord.x,data.coord.y,data.coord.z+0.7), false, true)
	SetEntityHeading(shell,GetEntityHeading(vehicle))
	SetEntityNoCollisionEntity(shell,vehicle,false)
	SetEntityCompletelyDisableCollision(shell,true,false)
	SetVehicleOnGroundProperly(vehicle)
	FreezeEntityPosition(vehicle,true)
	FreezeEntityPosition(shell,true)
	SetEntityCanBeDamaged(shell,false)
	SetEntityInvincible(shell,true)
	SetEntityAlpha(shell,0,false)
	SetVehicleEngineOn(vehicle,false,true,true)
	SetVehicleFuelLevel(vehicle,0.0)
	for i = 0, 7 do
		if status == nil or status.door[tostring(i)] and status.door[tostring(i)] ~= 0 then
			SetVehicleDoorBroken(vehicle, i, true)
		end
		if i == 4 and status.bonnet ~= 0 then
			SetVehicleDoorBroken(vehicle, i, true)
		end
		if i == 5 and status.trunk ~= 0 then
			SetVehicleDoorBroken(vehicle, i, true)
		end
	end
	for i = 0, 3 do
		local i = tonumber(i)
		SetVehicleWheelTireColliderSize(vehicle,i,0.4)
		--
		if status.wheel[tostring(i)] and status.wheel[tostring(i)] >= 1 then
			SetVehicleWheelTireColliderSize(vehicle, i, -5.0)
			
		end
	end
	local paint = json.decode(data.paint or '[]') or {}
	if paint and status['paint'] == 0 then
		SetVehicleCustomPrimaryColour(vehicle, paint['1'], paint['2'], paint['3'])
	else
		SetVehicleColours(vehicle,13,13)
		SetVehicleDirtLevel(vehicle, 15.0)
		SetVehicleRudderBroken(vehicle,true)
		SetVehicleEnveffScale(vehicle,1.0)
	end
	--SetVehicleOnGroundProperly(vehicle)
	SetVehicleNumberPlateText(vehicle,data.plate)
	spawnprojectcars[data.plate] = vehicle
	spawnprojectshell[data.plate] = shell
	return vehicle
end

SpawnSeat = function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    PreloadAnimation("anim@heists@box_carry@")
    TaskPlayAnim(ped, "anim@heists@box_carry@" ,"idle", 5.0, -1, -1, 50, 0, false, false, false)
    currentobject = CreateObject(GetHashKey('prop_car_seat'), coords.x, coords.y, coords.z,  true,  true, true)
    AttachEntityToEntity(currentobject, ped, GetPedBoneIndex(ped, 56604), 0.1, 0.40, -0.65, 0.0, 0.0, 180.0, true, true, false, true, 1, true)
end

SpawnDoor = function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    PreloadAnimation("anim@heists@box_carry@")
    TaskPlayAnim(ped, "anim@heists@box_carry@" ,"idle", 5.0, -1, -1, 50, 0, false, false, false)
    currentobject = CreateObject(GetHashKey('prop_car_door_01'), coords.x, coords.y, coords.z,  true,  true, true)
    AttachEntityToEntity(currentobject, ped, GetPedBoneIndex(ped, 56604), 0.1, 0.40, -0.65, 0.0, 0.0, 180.0, true, true, false, true, 1, true)
end

SetVehicleUpdate = function(type,index)
	local index = tonumber(index)
	local vehicle = getveh()
	local projectcars = GlobalState.ProjectCars
	plate = string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1')
	if projectcars[plate] then
		local status = json.decode(projectcars[plate].status)
		local bonnet = status.bonnet
		local trunk = status.trunk
		local doors = status.door
		local seat = status.seat
		local wheel = status.wheel
		local brake = status.brake
		local engine = status.engine
		local tranny = status.transmition
		local exhaust = status.exhaust
		local paint = status.paint
		SetVehicleFixed(vehicle)
		if type == 'wheel' then
			wheel[tostring(index)] = 0
			for i = 0, 3 do
				local i = tonumber(i)
				
				SetVehicleWheelTireColliderSize(vehicle,i,0.4)
				--
				if wheel[tostring(i)] and wheel[tostring(i)] >= 1 then
					if i == index then
						
						wheel[tostring(i)] = wheel[tostring(i)] - 1
					end
					if i ~= index then
						SetVehicleWheelTireColliderSize(vehicle, i, -5.0)
						
					end
				end
			end
		end
		
		if type == 'door' then
			doors[tostring(index)] = 0
			for i = 0, 7 do
				local i = tonumber(i)
				if status.door[tostring(i)] and status.door[tostring(i)] >= 1 then
					if i == index then
						status.door[tostring(i)] = status.door[tostring(i)] - 1
					end
					if i ~= index then
						SetVehicleDoorBroken(vehicle, i, true)
						
					end
				end
			end
		end
		
		if type == 'bonnet' then
			bonnet = 0
		elseif type == 'bonnet' and bonnet == 1 then
			SetVehicleDoorBroken(vehicle, 4, true)		
		end
		if type == 'trunk' then
			trunk = 0
		elseif type == 'trunk' and trunk == 1 then
			SetVehicleDoorBroken(vehicle, 5, true)	
		end
		if type == 'seat' then
			seat[tostring(index)] = 0
		end
		if type == 'brake' then
			brake[tostring(index)] = 0
		end
		if type == 'engine' then
			engine = 0
		end
		if type == 'transmition' then
			tranny = 0
		end
		if type == 'exhaust' then
			exhaust = 0
		end
		local props = GetVehicleProperties(vehicle)
		if type == 'paint' then
			paint = 0
			projectcars[plate].paint = json.encode(props.rgb)
		end

		status.wheel = wheel
		status.bonnet = bonnet
		status.trunk = trunk
		status.door = doors
		status.seat = seat
		status.brake = brake
		status.engine = engine
		status.transmition = tranny
		status.exhaust = exhaust
		status.paint = paint
		projectcars[plate].status = json.encode(status)
		TriggerServerEvent('renzu_projectcars:updateprojectcars',projectcars,plate,props)
	end
end

InstallDoor = function()
    local ped = PlayerPedId()
	local nearestdoor = 10
	success = false
	local projectcars = GlobalState.ProjectCars
	local vehicle = getveh()
	plate = string.gsub(tostring(GetVehicleNumberPlateText(vehicle)), '^%s*(.-)%s*$', '%1')
	local status = json.decode(projectcars[plate].status)
	local seat = status.seat
	local door = status.door
	local reason = 'far'
	local dist = -1
	for i = 0, 7 do
		local doors = GetEntryPositionOfDoor(vehicle,i)
		
		if doors.x ~= 0.0 then
			local dis = #(GetEntityCoords(PlayerPedId()) - doors)
			if dist == -1 and door[tostring(i)] and door[tostring(i)] > 0 and dist < 4 or dist >= dis and door[tostring(i)] and door[tostring(i)] > 0 then
				dist = dis
				nearestdoor = i
			end
		end
	end
	if seat[tostring(nearestdoor-1)] and seat[tostring(nearestdoor-1)] <= 0 and door[tostring(nearestdoor)] > 0 and dist < 3 then
		success = true
	elseif seat[tostring(nearestdoor-1)] and seat[tostring(nearestdoor-1)] > 0 and door[tostring(nearestdoor)] > 0 then
		reason = 'seat'
		success = false
	elseif seat[tostring(nearestdoor-1)] <= 0 and door[tostring(nearestdoor)] <= 0 then
		reason = 'alreadyinstall'
		--break
	end
	if success then
		
		SetVehicleUpdate('door',nearestdoor)
	elseif reason == 'seat' then
		if Config.RenzuNotify then
			TriggerEvent('renzu_notify:Notify', 'error','ProjectCars', Locale[Config.Locale].install_seat)
		else
			Notify(Locale[Config.Locale].install_seat)
		end
	elseif reason == 'alreadyinstall' then
		if Config.RenzuNotify then
			TriggerEvent('renzu_notify:Notify', 'error','ProjectCars', Locale[Config.Locale].already_install)
		else
			Notify(Locale[Config.Locale].already_install)
		end
	else
		if Config.RenzuNotify then
			TriggerEvent('renzu_notify:Notify', 'error','ProjectCars', Locale[Config.Locale].far_away)
		else
			Notify(Locale[Config.Locale].far_away)
		end
	end
	DeleteObject(currentobject)
	ClearPedTasks(ped)
end

InstallSeat = function()
	
    local ped = PlayerPedId()
	local nearestseat = 10
	success = false
	local projectcars = GlobalState.ProjectCars
	local vehicle = getveh()
	plate = string.gsub(tostring(GetVehicleNumberPlateText(vehicle)), '^%s*(.-)%s*$', '%1')
	local status = json.decode(projectcars[plate].status)
	local seat = status.seat
	local alreadyinstall = false
	local dist = -1
	for i = 0, 4 do
		local doors = GetEntryPositionOfDoor(getveh(),i)
		if doors.x ~= 0.0 then
			local i = i - 1
			local dis = #(GetEntityCoords(PlayerPedId()) - doors)
			if dist == -1 and seat[tostring(i)] and seat[tostring(i)] > 0 and dis < 3 or dist >= dis and seat[tostring(i)] and seat[tostring(i)] > 0 then
				dist = dis
				nearestseat = i
			elseif seat[tostring(i)] and seat[tostring(i)] <= 0 then
				alreadyinstall = true
			end
		end
	end
	
	if seat[tostring(nearestseat)] and seat[tostring(nearestseat)] > 0 and dist < 2 then
		success = true
	elseif seat[tostring(i)] and seat[tostring(i)] <= 0 and dist < 2 then
		alreadyinstall = true
	end
	
	if success then
		
		SetVehicleUpdate('seat',nearestseat)
	elseif alreadyinstall then
		if Config.RenzuNotify then
			TriggerEvent('renzu_notify:Notify', 'error','ProjectCars', Locale[Config.Locale].already_install)
		else
			Notify(Locale[Config.Locale].already_install)
		end
	end
	DeleteObject(currentobject)
	ClearPedTasks(ped)
end

SpawnBonnet = function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    PreloadAnimation("anim@heists@box_carry@")
    TaskPlayAnim(ped, "anim@heists@box_carry@" ,"idle", 5.0, -1, -1, 50, 0, false, false, false)
    currentobject = CreateObject(GetHashKey('imp_prop_impexp_bonnet_02a'), coords.x, coords.y, coords.z,  true,  true, true)
    AttachEntityToEntity(currentobject, ped, GetPedBoneIndex(ped, 56604), 0.0, 0.75, 0.45, 2.0, 0.0, 0.0, true, true, false, true, 1, true)
end

InstallBonnet = function()
    local ped = PlayerPedId()
	local index = tonumber(index)
	local vehicle = getveh()
	success = false
	local bone = GetEntityBoneIndexByName(vehicle,'bonnet')
	
	local projectcars = GlobalState.ProjectCars
	plate = string.gsub(tostring(GetVehicleNumberPlateText(vehicle)), '^%s*(.-)%s*$', '%1')
	local status = json.decode(projectcars[plate].status or '[]') or {}
	local x,y,z = table.unpack(GetWorldPositionOfEntityBone(vehicle, bone))
	
	if vehicle ~= 0 and status.engine == 0 and status.transmition == 0 and #(GetEntityCoords(ped) - vector3(x,y,z)) <= 4.0 then
		SetVehicleUpdate('bonnet',0)
		success = true
	elseif status.engine == 1 then
		if Config.RenzuNotify then
			TriggerEvent('renzu_notify:Notify', 'error','ProjectCars', Locale[Config.Locale].install_engine)
		else
			Notify(Locale[Config.Locale].install_engine)
		end
	elseif status.transmition == 1 then
		if Config.RenzuNotify then
			TriggerEvent('renzu_notify:Notify', 'error','ProjectCars', Locale[Config.Locale].install_tranny)
		else
			Notify(Locale[Config.Locale].install_tranny)
		end
	end
    DeleteObject(bonnet)
    ClearPedTasks(ped)
end

SpawnTrunk = function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    PreloadAnimation("anim@heists@box_carry@")
    TaskPlayAnim(ped, "anim@heists@box_carry@" ,"idle", 5.0, -1, -1, 50, 0, false, false, false)
    currentobject = CreateObject(GetHashKey('imp_prop_impexp_trunk_01a'), coords.x, coords.y, coords.z,  true,  true, true)
    AttachEntityToEntity(currentobject, ped, GetPedBoneIndex(ped, 56604), 0.0, 0.40, 0.1, 0.0, 0.0, 180.0, true, true, false, true, 1, true)
end

InstallTrunk = function()
    local ped = PlayerPedId()
	local vehicle = getveh()
	success = false
	local bone = GetEntityBoneIndexByName(vehicle,'boot')
	local projectcars = GlobalState.ProjectCars
	
	plate = string.gsub(tostring(GetVehicleNumberPlateText(vehicle)), '^%s*(.-)%s*$', '%1')
	local status = json.decode(projectcars[plate].status or '[]') or {}
	local x,y,z = table.unpack(GetWorldPositionOfEntityBone(vehicle, bone))
	
	if vehicle ~= 0 and #(GetEntityCoords(ped) - vector3(x,y,z)) <= 4 then
		
		SetVehicleUpdate('trunk',0)
		success = true
	elseif status.engine == 1 then
		if Config.RenzuNotify then
			TriggerEvent('renzu_notify:Notify', 'error','ProjectCars', Locale[Config.Locale].install_engine)
		else
			Notify(Locale[Config.Locale].install_engine)
		end
	elseif status.transmition == 1 then
		if Config.RenzuNotify then
			TriggerEvent('renzu_notify:Notify', 'error','ProjectCars', Locale[Config.Locale].install_tranny)
		else
			Notify(Locale[Config.Locale].install_tranny)
		end
	end
    DeleteObject(trunk)
    ClearPedTasks(ped)
end

SpawnWheel = function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    PreloadAnimation("anim@heists@box_carry@")
    TaskPlayAnim(ped, "anim@heists@box_carry@" ,"idle", 5.0, -1, -1, 50, 0, false, false, false)
    currentobject = CreateObject(GetHashKey('prop_wheel_01'), coords.x, coords.y, coords.z,  true,  true, true)
    AttachEntityToEntity(currentobject, ped, GetPedBoneIndex(ped, 56604), -0.08, 0.30, 0.37, 0.0, 0.0, 180.0, true, true, false, true, 1, true)
end

SpawnEngine2 = function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    PreloadAnimation("anim@heists@box_carry@")
    TaskPlayAnim(ped, "anim@heists@box_carry@" ,"idle", 5.0, -1, -1, 50, 0, false, false, false)
    currentobject = CreateObject(GetHashKey('prop_car_engine_01'), coords.x, coords.y, coords.z,  true,  true, true)
	AttachEntityToEntity(currentobject, ped, GetPedBoneIndex(ped, 56604), 0.025, 0.0, 0.15, 90.0, 0.0, 180.0, true, true, false, true, 1, true)
end

SpawnTranny = function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    PreloadAnimation("anim@heists@box_carry@")
    TaskPlayAnim(ped, "anim@heists@box_carry@" ,"idle", 5.0, -1, -1, 50, 0, false, false, false)
    currentobject = CreateObject(GetHashKey('imp_prop_impexp_gearbox_01'), coords.x, coords.y, coords.z,  true,  true, true)
    AttachEntityToEntity(currentobject, ped, GetPedBoneIndex(ped, 56604), -0.08, 0.30, 0.37, 0.0, 0.0, 180.0, true, true, false, true, 1, true)
end

SpawnExhaust = function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
	PreloadAnimation("anim@heists@box_carry@")
    TaskPlayAnim(ped, "anim@heists@box_carry@" ,"idle", 5.0, -1, -1, 50, 0, false, false, false)
    currentobject = CreateObject(GetHashKey('imp_prop_impexp_exhaust_01'), coords.x, coords.y, coords.z,  true,  true, true)
    AttachEntityToEntity(currentobject, ped, GetPedBoneIndex(ped, 56604), -0.08, 0.30, 0.37, 0.0, 0.0, 180.0, true, true, false, true, 1, true)
end

InstallExhaust = function()
    local ped = PlayerPedId()
	local vehicle = getveh()
	success = false
	local bone = GetEntityBoneIndexByName(vehicle,'exhaust') ~= -1 or GetEntityBoneIndexByName(vehicle,'boot')
	local projectcars = GlobalState.ProjectCars
	
	plate = string.gsub(tostring(GetVehicleNumberPlateText(vehicle)), '^%s*(.-)%s*$', '%1')
	local status = json.decode(projectcars[plate].status or '[]') or {}
	local x,y,z = table.unpack(GetWorldPositionOfEntityBone(vehicle, bone))
	if vehicle ~= 0 and #(GetEntityCoords(ped) - vector3(x,y,z)) <= 10 then
		
		SetVehicleUpdate('exhaust',0)
		success = true
	else
		if Config.RenzuNotify then
			TriggerEvent('renzu_notify:Notify', 'error','ProjectCars', Locale[Config.Locale].far_away)
		else
			Notify(Locale[Config.Locale].far_away)
		end
	end
    DeleteObject(exhaust)
    ClearPedTasks(ped)
end

SpawnBrake = function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
	PreloadAnimation("anim@heists@box_carry@")
    TaskPlayAnim(ped, "anim@heists@box_carry@" ,"idle", 5.0, -1, -1, 50, 0, false, false, false)
    currentobject = CreateObject(GetHashKey('imp_prop_impexp_brake_caliper_01a'), coords.x, coords.y, coords.z,  true,  true, true)
    AttachEntityToEntity(currentobject, ped, GetPedBoneIndex(ped, 56604), -0.08, 0.30, 0.37, 0.0, 0.0, 180.0, true, true, false, true, 1, true)
end

InstallBrake = function()
	local nearestwheel = 10
    local ped = PlayerPedId()
	local coord = GetEntityCoords(ped)-vec3(0,0,5.0)
	local vehicle = getveh()
	local bones = {
		[0] = 'wheel_lf',
		[1] = 'wheel_rf',
		[2] = 'wheel_lr',
		[3] = 'wheel_rr'
	}
	success = false
	local projectcars = GlobalState.ProjectCars
	plate = string.gsub(tostring(GetVehicleNumberPlateText(vehicle)), '^%s*(.-)%s*$', '%1')
	local status = json.decode(projectcars[plate].status)
	local wheelob = status.wheel
	local brake = status.brake
	local status = false
	local alreadyinstall = false
	local dist = -1
	for k,v in pairs(bones) do
		local wheelworldpos = GetWorldPositionOfEntityBone(vehicle,GetEntityBoneIndexByName(vehicle,v))
		local wheelpos = GetOffsetFromEntityGivenWorldCoords(vehicle, wheelworldpos.x, wheelworldpos.y, wheelworldpos.z)
		
		local wheelcoord = #(coord - wheelworldpos)
		if dist == -1  and wheelcoord < 3 or dist >= wheelcoord then
			nearestwheel = k
			dist = wheelcoord
		end
	end
	
	if dist > -1 and wheelob[tostring(nearestwheel)] and wheelob[tostring(nearestwheel)] >= 0 and brake[tostring(nearestwheel)] and brake[tostring(nearestwheel)] > 0 and dist < 2 then
		status = true
		success = true
	elseif brake[tostring(nearestwheel)] and brake[tostring(nearestwheel)] <= 0 and dist < 2 or dist == -1 then
		alreadyinstall = true
	end
	
	if status then
		SetVehicleUpdate('brake',nearestwheel)
	elseif alreadyinstall then
		if Config.RenzuNotify then
			TriggerEvent('renzu_notify:Notify', 'error','ProjectCars', Locale[Config.Locale].already_install)
		else
			Notify(Locale[Config.Locale].already_install)
		end
	else
		if Config.RenzuNotify then
			TriggerEvent('renzu_notify:Notify', 'error','ProjectCars', Locale[Config.Locale].far_away)
		else
			Notify(Locale[Config.Locale].far_away)
		end
	end
    DeleteObject(wheel)
    ClearPedTasks(ped)
end

InstallWheel = function()
	local nearestwheel = 10
    local ped = PlayerPedId()
	local coord = GetEntityCoords(ped)-vec3(0,0,5.0)
	local vehicle = getveh()
	local bones = {
		[0] = 'wheel_lf',
		[1] = 'wheel_rf',
		[2] = 'wheel_lr',
		[3] = 'wheel_rr'
	}
	local projectcars = GlobalState.ProjectCars
	plate = string.gsub(tostring(GetVehicleNumberPlateText(vehicle)), '^%s*(.-)%s*$', '%1')
	local status = json.decode(projectcars[plate].status)
	local wheelob = status.wheel
	local brake = status.brake
	success = false
	local alreadyinstall = false
	local installbreak = false
	local dist = -1
	for k,v in pairs(bones) do
		local wheelworldpos = GetWorldPositionOfEntityBone(vehicle,GetEntityBoneIndexByName(vehicle,v))
		local wheelpos = GetOffsetFromEntityGivenWorldCoords(vehicle, wheelworldpos.x, wheelworldpos.y, wheelworldpos.z)
		--
		local wheelcoord = #(coord - wheelworldpos)
		
		
		if dist == -1 and wheelob[tostring(k)] and wheelob[tostring(k)] >= 1 and wheelcoord < 3 or dist >= wheelcoord and wheelob[tostring(k)] and wheelob[tostring(k)] >= 1 then
			dist = wheelcoord
			nearestwheel = k
		end
	end
	
	if brake[tostring(nearestwheel)] and brake[tostring(nearestwheel)] <= 0 and wheelob[tostring(nearestwheel)] and wheelob[tostring(nearestwheel)] >= 1 and dist < 2 then
		success = true
	elseif brake[tostring(nearestwheel)] and brake[tostring(nearestwheel)] >= 1 and dist < 2 then
		installbreak = true
	elseif wheelob[tostring(nearestwheel)] and wheelob[tostring(nearestwheel)] <= 0 and dist < 2 then
		alreadyinstall = true
		--break
	elseif wheelob[tostring(nearestwheel)] and wheelob[tostring(nearestwheel)] <= 0 then
		alreadyinstall = true
		--break
	end
	
	if success then
		
		SetVehicleUpdate('wheel',nearestwheel)
	elseif installbreak then
		if Config.RenzuNotify then
			TriggerEvent('renzu_notify:Notify', 'error','ProjectCars', Locale[Config.Locale].install_brake)
		else
			Notify(Locale[Config.Locale].install_brake)
		end
	elseif alreadyinstall then
		if Config.RenzuNotify then
			TriggerEvent('renzu_notify:Notify', 'error','ProjectCars', Locale[Config.Locale].already_install)
		else
			Notify(Locale[Config.Locale].already_install)
		end
	else
		if Config.RenzuNotify then
			TriggerEvent('renzu_notify:Notify', 'error','ProjectCars', Locale[Config.Locale].far_away)
		else
			Notify(Locale[Config.Locale].far_away)
		end
	end
	DeleteObject(wheel)
	ClearPedTasks(ped)
end

standmodel , enginemodel = nil, nil
repairengine = function(plate,engine,reverse)
	vehicle  = getveh()
	local prop_stand = 'prop_engine_hoist'
	local prop_engine = 'prop_car_engine_01'
	if not engine then
		prop_engine = 'imp_prop_impexp_gearbox_01'
	end
	--
	Citizen.Wait(200)
	local bone = GetEntityBoneIndexByName(vehicle ,'bonnet')
	local d1,d2 = GetModelDimensions(GetEntityModel(vehicle ))
	local stand = GetOffsetFromEntityInWorldCoords(vehicle , 0.0,d2.y+0.4,0.0)
	local obj = nil

	local veh_heading = GetEntityHeading(vehicle )
	local veh_coord = GetEntityCoords(vehicle ,false)
	local x,y,z = table.unpack(GetWorldPositionOfEntityBone(vehicle , bone))
	local coordf = veh_coord + GetEntityForwardVector(vehicle ) * 3.0
	standmodel = CreateObject(GetHashKey(prop_stand),coordf,true,true,true)
	obj = standmodel
	standprop = obj
	SetEntityAsMissionEntity(obj, true, true)
	SetEntityCompletelyDisableCollision(obj,true,false)
	SetEntityNoCollisionEntity(vehicle , obj, false)
	SetEntityHeading(obj, GetEntityHeading(vehicle ))
	PlaceObjectOnGroundProperly(obj)
	FreezeEntityPosition(obj, true)
	SetEntityCollision(obj, false, true)
	while not DoesEntityExist(obj) do
		Citizen.Wait(100)
	end
	local d21 = GetModelDimensions(GetEntityModel(obj))
	local stand = GetOffsetFromEntityInWorldCoords(obj, 0.0,d21.y+0.2,0.0)
	Citizen.Wait(500)
	local engine_r = GetEntityBoneRotation(vehicle , bone)
	local z = 1.45
	if reverse then
		z = 0.0
	end
	enginemodel = CreateObject(GetHashKey(prop_engine),stand.x+0.27,stand.y-0.2,stand.z+z,true,true,true)
	SetEntityCompletelyDisableCollision(enginemodel,true,false)
	AttachEntityToEntity(enginemodel,vehicle ,GetEntityBoneIndexByName(vehicle ,'neon_f'),0.0,-0.45,z,0.0,90.0,0.0,true,false,false,false,70,true)
	--AttachEntityToEntity(enginemodel,vehicle ,bone,0.0,0.0,0.0,0.0,0.0,0.0,false,false,false,false,1,false)
	carryModel2 = enginemodel
	engineprop = carryModel2
	SetEntityAsMissionEntity(engineprop, true, true)
	FreezeEntityPosition(carryModel2, true)
end

playanimation = function(animDict,name)
	RequestAnimDict(animDict)
	while not HasAnimDictLoaded(animDict) do 
		Wait(1)
		RequestAnimDict(animDict)
	end
	TaskPlayAnim(PlayerPedId(), animDict, name, 2.0, 2.0, -1, 47, 0, 0, 0, 0)
end

SpawnEngine = function(engine,reverse)
	success = false
	local vehicle = getveh()
	local ped = PlayerPedId()
	local bone = GetEntityBoneIndexByName(vehicle,'bonnet')
	if bone == -1 then
		bone = GetEntityBoneIndexByName(vehicle,'engine')
	end
	if bone == -1 then
		bone = GetEntityBoneIndexByName(vehicle,'wheel_rf')
	end
	local x,y,z = table.unpack(GetWorldPositionOfEntityBone(vehicle, bone))
	if vehicle ~= 0 and #(GetEntityCoords(ped) - vector3(x,y,z)) <= 10 then
		busy_install = true
		--SetVehicleFixed(vehicle)
		plate = tostring(GetVehicleNumberPlateText(vehicle))
		Citizen.Wait(2000)
		playanimation('creatures@rottweiler@tricks@','petting_franklin')
		Wait(2500)
		ClearPedTasks(ped)
		Wait(200)
		installing = true
		if installing then
			repairengine(plate,engine,reverse)
		end
		engine_c = GetOffsetFromEntityInWorldCoords(enginemodel)
		standProp = GetOffsetFromEntityInWorldCoords(standmodel)
		local count = 25
		DetachEntity(enginemodel)
		while installing do
			DrawText3Ds(standProp+vec3(0.0,0.0,2.0), 'Press ⬆️ - ⬇️ to Pull') 
			if IsControlJustReleased(1, 173) then
				SetEntityCoords(enginemodel,engine_c.x,engine_c.y,engine_c.z - 0.05)
				engine_c = GetOffsetFromEntityInWorldCoords(enginemodel)
				count = not reverse and count - 1 or count + 1
			end
			if IsControlJustReleased(1, 172) then
				SetEntityCoords(enginemodel,engine_c.x,engine_c.y,engine_c.z + 0.05)
				engine_c = GetOffsetFromEntityInWorldCoords(enginemodel)
				count = not reverse and count + 1 or count - 1
			end
			if count <= 0 then
				installing = false
				busy_install = false
				break
			end
			Wait(0)
		end

		playanimation('creatures@rottweiler@tricks@','petting_franklin')
		Wait(10000)
		busy_install = false
		installing = false
		DeleteEntity(enginemodel)
		DeleteEntity(standmodel)
		ClearPedTasks(ped)
		if not reverse then
			SetVehicleUpdate(engine and 'engine' or 'transmition',0)
		end
		success = true
	else
		success = false
		if Config.RenzuNotify then
			TriggerEvent('renzu_notify:Notify', 'error','ProjectCars', Locale[Config.Locale].far_away)
		else
			Notify(Locale[Config.Locale].far_away)
		end
	end
end

PreloadAnimation = function(dick)
	RequestAnimDict(dick)
    while not HasAnimDictLoaded(dick) do
        Citizen.Wait(0)
    end
end

getveh = function()
    local ped = PlayerPedId()
	local v = GetVehiclePedIsIn(PlayerPedId(), false)
	lastveh = GetVehiclePedIsIn(PlayerPedId(), true)
	local mycoord = GetEntityCoords(ped)
	local dis = -1
	if v == 0 then
		if #(mycoord - GetEntityCoords(lastveh)) < 5 then
			v = lastveh
		end
		dis = #(mycoord - GetEntityCoords(lastveh))
	end
	if dis > 3 then
		v = 0
	end
	if v == 0 then
		local count = 5
		v = GetClosestVehicle(mycoord, 8.000, 0, 70)
		while #(mycoord - GetEntityCoords(v)) > 10 and count >= 0 do
			v = GetClosestVehicle(mycoord,8.000, 0, 70)
			count = count - 1
			Wait(1)
		end
        if v == 0 then
            local temp = {}
            for k,v in pairs(GetGamePool('CVehicle')) do
                local dist = #(mycoord - GetEntityCoords(v))
                temp[k] = {}
                temp[k].dist = dist
                temp[k].entity = v
            end
            local dist = -1
            local nearestveh = nil
            for k,v in pairs(temp) do
                if dist == -1 or dist > v.dist then
                    dist = v.dist
                    nearestveh = v.entity
                end
            end
            v = nearestveh
        end
	end
	return tonumber(v)
end

GetVehicleProperties = function(vehicle)
    if DoesEntityExist(vehicle) then
        -- https://github.com/esx-framework/es_extended/tree/v1-final COPYRIGHT
        if DoesEntityExist(vehicle) then
            local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
            local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
            local extras = {}
            for extraId=0, 12 do
                if DoesExtraExist(vehicle, extraId) then
                    local state = IsVehicleExtraTurnedOn(vehicle, extraId) == 1
                    extras[tostring(extraId)] = state
                end
            end
            local plate = GetVehicleNumberPlateText(vehicle)
			plate = string.gsub(tostring(GetVehicleNumberPlateText(vehicle)), '^%s*(.-)%s*$', '%1')
            local modlivery = GetVehicleLivery(vehicle)
            if modlivery == -1 then
                modlivery = GetVehicleMod(vehicle, 48)
            end
            return {
                model             = GetEntityModel(vehicle),
                plate             = plate,
                plateIndex        = GetVehicleNumberPlateTextIndex(vehicle),

                bodyHealth        = MathRound(GetVehicleBodyHealth(vehicle), 1),
                engineHealth      = MathRound(GetVehicleEngineHealth(vehicle), 1),
                tankHealth        = MathRound(GetVehiclePetrolTankHealth(vehicle), 1),

                fuelLevel         = MathRound(GetVehicleFuelLevel(vehicle), 1),
                dirtLevel         = MathRound(GetVehicleDirtLevel(vehicle), 1),
                color1            = colorPrimary,
                color2            = colorSecondary,
                rgb				  = table.pack(GetVehicleCustomPrimaryColour(vehicle)),
                rgb2				  = table.pack(GetVehicleCustomSecondaryColour(vehicle)),
                pearlescentColor  = pearlescentColor,
                wheelColor        = wheelColor,

                wheels            = GetVehicleWheelType(vehicle),
                windowTint        = GetVehicleWindowTint(vehicle),
                xenonColor        = GetVehicleXenonLightsColour(vehicle),

                neonEnabled       = {
                    IsVehicleNeonLightEnabled(vehicle, 0),
                    IsVehicleNeonLightEnabled(vehicle, 1),
                    IsVehicleNeonLightEnabled(vehicle, 2),
                    IsVehicleNeonLightEnabled(vehicle, 3)
                },

                neonColor         = table.pack(GetVehicleNeonLightsColour(vehicle)),
                extras            = extras,
                tyreSmokeColor    = table.pack(GetVehicleTyreSmokeColor(vehicle)),

                modSpoilers       = GetVehicleMod(vehicle, 0),
                modFrontBumper    = GetVehicleMod(vehicle, 1),
                modRearBumper     = GetVehicleMod(vehicle, 2),
                modSideSkirt      = GetVehicleMod(vehicle, 3),
                modExhaust        = GetVehicleMod(vehicle, 4),
                modFrame          = GetVehicleMod(vehicle, 5),
                modGrille         = GetVehicleMod(vehicle, 6),
                modHood           = GetVehicleMod(vehicle, 7),
                modFender         = GetVehicleMod(vehicle, 8),
                modRightFender    = GetVehicleMod(vehicle, 9),
                modRoof           = GetVehicleMod(vehicle, 10),

                modEngine         = GetVehicleMod(vehicle, 11),
                modBrakes         = GetVehicleMod(vehicle, 12),
                modTransmission   = GetVehicleMod(vehicle, 13),
                modHorns          = GetVehicleMod(vehicle, 14),
                modSuspension     = GetVehicleMod(vehicle, 15),
                modArmor          = GetVehicleMod(vehicle, 16),

                modTurbo          = IsToggleModOn(vehicle, 18),
                modSmokeEnabled   = IsToggleModOn(vehicle, 20),
                modXenon          = IsToggleModOn(vehicle, 22),

                modFrontWheels    = GetVehicleMod(vehicle, 23),
                modBackWheels     = GetVehicleMod(vehicle, 24),

                modPlateHolder    = GetVehicleMod(vehicle, 25),
                modVanityPlate    = GetVehicleMod(vehicle, 26),
                modTrimA          = GetVehicleMod(vehicle, 27),
                modOrnaments      = GetVehicleMod(vehicle, 28),
                modDashboard      = GetVehicleMod(vehicle, 29),
                modDial           = GetVehicleMod(vehicle, 30),
                modDoorSpeaker    = GetVehicleMod(vehicle, 31),
                modSeats          = GetVehicleMod(vehicle, 32),
                modSteeringWheel  = GetVehicleMod(vehicle, 33),
                modShifterLeavers = GetVehicleMod(vehicle, 34),
                modAPlate         = GetVehicleMod(vehicle, 35),
                modSpeakers       = GetVehicleMod(vehicle, 36),
                modTrunk          = GetVehicleMod(vehicle, 37),
                modHydrolic       = GetVehicleMod(vehicle, 38),
                modEngineBlock    = GetVehicleMod(vehicle, 39),
                modAirFilter      = GetVehicleMod(vehicle, 40),
                modStruts         = GetVehicleMod(vehicle, 41),
                modArchCover      = GetVehicleMod(vehicle, 42),
                modAerials        = GetVehicleMod(vehicle, 43),
                modTrimB          = GetVehicleMod(vehicle, 44),
                modTank           = GetVehicleMod(vehicle, 45),
                modWindows        = GetVehicleMod(vehicle, 46),
                modLivery         = modlivery
            }
        else
            return
        end
    end
end

SetVehicleProp = function(vehicle, props)
    -- https://github.com/esx-framework/es_extended/tree/v1-final COPYRIGHT
    if DoesEntityExist(vehicle) then
		local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
		local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
		SetVehicleModKit(vehicle, 0)
		if props.sound then ForceVehicleEngineAudio(vehicle, props.sound) end
		if props.plate then SetVehicleNumberPlateText(vehicle, props.plate) end
		if props.plateIndex then SetVehicleNumberPlateTextIndex(vehicle, props.plateIndex) end
		if props.bodyHealth then SetVehicleBodyHealth(vehicle, props.bodyHealth + 0.0) end
		if props.engineHealth then SetVehicleEngineHealth(vehicle, props.engineHealth + 0.0) end
		if props.tankHealth then SetVehiclePetrolTankHealth(vehicle, props.tankHealth + 0.0) end
		if props.dirtLevel then SetVehicleDirtLevel(vehicle, props.dirtLevel + 0.0) end
		if props.rgb then SetVehicleCustomPrimaryColour(vehicle, props.rgb[1], props.rgb[2], props.rgb[3]) end
		if props.rgb2 then SetVehicleCustomSecondaryColour(vehicle, props.rgb2[1], props.rgb2[2], props.rgb2[3]) end
		if props.color1 then SetVehicleColours(vehicle, props.color1, colorSecondary) end
		if props.color2 then SetVehicleColours(vehicle, props.color1 or colorPrimary, props.color2) end
		if props.pearlescentColor then SetVehicleExtraColours(vehicle, props.pearlescentColor, wheelColor) end
		if props.wheelColor then SetVehicleExtraColours(vehicle, props.pearlescentColor or pearlescentColor, props.wheelColor) end
		if props.wheels then SetVehicleWheelType(vehicle, props.wheels) end
		if props.windowTint then SetVehicleWindowTint(vehicle, props.windowTint) end

		if props.neonEnabled then
			SetVehicleNeonLightEnabled(vehicle, 0, props.neonEnabled[1])
			SetVehicleNeonLightEnabled(vehicle, 1, props.neonEnabled[2])
			SetVehicleNeonLightEnabled(vehicle, 2, props.neonEnabled[3])
			SetVehicleNeonLightEnabled(vehicle, 3, props.neonEnabled[4])
		end

		if props.extras then
			for extraId,enabled in pairs(props.extras) do
				if enabled then
					SetVehicleExtra(vehicle, tonumber(extraId), 0)
				else
					SetVehicleExtra(vehicle, tonumber(extraId), 1)
				end
			end
		end

		if props.neonColor then SetVehicleNeonLightsColour(vehicle, props.neonColor[1], props.neonColor[2], props.neonColor[3]) end
		if props.xenonColor then SetVehicleXenonLightsColour(vehicle, props.xenonColor) end
		if props.modSmokeEnabled then ToggleVehicleMod(vehicle, 20, true) else ToggleVehicleMod(vehicle, 20, false) end
		if props.tyreSmokeColor then SetVehicleTyreSmokeColor(vehicle, props.tyreSmokeColor[1], props.tyreSmokeColor[2], props.tyreSmokeColor[3]) end
		if props.modSpoilers then SetVehicleMod(vehicle, 0, props.modSpoilers, false) end
		if props.modFrontBumper then SetVehicleMod(vehicle, 1, props.modFrontBumper, false) end
		if props.modRearBumper then SetVehicleMod(vehicle, 2, props.modRearBumper, false) end
		if props.modSideSkirt then SetVehicleMod(vehicle, 3, props.modSideSkirt, false) end
		if props.modExhaust then SetVehicleMod(vehicle, 4, props.modExhaust, false) end
		if props.modFrame then SetVehicleMod(vehicle, 5, props.modFrame, false) end
		if props.modGrille then SetVehicleMod(vehicle, 6, props.modGrille, false) end
		if props.modHood then SetVehicleMod(vehicle, 7, props.modHood, false) end
		if props.modFender then SetVehicleMod(vehicle, 8, props.modFender, false) end
		if props.modRightFender then SetVehicleMod(vehicle, 9, props.modRightFender, false) end
		if props.modRoof then SetVehicleMod(vehicle, 10, props.modRoof, false) end
		if props.modEngine then SetVehicleMod(vehicle, 11, props.modEngine, false) end
		if props.modBrakes then SetVehicleMod(vehicle, 12, props.modBrakes, false) end
		if props.modTransmission then SetVehicleMod(vehicle, 13, props.modTransmission, false) end
		if props.modHorns then SetVehicleMod(vehicle, 14, props.modHorns, false) end
		if props.modSuspension then SetVehicleMod(vehicle, 15, props.modSuspension, false) end
		if props.modArmor then SetVehicleMod(vehicle, 16, props.modArmor, false) end
		if props.modTurbo then ToggleVehicleMod(vehicle,  18, props.modTurbo) else ToggleVehicleMod(vehicle,  18, false) end
		if props.modXenon then ToggleVehicleMod(vehicle,  22, props.modXenon) else ToggleVehicleMod(vehicle,  22, false) end
		if props.modFrontWheels then SetVehicleMod(vehicle, 23, props.modFrontWheels, false) end
		if props.modBackWheels then SetVehicleMod(vehicle, 24, props.modBackWheels, false) end
		if props.modPlateHolder then SetVehicleMod(vehicle, 25, props.modPlateHolder, false) end
		if props.modVanityPlate then SetVehicleMod(vehicle, 26, props.modVanityPlate, false) end
		if props.modTrimA then SetVehicleMod(vehicle, 27, props.modTrimA, false) end
		if props.modOrnaments then SetVehicleMod(vehicle, 28, props.modOrnaments, false) end
		if props.modDashboard then SetVehicleMod(vehicle, 29, props.modDashboard, false) end
		if props.modDial then SetVehicleMod(vehicle, 30, props.modDial, false) end
		if props.modDoorSpeaker then SetVehicleMod(vehicle, 31, props.modDoorSpeaker, false) end
		if props.modSeats then SetVehicleMod(vehicle, 32, props.modSeats, false) end
		if props.modSteeringWheel then SetVehicleMod(vehicle, 33, props.modSteeringWheel, false) end
		if props.modShifterLeavers then SetVehicleMod(vehicle, 34, props.modShifterLeavers, false) end
		if props.modAPlate then SetVehicleMod(vehicle, 35, props.modAPlate, false) end
		if props.modSpeakers then SetVehicleMod(vehicle, 36, props.modSpeakers, false) end
		if props.modTrunk then SetVehicleMod(vehicle, 37, props.modTrunk, false) end
		if props.modHydrolic then SetVehicleMod(vehicle, 38, props.modHydrolic, false) end
		if props.modEngineBlock then SetVehicleMod(vehicle, 39, props.modEngineBlock, false) end
		if props.modAirFilter then SetVehicleMod(vehicle, 40, props.modAirFilter, false) end
		if props.modStruts then SetVehicleMod(vehicle, 41, props.modStruts, false) end
		if props.modArchCover then SetVehicleMod(vehicle, 42, props.modArchCover, false) end
		if props.modAerials then SetVehicleMod(vehicle, 43, props.modAerials, false) end
		if props.modTrimB then SetVehicleMod(vehicle, 44, props.modTrimB, false) end
		if props.modTank then SetVehicleMod(vehicle, 45, props.modTank, false) end
		if props.modWindows then SetVehicleMod(vehicle, 46, props.modWindows, false) end

		if props.modLivery then
			SetVehicleMod(vehicle, 48, props.modLivery, false)
			SetVehicleLivery(vehicle, props.modLivery)
		end
        if props.fuelLevel then SetVehicleFuelLevel(vehicle, props.fuelLevel + 0.0) if DecorGetFloat(vehicle,'_FUEL_LEVEL') then DecorSetFloat(vehicle,'_FUEL_LEVEL',props.fuelLevel + 0.0) end end
	end
end

AddEventHandler('onResourceStop', function(res)
    if res == 'renzu_projectcars' then
		local projectcars = GlobalState.ProjectCars
		for k,v in pairs(projectcars) do
			local plate = v.plate
			DeleteEntity(spawnprojectcars[plate])
			DeleteEntity(spawnprojectshell[plate])
			if blips[plate] then
				RemoveBlip(blips[plate])
			end
		end
	end
end)