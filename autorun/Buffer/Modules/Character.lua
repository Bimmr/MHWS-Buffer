local ModuleBase = require("Buffer.Misc.ModuleBase")
local language = require("Buffer.Misc.Language")
local utils = require("Buffer.Misc.Utils")

local Module = ModuleBase:new("character", {
    health = {
        max = false,
        unlimited = false,
        healing = false
    },
    stamina = {
        max = false,
        unlimited = false
    },
    item_buffs = {
        dash_juice = false,
        hot_drink = false,
        cool_drink = false,
        imunizer = false,
        might_seed = false, -- _Kairiki_Timer
        might_pill = false, -- _Kairiki_G_Timer
        adamant_seed = false, -- _Nintai_Timer
        adamant_pill = false, -- _Nintai_G_Timer

        demon_drug = false, -- _KijinDrink
        mega_demondrug = false, -- _KijinDrink_G
        armor_skin = false, -- _KoukaDrink
        mega_armorskin = false, -- _KoukaDrink_G 

        demon_powder = false, -- _KijinPowder_Timer
        hardshell_powder = false -- _KoukaPowder_Timer
    },
    blights_and_conditions = {
        blights = {
            fire = false,
            thunder = false,
            water = false,
            ice = false,
            dragon = false,
            all = false
        },
        conditions = {
            poison = false,
            stench = false,
            blast = false,
            bleed = false,
            defense_down = false,
            frenzy = false,
            stun = false,
            paralyze = false,
            sleep = false,
            sticky = false,
            frozen = false,
            bubble = false,
            hp_reduction = false,
            all = false
        }
    },
    mantles = {
        instant_cooldown = false,
        unlimited_duration = false
    },
    stats = {
        use_bonus_mode = false,
        attack = -1,
        defence = -1,
        critical_chance = -1,
        elemental_attack = -1,
        element = -1,
        defence_attributes = {
            fire_enable = false,
            _fire_value = 0,
            water_enable = false,
            _water_value = 0,
            ice_enable = false,
            _ice_value = 0,
            thunder_enable = false,
            _thunder_value = 0,
            dragon_enable = false,
            _dragon_value = 0
        }
    },
    invincible = false,
    unlimited_sharpness = false,
    unlimited_consumables = false,
    unlimited_slingers = false,
    unlimited_meal_timer = false,
})

-- Local variables
local skip_consumable_use = false
local slinger_skip_active = false

-- Item Buffs
local ITEM_BUFFS_DATA = {
    dash_juice =       {field = "_DashJuice_Timer",     duration = 600},
    hot_drink =        {field = "_HotDrink_Timer",      duration = 600},
    cool_drink =       {field = "_CoolerDrink_Timer",   duration = 600},
    imunizer =         {field = "_Immunizer_Timer",     duration = 300},
    might_seed =       {field = "_Kairiki_Timer",       duration = 180},
    might_pill =       {field = "_Kairiki_G_Timer",     duration = 90},
    adamant_seed =     {field = "_Nintai_Timer",       duration = 180},
    adamant_pill =     {field = "_Nintai_G_Timer",     duration = 90},
    demon_powder =     {field = "_KijinPowder_Timer",   duration = 180},
    hardshell_powder = {field = "_KoukaPowder_Timer",   duration = 180}
    -- Demon Drug, Mega Demondrug, Armor Skin, Mega Armorskin are handled differently
}

-- Conditions
local CONDITIONS_DATA = {
    poison =        "_Poison",
    stench =        "_Stench",
    blast =         "_Blast",
    bleed =         "_Bleed",
    defense_down =  "_DefDown",
    sleep =         "_Sleep",
    bubble =        "_Ex00",
    hp_reduction =  "_Ex01",
    -- Frenzy, Stun, Paralyze, Sticky, Frozen are handled differently
}
local BLIGHTS_DATA = {
    fire =          "_Fire",
    thunder =       "_Elec",
    water =         "_Water",
    ice =           "_Ice",
    dragon =        "_Dragon",
}

--- Updates a float field value to reach a target total value
--- @param key string Cache key for storing original values
--- @param field_name string Name of the field to update
--- @param managed userdata The managed object containing the field
--- @param target_value number The desired final value (pass -1 to disable/restore)
--- @param current_total_value number The current total value from the game (get_Current...)
local function updateDahliaFloatBox(key, field_name, managed, target_value, current_total_value, use_bonus_mode)
    if not managed then return end

    -- Ensure cache table exists
    Module.old[key] = Module.old[key] or {}
    local cache = Module.old[key]
    
    -- Get field reference
    local field = managed:get_field(field_name)
    if not field then return end

    -- Determine if feature is disabled
    if target_value < 0 then
        -- Restore original value if cached
        if cache[field_name] then
            field:write(cache[field_name] + 0.0)
            cache[field_name] = nil
        end
        return
    end

    -- Get the value currently in the field (Our contribution + Base)
    local current_field_value = field:read()

    -- Cache original value on first use
    if not cache[field_name] then
        cache[field_name] = current_field_value
    end

    local new_value
    if use_bonus_mode then
        -- Bonus Mode: Add user value to the original field value
        new_value = cache[field_name] + target_value
    else
        -- Target Mode: Calculate offset to reach target total
        -- Total = FieldValue + Others  =>  Others = Total - FieldValue
        local other_contributions = current_total_value - current_field_value

        -- Calculate new field value to reach target
        -- Target = NewFieldValue + Others  =>  NewFieldValue = Target - Others
        new_value = target_value - other_contributions
    end

    field:write(new_value + 0.0)
end

--- Updates a DahliaFloatBox value directly with caching and toggle support
--- @param key string Cache key category
--- @param id string Unique identifier for this box in the cache
--- @param box userdata The DahliaFloatBox object
--- @param new_value number The new value to apply
--- @param enabled boolean Whether to apply the new value
local function updateDahliaFloatBoxToggle(key, id, box, new_value, enabled)
    if not box then return end

    -- Ensure cache table exists
    Module.old[key] = Module.old[key] or {}
    local cache = Module.old[key]

    if not enabled then
        -- Restore original value if cached
        if cache[id] then
            box:write(cache[id] + 0.0)
            cache[id] = nil
        end
        return
    end

    -- Cache original value on first use
    cache[id] = cache[id] or box:read()
    
    -- Write new value
    box:write(new_value + 0.0)
end

function Module.create_hooks() 

    
    -- Watch for weapon changes to reset stat changes
    sdk.hook(sdk.find_type_definition("app.HunterCharacter"):get_method("changeWeapon"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("app.HunterCharacter") then return end
        if not managed:get_IsMaster() then return end

        Module.reset_stat_changes()
    end)
    
    -- Watch for reserve weapon changes
    sdk.hook(sdk.find_type_definition("app.HunterCharacter"):get_method("changeWeaponFromReserve"), function(args) 
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("app.HunterCharacter") then return end
        if not managed:get_IsMaster() then return end

        Module.reset_stat_changes()
    end)


    Module:init_stagger("character_status_update", 5)
    sdk.hook(sdk.find_type_definition("app.cHunterStatus"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("app.cHunterStatus") then return end
        if managed:get_IsMaster() == false then return end

        if not Module:should_execute_staggered("character_status_update") then return end

        -- Managers
        local health = managed:get_field("_Health")
        local hunter_meal_effect = managed:get_field("_MealEffect")
        local meal_effect = hunter_meal_effect:get_field("_MealEffect")
        local stamina = managed:get_field("_Stamina")
        local item_buffs = managed:get_field("_ItemBuff")
        local conditions = managed:get_field("_BadConditions")

        -- Health
        if health ~= nil then
            local health_manager = health:get_field("<HealthMgr>k__BackingField")

            if Module.data.health.unlimited then
                health_manager:set_Health(health_manager:get_MaxHealth())
            end
            if Module.data.health.healing then
                health:set_field("_RedHealth", health_manager:get_MaxHealth())
            end
        end

        if Module.data.health.max then
            if hunter_meal_effect ~= nil then
                if hunter_meal_effect:get_field("_IsEffectActive") ~= true then
                    hunter_meal_effect:set_field("_IsEffectActive", true)
                end
                if hunter_meal_effect:get_field("_MaxHealthAdd") < 50 then
                    hunter_meal_effect:set_field("_MaxHealthAdd", 50)
                end
            end
        end

        -- Stamina
        if stamina ~= nil then
            if Module.data.stamina.unlimited then
                stamina:set_field("_RequestHealStaminaMax", true)
            end

            if Module.data.stamina.max then
                if hunter_meal_effect:get_field("_IsEffectActive") ~= true then
                    hunter_meal_effect:set_field("_IsEffectActive", true)
                end
                if hunter_meal_effect:get_field("_MaxStaminaAdd") < 50 then --* Doesn't actually do anything, but it makes it look like stamina got increased by food
                    hunter_meal_effect:set_field("_MaxStaminaAdd", 50)
                end
                if stamina:get_MaxStamina() < 150 then
                    stamina:set_field("_RequestAddMaxStamina", 1)
                end
            end
        end

        -- Meal Timer
        if Module.data.unlimited_meal_timer then
            if hunter_meal_effect ~= nil then
                if hunter_meal_effect:get_field("_IsTimerActive") then
                    hunter_meal_effect:set_field("_DurationTimer", hunter_meal_effect:get_field("_TimerMax"))
                end
            end
        end

        -- Item Buffs
        if item_buffs ~= nil then

            -- Basic item buffs
            for buff_name, buff_data in pairs(ITEM_BUFFS_DATA) do
                if Module.data.item_buffs[buff_name] then
                    item_buffs:set_field(buff_data.field, buff_data.duration)
                end
            end
            
            -- Demon Drug is handled differently
            if Module.data.item_buffs.demon_drug then
                local demon_drug = item_buffs:get_field("_KijinDrink")
                if demon_drug:get_field("_Timer") <= 0 then
                    item_buffs:activateItemBuff(sdk.to_ptr(4), 1.0, 1.0)   
                end
            end
            -- Mega Demondrug is handled differently
            if Module.data.item_buffs.mega_demondrug then
                local mega_demon_drug = item_buffs:get_field("_KijinDrink_G")
                if mega_demon_drug:get_field("_Timer") <= 0 then
                    item_buffs:activateItemBuff(sdk.to_ptr(5), 1.0, 1.0)
                end
            end
            -- Armor Skin is handled differently
            if Module.data.item_buffs.armor_skin then
                local armor_skin = item_buffs:get_field("_KoukaDrink")
                if armor_skin:get_field("_Timer") <= 0 then
                    item_buffs:activateItemBuff(sdk.to_ptr(10), 1.0, 1.0)        
                end
            end
            -- Mega Armorskin is handled differently
            if Module.data.item_buffs.mega_armorskin then
                local mega_armor_skin = item_buffs:get_field("_KoukaDrink_G")
                if mega_armor_skin:get_field("_Timer") <= 0 then
                    item_buffs:activateItemBuff(sdk.to_ptr(11), 1.0, 1.0)
                end
            end
        end

        -- Conditions
        for condition_name, field_name in pairs(CONDITIONS_DATA) do
            if Module.data.blights_and_conditions.conditions[condition_name] or Module.data.blights_and_conditions.conditions.all then
                local condition = conditions:get_field(field_name)
                if condition:call("get_IsActive") then
                    condition:call("forceDeactivate")
                end
            end
        end
        -- Blights
        for blight_name, field_name in pairs(BLIGHTS_DATA) do
            if Module.data.blights_and_conditions.blights[blight_name] or Module.data.blights_and_conditions.blights.all then
                local blight = conditions:get_field(field_name)
                if blight:call("get_IsActive") then
                    blight:call("forceDeactivate")
                end
            end
        end

        -- Frenzy is handled different
        if Module.data.blights_and_conditions.conditions.frenzy or Module.data.blights_and_conditions.conditions.all then
            local frenzy = conditions:get_field("_Frenzy")
            -- _State (0 = Infect(Ready)), 1 = Outbreak(Bad)), 2 = Overcome(Good))
            -- _DurationTimer - counts down from _DurationTime
            -- _OvercomePoint - builds up on attack towards _OvercomeTargetPoint
            -- _PointReduceTimer - Builds up to 1 (Keeping at 0 stops _DurationTimer from counting down, if _State is 1)
            -- _OvercomeCount - (Tracks how many times you've overcome, increases _OvercomeTargetPoint by 10 per)
            if frenzy:get_field("_State") == 1 and frenzy:get_field("_DurationTimer") > 1.0 then
                frenzy:set_field("_DurationTimer", 0.2)
            end
        end
        -- Stun is handled differently
        if Module.data.blights_and_conditions.conditions.stun or Module.data.blights_and_conditions.conditions.all then
            local stun = conditions:get_field("_Stun")
            if stun:get_field("_ReduceTimer") < 6 then --? Maybe a Jewel or skill lowers this
                stun:set_field("_ReduceTimer", 6)
            end
            if stun:get_Accumulator() > 0 then
                stun:resetAccumulator()
            end
        end
        -- Paralyze is handled differently
        if Module.data.blights_and_conditions.conditions.paralyze or Module.data.blights_and_conditions.conditions.all then
            local paralyze = conditions:get_field("_Paralyze") -- Effect still plays
            if paralyze:call("get_IsActive") then
                paralyze:cure() --* cure stops more of the animation than forceDeactivate
            end
            if paralyze:get_Accumulator() > 0 then
                paralyze:resetAccumulator()
            end
        end
        -- Sticky is handled differently
        if Module.data.blights_and_conditions.conditions.sticky or Module.data.blights_and_conditions.conditions.all then
            local sticky = conditions:get_field("_Sticky") -- Effect probably still plays
            if sticky:call("get_IsActive") then
                sticky:set_field("_DurationTime", 0)
                sticky:set_field("_IsRestrainted", false)
            end
        end
        -- Frozen is handled differently
        if Module.data.blights_and_conditions.conditions.frozen or Module.data.blights_and_conditions.conditions.all then
            local frozen = conditions:get_field("_Frozen") -- Effect still partially plays
            if frozen:call("get_IsActive") then
                frozen:cure()
            end
            if frozen:get_Accumulator() > 0 then
                frozen:resetAccumulator()
            end
        end
        
        -- Stats
        local user_bonus_mode = Module.data.stats.use_bonus_mode
        updateDahliaFloatBox("attack",          "_WeaponAttackPower",           managed:get_AttackPower(),  Module.data.stats.attack, managed:get_AttackPower():get_CurrentAttackPower(), user_bonus_mode)
        updateDahliaFloatBox("defence",         "_OriginalArmorDefencePower",   managed:get_DefencePower(), Module.data.stats.defence, managed:get_DefencePower():get_CurrentDefencePower(), user_bonus_mode)
        updateDahliaFloatBox("critical_chance", "_OriginalCritical",            managed:get_CriticalRate(), Module.data.stats.critical_chance, managed:get_CriticalRate():get_CurrentCriticalRate(), user_bonus_mode)
        updateDahliaFloatBox("elemental_attack", "_WeaponAttrPower",            managed:get_AttackPower(), Module.data.stats.elemental_attack > 0 and Module.data.stats.elemental_attack / 10 or Module.data.stats.elemental_attack, managed:get_AttackPower():get_CurrentAttrPower(), user_bonus_mode)
        
        -- Defence Attributes
        local def_attrs = Module.data.stats.defence_attributes
        local defence_power = managed:get_DefencePower()
        local attribute_defence = defence_power:get_field("_OriginalElementResistPower") -- Array of DahliaFloatBoxes
        
        -- Defence attributes seem to be offset by 10
        updateDahliaFloatBoxToggle("defence_attributes", "fire", attribute_defence[1], def_attrs._fire_value - 10, def_attrs.fire_enable)
        updateDahliaFloatBoxToggle("defence_attributes", "water", attribute_defence[2], def_attrs._water_value - 10, def_attrs.water_enable)
        updateDahliaFloatBoxToggle("defence_attributes", "thunder", attribute_defence[3], def_attrs._thunder_value - 10, def_attrs.thunder_enable)
        updateDahliaFloatBoxToggle("defence_attributes", "ice", attribute_defence[4], def_attrs._ice_value - 10, def_attrs.ice_enable)
        updateDahliaFloatBoxToggle("defence_attributes", "dragon", attribute_defence[5], def_attrs._dragon_value - 10, def_attrs.dragon_enable)

        -- Element
        Module:cache_and_update_field("element", managed:get_field("_AttackPower"), "_WeaponAttrType", Module.data.stats.element)

   end)

    -- Unlimited Sharpness
    sdk.hook(sdk.find_type_definition("app.cHunterWeaponHandlingBase"):get_method("consumeKireajiFromAttack(app.HitInfo)"), function(args)
        if Module.data.unlimited_sharpness then
            return sdk.PreHookResult.SKIP_ORIGINAL
        end
    end)

    sdk.hook(sdk.find_type_definition("app.cHunterWeaponHandlingBase"):get_method("consumeKireaji(System.Int32, System.Boolean)"), function(args)
        if Module.data.unlimited_sharpness then
            return sdk.PreHookResult.SKIP_ORIGINAL
        end
    end)


    -- Invincibility
    sdk.hook(sdk.find_type_definition("app.HunterCharacter"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("app.HunterCharacter") then return end
        if not managed:get_IsMaster() then return end

        if Module.data.invincible then
            managed:makeInvincible()
        end

    end)


    -- Unlimited Consumables
    sdk.hook(sdk.find_type_definition("app.HunterCharacter.cHunterExtendBase"):get_method("useItem"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_IsMaster() then return end

        if Module.data.unlimited_consumables then
            skip_consumable_use = true
        end

    end, function(retval)
        skip_consumable_use = false
        return retval
    end)
    

    -- Weapon holstered slinger shot
    sdk. hook(sdk.find_type_definition("app.HunterCharacter"):get_method("shootSlinger(app.HunterDef.SLINGER_AMMO_TYPE, via.vec3, System.Nullable`1<via.vec2>)"), function(args)
        local managed = sdk. to_managed_object(args[2])
        if not managed: get_IsMaster() then return end

        if Module.data. unlimited_slingers then
            slinger_skip_active = true
        end
    end, function(retval)
        return retval
    end)

    -- Weapon out slinger shot
    sdk.hook(sdk.find_type_definition("app.HunterCharacter"):get_method("shootSlinger(app.HunterDef.SLINGER_AMMO_TYPE, via.vec3, via.vec3, System.Nullable`1<via.vec2>)"), function(args)
        local managed = sdk. to_managed_object(args[2])
        if not managed: get_IsMaster() then return end

        if Module.data. unlimited_slingers then
            slinger_skip_active = true
        end
    end, function(retval)
        return retval
    end)

    -- Weapon holstered slinger use (called after shootSlinger for holstered weapon)
    sdk.hook(sdk.find_type_definition("app.HunterCharacter"):get_method("useSlinger"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_IsMaster() then return end
        -- Skip flag already set by shootSlinger if needed
    end, function(retval)
        slinger_skip_active = false
        return retval
    end)

    -- Pickupable slinger ammo consumption (thorngrass, burst, etc.)
    sdk.hook(sdk.find_type_definition("app.cSlingerAmmo"):get_method("useAmmo"), function(args)
        if Module.data.unlimited_slingers then
            return sdk.PreHookResult. SKIP_ORIGINAL
        end
    end, function(retval) 
        return retval 
    end)

    -- Item pouch changes (handles consumable items like dung pods, lightning pods)
    sdk.hook(sdk.find_type_definition("app.savedata.cItemParam"):get_method("changeItemPouchNum(app.ItemDef.ID, System.Int16, app.savedata.cItemParam.POUCH_CHANGE_TYPE)"), function(args)
        if skip_consumable_use or slinger_skip_active then
            return sdk.PreHookResult.SKIP_ORIGINAL
        end
    end, function(retval)
        slinger_skip_active = false
        return retval 
    end)

    -- Mantles
    Module:init_stagger("character_mantles_update", 10)
    sdk.hook(sdk.find_type_definition("app.mcActiveSkillController"):get_method("updateMain"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not managed then return end
        if not managed:get_field("_Hunter"):get_IsMaster() then return end

        if not Module:should_execute_staggered("character_mantles_update") then return end

        local mantles = managed:get_field("_ActiveSkills")
        if not mantles or not (Module.data.mantles.instant_cooldown or Module.data.mantles.unlimited_duration) then return end

        for i, mantle in pairs(mantles) do
            if mantle then
                if Module.data.mantles.instant_cooldown and not mantle:get_IsUse() and mantle:get_Timer() > 0 then
                    mantle:crearTime()
                elseif Module.data.mantles.unlimited_duration and mantle:get_IsUse() then
                    mantle:setTime(mantle:get_MaxEffectiveTime())
                end
            end
        end

    end)

end

function Module.add_ui()
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    languagePrefix = Module.title .. ".health."
    if imgui.tree_node(language.get(languagePrefix .. "title")) then

            changed, Module.data.health.max = imgui.checkbox(language.get(languagePrefix .. "max"), Module.data.health.max)
            any_changed = any_changed or changed

            changed, Module.data.health.unlimited = imgui.checkbox(language.get(languagePrefix .. "unlimited"), Module.data.health.unlimited)
            any_changed = any_changed or changed

            changed, Module.data.health.healing = imgui.checkbox(language.get(languagePrefix .. "healing"), Module.data.health.healing)
            utils.tooltip(language.get(languagePrefix .. "healing_tooltip"))
            any_changed = any_changed or changed

            imgui.tree_pop()

        end

        languagePrefix = Module.title .. ".stamina."
        if imgui.tree_node(language.get(languagePrefix .. "title")) then

            changed, Module.data.stamina.max = imgui.checkbox(language.get(languagePrefix .. "max"), Module.data.stamina.max)
            any_changed = any_changed or changed

            changed, Module.data.stamina.unlimited = imgui.checkbox(language.get(languagePrefix .. "unlimited"), Module.data.stamina.unlimited)
            any_changed = any_changed or changed

            imgui.tree_pop()
        end

        languagePrefix = Module.title .. ".blights_and_conditions."

        if imgui.tree_node(language.get(languagePrefix .. "title")) then
            
            utils.tooltip(language.get(languagePrefix .. "tooltip"))

            languagePrefix = Module.title .. ".blights_and_conditions.blights."
            if imgui.tree_node(language.get(languagePrefix .. "title")) then

                local BLIGHT_KEYS = {
                    "fire", "thunder", "water", 
                    "ice", "dragon", "all"
                }

                local max_width = 0
                for _, key in ipairs(BLIGHT_KEYS) do
                    local text = language.get(languagePrefix .. key)
                    max_width = math.max(max_width, imgui.calc_text_size(text).x)
                end
                local row_width = imgui.calc_item_width()
                local col_width = math.max(max_width + 24 + 20, row_width / 2)

                imgui.begin_table(Module.title .. "1", 2, 0)
                imgui.table_setup_column("1", 16 + 4096, col_width)
                imgui.table_setup_column("2", 16 + 4096, col_width)
                imgui.table_next_row()

                for i, key in ipairs(BLIGHT_KEYS) do
                    if i == 1 or i == math.ceil(#BLIGHT_KEYS / 2) + 1 then imgui.table_next_column() end
                    changed, Module.data.blights_and_conditions.blights[key] = imgui.checkbox(language.get(languagePrefix .. key), Module.data.blights_and_conditions.blights[key])
                    any_changed = any_changed or changed
                end

                imgui.end_table()
                imgui.tree_pop()
            end
                
            languagePrefix = Module.title .. ".blights_and_conditions.conditions."
            if imgui.tree_node(language.get(languagePrefix .. "title")) then

                local CONDITION_KEYS = {
                    "poison", "stench", "blast", "bleed", "defense_down", "frenzy", "hp_reduction",
                    "stun", "paralyze", "sleep", "sticky", "frozen", "bubble", "all"
                }

                local max_width = 0
                for _, key in ipairs(CONDITION_KEYS) do
                    local text = language.get(languagePrefix .. key)
                    max_width = math.max(max_width, imgui.calc_text_size(text).x)
                end
                local row_width = imgui.calc_item_width()
                local col_width = math.max(max_width + 24 + 20, row_width / 2)

                imgui.begin_table(Module.title .. "2", 2, 0)
                imgui.table_setup_column("1", 16 + 4096, col_width)
                imgui.table_setup_column("2", 16 + 4096, col_width)
                imgui.table_next_row()

                for i, key in ipairs(CONDITION_KEYS) do
                   if i == 1 or i == math.ceil(#CONDITION_KEYS / 2) + 1 then imgui.table_next_column() end
                   changed, Module.data.blights_and_conditions.conditions[key] = imgui.checkbox(language.get(languagePrefix .. key), Module.data.blights_and_conditions.conditions[key])
                   any_changed = any_changed or changed
                end

                imgui.end_table()
                imgui.tree_pop()
            end
            imgui.tree_pop()
        else
            utils.tooltip(language.get(Module.title .. ".blights_and_conditions." .. "tooltip"))
        end

        languagePrefix = Module.title .. ".item_buffs."
        if imgui.tree_node(language.get(languagePrefix .. "title")) then

            local ITEM_KEYS = {
                "might_seed", "might_pill", "demon_drug", "mega_demondrug", "demon_powder", "hot_drink", "dash_juice",
                "adamant_seed", "adamant_pill", "armor_skin", "mega_armorskin", "hardshell_powder", "cool_drink", "imunizer"
            }

            local max_width = 0
            for _, key in ipairs(ITEM_KEYS) do
                local text = language.get(languagePrefix .. key)
                max_width = math.max(max_width, imgui.calc_text_size(text).x)
            end
            local row_width = imgui.calc_item_width()
            local col_width = math.max(max_width + 24 + 20, row_width / 2)

            imgui.begin_table(Module.title .. "3", 2, 0)
            imgui.table_setup_column("1", 16 + 4096, col_width)
            imgui.table_setup_column("2", 16 + 4096, col_width)
            imgui.table_next_row()

            for i, key in ipairs(ITEM_KEYS) do
                if i == 1 or i == math.ceil(#ITEM_KEYS / 2) + 1 then imgui.table_next_column() end
               changed, Module.data.item_buffs[key] = imgui.checkbox(language.get(languagePrefix .. key), Module.data.item_buffs[key])
               any_changed = any_changed or changed
            end

            imgui.end_table()
            imgui.tree_pop()
        end

        languagePrefix = Module.title .. ".mantles."
        if imgui.tree_node(language.get(languagePrefix .. "title")) then

            changed, Module.data.mantles.instant_cooldown = imgui.checkbox(language.get(languagePrefix .. "instant_cooldown"), Module.data.mantles.instant_cooldown)
            any_changed = any_changed or changed

            changed, Module.data.mantles.unlimited_duration = imgui.checkbox(language.get(languagePrefix .. "unlimited_duration"), Module.data.mantles.unlimited_duration)
            any_changed = any_changed or changed
            imgui.tree_pop()
        end
        
        languagePrefix = Module.title .. ".stats."
        if imgui.tree_node(language.get(languagePrefix .. "title")) then

            changed, Module.data.stats.attack = imgui.drag_int(language.get(languagePrefix .. "attack"), Module.data.stats.attack, 1, -1, 5000, Module.data.stats.attack < 0 and language.get("base.disabled") or "%d")
            any_changed = any_changed or changed

            changed, Module.data.stats.defence = imgui.drag_int(language.get(languagePrefix .. "defence"), Module.data.stats.defence, 1, -1, 5000, Module.data.stats.defence < 0 and language.get("base.disabled") or "%d")
            any_changed = any_changed or changed


            changed, Module.data.stats.critical_chance = imgui.slider_int(language.get(languagePrefix .. "critical_chance"), Module.data.stats.critical_chance, -1, 100, Module.data.stats.critical_chance == -1 and language.get("base.disabled") or "%d%%")
            any_changed = any_changed or changed

            changed, Module.data.stats.elemental_attack = imgui.drag_int(language.get(languagePrefix .. "elemental_attack"), Module.data.stats.elemental_attack, 1, -1, 2000, Module.data.stats.elemental_attack < 0 and language.get("base.disabled") or "%d")
            any_changed = any_changed or changed

            languagePrefix = languagePrefix .. "element."
            local attr_type = {
                language.get("base.disabled"),
                language.get(languagePrefix .. "none"),
                language.get(languagePrefix .. "fire"),
                language.get(languagePrefix .. "water"),
                language.get(languagePrefix .. "ice"),
                language.get(languagePrefix .. "thunder"),
                language.get(languagePrefix .. "dragon"),
                language.get(languagePrefix .. "poison"),
                language.get(languagePrefix .. "paralyze"),
                language.get(languagePrefix .. "sleep"),
                language.get(languagePrefix .. "blast")
            }
            local attr_index = Module.data.stats.element + 2
            changed, attr_index = imgui.combo(language.get(languagePrefix .. "title"), attr_index, attr_type)
            Module.data.stats.element = attr_index - 2
            any_changed = any_changed or changed

            

            languagePrefix = Module.title .. ".stats.defence_attributes."
            if imgui.tree_node(language.get(languagePrefix .. "title")) then
                local element_prefix = Module.title .. ".stats.element."
                local DEFENCE_ATTR_KEYS = { "fire", "water", "ice", "thunder", "dragon" }

                local row_width = imgui.calc_item_width()
                local longest_text_width = 0
                for _, key in ipairs(DEFENCE_ATTR_KEYS) do
                    local text = language.get(languagePrefix .. key .. "_enable"):format(language.get(element_prefix .. key))
                    longest_text_width = math.max(longest_text_width, imgui.calc_text_size(text).x)
                end
                
                imgui.begin_table(Module.title .. "4", 2, 0)

                local column_1_width = longest_text_width + 24 + 10  -- Text length + Checkbox sizing + padding
                imgui.table_setup_column("Toggle", 16 + 4096, column_1_width)

                for _, key in ipairs(DEFENCE_ATTR_KEYS) do
                    local display_name = language.get(element_prefix .. key)
                    local enable_text = language.get(languagePrefix .. key .. "_enable"):format(display_name)
                    
                    imgui.table_next_column()
                    imgui.push_id(key)
                    
                    changed, Module.data.stats.defence_attributes[key .. "_enable"] = imgui.checkbox(enable_text, Module.data.stats.defence_attributes[key .. "_enable"])
                    any_changed = any_changed or changed

                    imgui.table_next_column()
                    if Module.data.stats.defence_attributes[key .. "_enable"] then
                        imgui.set_next_item_width(row_width - (column_1_width + 20 + 10)) -- Possible row width - (first column + padding) 
                        changed, Module.data.stats.defence_attributes["_" .. key .. "_value"] = imgui.slider_int(language.get(languagePrefix .."value"):format(display_name), Module.data.stats.defence_attributes["_" .. key .. "_value"], -100, 100, "%d")
                        any_changed = any_changed or changed
                    end
                    imgui.pop_id()
                end
                imgui.end_table()
                imgui.tree_pop()
            end
            

            imgui.tree_pop()
        end
        
        languagePrefix = Module.title .. "."

        changed, Module.data.invincible = imgui.checkbox(language.get(languagePrefix .. "invincible"), Module.data.invincible)
        utils.tooltip(language.get(languagePrefix .. "invincible_tooltip"))
        any_changed = any_changed or changed

        changed, Module.data.unlimited_sharpness = imgui.checkbox(language.get(languagePrefix .. "unlimited_sharpness"), Module.data.unlimited_sharpness)
        any_changed = any_changed or changed

        changed, Module.data.unlimited_consumables = imgui.checkbox(language.get(languagePrefix .. "unlimited_consumables"), Module.data.unlimited_consumables)
        any_changed = any_changed or changed
        
        changed, Module.data.unlimited_slingers = imgui.checkbox(language.get(languagePrefix .. "unlimited_slingers"), Module.data.unlimited_slingers)
        any_changed = any_changed or changed

        changed, Module.data.unlimited_meal_timer = imgui.checkbox(language.get(languagePrefix .. "unlimited_meal_timer"), Module.data.unlimited_meal_timer)
        any_changed = any_changed or changed
            

    return any_changed
end

function Module.reset_stat_changes()
    local hunter = utils.get_master_character()
    if not hunter then return end
    local status = hunter:get_HunterStatus()
    if not status then return end

    local attack_power = status:get_AttackPower()
    local defence_power = status:get_DefencePower()
    local critical_rate = status:get_CriticalRate()

    updateDahliaFloatBox("attack",    "_WeaponAttackPower",           attack_power, -1, 0, false)
    updateDahliaFloatBox("defence",   "_OriginalArmorDefencePower",   defence_power, -1, 0, false)
    updateDahliaFloatBox("critical_chance", "_OriginalCritical",            critical_rate, -1, 0, false)
    updateDahliaFloatBox("elemental_attack", "_WeaponAttrPower",            attack_power, -1, 0, false)

    if attack_power then
        Module:cache_and_update_field("element", attack_power, "_WeaponAttrType", -1)
    end
end
function Module.reset_defence_attributes()
    
    local hunter = utils.get_master_character()
    if not hunter then return end
    local status = hunter:get_HunterStatus()
    if not status then return end

    local defence_power = status:get_DefencePower()
    if not defence_power then return end

    local attribute_defence = defence_power:get_field("_OriginalElementResistPower") -- Array of DahliaFloatBoxes
    if not attribute_defence then return end

    updateDahliaFloatBoxToggle("defence_attributes", "fire", attribute_defence[1], 0, false)
    updateDahliaFloatBoxToggle("defence_attributes", "water", attribute_defence[2], 0, false)
    updateDahliaFloatBoxToggle("defence_attributes", "thunder", attribute_defence[3], 0, false)
    updateDahliaFloatBoxToggle("defence_attributes", "ice", attribute_defence[4], 0, false)
    updateDahliaFloatBoxToggle("defence_attributes", "dragon", attribute_defence[5], 0, false)
end

function Module.reset()

    -- Disable all stat changes
    Module.reset_stat_changes()

    -- Disable defence attributes
    Module.reset_defence_attributes()
end

return Module
