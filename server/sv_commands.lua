RegisterCommand('addGarage', function(source, args, raw)
    if source == 0 then
        return
    end
    -- @TODO: check if player is admin
    if #args ~= 3 then
        TriggerClientEvent('chat:addMessage', source,
            'Garáže ^7» ^1Použití: ^0/addGarage <id> <display_name>  <blip>^0')
        return
    end
    local id = args[1]
    local displayName = args[2]
    local blip = args[3] == 'true' and 1 or 0
    local coords = GetEntityCoords(GetPlayerPed(source))
    local heading = GetEntityHeading(GetPlayerPed(source))
    local garage = {
        id = id,
        coords = vector4(coords.x, coords.y, coords.z, heading),
        display_name = displayName,
        blip = blip,
        zone_radius = {
            width = 5.0,
            height = 5.0
        }
    }
    MySQL.Async.execute(
        'INSERT INTO garages (id, coords, display_name, blip, zone_radius) VALUES (@id, @coords, @display_name, @blip, @zone_radius)',
        {
            ['@id'] = id,
            ['@coords'] = json.encode(garage.coords),
            ['@display_name'] = displayName,
            ['@blip'] = blip,
            ['@zone_radius'] = json.encode(garage.zone_radius)
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
    -- @TODO: check if player is admin
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
    -- @TODO: check if player is admin
    TriggerClientEvent('chat:addMessage', source, 'Garáže ^7» ^3Seznam garáží:^0')
    -- jo posilam tady nekolik client eventu ale bohuzel mi v chatu nejde newline char \n abych to dal do jednoho a je to jen admin command lol
    for _, garage in pairs(Garages) do
        TriggerClientEvent('chat:addMessage', source, '[^3' .. garage.id .. '^0] ' .. garage.display_name)
    end
end)

RegisterCommand('teleportGarage', function(source, args)
    -- @TODO: check if player is admin
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
    SetEntityCoords(GetPlayerPed(source), coords.x, coords.y, coords.z)
    SetEntityHeading(GetPlayerPed(source), coords.w)
    TriggerClientEvent('chat:addMessage', source, 'Garáže ^7» ^3Teleportuji...^0')
end)

RegisterCommand('giveVehicle', function(source, args, raw)
    -- @TODO: check if player is admin
    if #args ~= 4 then
        TriggerClientEvent('chat:addMessage', source,
            'Vozidla ^7» ^1Použití: ^0/giveVehicle <target> <model> <plate> <job>^0')
        return
    end
    local target = args[1]
    local model = args[2]
    local plate = args[3] == 'nil' and nil or args[3]
    local job = args[4] == 'nil' and nil or args[4]
    local esxTarget = esx.GetPlayerFromId(target)
    MySQL.Async.execute(
        'INSERT INTO users_vehicles (plate, owner, model, data, garage, stored, impound, type, job) VALUES (@plate, @owner, @model, @data, @garage, @stored, @impound, @type, @job)',
        {
            ['@plate'] = plate,
            ['@owner'] = esxTarget.identifier,
            ['@model'] = model,
            ['@data'] = json.encode({}),
            ['@garage'] = nil,
            ['@stored'] = true,
            ['@impound'] = false,
            ['@type'] = nil,
            ['@job'] = job
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
