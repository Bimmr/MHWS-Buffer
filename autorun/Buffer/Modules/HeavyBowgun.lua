local utils, config, language
local Module = {
    title = "heavy_bowgun",
    data = {
        max_special_ammo = false,
        max_wyvern_howl = false,
        -- wyvern_ignition_charge_level = -1,
        max_gatling_hits = false,
    }
}

function Module.init()
    utils = require("Buffer.Misc.Utils")
    config = require("Buffer.Misc.Config")
    language = require("Buffer.Misc.Language")

    Module.init_hooks()
end

function Module.init_hooks()
    
    -- Weapon changes
    sdk.hook(sdk.find_type_definition("app.cHunterWp12Handling"):get_method("update"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("app.cHunterWp12Handling") then return end

        -- Max Special Mode (Special ammo)
        if Module.data.max_special_ammo then
            local energy_bullet_info = managed:get_field("_EnergyBulletInfo")
            energy_bullet_info:set_field("_CurrentEnergy", energy_bullet_info:get_field("MAX_ENERGY"))
        end

        -- Wyverncounter Ignition - yes, charge level is spelled wrong
        -- Wyvernblast Ignition - Has no charge level
        -- TODO: Not Working
        -- if Module.data.wyvern_ignition_charge_level > -1 then
        --     managed:get_field("_EnergyBulletInfo"):set_field("_CharageLevel", Module.data.wyvern_ignition_charge_level)
        -- end


        -- Unsure what these are
        -- _EnergyBulletInfo:_StandardEnergyShellType
        -- _EnergyBulletInfo:WeakEnergyShellType
        -- _EnergyBulletInfo:PowerEnergyShellType

        -- Snipe Ammo (FocusBlast: WyvernHowl)
        if Module.data.max_wyvern_howl then
            local snipe_ammo = managed:get_field("_SnipeAmmo")
            snipe_ammo:set_field("_ChargeTimer", snipe_ammo:get_field("_ChargeTime")-0.1) -- Setting just below as it seems to glitch out and give an extra shot
            -- snipe_ammo:set_field("_CurrentAmmo", snipe_ammo:get_field("_MaxAmmo")) -- DOESN'T WORK
        end

        -- Gatling Hit - Only affects Wyvernheart Ignition
        if Module.data.max_gatling_hits then
            managed:set_field("_GatlingHitCount", 9) 
        end

    end, function(retval) end)
end

function Module.draw()
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    if imgui.collapsing_header(language.get(languagePrefix .. "title")) then
        imgui.indent(10)

        changed, Module.data.max_special_ammo = imgui.checkbox(language.get(languagePrefix .. "max_special_ammo"), Module.data.max_special_ammo)
        any_changed = any_changed or changed

        changed, Module.data.max_wyvern_howl = imgui.checkbox(language.get(languagePrefix .. "max_wyvern_howl"), Module.data.max_wyvern_howl)
        any_changed = any_changed or changed

        -- changed, Module.data.wyvern_ignition_charge_level = imgui.slider_int(language.get(languagePrefix .. "wyvern_ignition_charge_level"), Module.data.wyvern_ignition_charge_level, -1, 3, Module.data.wyvern_ignition_charge_level == -1 and language.get("base.disabled") or "%d")
        -- any_changed = any_changed or changed

        changed, Module.data.max_gatling_hits = imgui.checkbox(language.get(languagePrefix .. "max_gatling_hits"), Module.data.max_gatling_hits)
        utils.tooltip(language.get(languagePrefix .. "max_gatling_hits_tooltip"))
        any_changed = any_changed or changed

        if any_changed then config.save_section(Module.create_config_section()) end
        imgui.unindent(10)
        imgui.separator()
        imgui.spacing()
    end
end

function Module.reset()
    -- Implement reset functionality if needed
end

function Module.create_config_section()
    return {
        [Module.title] = Module.data
    }
end

function Module.load_from_config(config_section)
    if not config_section then return end
    utils.mergeTables(Module.data, config_section)
end

return Module
