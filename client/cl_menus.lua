function requestGarageMenu(garageId)
    local garage = Garages[garageId]
    --print('requesting garage menu for ' .. garageId)
    if IsPedInAnyVehicle(PlayerPedId()) then
        --print('player is in vehicle')
        openConfirmationMenu('Uložit vozidlo?', function(state)
            if state then
                --print('storing vehicle')
                storeVehicle(garageId)
            end
        end, false, false)
        return
    end
    -- if garage.job ~= nil then
    --     TriggerServerEvent('garages:requestVehicleDetails', garageId, garage.job)
    -- else
    TriggerServerEvent('garages:requestVehicleDetails', garageId)
    -- end
end

function openGarageMenu(vehicles, job, isManagement, garageId, categories, type)
    print('openGarageMenu', json.encode(vehicles), job, isManagement, garageId, categories)
    local uncategorized = {}
    for plate, vehicle in pairs(vehicles) do
        if job and vehicle.category ~= nil then
            if categories[vehicle.category] ~= nil then
                if categories[vehicle.category].allowed then
                    categories[vehicle.category].vehicles[plate] = vehicle
                end
            else
                uncategorized[plate] = vehicle
            end
        else
            --print(job, vehicle.job)
            if job == nil and vehicle.job == nil or job == vehicle.job then
                uncategorized[plate] = vehicle
            end
        end
    end
    --print(json.encode(categories), { indent = true })
    --print(json.encode(uncategorized), { indent = true })
    local elements = {}
    if isManagement then
        table.insert(elements, {
            label = 'Upravit garáž',
            action = 'edit'
        })
        table.insert(elements, {
            label = ' ',
            action = 'spacer'
        })
    end
    for name, category in pairs(categories) do
        if category.allowed and category.type == Garages[garageId].type then
            table.insert(elements, {
                label = category.name,
                category = category.name,
            })
        end
    end
    for plate, vehicle in pairs(uncategorized) do
        table.insert(elements, {
            label = formatVehicleData(vehicle),
            plate = plate
        })
    end
    esx.UI.Menu.Open('default', 'garages', garageId, {
        title = Garages[garageId].display_name,
        align = 'top-right',
        elements = elements
    }, function(data, menu)
        local category = data.current.category
        if category ~= nil then
            openCategoryMenu(categories[category], garageId)
        elseif data.current.action == 'edit' then
            openGarageEditMenu(garageId, categories, uncategorized, vehicles, job)
        elseif data.current.action ~= 'spacer' then
            local plate = data.current.plate
            local vehicle = vehicles[plate]
            selectVehicle(vehicle, garageId)
            menu.close()
        end
    end, function(data, menu)
        menu.close()
    end)
end

function openCategoryMenu(category, garageId)
    local elements = {}
    for plate, vehicle in pairs(category.vehicles) do
        --print(category.name, plate, vehicle)
        table.insert(elements, {
            label = formatVehicleData(vehicle),
            plate = plate
        })
    end
    esx.UI.Menu.Open('default', 'garages', 'category', {
        title = category.name,
        align = 'top-right',
        elements = elements
    }, function(data, menu)
        local plate = data.current.plate
        local vehicle = category.vehicles[plate]
        selectVehicle(vehicle, garageId)
        menu.close()
    end, function(data, menu)
        menu.close()
    end)
end

function openGarageEditMenu(garageId, categories, uncategorized, vehicles, job)
    local elements = {
        {
            label = 'Vytvořit kategorii',
            action = 'create_category'
        },
        {
            label = 'Minimální pozice správy',
            action = 'minimum_management_grade'
        },
        {
            label = ' ',
            action = 'spacer'
        }
    }
    for name, category in pairs(categories) do
        table.insert(elements, {
            label = category.name,
            category = category.name,
        })
    end
    for plate, vehicle in pairs(uncategorized) do
        table.insert(elements, {
            label = formatVehicleData(vehicle),
            plate = plate
        })
    end
    esx.UI.Menu.Open('default', 'garages', 'edit', {
        title = 'Úprava garáže',
        align = 'top-right',
        elements = elements
    }, function(data, menu)
        if data.current.action == 'create_category' then
            openCreateCategoryMenu(garageId, {
                job = job
            })
        elseif data.current.action == 'minimum_management_grade' then
            selectJobGrade('Minimální pozice', function(grade)
                TriggerServerEvent('garages:updateMinimumManagementGrade', grade, garageId)
            end, true)
        elseif data.current.category ~= nil then
            openCategoryEditMenu(categories[data.current.category], garageId)
        elseif data.current.plate ~= nil then
            openVehicleEditMenu(vehicles[data.current.plate], garageId)
        end
    end, function(data, menu)
        menu.close()
    end)
end

function openCreateCategoryMenu(garageId, initData)
    esx.UI.Menu.Open('default', 'garages', 'create_category', {
        title = 'Vytvořit kategorii',
        align = 'top-right',
        elements = {
            {
                label = 'Název kategorie' .. (initData.name ~= nil and ' (' .. initData.name .. ')' or ''),
                action = 'name',
                value = initData.name
            },
            {
                label = 'Minimální firemní pozice' ..
                    (initData.minimal_grade ~= nil and ' (' .. initData.minimal_grade .. ')' or ' (0)'),
                action = 'minimal_grade',
                value = initData.minimal_grade
            },
            {
                label = 'Vybraná firemní pozice' ..
                    (initData.only_grade ~= nil and ' (' .. initData.only_grade .. ')' or ' (0)'),
                action = 'only_grade',
                value = initData.only_grade
            },
            {
                label = ' ',
                action = 'spacer'
            },
            {
                label = '<span style="color:#2afc00;">Vytvořit</span>',
                action = 'create'
            }
        }
    }, function(data, menu)
        local action = data.current.action
        if action == 'name' then
            esx.UI.Menu.Open('dialog', 'garages', 'create_category_' .. action, {
                title = data.current.label
            }, function(data2, menu2)
                initData[action] = data2.value
                menu2.close()
                openCreateCategoryMenu(garageId, initData)
            end, function(data2, menu2)
                menu2.close()
            end)
        elseif action == 'minimal_grade' or action == 'only_grade' then
            selectJobGrade(data.current.label, function(id)
                initData[action] = id
                openCreateCategoryMenu(garageId, initData)
            end, true)
        elseif action == 'create' then
            if initData.name == nil then
                esx.ShowNotification('Musíš zadat název kategorie!', 'error')
                return
            end
            local category = cachedCategories[initData.name]
            --print('^4', json.encode(category), initData.job, '^0')
            if category ~= nil and category.job == initData.job then
                esx.ShowNotification('Kategorie s tímto názvem již existuje!', 'error')
                return
            end
            esx.ShowNotification('Kategorie byla vytvořena!', 'green')
            TriggerServerEvent('garages:createCategory', garageId, initData)
            esx.UI.Menu.CloseAll()
        end
    end, function(data, menu)
        menu.close()
    end)
end

function selectJobGrade(title, callback, close)
    local elements = {
        {
            label = 'Bez omezení',
            value = 0
        },
        {
            label = ' ',
            action = 'spacer'
        }
    }
    for id, data in pairs(cachedJobGrades) do
        table.insert(elements, {
            label = data.label,
            value = tonumber(id)
        })
    end
    esx.UI.Menu.Open('default', 'garages', 'select_job_grade', {
        title = title,
        align = 'top-right',
        elements = elements
    }, function(data, menu)
        if data.current.value ~= nil then
            callback(data.current.value)
            if close then
                menu.close()
            end
        end
    end, function(data, menu)
        menu.close()
    end)
end

function selectCategory(categories, callback)
    local elements = {
        {
            label = 'Bez kategorie',
            value = nil
        },
        {
            label = ' ',
            action = 'spacer'
        }
    }
    for name, category in pairs(categories) do
        table.insert(elements, {
            label = category.name,
            value = category.name
        })
    end
    esx.UI.Menu.Open('default', 'garages', 'select_category', {
        title = 'Vyber kategorii',
        align = 'top-right',
        elements = elements
    }, function(data, menu)
        if data.current.value ~= 'spacer' then
            callback(data.current.value)
            menu.close()
        end
    end, function(data, menu)
        menu.close()
    end)
end

function openCategoryEditMenu(category, garageId)
    local elements = {
        {
            label = '<span style="color: red;">Smazat kategorii</span>',
            action = 'delete'
        },
        {
            label = ' ',
            action = 'spacer'
        }
    }
    for plate, vehicle in pairs(category.vehicles) do
        table.insert(elements, {
            label = formatVehicleData(vehicle),
            plate = plate
        })
    end
    esx.UI.Menu.Open('default', 'garages', 'edit_category', {
        title = 'Úprava kategorie',
        align = 'top-right',
        elements = elements
    }, function(data, menu)
        if data.current.action == 'delete' then
            esx.ShowNotification(
                'Kategorie ' .. category.name .. ' byla smazána a vozidla přesunuty do hlavní kategorie.', 'green')
            TriggerServerEvent('garages:deleteCategory', category.name)
            esx.UI.Menu.CloseAll()
        elseif data.current.plate ~= nil then
            openVehicleEditMenu(category.vehicles[data.current.plate], garageId)
        end
    end, function(data, menu)
        menu.close()
    end)
end

function openVehicleEditMenu(vehicle, garageId)
    esx.UI.Menu.Open('default', 'garages', 'edit_vehicle', {
        title = vehicle.plate .. ' - Úprava',
        align = 'top-right',
        elements = {
            {
                label = 'Přesunout',
                action = 'move'
            },
            {
                label = 'Převést do osobní',
                action = 'owner'
            }
        }
    }, function(data, menu)
        if data.current.action == 'move' then
            selectCategory(cachedCategories, function(category)
                local categoryLabel = category
                if category == nil then
                    categoryLabel = 'Bez kategorie'
                end
                esx.ShowNotification('Vozidlo ' .. vehicle.plate .. ' přesunuto do kategorie ' .. categoryLabel .. '.',
                    'green')
                TriggerServerEvent('garages:moveVehicle', vehicle.plate, category)
                esx.UI.Menu.CloseAll()
            end)
        elseif data.current.action == 'owner' then
            esx.ShowNotification('Vozidlo ' .. vehicle.plate .. ' převedeno do osobní garáže.', 'green')
            TriggerServerEvent('garages:moveToPersonal', vehicle)
            esx.UI.Menu.CloseAll()
        end
    end, function(data, menu)
        menu.close()
    end)
end

function openConfirmationMenu(title, callback, closeAll, showCancel, translation)
    local elements = {}
    local translation = translation or { cancel = 'Zrušit', confirm = 'Potvrdit' }
    if showCancel then
        table.insert(elements, {
            label = translation.cancel,
            action = 'cancel'
        })
    end
    table.insert(elements, {
        label = translation.confirm,
        action = 'confirm'
    })
    esx.UI.Menu.Open('default', 'garages', 'confirmation', {
        title = title,
        align = 'top-right',
        elements = elements
    }, function(data, menu)
        menu.close()
        if data.current.action == 'cancel' then
            callback(false)
            return
        end
        if closeAll then
            esx.UI.Menu.CloseAll()
        end
        callback(true)
    end, function(data, menu)
        menu.close()
    end)
end
