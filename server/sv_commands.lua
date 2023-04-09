RegisterCommand('addGarage', function(source, args, raw)
    if source == 0 then
        return
    end
    if not isPlayerAdmin(source) then
        TriggerClientEvent('chat:addMessage', source,
            'Vozidla ^7» ^1Na toto nemáš dostatečná oprávnění^0')
        return
    end
    if #args ~= 4 then
        TriggerClientEvent('chat:addMessage', source,
            'Garáže ^7» ^1Použití: ^0/addGarage <id> <display_name> <blip> <type>^0')
        return
    end
    local id = args[1]
    local displayName = args[2]
    local blip = args[3] == 'true'
    local vehType = args[4] == 'nil' and 'car' or args[4]
    local playerPed = GetPlayerPed(source)
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    local garage = {
        id = id,
        coords = vector4(coords.x, coords.y, coords.z, heading),
        display_name = displayName,
        blip = blip,
        zone_radius = {
            width = 5.0,
            height = 5.0
        },
        type = vehType
    }
    MySQL.Async.execute(
        'INSERT INTO garages (id, coords, display_name, blip, zone_radius, type) VALUES (@id, @coords, @display_name, @blip, @zone_radius, @type)',
        {
            ['@id'] = id,
            ['@coords'] = json.encode(garage.coords),
            ['@display_name'] = displayName,
            ['@blip'] = blip,
            ['@zone_radius'] = json.encode(garage.zone_radius),
            ['@type'] = vehType
        }, function(rowsChanged)
            if rowsChanged == 1 then
                TriggerClientEvent('chat:addMessage', source,
                    'Garáže ^7» ^2Garáž ^0' .. id .. '^2 byla úspěšně přidána^0')
                Garages[id] = garage
                TriggerClientEvent('garages:addGarage', -1, garage)
            else
                TriggerClientEvent('chat:addMessage', source,
                    'Garáže ^7» ^1Nastala chyba při přidávání garáže^0')
            end
        end)
end)

RegisterCommand('deleteGarage', function(source, args, raw)
    if source == 0 then
        return
    end
    if not isPlayerAdmin(source) then
        TriggerClientEvent('chat:addMessage', source,
            'Vozidla ^7» ^1Na toto nemáš dostatečná oprávnění^0')
        return
    end
    if #args ~= 1 then
        TriggerClientEvent('chat:addMessage', source,
            'Garáže ^7» ^1Použití: ^0/deleteGarage <id>^0')
        return
    end
    local id = args[1]
    MySQL.Async.execute('DELETE FROM garages WHERE id = @id', { ['@id'] = id }, function(rowsChanged)
        if rowsChanged == 1 then
            TriggerClientEvent('chat:addMessage', source,
                'Garáže ^7» ^2Garáž ^0' .. id .. '^2 byla úspěšně smazána^0')
            Garages[id] = nil
            TriggerClientEvent('garages:deleteGarage', -1, id)
        else
            TriggerClientEvent('chat:addMessage', source,
                'Garáže ^7» ^1Nastala chyba při mazání garáže^0')
        end
    end)
end)

RegisterCommand('garages', function(source)
    if not isPlayerAdmin(source) then
        TriggerClientEvent('chat:addMessage', source,
            'Vozidla ^7» ^1Na toto nemáš dostatečná oprávnění^0')
        return
    end
    TriggerClientEvent('chat:addMessage', source, 'Garáže ^7» ^3Seznam garáží:^0')
    -- jo posilam tady nekolik client eventu ale bohuzel mi v chatu nejde newline char \n abych to dal do jednoho a je to jen admin command lol
    for _, garage in pairs(Garages) do
        TriggerClientEvent('chat:addMessage', source, '[^3' .. garage.id .. '^0] ' .. garage.display_name)
    end
end)

RegisterCommand('teleportGarage', function(source, args)
    if not isPlayerAdmin(source) then
        TriggerClientEvent('chat:addMessage', source,
            'Vozidla ^7» ^1Na toto nemáš dostatečná oprávnění^0')
        return
    end
    if source == 0 then
        return
    end
    if #args ~= 1 then
        TriggerClientEvent('chat:addMessage', source,
            'Garáže ^7» ^1Použití: ^0/teleportGarage <id>^0')
        return
    end
    local id = args[1]
    local garage = Garages[id]
    if garage == nil then
        TriggerClientEvent('chat:addMessage', source,
            'Garáže ^7» ^1Garáž ^0' .. id .. '^1 neexistuje^0')
        return
    end
    local coords = garage.coords
    local playerPed = GetPlayerPed(source)
    SetEntityCoords(playerPed, coords.x, coords.y, coords.z)
    SetEntityHeading(playerPed, coords.w)
    TriggerClientEvent('chat:addMessage', source, 'Garáže ^7» ^3Teleportuji...^0')
end)

RegisterCommand('giveVehicle', function(source, args, raw)
    if not isPlayerAdmin(source) then
        TriggerClientEvent('chat:addMessage', source,
            'Vozidla ^7» ^1Na toto nemáš dostatečná oprávnění^0')
        return
    end
    if #args ~= 5 then
        TriggerClientEvent('chat:addMessage', source,
            'Vozidla ^7» ^1Použití: ^0/giveVehicle <target> <model> <plate> <job> <type>^0')
        return
    end
    local target = args[1]
    local model = args[2]
    local plate = args[3] == 'nil' and nil or args[3]
    local job = args[4] == 'nil' and nil or args[4]
    local vehType = args[5] == 'nil' and 'car' or args[5]
    local esxTarget = esx.GetPlayerFromId(target)
    MySQL.Async.execute(
        'INSERT INTO owned_vehicles (plate, owner, model, vehicle, garage, stored, impound, type, job) VALUES (@plate, @owner, @model, @data, @garage, @stored, @impound, @type, @job)',
        {
            ['@plate'] = plate,
            ['@owner'] = esxTarget.identifier,
            ['@model'] = model,
            ['@data'] = json.encode({}),
            ['@garage'] = nil,
            ['@stored'] = true,
            ['@impound'] = false,
            ['@job'] = job,
            ['@type'] = vehType
        }, function(rowsChanged)
            if rowsChanged == 1 then
                local admin = 'Konzole'
                if source ~= 0 then
                    admin = GetPlayerName(source)
                end
                TriggerClientEvent('chat:addMessage', source,
                    'Vozidla ^7» ^2Vozidlo ^0' .. model .. '^2 bylo úspěšně přidáno^0')
                TriggerClientEvent('chat:addMessage', target,
                    'Vozidla ^7» ^2Obdržel jsi vozidlo ^0' .. model .. '^2 od ^0' .. admin .. '^2^0')
            else
                TriggerClientEvent('chat:addMessage', source,
                    'Vozidla ^7» ^1Nastala chyba při přidávání vozidla^0')
            end
        end)
end)

RegisterCommand('firma', function(source, args)
    if source == 0 then
        return
    end

    local vehicle = GetVehiclePedIsIn(GetPlayerPed(source))
    if vehicle == nil or not DoesEntityExist(vehicle) then
        showNotification('Garáže', 'Musíš být ve vozidle', 'error')
        return
    end
    local player = esx.GetPlayerFromId(source)
    local plate = GetVehicleNumberPlateText(vehicle)
    plate = string.gsub(plate, '%s+', '')
    local job = player.job.name
    local minimalManagementGrade = getMinimalManagementGrade(job)
    if minimalManagementGrade == nil then -- k tomuhle by nikdy nemělo dojít, ale radši to tu nechám pro jistotu :D
        showNotification('Garáže', 'Tento job nemá garáž nebo nastavenou pozici pro správu.', 'error')
        return
    end
    --print('minimalManagementGrade: ' .. minimalManagementGrade)
    --print('player.job.grade: ' .. player.job.grade)
    if player.job.grade < minimalManagementGrade then
        showNotification('Garáže',
            'Pro přepsání vozidla na firmu musíš mít povolené spravování firemní garáže na tvé pozici',
            'error')
        return
    end
    local row = MySQL.Sync.execute(
        'UPDATE owned_vehicles SET job = @job WHERE plate = @plate',
        {
            ['@job'] = job,
            ['@plate'] = plate
        }
    )
    if row then
        if row < 1 then
            showNotification('Garáže', 'Toto vozidlo není tvé.', 'error')
            return
        else
            showNotification('Garáže', 'Vozidlo ' .. plate .. ' bylo přepsáno na firmu.', 'success')
        end
    else
        showNotification('Garáže', 'Nastala chyba při přepisování vozidla na firmu.', 'error')
    end
end)
