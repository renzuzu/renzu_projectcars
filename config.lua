Config = {}
Config.Locale = 'en'
Config.Mysql = 'oxmysql' -- "ghmattisql", "mysql-async", "oxmysql"
Config.framework = 'ESX' -- ESX or QBCORE
Config.weight_type = false
Config.weight = 1.5

--READ THIS PART IF META INVENTORY
-- META Inventory Support
-- Changing this value will need you to fully restart in client to able to use the item
-- And Item must be registered properly in your OX Inventory /data/items.lua ( Automatic registered when you restart ox after this script imported a items to SQL)
Config.MetaInventory = true -- ox_inventory is the only supported for esx Framework META datas || if false will use default esx item functions
-- ESX OX Inventory 95% Supported ( less issues and bug , but have some temporary logic to get item slot from server )
-- QBCORE qb-inventory = 70% partially supported (im unfamilliar yet) ( but it will work, the demo video is using a qbcore without a issue , junk vehicles shells, parts metas, chopshop reward for current vehicle)
-- This is designed for advanced and more complex usage, 
-- eg. Blista Door will be able to use in Blista Model Project cars only.
-- when this enable, Shop and Chopshop will adjust the feature, model meta datas are automatically added to your newly bought , received item from chop. (GIVEITEM command may not work properly if metas are not declared)
-- IF FALSE, Brand Shops for Parts will be disable, and any parts can be used to any vehicle models and vehicle_blueprints will be used instead of vehicle_shell (spawning project cars)
-- META Inventory Support

Config.items = {'vehicle_shell','vehicle_blueprints'} -- note: vehicle_shell usage is for item meta inventory only, if you are not using meta inventory, vehicle_blueprints are the one usable to spawn your bought shells.(junk vehicle)

-- CONFIGURE THIS PART (MAIN SETTINGS)
Config.jobonly = false -- enable disable job requirement for using the shops
Config.carbuilderjob = 'mechanic'
Config.job_AllShopFree = true
-- CONFIGURE THIS PART (MAIN SETTINGS)

-- GENERAL CONFIG
Config.EnableInteraction = true -- if true will use interaction, required my lockgame or progressbar
Config.Default_garage = 'A' -- what garage id ex. A , pillboxgarage (important to change this on some garage scripts like renzu_garage)
Config.KeySystemEvent = 'vehiclekeys:client:SetOwner' -- <-- default qbcore keys, change it to whatever key system you have -- if this is not working properly, your key system must be triming the plates incorrectly.
-- GENERAL CONFIG

-- Shops
Config.JunkShop = {
	['Junk Shop'] = { -- <-- dont change -- this is where your players can buy vehicle shells aka junk vehicle for project cars
		server = false,
		label = 'Vehicle Junk Shop', -- can change
		model = GetHashKey('csb_car3guy2'),
		event = 'renzu_projectcars:openshop',
		coord = vector3(2339.1081542969,3054.2561035156,48.151859283447),
		blipsprite = 524,
		args = function() return Config.MetaInventory and Config.Vehicles or nil end
	},
	['Auto Shop'] = { -- <-- dont change -- this is where your players will buy vehicle parts
		server = false,
		label = 'Auto Shop', -- can change
		model = GetHashKey('csb_car3guy2'),
		event = Config.MetaInventory and 'renzu_projectcars:openautoshop' or 'renzu_projectcars:openpartlist',
		coord = vector3(867.64739990234,-1061.3259277344,28.947834014893),
		blipsprite = 642,
		args = function() return Config.MetaInventory and Config.Vehicles or nil end
	}
}
-- Builder Job
-- Boss can request orders from manufacturer (imaginary) and be paid after releasing orders
-- integration with my vehicle shop (renzu_vehicleshop v2) Soon
Config.EnableBuilderJob = true -- enable disable this feature
Config.MaxProjectOrderList = 10 -- max vehicles from job order lists
Config.BuilderJobs = {
	['mechanic'] = { -- job
		blipsprite = 569,
		label = 'Automotive Service',
		event = 'renzu_projectcars:gotowarehouse',
		range = 300.0,
		coord = vector3(895.21099853516,-896.31213378906,27.789014816284),
		exit = vector3(-1245.1499023438,-3023.052734375,-48.489776611328),
		spawn = vector3(-1267.4389648438,-3013.4169921875,-48.490139007568),
		brands = {
			['dinka'] = true,
			['maibatsu'] = true,
		},
		['warehouse'] = {
			['enter'] = {
				label = 'Enter Warehouse',
				event = 'renzu_projectcars:gotowarehouse',
				coord = vector3(895.21099853516,-896.31213378906,27.789014816284),
			},
			['exit'] = {
				label = 'Exit Warehouse',
				event = 'renzu_projectcars:gotowarehouse',
				coord = vector3(-1245.1499023438,-3023.052734375,-48.489776611328),
			},
			['buildermenu'] = {
				label = 'Builder Menu',
				event = 'renzu_projectcars:buildermenu',
				coord = vector3(-1294.5773925781,-3018.4392089844,-48.490032196045),
			},
			['garage'] = {
				label = 'Garage Menu',
				event = 'renzu_projectcars:garagemenu',
				coord = vector3(-1295.2064208984,-3002.2260742188,-48.489944458008),
			},
			['stockroom'] = {
				label = 'Stock Room',
				event = Config.MetaInventory and 'renzu_projectcars:stockroom' or 'renzu_projectcars:openpartlist',
				coord = vector3(-1297.7445068359,-3030.7507324219,-48.4899559021),
			},
		}
	},
	-- new job? copy the table above and change the job and coordinates.
}

-- PROJECT CAR ZONE
-- you dont want your players to spam the vehicle building anywhere? set this to true
Config.EnableZoneOnly = false -- Allow Car building in designated location only
Config.BuildZone = {
	['Zone 1'] = { -- <-- dont change -- sandy shore
		buildzone = true,
		label = 'Project Car Site 1', -- can change
		coord = vector3(1730.5634765625,3310.7248535156,41.223526000977),
		blipsprite = 641,
		radius = 150
	},

	['Zone 2'] = { -- <-- dont change -- Hangar Airport
		buildzone = true,
		label = 'Project Car Site 2', -- can change
		coord = vector3(-960.12908935547,-2993.1423339844,13.945062637329),
		blipsprite = 641,
		radius = 300
	},
}

-- CHOPSHOP ( configure this correctly ) disable or enable it its up to you ( this is a bonus feature in project cars )
Config.EnableChopShop = true -- Built in ChopShop (for parts)
Config.DeleteVehicleSql = true -- Delete the vehicle in database | carefully changing this from true to false, player can abuse the chopshop
Config.ChopShop = {
	['Chop Shop 1'] = { -- <-- dont change
		chopzone = true,
		label = 'Chop Shop 1', -- can change
		coord = vector3(-465.54257202148,-1717.1135253906,18.161306381226),
		store = vector3(-469.09759521484,-1718.4575195313,18.689140319824),
		blip = 620
	},
}

Config.parts = { -- parts initial shop price, props, labels
	['door'] = {prop = 'prop_car_door_01', price = 15000, label = 'Door', metaprice = 0.03},
	['bonnet'] = {prop = 'imp_prop_impexp_bonnet_02a', price = 15000, label = 'Hood' , metaprice = 0.07},
	['trunk'] = {prop = 'imp_prop_impexp_trunk_01a', price = 15000, label = 'Trunk' , metaprice = 0.07},
	['wheel'] = {prop = 'prop_wheel_01', price = 10000, label = 'Wheel' , metaprice = 0.025},
	['seat'] = {prop = 'prop_car_seat', price = 7000, label = 'Seat', metaprice = 0.02},
	['engine'] = {prop = 'prop_car_engine_01', price = 25000, label = 'Engine', metaprice = 0.2},
	['transmition'] = {prop = 'imp_prop_impexp_gearbox_01', price = 25000, label = 'Transmission', metaprice = 0.15},
	['exhaust'] = {prop = 'imp_prop_impexp_exhaust_01', price = 15000, label = 'Exhaust', metaprice = 0.03},
	['brake'] = {prop = 'imp_prop_impexp_brake_caliper_01a', price = 15000, label = 'Brake', metaprice = 0.02},
	['paint'] = {prop = 'ng_proc_spraycan01b', price = 15000, label = 'Paint', func = 'renzu_projectcars:openpaint', metaprice = 0.07},
}

Config.Paint = { -- paint initial price, Label, itemname, and rgb colors (this feature required your garage to support CustomColour)
	-- you can add other rgb patterns
    ['white'] = {label = 'Paint White', item = 'paint_white', price = 15000, color = {255, 255, 255}},
    ['red'] =  {label = 'Paint Red', item = 'paint_red',price = 15000, color = {255, 0, 0}},
    ['pink'] = {label = 'Paint Pink', item = 'paint_pink',price = 15000, color = {253, 51, 153}},
    ['blue'] = {label = 'Paint Blue', item = 'paint_blue',price = 15000, color = {0, 0, 255}},
    ['yellow'] = {label = 'Paint Yellow', item = 'paint_yellow',price = 15000, color = {255, 255, 0}},
    ['green'] = {label = 'Paint Green',item = 'paint_green',price = 15000, color = {0, 255, 0}},
    ['orange'] = {label = 'Paint Orange', item = 'paint_orange',price = 15000, color = {153, 76, 0}},
    ['brown'] = {label = 'Paint Brown', item = 'paint_brown',price = 15000, color = {51, 25, 0}},
    ['purple'] =  {label = 'Paint Purple',item = 'paint_purple',price = 15000, color = {128, 1, 128}},
    ['grey'] = {label = 'Paint Grey', item = 'paint_grey',price = 15000, color = {50, 50, 50}},
    ['black'] = {label = 'Paint Black', item = 'paint_black',price = 15000, color = {0, 0, 0}},
}

-- Private Garage to Built Project cars
-- Another Bonus Feat unplanned
-- this is a temporary garage for your players , so they can built project cars in peace
-- Using Routing Buckets (dimension world or entity awareness)
-- Only 1 garage is supported medium size of 6 cars garage
Config.EnableGarage = true
Config.EntraceFee = 10000
Config.GarageCoord = vector4(636.93872070312,4750.7319335938,-58.999935150146,95.324378967285)
Config.Garage = {
	[1] = {
		buy = {model = 'u_m_m_streetart_01', label = 'Rent Garage (1 day : $'..Config.EntraceFee..')', coord = vector3(109.28265380859,-1088.5358886719,29.302461624146), cost = 10000},
		enter = {label = 'Enter Garage', coord = vector3(132.40071105957,-1081.5100097656,28.518619537354)},
		exit = {label = 'Exit Garage', coord = vector3(641.77276611328,4750.525390625,-59.000015258789)},
		spawn = {label = 'Spawn Area', coord = vector4(143.33265686035,-1081.1436767578,28.518182754517,358.41958618164)},
	}
}

-- DELETE EXISTING PROJECT CAR (admins only)
-- deletes nearest project car
Config.DeleteCommand = 'destroyprojectcar'