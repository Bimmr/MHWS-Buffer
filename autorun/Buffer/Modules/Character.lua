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
        bonus_attack = -1,
        bonus_defence = -1,
        critical_chance = -1,
        bonus_elemental = -1,
        element = -1
    },
    invincible = false,
    unlimited_sharpness = false,
    unlimited_consumables = false,
    unlimited_slingers = false,
    unlimited_meal_timer = false,
})

-- Local variables
local skip_consumable_use = false
local skip_slinger_use = false

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
    poison =        {field = "_Poison",  duration_field = "_DurationTimer",     method = "forceDeactivate"},
    stench =        {field = "_Stench",  duration_field = "_DurationTimer",     method = "forceDeactivate"},
    blast =         {field = "_Blast",   duration_field = "_CureAccumerator",   method = "forceDeactivate"},
    bleed =         {field = "_Bleed",   duration_field = "_CureTimer",         method = "forceDeactivate"},
    defense_down =  {field = "_DefDown", duration_field = "_DurationTimer",     method = "forceDeactivate"},
    sleep =         {field = "_Sleep",   duration_field = "_DurationTime",      method = "forceDeactivate"},
    bubble =        {field = "_Ex00",    duration_field = "_DurationTimer",     method = "forceDeactivate"},
    hp_reduction =  {field = "_Ex01",    duration_field = "_DurationTimer",     method = "forceDeactivate"},
    -- Frenzy, Stun, Paralyze, Sticky, Frozen are handled differently
}
local BLIGHTS_DATA = {
    fire =          {field = "_Fire",    duration_field = "_DurationTimer",     method = "forceDeactivate"},
    thunder =       {field = "_Elec",    duration_field = "_DurationTimer",     method = "forceDeactivate"},
    water =         {field = "_Water",   duration_field = "_DurationTimer",     method = "forceDeactivate"},
    ice =           {field = "_Ice",     duration_field = "_DurationTimer",     method = "forceDeactivate"},
    dragon =        {field = "_Dragon",  duration_field = "_DurationTimer",     method = "forceDeactivate"},
}

--- Updates a float field value with caching and restoration support
--- @param key string Cache key for storing original values
--- @param field_name string Name of the field to update
--- @param managed userdata The managed object containing the field
--- @param new_value number The new value to apply
--- @param is_override boolean If true, replaces value; if false, adds to original
local function updateDahliaFloatBox(key, field_name, managed, new_value, is_override)
    if not managed then return end

    -- Ensure cache table exists
    Module.old[key] = Module.old[key] or {}
    local cache = Module.old[key]
    
    -- Get field reference
    local field = managed:get_field(field_name)
    if not field then return end

    -- Determine if feature is disabled
    local disabled = (is_override and new_value < 0) or (not is_override and new_value <= 0)

    if disabled then
        -- Restore original value if cached
        if cache[field_name] then
            field:write(cache[field_name] + 0.0)
            cache[field_name] = nil
        end
        return
    end

    -- Cache original value on first use
    cache[field_name] = cache[field_name] or field:read()
    local original = cache[field_name]

    -- Calculate and write new value (always as float)
    local final_value = is_override and new_value or (original + new_value)
    field:write(final_value + 0.0)
end

function Module.create_hooks() 

    sdk.hook(sdk.find_type_definition("app.cHunterStatus"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("app.cHunterStatus") then return end
        if managed:get_IsMaster() == false then return end

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
        for condition_name, condition_data in pairs(CONDITIONS_DATA) do
            if Module.data.blights_and_conditions.conditions[condition_name] or Module.data.blights_and_conditions.conditions.all then
                local condition = conditions:get_field(condition_data.field)
                if condition:get_field(condition_data.duration_field) > 0 then
                    condition:call(condition_data.method)
                end
            end
        end
        -- Blights
        for blight_name, blight_data in pairs(BLIGHTS_DATA) do
            if Module.data.blights_and_conditions.blights[blight_name] or Module.data.blights_and_conditions.blights.all then
                local blight = conditions:get_field(blight_data.field)
                if blight:get_field(blight_data.duration_field) > 0 then
                    blight:call(blight_data.method)
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
            if stun:get_field("_Accumulator") > 0 then
                stun:set_field("_Accumulator", 0)
            end
        end
        -- Paralyze is handled differently
        if Module.data.blights_and_conditions.conditions.paralyze or Module.data.blights_and_conditions.conditions.all then
            local paralyze = conditions:get_field("_Paralyze") -- Effect still plays
            if paralyze:get_field("_DurationTime") > 0 then
                paralyze:cure() --* cure stops more of the animation than forceDeactivate
            end
            if paralyze:get_field("_Accumulator") > 0 then
                paralyze:set_field("_Accumulator", 0)
            end
        end
        -- Sticky is handled differently
        if Module.data.blights_and_conditions.conditions.sticky or Module.data.blights_and_conditions.conditions.all then
            local sticky = conditions:get_field("_Sticky") -- Effect probably still plays
            if sticky:get_field("_DurationTime") > 0 then
                sticky:set_field("_DurationTime", 0)
                sticky:set_field("_IsRestrainted", false)
            end
        end
        -- Frozen is handled differently
        if Module.data.blights_and_conditions.conditions.frozen or Module.data.blights_and_conditions.conditions.all then
            local frozen = conditions:get_field("_Frozen") -- Effect still partially plays
            if frozen:get_field("_DurationTime") > 0 then
                frozen:cure()
            end
            if frozen:get_field("_Accumulator") > 0 then
                frozen:set_field("_Accumulator", 0)
            end
        end
        
        -- Stats
        updateDahliaFloatBox("bonus_attack",    "_WeaponAttackPower",           managed:get_AttackPower(),  Module.data.stats.bonus_attack, false)
        updateDahliaFloatBox("bonus_defence",   "_OriginalArmorDefencePower",   managed:get_DefencePower(), Module.data.stats.bonus_defence, false)
        updateDahliaFloatBox("critical_chance", "_OriginalCritical",            managed:get_CriticalRate(), Module.data.stats.critical_chance, true)
        updateDahliaFloatBox("elemental_attack", "_WeaponAttrPower",            managed:get_AttackPower(), Module.data.stats.bonus_elemental > 0 and Module.data.stats.bonus_elemental / 10 or Module.data.stats.bonus_elemental, false)

        -- Element
        if Module.data.stats.element ~= -1 then
            local attack_power = managed:get_field("_AttackPower")
            if not Module.old.stats then Module.old.stats = {} end
            if Module.old.stats.element == nil then
                Module.old.stats.element = attack_power:get_field("_WeaponAttrType")
            end
            attack_power:set_field("_WeaponAttrType", Module.data.stats.element)
        elseif Module.old.stats and Module.old.stats.element ~= nil then
            local attack_power = managed:get_field("_AttackPower")
            attack_power:set_field("_WeaponAttrType", Module.old.stats.element)
            Module.old.stats.element = nil
        end

    end, function(retval)
    end)

    -- Unlimited Sharpness
    sdk.hook(sdk.find_type_definition("app.cHunterWeaponHandlingBase"):get_method("consumeKireajiFromAttack(app.HitInfo)"), function(args)
        if Module.data.unlimited_sharpness then
            return sdk.PreHookResult.SKIP_ORIGINAL
        end
    end, function(retval) end)

    sdk.hook(sdk.find_type_definition("app.cHunterWeaponHandlingBase"):get_method("consumeKireaji(System.Int32, System.Boolean)"), function(args)
        if Module.data.unlimited_sharpness then
            return sdk.PreHookResult.SKIP_ORIGINAL
        end
    end, function(retval) end)


    -- Invincibility
    sdk.hook(sdk.find_type_definition("app.HunterCharacter"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("app.HunterCharacter") then return end
        if not managed:get_IsMaster() then return end

        if Module.data.invincible then
            managed:makeInvincible()
        end

    end, function(retval) end)


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

    -- Unlimited Slingers
    sdk.hook(sdk.find_type_definition("app.HunterCharacter"):get_method("useSlinger"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_IsMaster() then return end

        if Module.data.unlimited_slingers then
            skip_slinger_use = true
        end
    end, function(retval)
        skip_slinger_use = false
        return retval
    end)
    
    -- Used for consumables in both the slinger and item pouch
    sdk.hook(sdk.find_type_definition("app.savedata.cItemParam"):get_method("changeItemPouchNum(app.ItemDef.ID, System.Int16, app.savedata.cItemParam.POUCH_CHANGE_TYPE)"), function(args)
        if skip_consumable_use or skip_slinger_use then
            return sdk.PreHookResult.SKIP_ORIGINAL
        end
    end, function(retval) return retval end)
    
    -- Pickupable slinger ammo
    sdk.hook(sdk.find_type_definition("app.cSlingerAmmo"):get_method("useAmmo"), function(args)
        if skip_slinger_use then
            return sdk.PreHookResult.SKIP_ORIGINAL
        end
    end, function(retval) return retval end)


    -- Mantles
    sdk.hook(sdk.find_type_definition("app.mcActiveSkillController"):get_method("updateMain"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not managed then return end
        if not managed:get_field("_Hunter"):get_IsMaster() then return end

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

    end, function(retval) end)

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

            languagePrefix = Module.title .. ".blights_and_conditions.blights."
            if imgui.tree_node(language.get(languagePrefix .. "title")) then

                imgui.begin_table(Module.title .. "1", 2, nil, nil, nil)
                imgui.table_next_row()

                local BLIGHT_KEYS = {
                    "fire", "thunder", "water", 
                    "ice", "dragon", "all"
                }

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

                imgui.begin_table(Module.title .. "2", 2, nil, nil, nil)
                imgui.table_next_row()

                local CONDITION_KEYS = {
                    "poison", "stench", "blast", "bleed", "defense_down", "frenzy", "hp_reduction",
                    "stun", "paralyze", "sleep", "sticky", "frozen", "bubble", "all"
                }

                for i, key in ipairs(CONDITION_KEYS) do
                   if i == 1 or i == math.ceil(#CONDITION_KEYS / 2) + 1 then imgui.table_next_column() end
                   changed, Module.data.blights_and_conditions.conditions[key] = imgui.checkbox(language.get(languagePrefix .. key), Module.data.blights_and_conditions.conditions[key])
                   any_changed = any_changed or changed
                end

                imgui.end_table()
                imgui.tree_pop()
            end
            imgui.tree_pop()
        end
        utils.tooltip(language.get(languagePrefix .. "tooltip"))

        languagePrefix = Module.title .. ".item_buffs."
        if imgui.tree_node(language.get(languagePrefix .. "title")) then

            imgui.begin_table(Module.title .. "3", 2, nil, nil, nil)
            imgui.table_next_row()

            local ITEM_KEYS = {
                "might_seed", "might_pill", "demon_drug", "mega_demondrug", "demon_powder", "hot_drink", "dash_juice",
                "adamant_seed", "adamant_pill", "armor_skin", "mega_armorskin", "hardshell_powder", "cool_drink", "imunizer"
            }

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

            changed, Module.data.stats.bonus_attack = imgui.drag_int(language.get(languagePrefix .. "bonus_attack"), Module.data.stats.bonus_attack, 1, 0, 5000, Module.data.stats.bonus_attack <= 0 and language.get("base.disabled") or "%d")
            any_changed = any_changed or changed

            changed, Module.data.stats.bonus_defence = imgui.drag_int(language.get(languagePrefix .. "bonus_defence"), Module.data.stats.bonus_defence, 1, 0, 5000, Module.data.stats.bonus_defence <= 0 and language.get("base.disabled") or "%d")
            any_changed = any_changed or changed

            changed, Module.data.stats.critical_chance = imgui.slider_int(language.get(languagePrefix .. "critical_chance"), Module.data.stats.critical_chance, -1, 100, Module.data.stats.critical_chance == -1 and language.get("base.disabled") or "%d%%")
            any_changed = any_changed or changed

            changed, Module.data.stats.bonus_elemental = imgui.drag_int(language.get(languagePrefix .. "bonus_elemental"), Module.data.stats.bonus_elemental, 1, 0, 2000, Module.data.stats.bonus_elemental <= 0 and language.get("base.disabled") or "%d")
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

function Module.reset()
    -- Implement reset functionality if needed
end

return Module
