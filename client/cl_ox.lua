ox_context = true

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
