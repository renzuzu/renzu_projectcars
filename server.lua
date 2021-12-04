

ESX = nil
QBCore = nil
vehicletable = 'owned_vehicles'
vehiclemod = 'vehicle'
owner = 'owner'
stored = 'stored'
garage_id = 'garage_id'
type_ = 'type'
RegisterServerCallBack_ = nil
RegisterUsableItem = nil
projectcars = {}
Citizen.CreateThread(function()
    Initialized()
    -- SetResourceKvp('renzu_garage','[]')
    -- GlobalState.JobGarage = {}
    if not GetResourceKvpString('project_order_lists') then
        local orderlist = {}
        SetResourceKvp('project_order_lists',orderlist)
    end
    if not GlobalState.ProjectOrders then
        GlobalState.ProjectOrders = {}
    end
    if GetResourceKvpString('renzu_garage') then
        GlobalState.JobGarage = json.decode(GetResourceKvpString('renzu_garage'))
    end
    if GlobalState.JobGarage == nil then GlobalState.JobGarage = {} end
    if GlobalState.GarageInside == nil then GlobalState.GarageInside = {} end
    if GlobalState.RenterGarage == nil then GlobalState.RenterGarage = {} end
    if GlobalState.ChopVehicles == nil then GlobalState.ChopVehicles = {} end
    local result = SqlFunc(Config.Mysql,'fetchAll','SELECT * FROM renzu_projectcars', {})
    if result and result[1] then
        for k,v in pairs(result) do
        projectcars[v.plate] = v
        end
    end
    GlobalState.ProjectCars = projectcars or {}

    RegisterNetEvent('renzu_projectcars:buyshell')
    AddEventHandler('renzu_projectcars:buyshell', function(data)
        local source = source
        local xPlayer = GetPlayerFromId(source)
        local price = (data.price * Config.PercentShellPrice)
        if Config.MetaInventory and xPlayer.getMoney() >= price then
            xPlayer.addInventoryItem('vehicle_shell',1,data.model)
            xPlayer.removeMoney(price)
        end
        if not Config.MetaInventory and xPlayer.getMoney() >= price then
            local result = SqlFunc(Config.Mysql,'fetchAll','SELECT * FROM renzu_projectcars_items WHERE `identifier` = @identifier', {['@identifier'] = xPlayer.identifier})
            if result and result[1] then
                local inv = json.decode(result[1].items or '[]')
                if not inv[data.model] then
                    inv[data.model] = 0
                end
                inv[data.model] = inv[data.model] + 1
                SqlFunc(Config.Mysql,'execute','UPDATE renzu_projectcars_items SET `items` = @items WHERE `identifier` = @identifier', {
                    ['@items'] = json.encode(inv),
                    ['@identifier'] = xPlayer.identifier,
                })
            else
                local items = {}
                if not items[data.model] then
                    items[data.model] = 0
                end
                items[data.model] = items[data.model] + 1
                SqlFunc(Config.Mysql,'execute','INSERT INTO renzu_projectcars_items (`identifier`, `items`) VALUES (@identifier, @items)', {
                    ['@items']   = json.encode(items),
                    ['@identifier']   = xPlayer.identifier,
                })
            end
            local item = xPlayer.getInventoryItem('vehicle_blueprints')
            if item.count == 0 then
                xPlayer.addInventoryItem('vehicle_blueprints',1)
            end
            xPlayer.removeMoney(price)
            TriggerClientEvent('renzu_notify:Notify', source, 'success','ProjectCars', Locale[Config.Locale].success_bought_shell)
        end
    end)

    RegisterNetEvent('renzu_projectcars:spawnshell')
    AddEventHandler('renzu_projectcars:spawnshell', function(data)
        local source = source
        local xPlayer = GetPlayerFromId(source)
        local result = SqlFunc(Config.Mysql,'fetchAll','SELECT * FROM renzu_projectcars_items WHERE `identifier` = @identifier', {['@identifier'] = xPlayer.identifier})
        local job = xPlayer.job.name
        if result and result[1] and not Config.BuilderJobs[job] then
            local inv = json.decode(result[1].items or '[]')
            if inv[data.model] then
                inv[data.model] = inv[data.model] -1
                if inv[data.model] == 0 then
                    inv[data.model] = nil
                end
                SqlFunc(Config.Mysql,'execute','UPDATE renzu_projectcars_items SET `items` = @items WHERE `identifier` = @identifier', {
                    ['@items'] = json.encode(inv),
                    ['@identifier'] = xPlayer.identifier,
                })
                TriggerClientEvent('renzu_projectcars:spawnnewproject',source,data.model)
            end
        end
        if Config.BuilderJobs[job] then
            TriggerClientEvent('renzu_projectcars:spawnnewproject',source,data.model)
        end
    end)

    function GetPaintData(i)
        local allowed = false
        for k,v in pairs(Config.Paint) do
            if i.item == v.item then
                allowed = true
                break
            end
        end
        local data = {
            itemname = i.item,
            price = i.price,
            color = i.color
        }
        return allowed and data or nil
    end

    RegisterNetEvent('renzu_projectcars:buyparts')
    AddEventHandler('renzu_projectcars:buyparts', function(info,val)
        local item = info[1]
        local info = info[2]
        print(item,info)
        local val = tonumber(val) or nil
        local price = 0
        if type(item) == 'table' and GetPaintData(item) then
            price = GetPaintData(item).price
            item = GetPaintData(item).itemname
            local xPlayer = GetPlayerFromId(source)
            if val == nil then
                val = 1
            end
            if xPlayer.getMoney() >= (price * val) then
                xPlayer.addInventoryItem(item,type(info) == 'number' and info or val)
                xPlayer.removeMoney((price * val))
            else
                TriggerClientEvent('renzu_notify:Notify', source, 'error','ProjectCars', Locale[Config.Locale].notenoughmoney)
            end
        else
            local price = info and info.model and Config.Vehicles[info.model] and Config.Vehicles[info.model].price * Config.parts[item].metaprice  or Config.parts[item].price
            if not Config.MetaInventory then
                price = Config.parts[item].price
            end
            item = Config.parts[item] and item
            local xPlayer = GetPlayerFromId(source)
            if val == nil then
                val = 1
            end
            if xPlayer.getMoney() >= (price * val) then
                xPlayer.addInventoryItem(item,val,info ~= nil and info.model or nil)
                xPlayer.removeMoney((price * val))
            else
                TriggerClientEvent('renzu_notify:Notify', source, 'error','ProjectCars', Locale[Config.Locale].notenoughmoney)
            end
        end
    end)

    RegisterNetEvent('renzu_projectcars:updateprojectcars')
    AddEventHandler('renzu_projectcars:updateprojectcars', function(data,plate,props)
        local xPlayer = GetPlayerFromId(source)
        GlobalState.ProjectCars = data
        projectcars = data
        UpdateProject(data[plate],xPlayer,props)
    end)

    RegisterNetEvent('renzu_projectcars:newproject')
    AddEventHandler('renzu_projectcars:newproject', function(data)
    local xPlayer = GetPlayerFromId(source)
    UpdateProject(data,xPlayer)
    end)

    function UpdateProject(data,xPlayer,props)
        local plate_ = string.gsub(data.plate, '^%s*(.-)%s*$', '%1')
        local result = SqlFunc(Config.Mysql,'fetchAll','SELECT * FROM renzu_projectcars WHERE TRIM(plate) = @plate', {['@plate'] = plate_})
        if result[1] == nil then
            local newproject = {}
            for k,v in pairs(Config.parts) do
                if k == 'engine' or k == 'transmition' then
                    newproject[k] = 1
                end
                if k == 'bonnet' and data.bonnet then
                    newproject[k] = data.bonnet
                end
                if k == 'trunk' and data.trunk then
                    newproject[k] = data.trunk
                end
                if k == 'exhaust' and data.exhaust then
                    newproject[k] = data.exhaust
                end
                if k == 'wheel' and data.wheel then
                    newproject[k] = data.wheel
                end
                if k == 'brake' and data.brake then
                    newproject[k] = data.brake
                end
                if k == 'door' and data.seat then
                    local doordata = {}
                    for i = 0,3 do
                    doordata[tostring(i)] = 1
                    if data.seat == 2 and i == 2 or data.seat == 2 and i == 3 then
                        doordata[tostring(i)] = 0
                    end
                    end
                    newproject[k] = doordata
                end
                if k == 'seat' and data.seat then
                    local seatdata = {}
                    for i = 0,data.seat-1 do
                    seatdata[tostring(i-1)] = 1
                    end
                    newproject[k] = seatdata
                end
                if k == 'paint' and data.paint then
                    newproject[k] = 1
                end
            end
        SqlFunc(Config.Mysql,'execute','INSERT INTO renzu_projectcars (`plate`, `identifier`, `coord`, `model`, `status`) VALUES (@plate, @identifier, @coord, @model, @status)', {
            ['@plate']   = plate_,
            ['@identifier']   = xPlayer.identifier,
            ['@model']   = data.model,
            ['@paint']   = json.encode(data.paint) or '[]',
            ['@coord']   = json.encode(vector4(data.coord,data.heading)),
            ['@status'] = json.encode(newproject)
        })
        projectcars[plate_] = {}
        projectcars[plate_].plate = plate_
        projectcars[plate_].model = data.model
        projectcars[plate_].paint = data.paint
        projectcars[plate_].identifier = xPlayer.identifier
        projectcars[plate_].coord = json.encode(vector4(data.coord,data.heading))
        projectcars[plate_].status = json.encode(newproject)
        projectcars[plate_].paint = json.encode(data.paint) or '[]'
        GlobalState.ProjectCars = projectcars
        elseif result[1] then
        local status = projectcars[plate_].status
        SqlFunc(Config.Mysql,'execute','UPDATE renzu_projectcars SET `status` = @status, `paint` = @paint WHERE TRIM(plate) = @plate', {
            ['@plate'] = plate_,
            ['@status'] = status,
            ['@paint'] = projectcars[plate_].paint or '[]'
        })
        TriggerClientEvent('renzu_projectcars:updatelocalproject',-1,projectcars[plate_])
        ProjectProgress(projectcars[plate_],props,xPlayer)
        end
    end

    function AddOwnedVehicles(data,props,xPlayer)
        local xPlayer = GetPlayerFromIdentifier(data.identifier)
        local plate = FinalPlate()
        props.plate = plate
        local prop = json.encode(props)
        local type = 'car'
        if Config.framework == 'QBCORE' then
            type = data.model
        end
        local query = 'INSERT INTO '..vehicletable..' ('..owner..', plate, '..vehiclemod..', `'..stored..'`, '..garage_id..', `'..type_..'`) VALUES (@'..owner..', @plate, @props, @'..stored..', @'..garage_id..', @'..type_..')'
        if Config.framework == 'QBCORE' then
            query = 'INSERT INTO '..vehicletable..' ('..owner..', plate, '..vehiclemod..', `'..stored..'`, '..garage_id..', `'..type_..'`, citizenid, hash) VALUES (@'..owner..', @plate, @props, @'..stored..', @'..garage_id..', @'..type_..', @citizenid, @hash)'
        end
        local var = {
            ['@'..owner..'']   = data.identifier,
            ['@plate']   = plate,
            ['@props'] = prop,
            ['@'..stored..''] = 1,
            ['@'..garage_id..''] = Config.Default_garage,
            ['@'..type_..''] = type
        }
        if Config.framework == 'QBCORE' then
            var['@hash'] = tostring(GetHashKey(data.model))
            var['@citizenid'] = xPlayer.citizenid
        end
        SqlFunc(Config.Mysql,'execute',query,var)
        projectcars[data.plate] = nil
        GlobalState.ProjectCars = projectcars
        SqlFunc(Config.Mysql,'execute','DELETE FROM renzu_projectcars WHERE TRIM(UPPER(plate)) = @plate',{['@plate'] = data.plate})
        TriggerClientEvent('renzu_projectcars:updateprojectable',-1,data.plate)
        Wait(1000)
        if xPlayer then
            if GlobalState.GarageInside[xPlayer.identifier] then
                SetPlayerRoutingBucket(xPlayer.source,0)
                SetEntityCoords(GetPlayerPed(xPlayer.source),Config.Garage[1].spawn.coord.x,Config.Garage[1].spawn.coord.y,Config.Garage[1].spawn.coord.z)
                Wait(1000)
            end
            TriggerClientEvent('renzu_projectcars:spawnfinishproject',xPlayer.source,data,props)
            if GlobalState.GarageInside[xPlayer.identifier] then
                Wait(4000)
                local gi = GlobalState.GarageInside
                gi[xPlayer.identifier] = false
                GlobalState.GarageInside = gi
            end
        end
    end

    function RemoveOwnedVehicles(data,props,xPlayer)
        local prop = json.encode(props)
        local xPlayer = GetPlayerFromIdentifier(data.frontman)
        if Config.DeleteVehicleSql then
            SqlFunc(Config.Mysql,'execute','DELETE FROM '..vehicletable..' WHERE `plate` = @plate',{['@plate'] = data.plate})
        end
        if xPlayer and Config.MetaInventory then
            xPlayer.addInventoryItem('vehicle_shell',1,data.model)
            TriggerClientEvent('renzu_notify:Notify', xPlayer.source, 'success','ProjectCars', Locale[Config.Locale].receive_shell_chop)
        end
        if xPlayer and not Config.MetaInventory then
            local result = SqlFunc(Config.Mysql,'fetchAll','SELECT * FROM renzu_projectcars_items WHERE `identifier` = @identifier', {['@identifier'] = xPlayer.identifier})
            if result and result[1] then
                local inv = json.decode(result[1].items or '[]')
                if not inv[data.model] then
                    inv[data.model] = 0
                end
                inv[data.model] = inv[data.model] + 1
                SqlFunc(Config.Mysql,'execute','UPDATE renzu_projectcars_items SET `items` = @items WHERE `identifier` = @identifier', {
                    ['@items'] = json.encode(inv),
                    ['@identifier'] = xPlayer.identifier,
                })
            else
                local items = {}
                if not items[data.model] then
                    items[data.model] = 0
                end
                items[data.model] = items[data.model] + 1
                SqlFunc(Config.Mysql,'execute','INSERT INTO renzu_projectcars_items (`identifier`, `items`) VALUES (@identifier, @items)', {
                    ['@items']   = json.encode(items),
                    ['@identifier']   = xPlayer.identifier,
                })
            end
            local item = xPlayer.getInventoryItem('vehicle_blueprints')
            if item.count == 0 then
                xPlayer.addInventoryItem('vehicle_blueprints',1)
            end
            TriggerClientEvent('renzu_notify:Notify', xPlayer.source, 'success','ProjectCars', Locale[Config.Locale].receive_shell_chop)
        end
        TriggerClientEvent('renzu_projectcars:deletechopped',-1,data.plate)
        local status = json.decode(data.status)
        local done = true
        for k,v in pairs(Config.parts) do
            if k ~= 'paint' and k ~= 'seat' and k ~= 'door' then
                xPlayer.addInventoryItem(k,1,data.model)
            end
        end
        xPlayer.addInventoryItem('door',data.seat,data.model)
        xPlayer.addInventoryItem('seat',data.seat,data.model)
        local chop = GlobalState.ChopVehicles
        chop[data.plate] = nil
        GlobalState.ChopVehicles = chop
    end

    function ProjectProgress(projectcars,props,xPlayer,chop)
        local status = json.decode(projectcars.status)
        local done = true
        for k,v in pairs(status) do
            if type(v) == 'number' and v > 0 then
            done = false
            end
            if type(v) == 'table' then
            for k,v2 in pairs(v) do
                if v2 > 0 then
                done = false
                end
            end
            end
        end
        if not chop and done then
            AddOwnedVehicles(projectcars,props,xPlayer)
        elseif chop and done then
            RemoveOwnedVehicles(projectcars,props,xPlayer)
        end
    end

    function firstToUpper(str)
        return (str:gsub("^%l", string.upper))
    end

    RegisterNetEvent('renzu_projectcars:removeitem')
    AddEventHandler('renzu_projectcars:removeitem', function(item,model)
    local xPlayer = GetPlayerFromId(source)
    xPlayer.removeInventoryItem(item, 1, model)
    end)

    RegisterNetEvent('renzu_projectcars:updatechopcar')
    AddEventHandler('renzu_projectcars:updatechopcar', function(data)
        local source = source
        local xPlayer = GetPlayerFromId(source)
        local chop = GlobalState.ChopVehicles
        local part = {}
        for k,v in pairs(chop[data.plate].status) do
            if string.find(data.part, k) then
                if type(v) == 'number' then
                    chop[data.plate].status[k] = 0
                    part = k
                else
                    for k2,v2 in pairs(v) do
                        if tonumber(k2) == tonumber(data.t) then
                            chop[data.plate].status[k][k2] = 0
                            part[k] = k2
                        end
                    end
                end
            end
        end
        if part then
            local ent = Entity(NetworkGetEntityFromNetworkId(data.net)).state
            local choppedvehicles = ent.chopped
            if not choppedvehicles then
                choppedvehicles = {}
            end
            if choppedvehicles[data.part] == nil then
                choppedvehicles[data.part] = true
            end
            ent.chopped = choppedvehicles
            TriggerClientEvent('renzu_projectcars:updatechopcar',-1,part,data.net,data.part,data.plate,xPlayer.identifier)
        end
        GlobalState.ChopVehicles = chop
        local chop_prog = chop[data.plate]
        chop_prog.status = json.encode(chop_prog.status)
        chop_prog.seat = data.seat
        ProjectProgress(chop_prog,{},xPlayer,true)
    end)

    RegisterNetEvent('renzu_projectcars:registerchop')
    AddEventHandler('renzu_projectcars:registerchop', function(data)
        local chop = GlobalState.ChopVehicles
        local newproject = {}
        for k,v in pairs(Config.parts) do
            if k == 'engine' or k == 'transmition' then
                newproject[k] = 1
            end
            if k == 'bonnet' and data.bonnet then
                newproject[k] = data.bonnet
            end
            if k == 'trunk' and data.trunk then
                newproject[k] = data.trunk
            end
            if k == 'exhaust' and data.exhaust then
                newproject[k] = data.exhaust
            end
            if k == 'wheel' and data.wheel then
                newproject[k] = data.wheel
            end
            if k == 'brake' and data.brake then
                newproject[k] = data.brake
            end
            if k == 'door' and data.seat then
                local doordata = {}
                for i = 0,3 do
                doordata[tostring(i)] = 1
                if data.seat == 2 and i == 2 or data.seat == 2 and i == 3 then
                    doordata[tostring(i)] = 0
                end
                end
                newproject[k] = doordata
            end
            if k == 'seat' and data.seat then
                local seatdata = {}
                for i = 0,data.seat-1 do
                    seatdata[tostring(i-1)] = 1
                end
                newproject[k] = seatdata
            end
        end
        if chop[data.plate] == nil then chop[data.plate] = {} end
        chop[data.plate].plate = data.plate
        chop[data.plate].status = newproject
        chop[data.plate].coord = data.coord
        chop[data.plate].heading = data.heading
        chop[data.plate].model = data.model
        chop[data.plate].frontman = data.frontman
        GlobalState.ChopVehicles = chop
        print("NEW CHOP DATA")
        TriggerClientEvent('renzu_projectcars:newchop',-1,data.net,data.plate)
    end)

    RegisterServerCallBack_('renzu_projectcars:GenPlate', function (source, cb, prefix)
        cb(GenPlate(prefix))
    end)

    function GenerateGarageId()
        local garages = GlobalState.RenterGarage
        local gen = math.random(100,65000)
        local repeatloop = false
        for k,v in pairs(garages) do
            if v == gen then
                repeatloop = true
            end
        end
        if not repeatloop then return gen end
        Wait(1)
        GenerateGarageId()
    end
    RegisterNetEvent('renzu_projectcars:garage')
    AddEventHandler('renzu_projectcars:garage', function(action,data)
        local source = source
        local xPlayer = GetPlayerFromId(source)
        if action == 'buy' and not GlobalState.RenterGarage[xPlayer.identifier] and xPlayer.getMoney() >= Config.EntraceFee then
            xPlayer.removeMoney(Config.EntraceFee)
            local garage = GlobalState.RenterGarage
            garage[xPlayer.identifier] = GenerateGarageId()
            GlobalState.RenterGarage = garage
        elseif action == 'buy' and GlobalState.RenterGarage[xPlayer.identifier] then
            TriggerClientEvent('renzu_notify:Notify', source,'error','ProjectCars', Locale[Config.Locale].alreadygarage..' - GarageID : '..GlobalState.RenterGarage[xPlayer.identifier])
        elseif action == 'buy' and xPlayer.getMoney() < Config.EntraceFee then
            TriggerClientEvent('renzu_notify:Notify', source,'error','ProjectCars', Locale[Config.Locale].notenoughmoney)
        end
        if action == 'enter' and GlobalState.RenterGarage[xPlayer.identifier] then
            --print(GlobalState.RenterGarage[xPlayer.identifier],GetPlayerPed(source),coord)
            SetPlayerRoutingBucket(source,GlobalState.RenterGarage[xPlayer.identifier])
            FreezeEntityPosition(GetPlayerPed(source),true)
            SetEntityCoords(GetPlayerPed(source),Config.GarageCoord.x,Config.GarageCoord.y,Config.GarageCoord.z)
            Wait(2000)
            FreezeEntityPosition(GetPlayerPed(source),false)
            local inside = GlobalState.GarageInside
            inside[xPlayer.identifier] = GlobalState.RenterGarage[xPlayer.identifier]
            GlobalState.GarageInside = inside
        end
        if action == 'exit' and GlobalState.RenterGarage[xPlayer.identifier] then
            --print(GlobalState.RenterGarage[xPlayer.identifier],GetPlayerPed(source),coord)
            SetPlayerRoutingBucket(source,0)
            FreezeEntityPosition(GetPlayerPed(source),true)
            SetEntityCoords(GetPlayerPed(source),data.buy.coord.x,data.buy.coord.y,data.buy.coord.z)
            Wait(2000)
            FreezeEntityPosition(GetPlayerPed(source),false)
            local inside = GlobalState.GarageInside
            inside[xPlayer.identifier] = false
            GlobalState.GarageInside = inside
        end
    end)
    RegisterNetEvent('renzu_projectcars:changestate')
    AddEventHandler('renzu_projectcars:changestate', function(plate,job,props,state,model,net)
        local source = source
        plate = string.gsub(plate, '^%s*(.-)%s*$', '%1')
        local xPlayer = GetPlayerFromId(source)
        local jobgarage = {}
        if GetResourceKvpString('renzu_garage') == nil then
            jobgarage[job] = {}
            SetResourceKvp('renzu_garage',json.encode(jobgarage))
        else
            jobgarage = json.decode(GetResourceKvpString('renzu_garage'))
        end
        if state and isPlateOwned(plate) then
            SqlFunc(Config.Mysql,'execute','DELETE FROM '..vehicletable..' WHERE TRIM(plate) = @plate',{['@plate'] = plate})
            if not jobgarage[job] then jobgarage[job] = {} end
            jobgarage[job][plate] = {}
            jobgarage[job][plate].props = props
            jobgarage[job][plate].coord = vector4(GetEntityCoords(NetworkGetEntityFromNetworkId(net)),GetEntityHeading(NetworkGetEntityFromNetworkId(net)))
            SetResourceKvp('renzu_garage',json.encode(jobgarage))
            GlobalState.JobGarage = jobgarage
            TaskLeaveVehicle(GetPlayerPed(source),NetworkGetEntityFromNetworkId(net),0)
            Wait(1000)
            DeleteEntity(NetworkGetEntityFromNetworkId(net))
            local tempvehicles = GlobalState.GVehicles or {} -- renzu_garage compatibility
            tempvehicles[plate] = nil
            GlobalState.GVehicles = tempvehicles
        elseif not state then
            local prop = json.encode(props)
            local type = 'car'
            if Config.framework == 'QBCORE' then
                type = model
            end
            local query = 'INSERT INTO '..vehicletable..' ('..owner..', plate, '..vehiclemod..', `'..stored..'`, '..garage_id..', `'..type_..'`) VALUES (@'..owner..', @plate, @props, @'..stored..', @'..garage_id..', @'..type_..')'
            if Config.framework == 'QBCORE' then
                query = 'INSERT INTO '..vehicletable..' ('..owner..', plate, '..vehiclemod..', `'..stored..'`, '..garage_id..', `'..type_..'`, citizenid, hash) VALUES (@'..owner..', @plate, @props, @'..stored..', @'..garage_id..', @'..type_..', @citizenid, @hash)'
            end
            local var = {
                ['@'..owner..'']   = xPlayer.identifier,
                ['@plate']   = plate,
                ['@props'] = prop,
                ['@'..stored..''] = 1,
                ['@'..garage_id..''] = Config.Default_garage,
                ['@'..type_..''] = type
            }
            if Config.framework == 'QBCORE' then
                var['@hash'] = tostring(GetHashKey(model))
                var['@citizenid'] = xPlayer.citizenid
            end
            SqlFunc(Config.Mysql,'execute',query,var)
            local jobgarage = {}
            jobgarage = json.decode(GetResourceKvpString('renzu_garage'))
            jobgarage[job][plate].coord = json.encode(jobgarage[job][plate].coord)
            TriggerClientEvent('renzu_projectcars:spawnfinishproject',source,jobgarage[job][plate],jobgarage[job][plate].props)
            jobgarage[job][plate] = nil
            SetResourceKvp('renzu_garage',json.encode(jobgarage))
            GlobalState.JobGarage = jobgarage
        end
    end)

    RegisterNetEvent('renzu_projectcars:releasejoborder')
    AddEventHandler('renzu_projectcars:releasejoborder', function(model,data)
        local jobgarage = {}
        local source = source
        local xPlayer = GetPlayerFromId(source)
        local job = xPlayer.job.name
        if GetResourceKvpString('renzu_garage') == nil then
            jobgarage[job] = {}
            SetResourceKvp('renzu_garage',json.encode(jobgarage))
        else
            jobgarage = json.decode(GetResourceKvpString('renzu_garage'))
        end
        local plate = nil
        if jobgarage[job] then
            for k,v in pairs(jobgarage[job]) do
                if GetHashKey(model) == v.props.model then
                    plate = v.props.plate
                    break
                end
            end
            if plate then
                jobgarage[job][plate] = nil
                SetResourceKvp('renzu_garage',json.encode(jobgarage))
                GlobalState.JobGarage = jobgarage
                TriggerClientEvent('renzu_notify:Notify', source, 'success','ProjectCars', Locale[Config.Locale].orderjobrelease..' $'..data.price)
                xPlayer.addMoney(data.price)
                local list = GlobalState.ProjectOrders
                list[job][model] = nil
                GlobalState.ProjectOrders = list
            else
                TriggerClientEvent('renzu_notify:Notify', source, 'success','ProjectCars', Locale[Config.Locale].cantrelease)
            end
        else
            TriggerClientEvent('renzu_notify:Notify', source, 'success','ProjectCars', Locale[Config.Locale].novehiclesingarage)
        end
    end)

    RegisterNetEvent('renzu_projectcars:requestorderlist')
    AddEventHandler('renzu_projectcars:requestorderlist', function()
        local list = {}
        local source = source
        local xPlayer = GetPlayerFromId(source)
        local job = xPlayer.job.name
        list[job] = {}
        local c = 0
        for k,v in pairs(Config.Vehicles) do
            if v.brand and Config.BuilderJobs[job] and Config.BuilderJobs[job].brands[v.brand:lower()] then
                local rand = math.random(1,1000)
                if not list[job][v.model] and rand < 500 and c < Config.MaxProjectOrderList then
                    list[job][v.model] = v
                    c = c + 1
                end
            end
        end
        GlobalState.ProjectOrders = list
        TriggerClientEvent('renzu_notify:Notify', source, 'success','ProjectCars', Locale[Config.Locale].orderlistrefresh)
    end)

    local Charset = {}
    for i = 65,  90 do table.insert(Charset, string.char(i)) end
    for i = 97, 122 do table.insert(Charset, string.char(i)) end

    local NumberCharset = {}
    for i = 48,  57 do table.insert(NumberCharset, string.char(i)) end

    function GetRandomLetter(length)
        math.randomseed(GetGameTimer())
        if length > 0 then
            return GetRandomLetter(length - 1) .. Charset[math.random(1, #Charset)]
        else
            return ''
        end
    end

    local temp = {}

    function GetPlates()
        local vehicles = SqlFunc(Config.Mysql,'fetchAll','SELECT * FROM '..vehicletable..'',{})
        for k,v in pairs(vehicles) do
            if v.plate ~= nil then
                temp[v.plate] = v
            end
        end
    end

    function isPlateOwned(plate)
        local success = false
        local vehicles = SqlFunc(Config.Mysql,'fetchAll','SELECT * FROM '..vehicletable..'',{})
        for k,v in pairs(vehicles) do
            if string.gsub(v.plate, '^%s*(.-)%s*$', '%1') == string.gsub(plate, '^%s*(.-)%s*$', '%1') then
                temp[v.plate] = v
                success = true
                return success
            end
        end
        return success
    end

    function FinalPlate()
        GetPlates()
        return GenPlate(prefix)
    end

    CreateThread(function()
        Wait(1000)
        GetPlates()
    end)

    function GenPlate(prefix)
        local plate = LetterRand()..' '..NumRand()
        if prefix then plate = prefix..' '..NumRand() end
        if temp[plate] == nil then
            return plate
        end
        Wait(1)
        return GenPlate(prefix)
    end

    function LetterRand()
        local emptyString = {}
        local randomLetter;
        while (#emptyString < 6) do
            randomLetter = GetRandomLetter(1)
            table.insert(emptyString,randomLetter)
            Wait(0)
        end
        local a = string.format("%s%s%s", table.unpack(emptyString)):upper()  -- "2 words"
        return a
    end

    function NumRand()
        local emptyString = {}
        local randomLetter;
        while (#emptyString < 6) do
            randomLetter = GetRandomNumber(1)
            table.insert(emptyString,randomLetter)
            Wait(0)
        end
        local a = string.format("%i%i%i", table.unpack(emptyString))  -- "2 words"
        return a
    end

    function GetRandomNumber(length)
        math.randomseed(GetGameTimer())
        if length > 0 then
            return GetRandomNumber(length - 1) .. NumberCharset[math.random(1, #NumberCharset)]
        else
            return ''
        end
    end

    RegisterCommand(Config.DeleteCommand, function(source, args, rawCommand)
        local source = source
        local xPlayer = GetPlayerFromId(source)
        if xPlayer.getGroup() ~= 'user' then
            local projectcars = GlobalState.ProjectCars
            local pedcoord = GetEntityCoords(GetPlayerPed(source))
            for k,v in pairs(projectcars) do
                local coord = json.decode(v.coord)
                local project_coord = vector3(coord.x,coord.y,coord.z)
                if #(pedcoord - project_coord) < 5 then
                    SqlFunc(Config.Mysql,'execute','DELETE FROM renzu_projectcars WHERE TRIM(UPPER(plate)) = @plate',{['@plate'] = v.plate})
                    TriggerClientEvent('renzu_projectcars:updateprojectable', -1, v.plate)
                    projectcars[k] = nil
                    break
                end
            end
            GlobalState.ProjectCars = projectcars
            TriggerClientEvent('renzu_notify:Notify', source, 'success','ProjectCars', Locale[Config.Locale].cardeleted)
        else
            TriggerClientEvent('renzu_notify:Notify', source, 'error','ProjectCars', Locale[Config.Locale].noperms)
        end
    end)
end)