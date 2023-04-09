esx = exports.es_extended:getSharedObject()
Jobs = nil
Garages = {}
loaded = false
Categories = {}

MySQL.ready(function()
    MySQL.Async.fetchAll('SELECT * FROM garages', {}, function(garages)
        for _, garage in each(garages) do
            local coords = json.decode(garage.coords)
            if coords.w == nil then
                coords.w = 0.0
            end
            garage.coords = vector4(coords.x, coords.y, coords.z, coords.w)
            garage.blip = garage.blip == 1
            garage.zone_radius = garage.zone_radius and json.decode(garage.zone_radius) or {
                width = 5.0,
                height = 5.0
            }
            Garages[garage.id] = garage
        end
        loaded = true
        print('^2[garages] ^5Succesfully loaded ^4' .. #garages .. '^5 garages^0')
    end)

    MySQL.Async.fetchAll('SELECT * FROM garages_categories', {}, function(categories)
        for _, category in ipairs(categories) do
            Categories[category.name] = category
            Categories[category.name].restriction = json.decode(category.restriction)
        end
        print('^2[garages] ^5Succesfully loaded ^4' .. #Categories .. '^5 categories^0')
    end)

    if ImportGarages then
        ImportCodeSignGaragesSql()
    end
end)

function ImportCodeSignGaragesSql()
    local imported = 0
    local existingIds = {}
    for i, data in ipairs(ImportGarages) do
        if existingIds[data.Garage_ID] then
            print('^1[garages] ^3Garage with id ^1' .. data.Garage_ID .. '^3 already exists^0')
        else
            existingIds[data.Garage_ID] = true

            local affectedRow = MySQL.Sync.execute(
                'INSERT INTO garages (id, coords, display_name, blip, zone_radius, type) VALUES (@id, @coords, @display_name, @blip, @zone_radius, @type)',
                {
                    ['@id'] = data.Garage_ID,
                    ['@coords'] = json.encode(vector4(data.x_2, data.y_2, data.z_2, data.h_2)),
                    ['@display_name'] = data.Garage_ID,
                    ['@blip'] = data.EnableBlip and 1 or 0,
                    ['@zone_radius'] = json.encode({ width = data.Dist, height = data.Dist }),
                    ['@type'] = data.Type
                }
            )
            if affectedRow > 0 then
                imported = imported + 1
            end
        end
    end
    print('^2[garages] ^5Succesfully imported ^4' .. imported .. '^5 garages^0')
end

RegisterNetEvent('garages:load', function()
    local Source = source
    while not loaded do
        print('^2[garages] ^5Waiting for garages to load...^0')
        Wait(2000)
    end
    if Jobs == nil then
        Jobs = esx.GetJobs()
    end
    TriggerClientEvent('garages:loaded', Source, Garages)
end)

RegisterNetEvent('garages:requestVehicleDetails', function(garageId)
    local Source = source
    local player = esx.GetPlayerFromId(Source)
    local job = player.job.name
    local vehicles = {}
    local playerPed = GetPlayerPed(Source)
    local garage = Garages[garageId]
    local distance = #(GetEntityCoords(playerPed) - vector3(garage.coords))
    if distance < garage.zone_radius.width or distance < garage.zone_radius.height then
        -- if job == nil then
        --     vehicles = MySQL.Sync.fetchAll(
        --         'SELECT plate, model, garage, stored, impound, type, data, job FROM users_vehicles WHERE owner = @owner',
        --         {
        --             ['@owner'] = player.identifier,
        --         }
        --     )
        -- else
        --     if player.job.name ~= job then
        --         return
        --     end
        --     vehicles = MySQL.Sync.fetchAll(
        --         'SELECT plate, model, garage, stored, impound, type, category, data, job FROM users_vehicles WHERE job = @job',
        --         {
        --             ['@job'] = job,
        --         }
        --     )
        -- end
        vehicles = MySQL.Sync.fetchAll(
            'SELECT plate, model, vehicle, garage, stored, impound, type, category, job, impound_data FROM owned_vehicles WHERE (job = @job OR owner = @owner) AND type = @type',
            {
                ['@job'] = job,
                ['@owner'] = player.identifier,
                ['@type'] = garage.type
            }
        )
        local minimalManagementGrade = getMinimalManagementGrade(job)
        local receivingVehicles = {}
        for _, vehicle in each(vehicles) do
            vehicle.data = vehicle.vehicle
            vehicle.data = json.decode(vehicle.data)
            vehicle.model = vehicle.model or vehicle.data.model

            vehicle.data = {
                engineHealth = vehicle.data.engineHealth,
            }
            vehicle.stored = vehicle.stored == 1
            vehicle.impound = vehicle.impound == 1
            vehicle.impound_data = vehicle.impound_data and json.decode(vehicle.impound_data) or nil
            receivingVehicles[vehicle.plate] = vehicle
        end
        local categories = {}
        local isManagement = player.job.grade >= minimalManagementGrade and job ~= nil
        if job ~= nil then
            categories = getJobCategories(job, tonumber(player.job.grade), isManagement)
        end
        local grades = nil
        if isManagement then
            grades = Jobs[job].grades or {}
        end
        TriggerClientEvent('garages:receiveVehicleDetails', Source, garageId, receivingVehicles, categories, job,
            isManagement, grades)
    end
end)

RegisterNetEvent('garages:spawnVehicle', function(plate, garageId, money)
    local Source = source
    local playerPed = GetPlayerPed(Source)
    local garage = Garages[garageId]
    local distance = #(GetEntityCoords(playerPed) - vector3(garage.coords))
    if distance < garage.zone_radius.width or distance < garage.zone_radius.height then
        local vehicleOutside = isVehicleOutside(plate)
        if vehicleOutside then
            TriggerClientEvent('garages:sp', Source, nil, n)
            return
        end
        if money then
            if not pay(Source, money) then
                return
            end
        end
        local vehicle = MySQL.single.await(
            'SELECT * FROM owned_vehicles WHERE plate = @plate',
            {
                ['@plate'] = plate,
            }
        )
        vehicle.data = vehicle.vehicle
        vehicle.data = json.decode(vehicle.data)
        vehicle.model = vehicle.model or vehicle.data.model
        TriggerClientEvent('garages:spawnVehicle', Source, vehicle, garageId)
        MySQL.Async.execute('UPDATE owned_vehicles SET stored = @stored WHERE plate = @plate', {
            ['@stored'] = false,
            ['@plate'] = plate,
        })
    end
end)

RegisterNetEvent('garages:requestOutside', function(vehicle, garageId, parent)
    local Source = source
    local vehicleOutside = isVehicleOutside(vehicle.plate)
    TriggerClientEvent('garages:receiveOutside', Source, vehicle, garageId, parent, vehicleOutside)
end)

function getJobCategories(job, grade, isManagement)
    local jobCategories = {}
    for name, category in pairs(Categories) do
        if category.job == job then
            jobCategories[name] = category
            jobCategories[name].allowed = true
            local restrictions = category.restriction
            if not isManagement and restrictions ~= nil and restrictions ~= {} then
                if restrictions.minimal_grade ~= nil then
                    --print(grade, restrictions.minimal_grade)
                    if grade < restrictions.minimal_grade then
                        jobCategories[name].allowed = false
                    end
                end
                if restrictions.only_grade ~= nil then
                    if grade ~= restrictions.only_grade then
                        jobCategories[name].allowed = false
                    end
                end
            end
        end
    end
    return jobCategories
end

RegisterNetEvent('garages:storeVehicle', function(garageId, plate, vehicle, vehicleData)
    local Source = source
    vehicle = NetworkGetEntityFromNetworkId(vehicle)
    local model = vehicleData.modelArchetypeName
    local esxPlayer = esx.GetPlayerFromId(Source)
    local vehicleRow = MySQL.single.await(
        'SELECT owner, job FROM owned_vehicles WHERE plate = @plate',
        {
            ['@plate'] = plate,
        }
    )
    if vehicleRow == nil then
        TriggerClientEvent('garages:showNotification', Source, 'Garáž', 'Toto vozidlo není tvé ani tvé firmy.',
            'error')
        return
    end
    local canStore = (vehicleRow.job == nil and vehicleRow.owner == esxPlayer.identifier) or
        (vehicleRow.job ~= nil and esxPlayer.job.name == vehicleRow.job)
    if not canStore then
        TriggerClientEvent('garages:showNotification', Source, 'Garáž', 'Toto vozidlo není tvé ani tvé firmy.',
            'error')
        return
    end
    -- print(vehicleRow.job)
    -- print(esxPlayer.job.name)
    -- print(vehicleRow.owner)
    -- print(esxPlayer.identifier)
    vehicleData.modelArchetypeName = nil
    local affectedRows = MySQL.Sync.execute(
        'UPDATE owned_vehicles SET model = @model, stored = @stored, vehicle = @data, garage = @garage WHERE plate = @plate',
        {
            ['@model'] = model,
            ['@stored'] = true,
            ['@data'] = json.encode(vehicleData),
            ['@garage'] = garageId,
            ['@plate'] = plate,
        }
    )
    if affectedRows then
        DeleteEntity(vehicle)
        TriggerClientEvent('garages:showNotification', Source, 'Garáž', 'Vozidlo bylo úspěšně uloženo.', 'success')
    else
        TriggerClientEvent('garages:showNotification', Source, 'Garáž', 'Něco se pokazilo při ukládání vozidla.',
            'error')
    end
end)

RegisterNetEvent('garages:createCategory', function(garage, data)
    local Source = source
    local restriction = {
        only_grade = data.only_grade,
        minimal_grade = data.minimal_grade
    }
    local affectedRow = MySQL.Sync.execute(
        'INSERT INTO garages_categories (name, job, restriction) VALUES (@name, @job, @restriction)',
        {
            ['@name'] = data.name,
            ['@job'] = data.job,
            ['@restriction'] = json.encode(restriction)
        }
    )
    if affectedRow then
        Categories[data.name] = {
            name = data.name,
            job = data.job,
            restriction = restriction,
            type = data.type or 'car'
        }
        TriggerClientEvent('garages:createdCategory', Source, garage)
    end
end)

RegisterNetEvent('garages:moveVehicle', function(plate, category)
    -- print(plate, category)
    MySQL.Async.execute(
        'UPDATE owned_vehicles SET category = @category WHERE plate = @plate',
        {
            ['@category'] = category,
            ['@plate'] = plate
        }
    )
end)

RegisterNetEvent('garages:deleteCategory', function(category)
    local Source = source
    local vehicles = MySQL.Sync.fetchAll(
        'SELECT plate FROM owned_vehicles WHERE category = @category',
        {
            ['@category'] = category
        }
    )
    local job = esx.GetPlayerFromId(Source).job.name
    local i = 1
    local plate = nil
    local params = {}
    for _, vehicle in each(vehicles) do
        if plate == nil then
            plate = 'plate = @plate' .. i
        else
            plate = plate .. ' OR plate = @plate' .. i
        end
        params['@plate' .. i] = vehicle.plate
        i = i + 1
    end

    if plate ~= nil then
        MySQL.Sync.execute(
            'UPDATE owned_vehicles SET category = NULL WHERE ' .. plate,
            params
        )
    end
    local affectedRow = MySQL.Sync.execute(
        'DELETE FROM garages_categories WHERE name = @name AND job = @job',
        {
            ['@name'] = category,
            ['@job'] = job
        }
    )
    if affectedRow then
        Categories[category] = nil
    end
end)

RegisterNetEvent('garages:moveToPersonal', function(vehicle)
    local Source = source
    local player = esx.GetPlayerFromId(Source)
    if player.job.name ~= vehicle.job then
        return
    end
    MySQL.Async.execute(
        'UPDATE owned_vehicles SET job = NULL, owner = @owner WHERE plate = @plate',
        {
            ['@owner'] = player.identifier,
            ['@plate'] = vehicle.plate
        }
    )
end)

RegisterNetEvent('garages:updateMinimumManagementGrade', function(grade, garageId)
    local Source = source
    local player = esx.GetPlayerFromId(Source)
    local playerPed = GetPlayerPed(Source)
    local garage = Garages[garageId]
    local distance = #(GetEntityCoords(playerPed) - vector3(garage.coords))
    -- if distance > garage.zone_radius.width or distance > garage.zone_radius.height then
    local job = player.job.name
    local affectedRow = MySQL.Sync.execute('UPDATE garages_jobs SET grade = @grade WHERE job = @job', {
        ['@grade'] = grade,
        ['@job'] = job
    })
    if affectedRow then
        TriggerClientEvent('garages:showNotification', Source, 'Firemní garáž',
            'Minimální pozice pro správu garáže byla nastavena na ' ..
            Jobs[job].grades[tostring(grade)].label .. '.', 'success')
    end
    if affectedRow and affectedRow == 0 then
        MySQL.Async.execute('INSERT INTO garages_jobs (job, grade) VALUES (@job, @grade)', {
            ['@grade'] = grade,
            ['@job'] = job
        })
    end
    -- end
end)

function pay(source, money)
    local player = esx.GetPlayerFromId(source)
    if player.getMoney() < money then
        if player.getAccount('bank').money < money then
            TriggerClientEvent('garages:showNotification', source, 'Garáže',
                'Nemáš dostatek peněz na bankovním účtě ani v kapse.', 'error')
            return false
        end
        player.removeAccountMoney('bank', money)
        TriggerClientEvent('garages:showNotification', source, 'Garáže',
            'Zaplatil jsi ' .. money .. '$ z účtu za vytáhnutí.', 'success')
        return true
    else
        player.removeMoney(money)
        TriggerClientEvent('garages:showNotification', source, 'Garáže',
            'Zaplatil jsi ' .. money .. '$ z kapsy za vytáhnutí.', 'success')
        return true
    end
end

function isPlayerAdmin(source)
    if source == 0 then return true end
    local player = esx.GetPlayerFromId(source)
    return player.getGroup() == 'admin' or player.getGroup() == 'superadmin'
end

exports('saveVehicleProperties', function(plate, data)
    MySQL.Async.execute(
        'UPDATE owned_vehicles SET vehicle = @data WHERE plate = @plate',
        {
            ['@data'] = json.encode(vehicleData),
            ['@plate'] = plate
        }
    )
end)

function getMinimalManagementGrade(job)
    return MySQL.Sync.fetchScalar(
            'SELECT grade FROM garages_jobs WHERE job = @job',
            {
                ['@job'] = job,
            }
        ) or 0
end

function isVehicleOutside(plate)
    for k, entity in pairs(GetAllVehicles()) do
        if DoesEntityExist(entity) then
            local entityPlate = GetVehicleNumberPlateText(entity)
            entityPlate = string.gsub(entityPlate, '%s+', '')
            if entityPlate == plate and GetVehicleEngineHealth(entity) > 0 then
                return GetEntityCoords(entity)
            end
        end
    end
    return nil
end

RegisterNetEvent('garages:syncLocks', function(entity, num, vehiclePlayers)
    if vehiclePlayers ~= nil then
        for k, v in pairs(vehiclePlayers) do
            TriggerClientEvent('garages:syncLocks', v, entity, num)
        end
    end
    SetVehicleDoorsLocked(NetworkGetEntityFromNetworkId(entity), num)
end)
