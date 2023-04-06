Garages = {}
inGarage = nil
esx = exports.es_extended:getSharedObject()
cachedCategories = {}
cachedVehicles = {}
cachedJobGrades = {}
garageDebug = false

Citizen.CreateThread(function()
    TriggerServerEvent('garages:load')

    exports.chat:addSuggestion('/addGarage', 'Přidání garáže do databáze', {
        { name = 'id',           help = 'ID garáže' },
        { name = 'display_name', help = 'Název garáže' },
        { name = 'blip',         help = 'Zobrazovat blip - true/false' },
        { name = 'type',         help = 'Typ vozidla - car / etc.' }
    })
    exports.chat:addSuggestion('/deleteGarage', 'Smazání garáže z databáze', {
        { name = 'id', help = 'ID garáže' }
    })
    exports.chat:addSuggestion('/giveVehicle', 'Přidání vozidla do garáže', {
        { name = 'target', help = 'ID hráče' },
        { name = 'model',  help = 'Model vozidla' },
        { name = 'spz',    help = 'SPZ vozidla' },
        { name = 'job',    help = 'Jaké firmě auto patří - Jméno jobu / nil' },
        { name = 'type',   help = 'Typ vozidla - car / etc.' }
    })
    exports.chat:addSuggestion('/teleportGarage', 'Teleportace do garáže', {
        { name = 'target', help = 'ID hráče' }
    })
    exports.chat:addSuggestion('/garages', 'Vypsat garáže')
end)

RegisterNetEvent('garages:loaded', function(garages)
    Garages = garages

    for _, garage in pairs(garages) do
        addGarage(garage)
    end
end)

function addGarage(garage)
    if garage.blip then
        local blipDetails = GarageTypesBlips[garage.type]
        print(json.encode(blipDetails))
        local blip = AddBlipForCoord(garage.coords)
        SetBlipSprite(blip, blipDetails.sprite)
        SetBlipDisplay(blip, blipDetails.display)
        SetBlipScale(blip, blipDetails.scale)
        SetBlipColour(blip, blipDetails.colour)
        SetBlipAsShortRange(blip, blipDetails.short_range)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString('<font face="OpenSans-SemiBold">' .. blipDetails.title .. '</font>')
        EndTextCommandSetBlipName(blip)
    end
    TriggerEvent('polyZone:createZone', 'garage_' .. garage.id, 'box', {
        coords = garage.coords,
        width = garage.zone_radius.width,
        height = garage.zone_radius.height,
        heading = garage.coords.w,
        -- debugPoly = true,
        useZ = true
    })
end

AddEventHandler('polyZone:enteredZone', function(zoneName, point)
    if not zoneName:match('garage_') then
        return
    end
    local garageId = zoneName:match('garage_(.*)')
    inGarage = garageId
    Citizen.CreateThread(function()
        while inGarage == garageId do
            Citizen.Wait(0)
            local coords = Garages[garageId].coords
            local zone_radius = Garages[garageId].zone_radius
            local rgb = { r = 0, g = 255, b = 0 }
            if IsPedInAnyVehicle(PlayerPedId()) then
                rgb = { r = 255, b = 0, g = 0 }
            end
            DrawMarker(43, coords.x, coords.y, coords.z - 3.0, 0, 0, 0, 0, 0, coords.w, zone_radius.height,
                zone_radius.width, 5.0, rgb.r, rgb.g, rgb.b, 100)
            esx.ShowHelpNotification('~INPUT_CONTEXT~ <font face="OpenSans-SemiBold">Garáže</font>')
            if IsControlJustPressed(0, 38) then
                requestGarageMenu(garageId)
            end
        end
    end)
end)

AddEventHandler('polyZone:leftZone', function(zoneName, point)
    if not zoneName:match('garage_') then
        return
    end
    local garageId = zoneName:match('garage_(.*)')
    local garage = Garages[garageId]
    inGarage = nil
    esx.UI.Menu.CloseAll()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    esx.UI.Menu.CloseAll()
    for _, garage in pairs(Garages) do
        TriggerEvent('polyZone:removeZone', 'garage_' .. garage.id)
    end
    for id, _ in pairs(Impounds) do
        TriggerEvent('polyZone:removeZone', 'impound_' .. id)
    end
end)

RegisterNetEvent('garages:receiveVehicleDetails',
    function(garageId, vehicles, fetchedCategories, job, isManagement, grades)
        --print(isManagement)
        cachedVehicles = vehicles
        --print(json.encode(grades))
        cachedJobGrades = grades
        local categories = {}
        for _, category in pairs(fetchedCategories) do
            categories[category.name] = category
            categories[category.name].vehicles = {}
        end
        cachedCategories = categories
        esx.UI.Menu.Open('default', 'garages', 'select_type', {
            title = Garages[garageId].display_name,
            align = 'top-right',
            elements = {
                {
                    label = 'Osobní vozidla',
                    action = 'personal'
                },
                {
                    label = 'Firemní vozidla',
                    action = 'job'
                }
            }
        }, function(data, menu)
            if data.current.action == 'personal' then
                openGarageMenu(vehicles, nil, false, garageId, {})
            elseif data.current.action == 'job' then
                openGarageMenu(vehicles, job, isManagement, garageId, categories)
            end
        end, function(data, menu)
            menu.close()
        end)
    end
)

function formatVehicleData(vehicle)
    local vehicleName = GetDisplayNameFromVehicleModel(vehicle.model)

    local status = 'Mimo garáž'
    local color = 'red'

    if vehicle.stored and not vehicle.impound then
        local damage = vehicle.data
        if damage.engineHealth == nil then
            damage = 1000
        else
            damage = damage.engineHealth
        end
        status = 'Nepojízdné'
        color = 'red'
        if damage > 600 then
            status = 'Pojízdné'
            color = '#2afc00'
        elseif damage < 600 and damage > 300 then
            status = 'Poškozené'
            color = 'orange'
        elseif damage < 300 and damage > 100 then
            status = 'Velmi poškozené'
            color = '#fc6900'
        end
    end
    --print(vehicle.impound)
    --print(vehicle.stored)
    if vehicle.impound then
        status = 'Odtahovka'
        color = 'orange'
    end
    local vehicleLabel = string.format(
        '%s - %s <span style="color:%s">%s</span>',
        vehicleName,
        vehicle.plate,
        color,
        status
    )
    return vehicleLabel
end

function selectVehicle(vehicle, garageId)
    if vehicle.impound then
        esx.ShowNotification('Vozidlo je na odtahovce.')
        return
    end
    if vehicle.stored then
        if vehicle.garage == nil then
            spawnVehicle(vehicle, garageId)
            return
        end
        if garageId == vehicle.garage then
            spawnVehicle(vehicle, garageId)
            return
        end
        spawnForCash('Převést vozidlo do garáže za 500$?', vehicle.plate, garageId, 500)
        return
    end
    spawnForCash('Převést vozidlo za 700$?', vehicle.plate, garageId, 700)
    return
end

function spawnForCash(title, plate, garageId, amount)
    openConfirmationMenu(title, function(state)
        if state then
            TriggerServerEvent('garages:spawnVehicle', plate, garageId, amount)
        end
    end, true, true)
end

function spawnVehicle(vehicle, garageId)
    esx.UI.Menu.CloseAll()
    TriggerServerEvent('garages:spawnVehicle', vehicle.plate, garageId)
end

function storeVehicle(garageId)
    local vehicle = GetVehiclePedIsIn(PlayerPedId())
    local plate = GetVehicleNumberPlateText(vehicle)
    plate = string.gsub(plate, '%s+', '')
    TriggerServerEvent('garages:storeVehicle', garageId, plate, NetworkGetNetworkIdFromEntity(vehicle),
        esx.Game.GetVehicleProperties(vehicle))
end

RegisterNetEvent('garages:spawnVehicle', function(vehicle, garageId)
    local garage = Garages[garageId]
    local coords = garage.coords
    local playerPed = PlayerPedId()
    local distance = #(GetEntityCoords(playerPed) - vector3(coords.x, coords.y, coords.z))
    if distance < garage.zone_radius.width or distance < garage.zone_radius.height then
        esx.Game.SpawnVehicle(vehicle.model, vector3(coords.x, coords.y, coords.z), coords.w, function(createdVehicle)
            esx.Game.SetVehicleProperties(createdVehicle, json.decode(vehicle.data))
            SetVehicleNumberPlateText(createdVehicle, vehicle.plate)
            TaskWarpPedIntoVehicle(playerPed, createdVehicle, -1)
        end)
    end
end)

RegisterNetEvent('garages:createdCategory', function(garage)
    requestGarageMenu(garage)
end)

RegisterNetEvent('garages:addGarage', function(garage)
    Garages[garage.id] = garage
    addGarage(garage)
end)

RegisterNetEvent('garages:deleteGarage', function(garage)
    TriggerEvent('polyZone:removeZone', 'garage_' .. garage)
    Garages[garage] = nil
end)

--[[

RegisterCommand('red', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId())
    SetVehicleCustomPrimaryColour(vehicle, 255, 255, 0)
end)

Citizen.CreateThread(function()
    while garageDebug do
        Citizen.Wait(0)
        for _, v in pairs(Garages) do
            local coords = v.coords
            DrawMarker(43, coords.x, coords.y, coords.z - 2.0, 0, 0, 0, 0, 0, v.coords.w, v.zone_radius.height,
                v.zone_radius.width, 1255.0, 255, 0, 102, 100)
        end
    end
end)

 for _, category in pairs(fetchedCategories) do
        if category.parent ~= nil then
            if categories[category.parent] == nil then
                categories[category.parent] = {
                    name = category.parent,
                    parent = category.parent,
                    restriction = categroy.restriction,
                    children = {}
                }

                categories[category.parent].children[category.name] = {
                    name = category.name,
                    parent = category.parent,
                    restriction = category.restriction,
                    children = {}
                }
            else
                getCategoryParent(categories, category.parent)
            end
        end
        categories[category.id] = category
    end

local categories = {
    ['test'] = {
        name = 'test',
        parent = nil,
        children = {
            ['test2'] = {
                name = 'test2',
                parent = 'test',
                children = {
                    ['test3'] = {
                        name = 'test3',
                        parent = 'test2',
                        children = {}
                    }
                }
            }
        }
    }
}
function getCategoryParent(categories, parent)
    for name, category in pairs(categories) do
        if name == parent then
            return category.parent
        else
            if category.children ~= {} or category.children ~= nil then
                return getCategoryParent(category.children, parent)
            end
        end
    end
    return nil
end

print(getCategoryParent(categories, 'test3'))
]]
