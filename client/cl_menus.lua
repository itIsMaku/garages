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
            description = 'Menu pro správu firemní garáže',
            icon = 'edit',
            action = 'edit'
        })
        table.insert(elements, {
            label = ' ',
            action = 'spacer'
        })
    end
    for name, category in pairs(categories) do
        print('^3isAllowed?', category.name, category.allowed)
        if category.allowed and category.type == Garages[garageId].type then
            print('^3insert', category.name)
            table.insert(elements, {
                label = category.name,
                category = category.name,
            })
        end
    end
    for plate, vehicle in pairs(uncategorized) do
        local impoundName = nil
        if vehicle.impound_data and vehicle.impound_data.impound then
            impoundName = Impounds[vehicle.impound_data.impound].display_name
        end
        local vehicleLabel, status = formatVehicleData(vehicle, impoundName)
        local description = nil
        if ox_context then
            description = ('Stav: %s\nGaráž: %s'):format(status,
                Garages[vehicle.garage] and Garages[vehicle.garage].display_name or Garages[garageId].display_name)
        end
        table.insert(elements, {
            label = vehicleLabel,
            plate = plate,
            description = description
        })
    end
    esx.UI.Menu.Open('default', 'garages', garageId, {
        title = Garages[garageId].display_name,
        align = 'top-right',
        parent = 'select_type',
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
            selectVehicle(vehicle, garageId, garageId)
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
        local vehicleLabel, status = formatVehicleData(vehicle)
        local description = nil
        if ox_context then
            description = ('Stav: %s\nGaráž: %s'):format(status,
                Garages[vehicle.garage] and Garages[vehicle.garage].display_name or Garages[garageId].display_name)
        end
        table.insert(elements, {
            label = vehicleLabel,
            plate = plate,
            description = description
        })
    end
    esx.UI.Menu.Open('default', 'garages', 'category', {
        title = category.name,
        align = 'top-right',
        parent = garageId,
        elements = elements
    }, function(data, menu)
        local plate = data.current.plate
        local vehicle = category.vehicles[plate]
        selectVehicle(vehicle, garageId, 'category')
        menu.close()
    end, function(data, menu)
        menu.close()
    end)
end

function openGarageEditMenu(garageId, categories, uncategorized, vehicles, job)
    local elements = {
        {
            label = 'Vytvořit kategorii',
            description =
            'Vytvoříš novou kategorii pro vozidla, kterou můžeš limitovat od určité firemní pozice nebo pouze na určitou pozici',
            icon = 'add',
            action = 'create_category'
        },
        {
            label = 'Minimální pozice správy',
            description = 'Nastavení minimální firemní pozice, která může upravovat garáž',
            icon = 'users',
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
            icon = 'list'
            --description = 'Upravit kategorii vozidel a vozidla uvnitř'
        })
    end
    for plate, vehicle in pairs(uncategorized) do
        local vehicleLabel, status = formatVehicleData(vehicle)
        table.insert(elements, {
            label = vehicleLabel,
            plate = plate,
            icon = 'car'
            --description = 'Upravit vozidlo'
        })
    end
    esx.UI.Menu.Open('default', 'garages', 'edit', {
        title = 'Úprava garáže',
        align = 'top-right',
        parent = garageId,
        elements = elements
    }, function(data, menu)
        if data.current.action == 'create_category' then
            openCreateCategoryMenu(garageId, {
                job = job,
                type = Garages[garageId].type
            })
        elseif data.current.action == 'minimum_management_grade' then
            selectJobGrade('Minimální pozice', function(grade)
                TriggerServerEvent('garages:updateMinimumManagementGrade', grade, garageId)
            end, true, 'edit')
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
    if ox_context then
        local gradesOptions = {}
        for id, data in pairs(cachedJobGrades) do
            table.insert(gradesOptions, {
                label = data.label,
                value = tonumber(id)
            })
        end
        local options = {
            {
                type = 'input',
                label = 'Název kategorie',
                description = 'Název kategorie, která se zobrazí v menu',
                icon = 'tag',
                required = true
            },
            {
                type = 'select',
                label = 'Minimální pozice',
                description = 'Minimální pozice, která může kategorii otevřít',
                icon = 'users',
                options = gradesOptions,
                clearable = true
            },
            {
                type = 'select',
                label = 'Vybraná pozice',
                description =
                'Specifická pozice, která může kategorii otevřít (pokud je vybrána, minimální pozice se ignoruje)',
                icon = 'users',
                options = gradesOptions,
                clearable = true
            }
        }
        local categoryInput = lib.inputDialog('Vytvořit kategorii', options)
        if categoryInput == nil then
            return
        end
        local name = categoryInput[1]
        local minimal_grade = categoryInput[2]
        local selected_grade = categoryInput[3]
        local category = cachedCategories[name]
        initData.name = name
        initData.minimal_grade = minimal_grade
        initData.only_grade = selected_grade
        print(minimal_grade, selected_grade)
        if category ~= nil and category.job == initData.job then
            showNotification('Firemní garáž', 'Kategorie s tímto názvem již existuje!', 'error')
            return
        end
        showNotification('Firemní garáž', 'Kategorie byla vytvořena!', 'green')
        TriggerServerEvent('garages:createCategory', garageId, initData)
        esx.UI.Menu.CloseAll()
        return
    end
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
            end, true, 'create_category')
        elseif action == 'create' then
            if initData.name == nil then
                showNotification('Firemní garáž', 'Musíš zadat název kategorie!', 'error')
                return
            end
            local category = cachedCategories[initData.name]
            --print('^4', json.encode(category), initData.job, '^0')
            if category ~= nil and category.job == initData.job then
                showNotification('Firemní garáž', 'Kategorie s tímto názvem již existuje!', 'error')
                return
            end
            showNotification('Firemní garáž', 'Kategorie byla vytvořena!', 'green')
            TriggerServerEvent('garages:createCategory', garageId, initData)
            esx.UI.Menu.CloseAll()
        end
    end, function(data, menu)
        menu.close()
    end)
end

function selectJobGrade(title, callback, close, parent)
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
        parent = parent,
        elements = elements,
    }, function(data, menu)
        if data.current.value ~= nil then
            callback(data.current.value)
            print(data.current.value)
            if not ox_context and close then
                menu.close()
            end
        end
    end, function(data, menu)
        menu.close()
    end)
end

function selectCategory(categories, callback, parent)
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
        parent = parent,
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
            label = ox_context and 'Smazat kategorii' or '<span style="color: red;">Smazat kategorii</span>',
            action = 'delete',
            description = 'Smažeš kategorii a vozidla přesuneš do hlavní kategorie',
            icon = 'trash'
        },
        {
            label = ' ',
            action = 'spacer'
        }
    }
    for plate, vehicle in pairs(category.vehicles) do
        local vehicleLabel, status = formatVehicleData(vehicle)
        local description = nil
        if ox_context then
            description = status
        end
        table.insert(elements, {
            label = vehicleLabel,
            plate = plate,
            --description = description
        })
    end
    esx.UI.Menu.Open('default', 'garages', 'edit_category', {
        title = 'Úprava kategorie',
        align = 'top-right',
        parent = 'edit',
        elements = elements
    }, function(data, menu)
        if data.current.action == 'delete' then
            showNotification('Firemní garáž',
                'Kategorie ' .. category.name .. ' byla smazána a vozidla přesunuty do hlavní kategorie.', 'success')
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
        parent = 'edit',
        elements = {
            {
                label = 'Přesunout',
                description = 'Přesune vozidlo do jiné kategorie',
                icon = 'arrows-up-down-left-right',
                action = 'move'
            },
            {
                label = 'Převést do osobní',
                description = 'Přesune vozidlo do osobní garáže',
                icon = 'square-parking',
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
                showNotification(
                    'Firemní garáž',
                    'Vozidlo ' .. vehicle.plate .. ' přesunuto do kategorie ' .. categoryLabel .. '.',
                    'success'
                )
                TriggerServerEvent('garages:moveVehicle', vehicle.plate, category)
                esx.UI.Menu.CloseAll()
            end, 'edit_vehicle')
        elseif data.current.action == 'owner' then
            showNotification('Firemní garáž', 'Vozidlo ' .. vehicle.plate .. ' převedeno do osobní garáže.',
                'success')
            TriggerServerEvent('garages:moveToPersonal', vehicle)
            esx.UI.Menu.CloseAll()
        end
    end, function(data, menu)
        menu.close()
    end)
end

function openConfirmationMenu(title, callback, parent, closeAll, showCancel, translation)
    if ox_context and not showCancel then
        print('ox_context: ' .. title)
        callback(true)
        return
    end
    local elements = {}
    local translation = translation or { cancel = 'Zrušit', confirm = 'Potvrdit' }
    if showCancel and not ox_context then
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
        parent = parent,
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
