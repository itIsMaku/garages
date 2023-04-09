ox_context = true
ox_target = true

if ox_context then
    local function selectedElement(element, submit)
        local data = {
            current = element
        }
        local menu = {
            close = function()
                --lib.hideContext(false)
            end
        }
        submit(data, menu)
    end

    esx.UI.Menu.Open = function(type, namespace, id, settings, submit, close)
        local options = {}
        for _, element in ipairs(settings.elements) do
            if element.action ~= 'spacer' then
                local option = {
                    title = element.label,
                    description = element.description,
                    icon = element.icon or nil,
                    onSelect = function()
                        selectedElement(element, submit)
                    end
                }
                table.insert(options, option)
            end
        end
        local parent = nil
        if settings.parent ~= nil then
            parent = namespace .. '_' .. settings.parent
        end
        lib.registerContext({
            id = namespace .. '_' .. id,
            title = settings.title,
            menu = parent,
            options = options
        })
        lib.showContext(namespace .. '_' .. id)
    end

    esx.UI.Menu.CloseAll = function()
        if lib.getOpenContextMenu() ~= nil then
            lib.hideContext(false)
        end
    end
end

if ox_target then
    local options = {
        {
            name = 'garages:impoundVehicle',
            event = 'garages:impoundVehicle',
            icon = 'fa-solid fa-car',
            label = 'Odtáhnout vozidlo',
            canInteract = function(entity, distance, coords, name, bone)
                return isJobImpoundManagement(esx.PlayerData.job.name)
            end,
            num = 1
        },
        {
            name = 'garages:lockVehicle',
            event = 'garages:lockVehicle',
            icon = "fa-solid fa-key",
            label = "Zamknout/Odemknout",
            num = 2
        },
    }

    exports.ox_target:addGlobalVehicle(options)
end

AddEventHandler('onClientResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    if ox_target then
        exports.ox_target:removeGlobalVehicle({ 'garages:impoundVehicle', 'garages:lockVehicle' })
    end
end)
