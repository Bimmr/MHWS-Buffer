local utils, config, language
local Module = {
    title = "miscellaneous",
    data = {
        akuma = {
            instant_drive_gauge = false,
            gou_hadoken_max_level = false
        },
        water_gun = {
            unlimited_ammo = false,
        },
        pictomancy = {
            state = -1, -- 0 = Pom Motif, 2 = Wing Motif, 4 = Mog of the ages
            instant_cooldown = false,
        }
    }
}

function Module.init()
    utils = require("Buffer.Misc.Utils")
    config = require("Buffer.Misc.Config")
    language = require("Buffer.Misc.Language")

    Module.init_hooks()
end

function Module.init_hooks()


    sdk.hook(sdk.find_type_definition("app.HunterCharacter"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("app.HunterCharacter") then return end
        if not managed:get_IsMaster() then return end    

        -- Akuma 
        local akuma = managed:get_ExEmote00()
        -- Instant Drive Gauge
        if Module.data.akuma.instant_drive_gauge then
            akuma:set_field("_aimAttackTimer", 0)
        end       
        
        -- Set Gou Hadoken to maximum level (Technically 1 (0-1))
        if Module.data.akuma.gou_hadoken_max_level then
            if akuma:get_field("<ChargeLv>k__BackingField") ~= nil and akuma:get_field("ChargeLvMax") ~= nil then
                local max_level = akuma:get_field("ChargeLvMax")
                akuma:set_field("<ChargeLv>k__BackingField", max_level)
            end
        end

        -- Watergun
        local hunterInfo = managed:get_HunterInfoHolder()
        local exEmote01Info = hunterInfo:get_ExEmote01Info()
        if Module.data.water_gun.unlimited_ammo then
            exEmote01Info:set_field("_AmmoCount", exEmote01Info:get_field("_MaxAmmoCount"))
        end

        -- Pictomancy
        local pictomancy = managed:get_ExEmote03()
        -- Instant Cooldown
        if Module.data.pictomancy.instant_cooldown then
            pictomancy:set_field("<PictItemCDTimer>k__BackingField", 0)
        end

        -- Pictomancy State
        if Module.data.pictomancy.state ~= -1 then
            local current_state = pictomancy:get_field("<PictPhase>k__BackingField")

            -- Only set if different or if a multiple of 2 (0, 2, 4)
            if current_state % 2 ~= 0 or current_state ~= Module.data.pictomancy.state * 2 then
                pictomancy:set_field("<PictPhase>k__BackingField", Module.data.pictomancy.state * 2) -- x2 because in-game values are 0, 2, 4
            end
        end

    end, function(retval)
    end)
end

function Module.draw()
    imgui.push_id(Module.title)
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    if imgui.collapsing_header(language.get(languagePrefix .. "title")) then
        imgui.indent(10)        
        
        languagePrefix = Module.title .. ".akuma."
        if imgui.tree_node(language.get(languagePrefix .. "title")) then            
            
            changed, Module.data.akuma.instant_drive_gauge = imgui.checkbox(language.get(languagePrefix .. "instant_drive_gauge"), Module.data.akuma.instant_drive_gauge)
            any_changed = any_changed or changed

            changed, Module.data.akuma.gou_hadoken_max_level = imgui.checkbox(language.get(languagePrefix .. "gou_hadoken_max_level"), Module.data.akuma.gou_hadoken_max_level)
            any_changed = any_changed or changed

            imgui.tree_pop()
        end

        languagePrefix = Module.title .. ".water_gun."
        if imgui.tree_node(language.get(languagePrefix .. "title")) then
            
            changed, Module.data.water_gun.unlimited_ammo = imgui.checkbox(language.get(languagePrefix .. "unlimited_ammo"), Module.data.water_gun.unlimited_ammo)
            any_changed = any_changed or changed

            imgui.tree_pop()
        end

        languagePrefix = Module.title .. ".pictomancy."
        if imgui.tree_node(language.get(languagePrefix .. "title")) then
            languagePrefix = languagePrefix .. "state."
            local picto_states = {
                language.get("base.disabled"),
                language.get(languagePrefix .. "pom"),
                language.get(languagePrefix .. "wing"),
                language.get(languagePrefix .. "mog")
            }
            local pict_state_index = Module.data.pictomancy.state + 2
            changed, pict_state_index = imgui.combo(language.get(languagePrefix .. "title"), pict_state_index, picto_states)
            Module.data.pictomancy.state = pict_state_index - 2
            any_changed = any_changed or changed

            languagePrefix = Module.title .. ".pictomancy."
            changed, Module.data.pictomancy.instant_cooldown = imgui.checkbox(language.get(languagePrefix .. "instant_cooldown"), Module.data.pictomancy.instant_cooldown)
            any_changed = any_changed or changed

            imgui.tree_pop()
        end

        if any_changed then
            config.save_section(Module.create_config_section())
        end

        imgui.unindent(10)
        imgui.separator()
        imgui.spacing()
    end
    imgui.pop_id()
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
    if not config_section then
        return
    end
    utils.update_table_with_existing_table(Module.data, config_section)
end

return Module
