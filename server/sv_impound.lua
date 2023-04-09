RegisterNetEvent('garages:impoundVehicle', function(plate, data)
    local Source = source
    local player = esx.GetPlayerFromId(Source)
    local entity = NetworkGetEntityFromNetworkId(data.netId)
    local playerPed = GetPlayerPed(Source)
    local distance = (#(GetEntityCoords(playerPed) - GetEntityCoords(entity)))
    if distance > 5 then
        TriggerClientEvent('garages:showNotification', Source, 'Odtahovka', 'Vozidlo je příliš daleko.', 'error')
        return
    end
    data.netId = nil
    TriggerClientEvent('garages:showNotification', Source, 'Odtahovka', 'Probíhá odtahovaní vozidla...', 'inform')
    SetTimeout(5000, function()
        DeleteEntity(entity)
        MySQL.Async.execute(
            'UPDATE owned_vehicles SET impound = @impound, impound_data = @impound_data WHERE plate = @plate', {
                ['@plate'] = plate,
                ['@impound_data'] = json.encode(data),
                ['@impound'] = true
            }
        )
        TriggerClientEvent('garages:showNotification', Source, 'Odtahovka', 'Vozidlo bylo odtaženo.', 'success')
    end)
end)

RegisterNetEvent('garages:requestImpoundVehicles', function(impound, job, other)
    local Source = source
    local player = esx.GetPlayerFromId(Source)
    local whereClause = ' WHERE impound = @impound'
    if not other then
        if job then
            whereClause = ' WHERE impound = @impound AND job = @job'
        else
            whereClause = ' WHERE impound = @impound AND owner = @owner'
        end
    end
    local vehicles = MySQL.Sync.fetchAll(
        'SELECT plate, model, garage, job, impound_data FROM owned_vehicles' .. whereClause,
        {
            ['@owner'] = player.identifier,
            ['@job'] = player.job.name,
            ['@impound'] = true
        }
    )
    local receivingVehicles = {}
    for _, vehicle in each(vehicles) do
        --print(vehicle.plate)
        vehicle.impound_data = vehicle.impound_data and json.decode(vehicle.impound_data) or nil
        receivingVehicles[vehicle.plate] = vehicle
    end
    TriggerClientEvent('garages:receiveImpoundVehicles', Source, receivingVehicles, job, other)
end)

RegisterNetEvent('garages:payImpound', function(plate, data)
    local Source = source
    local player = esx.GetPlayerFromId(Source)
    local playerPed = GetPlayerPed(Source)
    local coords = GetEntityCoords(playerPed)
    local impound = Impounds[data.impound]
    local distance = #(coords - vector3(impound.coords))
    if distance < impound.zone_radius.width or distance < impound.zone_radius.height then
        if not pay(Source, ImpoundPrice) then
            return
        end
        MySQL.Async.execute(
            'UPDATE owned_vehicles SET impound = @impound, stored = @stored, impound_data = @impound_data WHERE plate = @plate',
            {
                ['@plate'] = plate,
                ['@impound_data'] = json.encode({}),
                ['@impound'] = false,
                ['@stored'] = true
            }
        )
        TriggerClientEvent('garages:showNotification', Source, 'Odtahovka', 'Vozidlo přemístěno do garáže.',
            'success')
    end
end)
