esx = exports.es_extended:getSharedObject()
esx.Jobs = esx.GetJobs()
Garages = {}
loaded = false
Categories = {}
MySQL.ready(function()
    --[[
    CREATE TABLE `garages` (
    `id` VARCHAR(50) NOT NULL DEFAULT '',
    `coords` JSON NOT NULL,
    `display_name` VARCHAR(50) NOT NULL DEFAULT '',
    `job` VARCHAR(50) NOT NULL DEFAULT '',
    `blip` TINYINT NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`)
    )
    COLLATE='utf8mb4_unicode_ci';

    CREATE TABLE `garages_categories` (
	`name` VARCHAR(50) NOT NULL DEFAULT '' COLLATE 'utf8mb4_unicode_ci',
	`parent` VARCHAR(50) NULL DEFAULT NULL,
	`job` VARCHAR(50) NOT NULL DEFAULT '' COLLATE 'utf8mb4_unicode_ci',
	`restriction` LONGTEXT NOT NULL COLLATE 'utf8mb4_unicode_ci',
	PRIMARY KEY (`name`) USING BTREE
    )
    COLLATE='utf8mb4_unicode_ci'
    ENGINE=InnoDB
    ;

    CREATE TABLE `users_vehicles` (
    `plate` VARCHAR(50) NOT NULL DEFAULT '' COLLATE 'utf8mb4_unicode_ci',
    `owner` VARCHAR(46) NULL DEFAULT NULL COLLATE 'utf8mb4_unicode_ci',
    `model` VARCHAR(50) NOT NULL DEFAULT '' COLLATE 'utf8mb4_unicode_ci',
    `data` LONGTEXT NOT NULL COLLATE 'utf8mb4_bin',
    `garage` VARCHAR(50) NOT NULL DEFAULT '' COLLATE 'utf8mb4_unicode_ci',
    `stored` TINYINT(4) NOT NULL DEFAULT '0',
    `impound` TINYINT(4) NOT NULL DEFAULT '0',
    `type` VARCHAR(50) NOT NULL DEFAULT '0' COLLATE 'utf8mb4_unicode_ci',
    `job` VARCHAR(50) NOT NULL DEFAULT '0' COLLATE 'utf8mb4_unicode_ci',
    `category` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_unicode_ci',
    PRIMARY KEY (`plate`) USING BTREE,
    CONSTRAINT `data` CHECK (json_valid(`data`))
    )
    COLLATE='utf8mb4_unicode_ci'
    ENGINE=InnoDB
    ;
    ]]
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
end)

RegisterNetEvent('garages:load', function()
    local Source = source
    while not loaded do
        print('^2[garages] ^5Waiting for garages to load...^0')
        Wait(2000)
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
            'SELECT plate, model, garage, stored, impound, type, category, data, job, impound_data FROM users_vehicles WHERE (job = @job OR owner = @owner) AND type = @type',
            {
                ['@job'] = job,
                ['@owner'] = player.identifier,
                ['@type'] = garage.type
            }
        )
        local minimalManagementGrade = getMinimalManagementGrade(job)
        local receivingVehicles = {}
        for _, vehicle in each(vehicles) do
            vehicle.data = json.decode(vehicle.data)
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
            grades = esx.Jobs[job].grades or {}
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
        if money then
            if not pay(Source, money) then
                return
            end
        end
        local vehicle = MySQL.single.await(
            'SELECT * FROM users_vehicles WHERE plate = @plate',
            {
                ['@plate'] = plate,
            }
        )
        TriggerClientEvent('garages:spawnVehicle', Source, vehicle, garageId)
        MySQL.Async.execute('UPDATE users_vehicles SET stored = @stored WHERE plate = @plate', {
            ['@stored'] = false,
            ['@plate'] = plate,
        })
    end
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
    local esxPlayer = esx.GetPlayerFromId(Source)
    local vehicleRow = MySQL.single.await(
        'SELECT owner, job FROM users_vehicles WHERE plate = @plate',
        {
            ['@plate'] = plate,
        }
    )
    if vehicleRow == nil then
        esxPlayer.showNotification('Toto vozidlo není tvé ani tvé firmy.', 'error')
        return
    end
    local canStore = (vehicleRow.job == nil and vehicleRow.owner == esxPlayer.identifier) or
        (vehicleRow.job ~= nil and esxPlayer.job.name == vehicleRow.job)
    if not canStore then
        esxPlayer.showNotification('Toto vozidlo není tvé ani tvé firmy.', 'error')
        return
    end
    -- print(vehicleRow.job)
    -- print(esxPlayer.job.name)
    -- print(vehicleRow.owner)
    -- print(esxPlayer.identifier)
    local affectedRows = MySQL.Sync.execute(
        'UPDATE users_vehicles SET stored = @stored, data = @data, garage = @garage WHERE plate = @plate',
        {
            ['@stored'] = true,
            ['@data'] = json.encode(vehicleData),
            ['@garage'] = garageId,
            ['@plate'] = plate,
        }
    )
    if affectedRows then
        DeleteEntity(vehicle)
        esxPlayer.showNotification('Vozidlo bylo úspěšně uloženo.', 'green')
    else
        esxPlayer.showNotification('Něco se pokazilo při ukládání vozidla.', 'error')
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
            restriction = restriction
        }
        TriggerClientEvent('garages:createdCategory', Source, garage)
    end
end)

RegisterNetEvent('garages:moveVehicle', function(plate, category)
    -- print(plate, category)
    MySQL.Async.execute(
        'UPDATE users_vehicles SET category = @category WHERE plate = @plate',
        {
            ['@category'] = category,
            ['@plate'] = plate
        }
    )
end)

RegisterNetEvent('garages:deleteCategory', function(category)
    local Source = source
    local vehicles = MySQL.Sync.fetchAll(
        'SELECT plate FROM users_vehicles WHERE category = @category',
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
            'UPDATE users_vehicles SET category = NULL WHERE ' .. plate,
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
        'UPDATE users_vehicles SET job = NULL, owner = @owner WHERE plate = @plate',
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
    if distance > garage.zone_radius.width or distance > garage.zone_radius.height then
        local job = player.job.name
        local affectedRow = MySQL.Sync.execute('UPDATE garages_jobs SET grade = @grade WHERE job = @job', {
            ['@grade'] = grade,
            ['@job'] = job
        })
        if affectedRow then
            player.showNotification('Minimální pozice pro správu garáže byla nastavena na ' ..
                esx.Jobs[job].grades[tostring(grade)].label .. '.', 'green')
        end
        if affectedRow and affectedRow == 0 then
            MySQL.Async.execute('INSERT INTO garages_jobs (job, grade) VALUES (@job, @grade)', {
                ['@grade'] = grade,
                ['@job'] = job
            })
        end
    end
end)

function pay(source, money)
    local player = esx.GetPlayerFromId(source)
    if player.getMoney() < money then
        if player.getAccount('bank').money < money then
            player.showNotification('Nemáš dostatek peněz na bankovním účtě ani v kapse.', 'error')
            return false
        end
        player.removeAccountMoney('bank', money)
        player.showNotification('Zaplatil jsi ' .. money .. '$ z účtu za vytáhnutí.')
        return true
    else
        player.removeMoney(money)
        player.showNotification('Zaplatil jsi ' .. money .. '$ z kapsy za vytáhnutí.')
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
        'UPDATE users_vehicles SET data = @data WHERE plate = @plate',
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
