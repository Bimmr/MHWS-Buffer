local version = "1.0.3"

local isWindowOpen, wasOpen = false, false

-- Constants
local WINDOW_WIDTH = 520
local WINDOW_HEIGHT = 450
local WINDOW_ROUNDING = 7.5
local FRAME_ROUNDING = 5.0
local WINDOW_ALPHA = 0.9

-- Utilities and Helpers
local utils = require("Buffer.Misc.Utils")
local config = require("Buffer.Misc.Config")
local language = require("Buffer.Misc.Language")
local bindings = require("Buffer.Misc.BindingsHelper")

-- -- Misc Modules
local character = require("Buffer.Modules.Character")
local miscellaneous = require("Buffer.Modules.Miscellaneous")

-- Weapon Modules
local greatSword = require("Buffer.Modules.GreatSword")
--local swordAndShield = require("Buffer.Modules.SwordAndShield")
local dualBlades = require("Buffer.Modules.DualBlades")
local longSword = require("Buffer.Modules.LongSword")
local hammer = require("Buffer.Modules.Hammer")
local huntingHorn = require("Buffer.Modules.HuntingHorn")
local lance = require("Buffer.Modules.Lance")
local gunlance = require("Buffer.Modules.Gunlance")
local switchAxe = require("Buffer.Modules.SwitchAxe")
local chargeBlade = require("Buffer.Modules.ChargeBlade")
local insectGlaive = require("Buffer.Modules.InsectGlaive")
local bow = require("Buffer.Modules.Bow")
local lightBowgun = require("Buffer.Modules.LightBowgun")
local heavyBowgun = require("Buffer.Modules.HeavyBowgun")

local modules = {
    character,
    miscellaneous,
    greatSword,
    -- swordAndShield,
    dualBlades,
    longSword,
    hammer,
    huntingHorn,
    lance,
    gunlance,
    switchAxe,
    chargeBlade,
    insectGlaive,
    bow,
    lightBowgun,
    heavyBowgun
}

-- Load the languages
language.init()

-- Load the bindings
bindings.load(modules)

-- Helper function to draw binding tables
local function draw_binding_table(device, bindings_list, table_id)
    if #bindings_list > 0 then
        imgui.begin_table(table_id, 3, nil, nil, nil)

        for i, bind in pairs(bindings_list) do
            imgui.push_id(i)
            imgui.table_next_row()
            imgui.table_next_column()
            local btns = bindings.get_names(device, bind.input)

            local title = bindings.get_setting_name_from_path(bind.path)
            imgui.text("   " .. title)
            imgui.table_next_column()
            local bind_string = ""

            for j, btn in pairs(btns) do
                bind_string = bind_string .. btn.name
                if j < #btns then bind_string = bind_string .. " + " end
            end

            imgui.text("   [ " .. bind_string .. " ]     ")
            imgui.table_next_column()
            if imgui.button(language.get("window.bindings.remove")) then
                bindings.remove(device, i)
            end
            imgui.same_line()
            imgui.text("  ")
            imgui.pop_id()
        end

        imgui.end_table()
        imgui.separator()
    end
end

-- Helper function to recursively check for enabled buffs
local function check_for_enabled(data_layer, parent_key, enabled_buffs)
    for key, value in pairs(data_layer) do
        if type(value) == "boolean" and value == true then
            table.insert(enabled_buffs, {parent_key .. "." .. key, value})
        elseif type(value) == "number" and value ~= -1 then
            table.insert(enabled_buffs, {parent_key .. "." .. key, value})
        elseif type(value) == "table" then
            check_for_enabled(value, parent_key .. "." .. key, enabled_buffs)
        end
    end
end

-- Init the modules
for _, module in pairs(modules) do
    if module.init then module:init() end
end

-- Check if the window was last open
if config.get("window.is_window_open") then isWindowOpen = true end

-- Add the menu to the REFramework Script Generated UI
re.on_draw_ui(function()

    if language.font.data ~= nil then imgui.push_font(language.font.data) end
    local languagePrefix = "window."

    -- Draw button to toggle window state
    imgui.indent(2)
    if imgui.button(language.get(languagePrefix .. "toggle_button")) then
        isWindowOpen = not isWindowOpen
        config.set("window.is_window_open", isWindowOpen)
    end
    imgui.unindent(2)

    if isWindowOpen then
        wasOpen = true

        imgui.push_style_var(imgui.ImGuiStyleVar.WindowRounding, WINDOW_ROUNDING) -- Rounded window
        imgui.push_style_var(imgui.ImGuiStyleVar.FrameRounding, FRAME_ROUNDING) -- Rounded elements
        imgui.push_style_var(imgui.ImGuiStyleVar.Alpha, WINDOW_ALPHA) -- Window transparency

        imgui.set_next_window_size(Vector2f.new(WINDOW_WIDTH, WINDOW_HEIGHT), 4)

        isWindowOpen = imgui.begin_window("[Buffer] "..language.get(languagePrefix .. "title"), isWindowOpen, 1024)
        bindings.draw()
        if imgui.begin_menu_bar() then

            languagePrefix = "window.bindings."
            if imgui.begin_menu(language.get(languagePrefix .. "title")) then
                imgui.spacing()
                if imgui.begin_menu("   " .. language.get(languagePrefix .. "keyboard")) then
                    imgui.spacing()
                    local device = bindings.DEVICE_TYPES.KEYBOARD
                    local keyboardBindings = bindings.get_bindings(device)
                    draw_binding_table(device, keyboardBindings, "bindings_keyboard")
                    if imgui.button("   " .. language.get(languagePrefix .. "add_keyboard") .. "   ", "", false) then bindings.popup_open(2) end
                    imgui.spacing()
                    imgui.end_menu()
                end
                if imgui.begin_menu("   " .. language.get(languagePrefix .. "gamepad")) then
                    imgui.spacing()
                    local device = bindings.DEVICE_TYPES.CONTROLLER
                    local gamepadBindings = bindings.get_bindings(device)
                    draw_binding_table(device, gamepadBindings, "bindings_gamepad")
                    if imgui.button("   " .. language.get(languagePrefix .. "add_gamepad") .. "   ", "", false) then bindings.popup_open(1) end
                    imgui.spacing()
                    imgui.end_menu()
                end
                
                imgui.spacing()
                imgui.end_menu()
            end
            languagePrefix = "window."
            if imgui.begin_menu(language.get(languagePrefix .. "settings")) then
                imgui.spacing()
                if imgui.begin_menu("   " .. language.get(languagePrefix .. "language")) then
                    imgui.spacing()
                    for _, lang in pairs(language.sorted) do
                        if imgui.menu_item("   " .. language.getLanguageName(lang) .. "   ", "", lang == language.current, lang ~= language.current) then language.change(lang) end
                    end
                    imgui.spacing()
                    imgui.end_menu()
                end
                if imgui.begin_menu("   " .. language.get(languagePrefix .. "font_size")) then
                    imgui.spacing()
                    language.font.temp_size = language.font.temp_size or language.font.size
                    local changed = false
                    changed, language.font.temp_size = imgui.slider_int(language.get(languagePrefix .. "font_size") .. " ", language.font.temp_size, 8, 24)
                    imgui.same_line()
                    if imgui.button(language.get(languagePrefix .. "font_size_apply")) then
                        language.change(language.current, language.font.temp_size)
                        language.font.temp_size = nil
                    end
                    imgui.spacing()
                    imgui.end_menu()
                end
                imgui.spacing()
                imgui.end_menu()
            end

            if imgui.begin_menu(language.get(languagePrefix .. "options")) then
                imgui.spacing()
                 if imgui.begin_menu("   " .. language.get(languagePrefix .. "enabled_buffs")) then
                    local enabled_buffs = {}

                    for _, module in pairs(modules) do
                        check_for_enabled(module.data, module.title, enabled_buffs)
                    end

                    if #enabled_buffs > 0 then
                        imgui.spacing()
                        imgui.begin_table("enabled_buffs", 3, nil, nil, nil)
                        for i, buff in pairs(enabled_buffs) do
                            -- Skip over bonus stats with zero value as they are disabled
                            if not (string.find(buff[1], "bonus_") and buff[2] == 0) then
                                imgui.spacing()
                                imgui.push_id(i)
                                imgui.table_next_row()
                                imgui.table_next_column()
                                imgui.text(" " .. bindings.get_setting_name_from_path(buff[1]))
                                imgui.table_next_column()
                                imgui.text("  " .. tostring(buff[2]) .. "  ")
                                imgui.table_next_column()
                                if imgui.button(language.get(languagePrefix .. "disable")) then
                                    local off_state
                                    if type(buff[2]) == "boolean" then
                                        off_state = false
                                    else
                                        off_state = -1
                                    end
                                    bindings.set_module_value(buff[1], off_state)
                                end
                                imgui.same_line()
                                imgui.text("  ")
                                imgui.pop_id()
                            end
                        end
                        imgui.spacing()
                        imgui.end_table()
                        imgui.separator()
                        imgui.spacing()
                        if imgui.button("   " .. language.get(languagePrefix .. "disable_all").. "   ", "", false) then
                            for _, module in pairs(modules) do
                                bindings.disable_all(module.data)
                                module:save_config()
                            end
                        end
                        imgui.spacing()
                    else
                        imgui.spacing()
                        imgui.text(" " .. language.get(languagePrefix .. "nothing_enabled").. " ")
                        imgui.spacing()
                    end
                    imgui.end_menu()
                end
               
                imgui.spacing()
                imgui.end_menu()
            end

            if imgui.begin_menu(language.get(languagePrefix .. "about")) then
                imgui.spacing()
                imgui.text("   " .. language.get(languagePrefix .. "author") .. ": Bimmr   ")
                if language.languages[language.current]["_TRANSLATOR"] then
                    imgui.text("   " .. language.get(languagePrefix .. "translator") .. ": " .. language.languages[language.current]["_TRANSLATOR"] .. "   ")
                end
                imgui.text("   " .. language.get(languagePrefix .. "version") .. ": " .. version .. "   ")

                imgui.spacing()
                imgui.end_menu()
            end

            imgui.end_menu_bar()
        end
        imgui.separator()

        imgui.spacing()
        for _, module in pairs(modules) do 
            module:draw_module()
        end
        imgui.spacing()

        imgui.end_window()
        imgui.pop_style_var(3)

        -- If the window is closed, but was just open. 
        -- This is needed because of the close icon on the window not triggering a save to the config
    elseif wasOpen then
        wasOpen = false
        config.set("window.is_window_open", isWindowOpen)
    end

    if language.font.data ~= nil then imgui.pop_font() end
end)

-- Keybinds
re.on_frame(function()
    bindings.update()
end)

-- On script reset, reset anything that needs to be reset
re.on_script_reset(function()
    for _, module in pairs(modules) do
        if module.reset then module:reset() end
    end
end)

-- On script save
re.on_config_save(function()
    for _, module in pairs(modules) do
        module:save_config()
    end
end)
