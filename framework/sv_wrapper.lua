Using = {}
function Initialized()
	if Config.framework == 'ESX' then
		ESX = exports['es_extended']:getSharedObject()
		RegisterServerCallBack_ = function(...)
			ESX.RegisterServerCallback(...)
		end
		RegisterUsableItem = function(...)
			ESX.RegisterUsableItem(...)
		end
		vehicletable = 'owned_vehicles'
		vehiclemod = 'vehicle'
		QBCore = {}
	elseif Config.framework == 'QBCORE' then
		QBCore = exports['qb-core']:GetCoreObject()
		RegisterServerCallBack_ =  function(...)
			return QBCore.Functions.CreateCallback(...)
		end
		RegisterUsableItem = function(...)
			return QBCore.Functions.CreateUseableItem(...)
		end
		vehicletable = 'player_vehicles '
		vehiclemod = 'mods'
		owner = 'license'
		stored = 'state'
		garage_id = 'garage'
		type_ = 'vehicle'
		ESX = {}
	end
	--CreateThread(function()
		c = 0
		if Config.framework == 'ESX' then
			CreateThread(function()
				for k,v in pairs(Config.items) do
					c = c + 1
					local name = string.lower(v)
					local label = string.upper(v)
					foundRow = SqlFunc(Config.Mysql,'fetchAll',"SELECT * FROM items WHERE name = @name", {
					['@name'] = name
					})
					if foundRow[1] == nil then
					local weight = 'limit'
					if Config.weight_type then
						SqlFunc(Config.Mysql,'execute',"INSERT INTO items (name, label, weight) VALUES (@name, @label, @weight)", {
						['@name'] = name,
						['@label'] = ""..firstToUpper(name).."",
						['@weight'] = Config.weight
						})
						print("Inserting "..name.."")
					else
						SqlFunc(Config.Mysql,'execute',"INSERT INTO items (name, label) VALUES (@name, @label)", {
						['@name'] = name,
						['@label'] = ""..firstToUpper(name).."",
						})
						print("Inserting "..name.."")
					end
					end
				end
				return
			end)

			CreateThread(function()
				for k,v in pairs(Config.Paint) do
					c = c + 1
					local name = string.lower(v.item)
					local label = string.upper(v.label)
					foundRow = SqlFunc(Config.Mysql,'fetchAll',"SELECT * FROM items WHERE name = @name", {
					['@name'] = name
					})
					if foundRow[1] == nil then
					local weight = 'limit'
					if Config.weight_type then
						SqlFunc(Config.Mysql,'execute',"INSERT INTO items (name, label, weight) VALUES (@name, @label, @weight)", {
						['@name'] = name,
						['@label'] = ""..firstToUpper(label).."",
						['@weight'] = Config.weight
						})
						print("Inserting "..name.."")
					else
						SqlFunc(Config.Mysql,'execute',"INSERT INTO items (name, label) VALUES (@name, @label)", {
						['@name'] = name,
						['@label'] = ""..firstToUpper(label).."",
						})
						print("Inserting "..name.."")
					end
					end
				end
				return
			end)

			CreateThread(function()
				for k,v in pairs(Config.parts) do
					c = c + 1
					local name = string.lower(k)
					local label = string.upper(v.label)
					foundRow = SqlFunc(Config.Mysql,'fetchAll',"SELECT * FROM items WHERE name = @name", {
						['@name'] = name
					})
					if foundRow[1] == nil then
					local weight = 'limit'
					if Config.weight_type then
						SqlFunc(Config.Mysql,'execute',"INSERT INTO items (name, label, weight) VALUES (@name, @label, @weight)", {
						['@name'] = name,
						['@label'] = ""..firstToUpper(label).."",
						['@weight'] = Config.weight
						})
						print("Inserting "..name.."")
					else
						SqlFunc(Config.Mysql,'execute',"INSERT INTO items (name, label) VALUES (@name, @label)", {
						['@name'] = name,
						['@label'] = ""..firstToUpper(label).."",
						})
						print("Inserting "..name.."")
					end
					end
				end
				return
			end)
		end
		for k,v in pairs(Config.items) do
			local name = string.lower(v)
			print("register item", v)
			if Config.MetaInventory and v == 'vehicle_shell' then
				RegisterUsableItem(name, function(source,item,data)
					local item <const> = item
					local source = source
					local xPlayer = GetPlayerFromId(source)
					local meta = ItemMeta(name,item,xPlayer,data)
					local ply = Player(source).state
					if Config.EnableZoneOnly and ply.buildzone or not Config.EnableZoneOnly or GlobalState.GarageInside[xPlayer.identifier] then
						TriggerClientEvent('renzu_projectcars:spawnnewproject',source,meta)
						xPlayer.removeInventoryItem(name, 1)
					else
						TriggerClientEvent('renzu_notify:Notify', source, 'error','ProjectCars', Locale[Config.Locale].not_inzone)
					end
				end)
			end
			if v == 'vehicle_blueprints' then
				RegisterUsableItem(name, function(source,item)
					local ply = Player(source).state
					if Config.EnableZoneOnly and ply.buildzone or not Config.EnableZoneOnly or GlobalState.GarageInside[xPlayer.identifier] then
						local xPlayer = GetPlayerFromId(source)
						local result = SqlFunc(Config.Mysql,'fetchAll','SELECT * FROM renzu_projectcars_items WHERE `identifier` = @identifier', {['@identifier'] = xPlayer.identifier})
						local owned = {}
						local identifier = result[1].identifier
						local items = json.decode(result[1].items or '[]')
						for k,v in pairs(items) do
							if identifier == xPlayer.identifier then
								owned[k] = Config.Vehicles[k]
							end
						end
						TriggerClientEvent('renzu_projectcars:openblueprints',source,owned)
					else
						TriggerClientEvent('renzu_notify:Notify', source, 'error','ProjectCars', Locale[Config.Locale].not_inzone)
					end
				end)
			end
		end
		for k,v in pairs(Config.parts) do
			RegisterUsableItem(k, function(source,item,data)
				local source = source
				local xPlayer = GetPlayerFromId(source)
				local item <const> = item
				if Config.MetaInventory then
					local meta = ItemMeta(k,item,xPlayer,data)
					if meta ~= nil then
						TriggerClientEvent('renzu_projectcars:useparts',source,k,meta)
					else
						print("Empty meta data")
					end
				else
					TriggerClientEvent('renzu_projectcars:useparts',source,k)
				end
			end)
		end
		for k,v in pairs(Config.Paint) do
			RegisterUsableItem(v.item, function(source,item)
				local xPlayer = GetPlayerFromId(source)
				print("PROJECTO CAR")
				TriggerClientEvent('renzu_projectcars:usepaint',source,k)
			end)
		end
	--end)
	print(" RUENZU PROJECTO CAR LOADED ")
end

function ItemMeta(name,data,xPlayer,ox)
	local xPlayer <const> = xPlayer
	local name <const> = name
	if Config.framework == 'ESX' then
		local Inventory = exports.ox_inventory:Inventory()
		local item = Inventory.Search(xPlayer.source, 1, name)
		local source = tonumber(xPlayer.source)
		local meta = nil
		if ox and ox.slot then
			-- thanks to linden
			print(ox.metadata.type,ox.metadata,ox)
			-- new ox updated latest https://github.com/overextended/ox_inventory/commit/a7028a23cc890a3ad357fe0d3784d81d0b2d078d and https://github.com/overextended/es_extended/commit/d7f5b969a83421825bfd82a972dc5ada9898f2f5
			meta = ox.metadata.type
		else
			-- old ox logic
			if not Using[source] then
				Using[source] = {}
			end
			while not Using[source][name] do Wait(100) end
			slot = Using[source][name]
			for k2,v in pairs(item) do
				if v.slot == slot then
					meta = v.metadata.type
				end
			end
		end
		return meta
	else
		local data <const> = data
		return data.info
	end
end

function GetPlayerFromIdentifier(identifier)
	self = {}
	if Config.framework == 'ESX' then
		local player = ESX.GetPlayerFromIdentifier(identifier)
		self.src = player and player.source
		return player
	else
		local getsrc = QBCore.Functions.GetSource(identifier)
		if not getsrc then return end
		self.src = getsrc
		return GetPlayerFromId(self.src)
	end
end

function GetPlayerFromId(src)
	self = {}
	self.src = src
	if Config.framework == 'ESX' then
		return ESX.GetPlayerFromId(self.src)
	elseif Config.framework == 'QBCORE' then
		xPlayer = QBCore.Functions.GetPlayer(self.src)
		if not xPlayer then return end
		if xPlayer.identifier == nil then
			xPlayer.identifier = xPlayer.PlayerData.license
		end
		if xPlayer.citizenid == nil then
			xPlayer.citizenid = xPlayer.PlayerData.citizenid
		end
		if xPlayer.job == nil then
			xPlayer.job = xPlayer.PlayerData.job
		end

		xPlayer.getMoney = function(value)
			return xPlayer.PlayerData.money['cash']
		end
		xPlayer.addMoney = function(value)
				QBCore.Functions.GetPlayer(tonumber(self.src)).Functions.AddMoney('cash',tonumber(value))
			return true
		end
		xPlayer.addAccountMoney = function(type, value)
			QBCore.Functions.GetPlayer(tonumber(self.src)).Functions.AddMoney(type,tonumber(value))
			return true
		end
		xPlayer.removeMoney = function(value)
			QBCore.Functions.GetPlayer(tonumber(self.src)).Functions.RemoveMoney('cash',tonumber(value))
			return true
		end
		xPlayer.getAccount = function(type)
			if type == 'money' then
				type = 'cash'
			end
			return {money = xPlayer.PlayerData.money[type]}
		end
		xPlayer.removeAccountMoney = function(type,val)
			if type == 'money' then
				type = 'cash'
			end
			QBCore.Functions.GetPlayer(tonumber(self.src)).Functions.RemoveMoney(type,tonumber(val))
			return true
		end
		xPlayer.showNotification = function(msg)
			TriggerEvent('QBCore:Notify',self.src, msg)
			return true
		end
		xPlayer.addInventoryItem = function(item,amount,info,slot)
			local info = info
			QBCore.Functions.GetPlayer(tonumber(self.src)).Functions.AddItem(item,amount,slot or false,info)
		end
		xPlayer.removeInventoryItem = function(item,amount,slot)
			QBCore.Functions.GetPlayer(tonumber(self.src)).Functions.RemoveItem(item, amount, slot or false)
		end
		xPlayer.getInventoryItem = function(item)
			local gi = QBCore.Functions.GetPlayer(tonumber(self.src)).Functions.GetItemByName(item) or {count = 0}
			gi.count = gi.amount or 0
			return gi
		end
		xPlayer.getGroup = function()
			return QBCore.Functions.IsOptin(self.src)
		end
		if xPlayer.source == nil then
			xPlayer.source = self.src
		end
		return xPlayer
	end
end

function VehicleNames()
	if Config.framework == 'ESX' then
		vehiclesname = SqlFunc(Config.Mysql,'fetchAll','SELECT * FROM vehicles', {})
	elseif Config.framework == 'QBCORE' then
		vehiclesname = QBCore.Shared.Vehicles
	end
end

function SqlFunc(plugin,type,query,var)
	local wait = promise:new()
	if type == 'fetchAll' and plugin == 'mysql-async' then
			MySQL.Async.fetchAll(query, var, function(result)
			wait:resolve(result)
		end)
	end
	if type == 'execute' and plugin == 'mysql-async' then
		MySQL.Async.execute(query, var, function(result)
			wait:resolve(result)
		end)
	end
	if type == 'execute' and plugin == 'ghmattisql' then
		exports['ghmattimysql']:execute(query, var, function(result)
			wait:resolve(result)
		end)
	end
	if type == 'fetchAll' and plugin == 'ghmattisql' then
		exports.ghmattimysql:execute(query, var, function(result)
			wait:resolve(result)
		end)
	end
	if type == 'execute' and plugin == 'oxmysql' then
		exports.oxmysql:execute(query, var, function(result)
			wait:resolve(result)
		end)
	end
	if type == 'fetchAll' and plugin == 'oxmysql' then
		exports['oxmysql']:fetch(query, var, function(result)
			wait:resolve(result)
		end)
	end
	return Citizen.Await(wait)
end