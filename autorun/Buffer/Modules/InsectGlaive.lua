local ModuleBase = require("Buffer.Misc.ModuleBase")
local utils = require("Buffer.Misc.Utils")
local language = require("Buffer.Misc.Language")

--TODO: Fast Charge doesn't work, or isn't broken and just says disabled

local Module = ModuleBase:new("insect_glaive", {
    kinsect = {
        power = -1,
        speed = -1,
        recovery = -1,
        unlimited_stamina = false,
        fast_charge = false,
        charge_time = 0,
    },
    red = false,
    white = false,
    orange = false,
    infinite_air_attacks = false,
    fast_charge = false,
    charge_time = 0,
    unrestricted_charge = false,
})

local shouldSkip = true
local function updateChargeHook(args)
    if Module.data.unrestricted_charge and shouldSkip then
        return sdk.PreHookResult.SKIP_ORIGINAL
    end
end


function Module.create_hooks()

    -- Watch for weapon changes, need to re-apply the default kinsect stats 
    sdk.hook(sdk.find_type_definition("app.HunterCharacter"):get_method("changeWeapon"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("app.HunterCharacter") then return end
        if not managed:get_IsMaster() then return end

        local player = utils.get_master_character()
        local weapon_handling = player:get_WeaponHandling()
        local reserve_weapon_handling = player:get_ReserveWeaponHandling()

        -- Check if the weapon handling for the main or reserve is a bow
        weapon_handling = (weapon_handling and weapon_handling:get_type_definition():is_a("app.cHunterWp10Handling")) and weapon_handling or nil
        reserve_weapon_handling = (reserve_weapon_handling and reserve_weapon_handling:get_type_definition():is_a("app.cHunterWp10Handling")) and reserve_weapon_handling or nil

        -- Get the weapon handling
        local weapon = weapon_handling or reserve_weapon_handling
        if not weapon then return end

        -- Reset kinsect stats when weapon changes
        Module:reset()
    end, function(retval) end)

    -- Weapon modifications
    sdk.hook(sdk.find_type_definition("app.cHunterWp10Handling"):get_method("update"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not Module:weapon_hook_guard(managed, "app.cHunterWp10Handling") then return end

        -- Kinsect
        local kinsect = managed:get_Insect()
        if kinsect then
            Module:cache_and_update_field("kinsect._PowerLv", kinsect, "_PowerLv", Module.data.kinsect.power)
            Module:cache_and_update_field("kinsect._SpeedLv", kinsect, "_SpeedLv", Module.data.kinsect.speed)
            Module:cache_and_update_field("kinsect._RecoveryLv", kinsect, "_RecoveryLv", Module.data.kinsect.recovery)
            
            -- Kinsect Stamina
            if Module.data.kinsect.unlimited_stamina then 
                kinsect:get_field("Stamina"):set_field("_Value", 100.0)
            end
        end
        
        -- Kinsect charge
        if Module.data.kinsect.fast_charge and managed:get_field("InsectChargeTimer") > Module.data.kinsect.charge_time/200 then
            managed:set_field("InsectChargeTimer", 100.0)
        end
        
        -- Extracts
        if Module.data.red then 
            managed:get_field("ExtractTimer")[0]:set_field("_Value", 89.0)
        end
        if Module.data.white then 
            managed:get_field("ExtractTimer")[1]:set_field("_Value", 89.0)
        end
        if Module.data.orange then 
            managed:get_field("ExtractTimer")[2]:set_field("_Value", 89.0)
        end
        if Module.data.red and Module.data.white and Module.data.orange then 
            managed:get_field("TrippleUpTimer"):set_field("_Value", 89.0)
        end

        -- Air attacks
        if Module.data.infinite_air_attacks then 
            managed:set_field("_EmStepCount", 2)
        end

        -- Charge attack
        if Module.data.fast_charge and managed:get_field("_ChargeTimer") > Module.data.charge_time/50 then
            managed:set_field("_ChargeTimer", 100.0)
        end

        -- Free Charge
        if Module.data.unrestricted_charge then
            shouldSkip = false
            managed:call("updateCharge")
            shouldSkip = true
        end

    end, function(retval) end)

    sdk.hook(sdk.find_type_definition("app.cHunterWp10Handling"):get_method("updateCharge"), updateChargeHook, nil)

end

function Module.add_ui()
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    imgui.push_id(Module.title.."kinsect")
    languagePrefix = Module.title .. ".kinsect."
    if imgui.tree_node(language.get(languagePrefix .. "title")) then
        changed, Module.data.kinsect.power = imgui.slider_int(language.get(languagePrefix .. "power"), Module.data.kinsect.power, -1, 200, Module.data.kinsect.power == -1 and language.get("base.disabled") or "%d")
        any_changed = any_changed or changed

        changed, Module.data.kinsect.speed = imgui.slider_int(language.get(languagePrefix .. "speed"), Module.data.kinsect.speed, -1, 100, Module.data.kinsect.speed == -1 and language.get("base.disabled") or "%d")
        any_changed = any_changed or changed

        changed, Module.data.kinsect.recovery = imgui.slider_int(language.get(languagePrefix .. "recovery"), Module.data.kinsect.recovery, -1, 100, Module.data.kinsect.recovery == -1 and language.get("base.disabled") or "%d")
        any_changed = any_changed or changed

        changed, Module.data.kinsect.unlimited_stamina = imgui.checkbox(language.get(languagePrefix .. "unlimited_stamina"), Module.data.kinsect.unlimited_stamina)
        any_changed = any_changed or changed

        changed, Module.data.kinsect.fast_charge = imgui.checkbox(language.get(languagePrefix .. "fast_charge"), Module.data.kinsect.fast_charge)
        any_changed = any_changed or changed

        if Module.data.kinsect.fast_charge then

            imgui.same_line()
            imgui.text("  ")
            imgui.same_line()
            imgui.set_next_item_width(imgui.calc_item_width() - 100)
            changed, Module.data.kinsect.charge_time = imgui.slider_int(language.get(languagePrefix .. "charge_time"), Module.data.kinsect.charge_time, 0, 100, Module.data.kinsect.charge_time == 0 and language.get("base.disabled") or "%d")
            utils.tooltip(language.get(languagePrefix.."charge_time_tooltip"))
            any_changed = any_changed or changed
        end

        imgui.tree_pop()
    end
    imgui.pop_id()

    languagePrefix = Module.title .. "."
    imgui.begin_table(Module.title.."1", 3, nil, nil, nil)
    imgui.table_next_row()
    imgui.table_next_column()

    changed, Module.data.red = imgui.checkbox(language.get(languagePrefix .. "red"), Module.data.red)
    any_changed = any_changed or changed

    imgui.table_next_column()

    changed, Module.data.white = imgui.checkbox(language.get(languagePrefix .. "white"), Module.data.white)
    any_changed = any_changed or changed

    imgui.table_next_column()

    changed, Module.data.orange = imgui.checkbox(language.get(languagePrefix .. "orange"), Module.data.orange)
    any_changed = any_changed or changed

    imgui.end_table()

    changed, Module.data.infinite_air_attacks = imgui.checkbox(language.get(languagePrefix .. "infinite_air_attacks"), Module.data.infinite_air_attacks)
    any_changed = any_changed or changed
    
    changed, Module.data.fast_charge = imgui.checkbox(language.get(languagePrefix .. "fast_charge"), Module.data.fast_charge)
    any_changed = any_changed or changed

    if Module.data.fast_charge then

        imgui.same_line()
        imgui.text("  ")
        imgui.same_line()
        imgui.set_next_item_width(imgui.calc_item_width() - 100)
        changed, Module.data.charge_time = imgui.slider_int(language.get(languagePrefix .. "charge_time"), Module.data.charge_time, 0, 100, Module.data.charge_time == 0 and language.get("base.disabled") or "%d")
        utils.tooltip(language.get(languagePrefix .. "charge_time_tooltip"))
        any_changed = any_changed or changed
    end

    changed, Module.data.unrestricted_charge = imgui.checkbox(language.get(languagePrefix .. "unrestricted_charge"), Module.data.unrestricted_charge)
    utils.tooltip(language.get(languagePrefix .. "unrestricted_charge_tooltip"))
    any_changed = any_changed or changed

    return any_changed
end

function Module.reset()
    local player = utils.get_master_character()
    if not player then return end
    
    local weapon_handling = player:get_WeaponHandling()
    local reserve_weapon_handling = player:get_ReserveWeaponHandling()

    -- Check if the weapon handling for the main or reserve is an insect glaive
    weapon_handling = (weapon_handling and weapon_handling:get_type_definition():is_a("app.cHunterWp10Handling")) and weapon_handling or nil
    reserve_weapon_handling = (reserve_weapon_handling and reserve_weapon_handling:get_type_definition():is_a("app.cHunterWp10Handling")) and reserve_weapon_handling or nil

    -- Get the weapon handling
    local weapon = weapon_handling or reserve_weapon_handling
    if not weapon then return end
    
    local kinsect = weapon:get_Insect()
    if kinsect then
        -- Restore cached kinsect stats
        Module:cache_and_update_field("kinsect._PowerLv", kinsect, "_PowerLv", -1)
        Module:cache_and_update_field("kinsect._SpeedLv", kinsect, "_SpeedLv", -1)
        Module:cache_and_update_field("kinsect._RecoveryLv", kinsect, "_RecoveryLv", -1)
    end
end

return Module
