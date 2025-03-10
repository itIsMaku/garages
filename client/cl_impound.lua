local currentImpound = nil

Citizen.CreateThread(function()
    for k, v in pairs(Impounds) do
        if v.blip then
            local blip = AddBlipForCoord(v.coords)
            SetBlipSprite(blip, 67)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, 0.65)
            SetBlipColour(blip, 4)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString('<font face="Fire Sans">Odtahovka</font>')
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
            esx.ShowHelpNotification('~INPUT_CONTEXT~ <font face="Fire Sans">Odtahovka</font>')
            DrawMarker(21, coords.x, coords.y, coords.z, 0, 0, 0, 0.0, 0.0, 0.0, 0.8, 0.7, 0.8, 255, 255, 0,
                100, false, false, 2, true)
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
                description = 'Vozidla, která ti byla odtažená',
                icon = 'user',
                action = 'personal'
            },
            {
                label = 'Firemní vozidla',
                description = 'Firemní vozidla, kteréábyly firmě odtažená',
                icon = 'building',
                action = 'job'
            }
        }

        if isJobImpoundManagement(esx.PlayerData.job.name) then
            table.insert(elements, {
                label = 'Ostatní vozidla',
                description = 'Veškerá vozidla odtažená policií, kde je vyžadována přítomnost policie',
                icon = 'handcuffs',
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
        parent = 'impound',
        elements = elements,
    }, function(data, menu)
        menu.close()
        local plate = data.current.plate
        local vehicle = vehicles[plate]
        local impoundData = vehicle.impound_data
        if impoundData.impound ~= nil and impoundData.impound ~= currentImpound then
            showNotification('Odtahovka',
                'Toto vozidlo je na odtahovce v ' .. Impounds[impoundData.impound].display_name .. '.',
                'error')
            return
        end
        if impoundData.authority and not impoundData.self and isJobImpoundManagement(impoundData.authority.job) and not isJobImpoundManagement(esx.PlayerData.job.name) then
            showNotification('Odtahovka', 'Toto vozidlo ti může vytáhnout pouze policista.', 'error')
            return
        end
        if impoundData.impound == nil then
            impoundData.impound = currentImpound
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
    if ox_context then
        local impoundOptions = {}
        for k, v in pairs(Impounds) do
            table.insert(impoundOptions, {
                label = v.display_name,
                value = k
            })
        end
        local options = {
            {
                type = 'select',
                label = 'Odtahovka',
                description = 'Na jaké odtahovce si hráč může vozidlo vyzvednout?',
                icon = 'warehouse',
                options = impoundOptions,
                clearable = true
            },
            {
                type = 'checkbox',
                label = 'Vytáhnutí vlastníkem bez policie',
                description = 'Může vlastník vozidla vyzvednout vozidlo bez přítomnosti policisty?',
                icon = 'user-police',
                checked = true
            }
        }
        local impoundInput = lib.inputDialog('Odtáhnout vozidlo', options)
        if impoundInput == nil then
            return
        end
        impoundData.impound = impoundInput[1]
        impoundData.self = impoundInput[2]
        local plate = GetVehicleNumberPlateText(entity)
        plate = string.gsub(plate, '%s+', '')
        TriggerServerEvent('garages:impoundVehicle', plate, impoundData)
        return
    end
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
            end, 'impound_vehicle', false, true, {
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

AddEventHandler('garages:impoundVehicle', function(data)
    local vehicle = data.entity
    impoundVehicle(vehicle, {
        authority = {
            job = esx.PlayerData.job.name
        },
        netId = NetworkGetNetworkIdFromEntity(vehicle)
    })
end)
