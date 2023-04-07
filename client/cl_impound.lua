local currentImpound = nil

Citizen.CreateThread(function()
    for k, v in pairs(Impounds) do
        if v.blip then
            local blip = AddBlipForCoord(v.coords)
            SetBlipSprite(blip, 67)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, 0.8)
            SetBlipColour(blip, 4)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString('<font face="OpenSans-SemiBold">Odtahovka</font>')
            EndTextCommandSetBlipName(blip)
        end

        TriggerEvent('polyZone:createZone', 'impound_' .. k, 'box', {
            coords = v.coords,
            width = v.zone_radius.width,
            height = v.zone_radius.height,
            heading = v.coords.w,
            useZ = true
        })
    end
end)

AddEventHandler('polyZone:enteredZone', function(zoneName)
    if not zoneName:match('impound_') then
        return
    end
    local impound = zoneName:match('impound_(.*)')
    currentImpound = impound
    Citizen.CreateThread(function()
        while currentImpound == impound do
            Citizen.Wait(0)
            local coords = Impounds[impound].coords
            local zone_radius = Impounds[impound].zone_radius
            esx.ShowHelpNotification('~INPUT_CONTEXT~ <font face="OpenSans-SemiBold">Odtahovka</font>')
            -- DrawMarker(43, coords.x, coords.y, coords.z - 3.0, 0, 0, 0, 0, 0, coords.w, zone_radius.height,
            --     zone_radius.width, 5.0, 0, 0, 255, 100)
            if IsControlJustPressed(0, 38) then
                openImpoundMenu()
            end
        end
    end)
end)

AddEventHandler('polyZone:leftZone', function(zoneName)
    if not zoneName:match('impound_') then
        return
    end
    currentImpound = nil
end)

function openImpoundMenu(vehicles, job, other)
    if vehicles == nil then
        local elements = {
            {
                label = 'Moje vozidla',
                action = 'personal'
            },
            {
                label = 'Firemní vozidla',
                action = 'job'
            }
        }

        if isJobImpoundManagement(esx.PlayerData.job.name) then
            table.insert(elements, {
                label = 'Ostatní vozidla',
                action = 'other'
            })
        end
        esx.UI.Menu.Open('default', 'garages', 'impound', {
            title = 'Odtahovka - ' .. Impounds[currentImpound].display_name,
            align = 'top-right',
            elements = elements
        }, function(data, menu)
            if data.current.action == 'personal' then
                TriggerServerEvent('garages:requestImpoundVehicles', currentImpound)
            elseif data.current.action == 'job' then
                TriggerServerEvent('garages:requestImpoundVehicles', currentImpound, true)
            elseif data.current.action == 'other' then
                TriggerServerEvent('garages:requestImpoundVehicles', currentImpound, nil, true)
            end
        end, function(data, menu)
            menu.close()
        end)
        return
    end
    local elements = {}
    for plate, vehicle in pairs(vehicles) do
        if other then
            table.insert(elements, {
                label = GetDisplayNameFromVehicleModel(vehicle.model) .. ' - ' .. plate,
                plate = plate
            })
        else
            if job and vehicle.job == esx.PlayerData.job.name then
                table.insert(elements, {
                    label = GetDisplayNameFromVehicleModel(vehicle.model) .. ' - ' .. plate,
                    plate = plate
                })
            elseif not job and vehicle.job == nil then
                table.insert(elements, {
                    label = GetDisplayNameFromVehicleModel(vehicle.model) .. ' - ' .. plate,
                    plate = plate
                })
            end
        end
    end
    esx.UI.Menu.Open('default', 'garages', 'personal_impound', {
        title = 'Odtahovka - ' .. Impounds[currentImpound].display_name,
        align = 'top-right',
        elements = elements,
    }, function(data, menu)
        menu.close()
        local plate = data.current.plate
        local vehicle = vehicles[plate]
        local impoundData = vehicle.impound_data
        if impoundData.impound ~= nil and impoundData.impound ~= currentImpound then
            esx.ShowNotification('Toto vozidlo je na odtahovce v ' .. Impounds[impoundData.impound].display_name .. '.',
                'error')
            return
        end
        if impoundData.authority and not impoundData.self and isJobImpoundManagement(impoundData.authority.job) and not isJobImpoundManagement(esx.PlayerData.job.name) then
            esx.ShowNotification('Toto vozidlo ti může vytáhnout pouze policista.', 'error')
            return
        end
        TriggerServerEvent('garages:payImpound', plate, impoundData)
    end, function(data, menu)
        menu.close()
    end)
end

-- RegisterCommand('impoundClosest', function()
--     impoundClosestVehicle()
-- end)

-- function impoundClosestVehicle()
--     local playerCoords = GetEntityCoords(PlayerPedId())
--     local vehicle = GetClosestVehicle(playerCoords.x, playerCoords.y, playerCoords.z, 2.0, 0, 7)
--     if vehicle == nil or not DoesEntityExist(vehicle) then
--         esx.ShowNotification('Žádné vozidlo poblíž nenalezeno.', 'error')
--         return
--     end
--     impoundVehicle(vehicle, {
--         authority = {
--             job = esx.PlayerData.job.name,
--             name = ''
--         },
--         netId = NetworkGetNetworkIdFromEntity(vehicle)
--     })
-- end

-- exports('impoundClosestVehicle', impoundClosestVehicle)

function impoundVehicle(entity, impoundData)
    esx.UI.Menu.Open('default', 'garages', 'impound_vehicle', {
        title = 'Odtáhnout vozidlo',
        align = 'top-right',
        elements = {
            {
                label = 'Místo' ..
                    (impoundData.impound ~= nil and ' (' .. Impounds[impoundData.impound].display_name .. ')' or ' (Kdekoliv)'),
                action = 'select_impound'
            },
            {
                label = 'Vytáhnutí vlastníkem' ..
                    (impoundData.self ~= nil and ' (' .. (impoundData.self and 'Ano' or 'Ne') .. ')' or ' (Ano)'),
                action = 'out_self'
            },
            {
                label = ' ',
                action = 'spacer'
            },
            {
                label = '<span style="color: orange;">Odtáhnout</span>',
                action = 'impound'
            }
        }
    }, function(data, menu)
        local action = data.current.action
        if action == 'select_impound' then
            selectImpound(function(impound)
                impoundData.impound = impound
                menu.close()
                impoundVehicle(entity, impoundData)
            end)
        elseif action == 'out_self' then
            openConfirmationMenu('Vytáhnutí vlastníkem?', function(state)
                impoundData.self = state
                menu.close()
                impoundVehicle(entity, impoundData)
            end, false, true, {
                cancel = 'Ne',
                confirm = 'Ano'
            })
        elseif action == 'impound' then
            menu.close()
            local plate = GetVehicleNumberPlateText(entity)
            plate = string.gsub(plate, '%s+', '')
            TriggerServerEvent('garages:impoundVehicle', plate, impoundData)
        end
    end, function(data, menu)
        menu.close()
    end)
end

exports('impoundVehicle', impoundVehicle)

function selectImpound(callback)
    local elements = {
        {
            label = 'Kdekoliv',
            action = nil
        }
    }
    for k, v in pairs(Impounds) do
        table.insert(elements, {
            label = v.display_name,
            action = k
        })
    end
    esx.UI.Menu.Open('default', 'garages', 'select_impound', {
        title = 'Vyber odtahovku',
        align = 'top-right',
        elements = elements
    }, function(data, menu)
        menu.close()
        local impound = data.current.action
        callback(impound)
    end, function(data, menu)
        menu.close()
    end)
end

function isJobImpoundManagement(job)
    for i, v in ipairs(ImpoundJobs) do
        if v == job then
            return true
        end
    end
end

RegisterNetEvent('garages:receiveImpoundVehicles', openImpoundMenu)
