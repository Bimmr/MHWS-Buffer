local version = "0.1.5"

local isWindowOpen, wasOpen = false, false

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


-- Init the modules, and load their config sections
for i, module in pairs(modules) do
    if module.init ~= nil then module.init() end
    if module.load_from_config ~= nil then module.load_from_config(config.get_section(module.title)) end
end

-- Check if the window was last open
if config.get("window.is_window_open") == true then isWindowOpen = true end

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

        imgui.push_style_var(3, 7.5) -- Rounded window
        imgui.push_style_var(12, 5.0) -- Rounded elements

        imgui.set_next_window_size(Vector2f.new(520, 450), 4)

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
                    log.debug(json.dump_string(keyboardBindings))
                    if #keyboardBindings > 0 then
                        imgui.begin_table("bindings_keyboard", 3, nil, nil, nil)

                        for i, bind in pairs(keyboardBindings) do
                            imgui.table_next_row()
                            imgui.table_next_column()
                            local btns = bindings.get_names(device, bind.input)
                            
                            local title = bindings.get_setting_name_from_path(bind.path)
                            imgui.text("   " .. title)
                            imgui.table_next_column()
                            local bind_string = ""
                            
                            for i, bind in pairs(btns) do
                                bind_string = bind_string .. bind.name
                                if i < #btns then bind_string = bind_string .. " + " end
                            end

                            imgui.text("   [ " .. bind_string .. " ]     ")
                            imgui.table_next_column()
                            if imgui.button(language.get(languagePrefix .. "remove").. " ".. tostring(i)) then 
                                bindings.remove(device, i) end
                            imgui.same_line()
                            imgui.text("  ")
                        end

                        imgui.end_table()
                        imgui.separator()
                    end
                    if imgui.button("   " .. language.get(languagePrefix .. "add_keyboard"), "", false) then bindings.popup_open(2) end
                    imgui.spacing()
                    imgui.end_menu()
                end
                if imgui.begin_menu("   " .. language.get(languagePrefix .. "gamepad")) then
                    imgui.spacing()
                    local device = bindings.DEVICE_TYPES.CONTROLLER
                    local gamepadBindings = bindings.get_bindings(device)
                    if #gamepadBindings > 0 then
                        imgui.begin_table("bindings_gamepad", 3, nil, nil, nil)

                        for i, bind in pairs(gamepadBindings) do
                            imgui.table_next_row()
                            imgui.table_next_column()
                            local btns = bindings.get_names(device, bind.input)

                            local title = bindings.get_setting_name_from_path(bind.path)
                            imgui.text("   " .. title)
                            imgui.table_next_column()
                            local bind_string = ""

                            for i, bind in pairs(btns) do
                                bind_string = bind_string .. bind.name
                                if i < #btns then bind_string = bind_string .. " + " end
                            end

                            imgui.text("   [ " .. bind_string .. " ]     ")
                            imgui.table_next_column()
                            if imgui.button(language.get(languagePrefix .. "remove").. " ".. tostring(i)) then 
                                bindings.remove(device, i) end
                            imgui.same_line()
                            imgui.text("  ")
                        end

                        imgui.end_table()
                        imgui.separator()
                    end
                    if imgui.button("   " .. language.get(languagePrefix .. "add_gamepad"), "", false) then bindings.popup_open(1) end
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
                        if imgui.menu_item("   " .. lang .. "   ", "", lang == language.current, lang ~= language.current) then language.change(lang) end
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
        for _, module in pairs(modules) do if module.draw ~= nil then module.draw() end end
        imgui.spacing()

        imgui.spacing()
        imgui.end_window()
        imgui.pop_style_var(2)

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
    for _, module in pairs(modules) do if module.reset ~= nil then module.reset() end end
end)

-- On script save
re.on_config_save(function()
    for _, module in pairs(modules) do config.save_section(module.create_config_section()) end
end)
