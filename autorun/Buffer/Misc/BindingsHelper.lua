-- BindingsHelper module - extends the Bindings module with additional functionality
local bindings = require("Buffer.Misc.Bindings")
local language = require("Buffer.Misc.Language")

local file_path = "Buffer/Bindings.json"
local enabled_text = language.get("window.bindings.enabled")
local disabled_text = language.get("window.bindings.disabled")

-- Create a new table that inherits all of the original bindings functionality
local helper = {}
helper.popup = {}  -- Store popup state in helper

setmetatable(helper, {
    __index = bindings
})

-- Preserve the constants from the original bindings
helper.DEVICE_TYPES = {
    NONE = 0,
    CONTROLLER = 1,
    KEYBOARD = 2
}

helper.CONTROLLER_TYPES = {
    NONE = 0,
    PLAYSTATION = 1,
    XBOX = 2
}

function helper.load()
    local file = json.load_file(file_path)
    if file then
        for _, bind in pairs(file) do
            helper.add(bind.device, bind.input, function()

                local path = utils.split(bind.path, ".")
                local value = bind.value

                if type(value) == "number" then
                    enabled_text = string.gsub(language.get("window.bindings.set_to"), "%%d", value)
                end

                local module_index
                for key, value in pairs(buffer.modules) do
                    if buffer.modules[key].title == path[1] then
                        module_index = key
                    end
                end

                table.remove(path, 1) -- Remove Module name
                table.remove(path, 1) -- Remove "data" from path

                local target = buffer.modules[module_index].data
                for i = 1, #path - 1 do
                    target = target[path[i]]
                end
                target[path[#path]] = not target[path[#path]]
                utils.send_message(helper.get_formatted_title(bind.path) .. " " ..
                                       (target[path[#path]] and enabled_text or disabled_text))
            end)
        end
    end
end

function helper.save()
    local file = {}
    for _, bind in pairs(helper.bindings) do
        local data = {
            device = bind.device,
            input = bind.input,
            path = bind.path,
            value = bind.value
        }
        table.insert(file, data)
    end
    json.save_file(file_path, file)
end

--- Returns the name of the setting based on the provided path.
--- @param path string The path to the setting (e.g., "data.character.health").
--- @return string The formatted name of the setting.
function helper.get_setting_name_from_path(path)
    path = string.gsub(path, "data%.", "")
    path = utils.split(path, ".")
    local currentPath = path[1]
    local title = language.get(currentPath .. ".title")
    for i = 2, #path, 1 do
        currentPath = currentPath .. "." .. path[i]
        if i == #path then
            title = title .. "/" .. language.get(currentPath)
        else
            title = title .. "/" .. language.get(currentPath .. ".title")
        end
    end
    return title
end

helper.original_update = bindings.update
function helper.update()
    helper.original_update()
end

function helper.draw()
    local listener = helper.listener:create("Buffer Popup")
    if helper.popup.open then

        local popup_size = Vector2f.new(350, 145)
        -- If a path has been chosen, make the window taller
        if helper.popup.path ~= nil then
            popup_size.y = 190
        end
        imgui.set_next_window_size(popup_size, 1 + 256)
        imgui.begin_window("buffer_bindings", nil, 1)
        imgui.indent(10)
        imgui.spacing()
        imgui.spacing()

        -- Change title depending on device
        if helper.popup.device == 1 then
            imgui.text(language.get("window.bindings.add_gamepad"))
        else
            imgui.text(language.get("window.bindings.add_keyboard"))
        end
        imgui.separator()
        imgui.spacing()
        imgui.spacing()

        -- Draw the path menu selector
         local binding_path = language.get("window.bindings.choose_modification")
        if helper.popup.path ~= nil then
            binding_path = helper.get_setting_name_from_path(helper.popup.path)
        end


        if imgui.begin_menu(binding_path) then
            for module_key, module in pairs(buffer.modules) do
                if imgui.begin_menu(language.get(module.title .. ".title")) then
                    local function draw_menu(data, path)
                        for key, value in pairs(data) do
                            local current_path = path .. "." .. key
                            if type(value) == "table" then
                                if imgui.begin_menu(language.get(module.title .. ".title") .. "/" .. key) then
                                    draw_menu(value, current_path)
                                    imgui.end_menu()
                                end
                            else
                                if imgui.menu_item(language.get(module.title .. ".title") .. "/" .. key) then
                                    helper.popup.path = module.title .. ".data." .. current_path:match("^.+%.(.+)$")
                                    helper.popup.value = value
                                end
                            end
                        end
                    end
                    draw_menu(module.data, "")
                    imgui.end_menu()
                end
            end
            imgui.end_menu()
        end


        -- Get the default hotkey text based on the device type
        local binding_hotkey = listener:get_device() == bindings.DEVICE_TYPES.KEYBOARD and
                              language.get("window.bindings.add_keyboard") or
                              language.get("window.bindings.add_gamepad")

        -- Popup listening
        if listener:is_listening() then
            helper.popup.device = listener:get_device()

            -- If listener is listening, display the current binding hotkey
            if #listener:get_inputs() ~= 0 then
                binding_hotkey = ""
                local inputs = listener:get_inputs()
                inputs = bindings.get_names(listener:get_device(), inputs)
                for _, input in ipairs(inputs) do
                    binding_hotkey = binding_hotkey .. input.name .. " + "
                end
            end
        
            -- Popup not listening, display hotkeys
        else
             for i, input in ipairs(listener:get_inputs()) do
                binding_hotkey = binding_hotkey .. input.name
                if i < #listener:get_inputs() then
                    binding_hotkey = binding_hotkey .. " + "
                end
            end
        end

        -- Draw the hotkey button
        if imgui.button(binding_hotkey) then
            listener:start()
        end
        

        -- Draw the value input field
        if helper.popup.value ~= nil then
            imgui.text(language.get("window.bindings.on_value") .. ": ")
            imgui.same_line()
            if type(helper.popup.value) == "boolean" then
                imgui.begin_disabled()
                imgui.input_text("   ", "true/false")
                imgui.end_disabled()
            elseif type(helper.popup.value) == "number" then
                imgui.text(language.get("window.bindings.on_value") .. ": ")
                local changed, on_value = imgui.input_text("     ", helper.popup.value, 1)
                if changed and on_value ~= "" and tonumber(on_value) then
                    helper.popup.value = tonumber(on_value)
                end
            end
        end
        imgui.spacing()
        imgui.spacing()
        imgui.separator()
        imgui.spacing()

        
        if imgui.button(language.get("window.bindings.cancel")) then
            bindings.popup_close()
        end
        if helper.popup.path and helper.popup.binding then
            imgui.same_line()
            if imgui.button(language.get("window.bindings.save")) then
                bindings.add(helper.popup.device, helper.popup.binding, helper.popup.path, helper.popup.on)
                bindings.popup_close()
            end
        end
        imgui.unindent(10)
        imgui.end_window()
        

    -- Somehow the popup is closed, but still listening
    elseif listener:is_listening() then
        helper.popup_close()
        listener:stop()
        listener:reset()
    end
end

-- Implement proper popup open function
function helper.popup_open(device)
    helper.popup.open = true
    helper.popup.device = device
    helper.popup.path = nil
    helper.popup.binding = nil
    helper.popup.value = nil
end

-- Implement proper popup close function
function helper.popup_close()
    helper.popup.open = false
end

return helper
