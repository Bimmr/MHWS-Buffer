local utils, config, language
local Module = {
    title = "bow",
    data = {
        charge_level = -1,
        all_arrow_types = false,
        unlimited_bottles = false,
        max_trick_arrow_gauge = false,
        unlimited_bladescale = false
    },
    hidden={
        tetrad_shot_active = false
    },
    old = {}
}

function Module.init()
    utils = require("Buffer.Misc.Utils")
    config = require("Buffer.Misc.Config")
    language = require("Buffer.Misc.Language")

    Module.init_hooks()
end

-- Reset the arrow types to the default arrow types
local function reset_arrow_types(weapon)
    local bottle_infos = weapon:get_field("<BottleInfos>k__BackingField")
    for i, bottle_info in ipairs(bottle_infos) do
        bottle_info:set_field("<CanLoading>k__BackingField", Module.old.bottle_infos[i])
    end
    Module.old.bottle_infos = nil
end

function Module.init_hooks()

    -- Watch for weapon changes, need to re-apply the default arrow types 
    sdk.hook(sdk.find_type_definition("app.HunterCharacter"):get_method("changeWeapon"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("app.HunterCharacter") then return end
        if not managed:get_IsMaster() then return end

        -- Get weapon handling
        local weapon_handling = managed:get_WeaponHandling()
        local reserve_weapon_handling = managed:get_ReserveWeaponHandling()
        if not weapon_handling then return end

        -- Check if the weapon handling for the main or reserve is a bow
        weapon_handling = (weapon_handling and weapon_handling:get_type_definition():is_a("app.cHunterWp11Handling")) and weapon_handling or nil
        reserve_weapon_handling = (reserve_weapon_handling and reserve_weapon_handling:get_type_definition():is_a("app.cHunterWp11Handling")) and reserve_weapon_handling or nil

        -- Get the weapon handling
        local weapon = weapon_handling or reserve_weapon_handling
        if not weapon then return end

        -- Check if all_arrow_types is enabled and we have the old arrow types
        if Module.data.all_arrow_types and Module.old.bottle_infos then

            -- Reset old arrow types
            reset_arrow_types(weapon)
        end
    end, function(retval) end)
    
    -- Weapon changes
    sdk.hook(sdk.find_type_definition("app.cHunterWp11Handling"):get_method("update"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("app.cHunterWp11Handling") then return end
        if not managed:get_Hunter() then return end
        if not managed:get_Hunter():get_IsMaster() then return end


        -- Charge Level
        if Module.data.charge_level ~= -1 then
            managed:set_field("<ChargeLv>k__BackingField", Module.data.charge_level)
        end


        -- All arrow types
        if Module.data.all_arrow_types then
            local bottle_infos = managed:get_field("<BottleInfos>k__BackingField")
            if not Module.old.bottle_infos then
                Module.old.bottle_infos = {}
                for i, bottle_info in ipairs(bottle_infos) do
                    Module.old.bottle_infos[i] = bottle_info:get_field("<CanLoading>k__BackingField")
                    bottle_info:set_field("<CanLoading>k__BackingField", true)
                end
                
            else
                for i, bottle_info in ipairs(bottle_infos) do
                    if not bottle_info:get_field("<CanLoading>k__BackingField") then
                        Module.old.bottle_infos = nil;
                        break
                    end
                end
            end
        elseif Module.old.bottle_infos then
            reset_arrow_types(managed)
        end

        -- Manually set type of arrow
        -- <BottleType>k__BackingField
            -- 1 = Close Range
            -- 2 = Power
            -- 3 = Pierce
            -- 4 = Paralysis
            -- 5 = Poison
            -- 6 = Sleep
            -- 7 = Blast
            -- 8 = Exhaust


        -- Unlimited bottles
        if Module.data.unlimited_bottles then
            Module.hidden.tetrad_shot_active = false
            local skills = managed:get_Hunter():get_HunterSkill():get_field("_NextSkillInfo"):get_field("_items")

            for i = 0, skills:get_Length() - 1 do
                local skill = skills:get_Item(i)
                if skill and skill:get_SkillData():get_Index() == 38 then -- Tetrad Shot
                     Module.hidden.tetrad_shot_active = true
                    break
                end
            end

            local max_bottle_num =  Module.hidden.tetrad_shot_active and 4 or 10

            managed:set_field("<BottleNum>k__BackingField", max_bottle_num)
            managed:set_field("<BottleShotCount>k__BackingField", 10 - max_bottle_num)
        end


        -- Trick Arrow Gauge 
        if Module.data.max_trick_arrow_gauge then
            managed:get_field("<ArrowGauge>k__BackingField"):set_field("_Value", 100)
        end

        -- Bladescale Loading
        if Module.data.unlimited_bladescale then
            local skills = managed:get_Hunter():get_HunterSkill():get_field("_NextSkillInfo"):get_field("_items")
            for i = 0, skills:get_Length() - 1 do
                local skill = skills:get_Item(i)
                if skill and skill:get_SkillData():get_Index() == 201 then -- Bladescale Loading
                    managed:set_field("<Skill218BottleNum>k__BackingField", 3)
                    break
                end
            end
        end

    end, function(retval) end)
end

function Module.draw()
    imgui.push_id(Module.title)
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    if imgui.collapsing_header("    " .. language.get(languagePrefix .. "title")) then
        imgui.indent(10)
       
        changed, Module.data.charge_level = imgui.slider_int(language.get(languagePrefix .. "charge_level"), Module.data.charge_level, -1, 3, Module.data.charge_level == -1 and language.get("base.disabled") or "%d")
        any_changed = any_changed or changed

        changed, Module.data.all_arrow_types = imgui.checkbox(language.get(languagePrefix .. "all_arrow_types"), Module.data.all_arrow_types)
        any_changed = any_changed or changed

        imgui.begin_table(Module.title.."1", 2, nil, nil, nil)
        imgui.table_next_row()
        imgui.table_next_column()

        changed, Module.data.unlimited_bottles = imgui.checkbox(language.get(languagePrefix .. "unlimited_bottles"), Module.data.unlimited_bottles)
        if  Module.hidden.tetrad_shot_active then
            imgui.same_line()
            utils.tooltip(language.get(languagePrefix .. "tetrad_shot_active"))
        end

        imgui.table_next_column()

        changed, Module.data.unlimited_bladescale = imgui.checkbox(language.get(languagePrefix .. "unlimited_bladescale"), Module.data.unlimited_bladescale)
        any_changed = any_changed or changed

        imgui.end_table()

        changed, Module.data.max_trick_arrow_gauge = imgui.checkbox(language.get(languagePrefix .. "max_trick_arrow_gauge"), Module.data.max_trick_arrow_gauge)
        any_changed = any_changed or changed

        if any_changed then config.save_section(Module.create_config_section()) end
        imgui.unindent(10)
        imgui.separator()
        imgui.spacing()
    end
    imgui.pop_id()
end

function Module.reset()

    -- Reset the arrow types if all_arrow_types is enabled
    if Module.data.all_arrow_types and Module.old.bottle_infos then
        local player = utils.getMasterCharacter()
        local weapon_handling = player:get_WeaponHandling()
        local reserve_weapon_handling = player:get_ReserveWeaponHandling()

        local weapon = weapon_handling:get_type_definition():is_a("app.cHunterWp11Handling") and weapon_handling or reserve_weapon_handling:get_type_definition():is_a("app.cHunterWp11Handling") and reserve_weapon_handling or nil
        if not weapon then return end
        
        reset_arrow_types(weapon)
    end
end

function Module.create_config_section()
    return {
        [Module.title] = Module.data
    }
end

function Module.load_from_config(config_section)
    if not config_section then return end
    utils.update_table_with_existing_table(Module.data, config_section)
end

return Module
