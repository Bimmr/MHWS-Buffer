local utils, config, language
local Module = {
    title = "character",
    data = {
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
            element = -1,
        },
        invincible = false,
        unlimited_sharpness = false,
        unlimited_consumables = false,
        unlimited_slingers = false,
    },
    old = {
        stats = {}
    }
}

function Module.init()
    utils = require("Buffer.Misc.Utils")
    config = require("Buffer.Misc.Config")
    language = require("Buffer.Misc.Language")

    Module.init_hooks()
end

function Module.init_hooks()

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

        if hunter_meal_effect ~= nil then
            if Module.data.health.max then
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
                if hunter_meal_effect:get_field("_MaxStaminaAdd") < 50 then -- Doesn't actually do anything, but it makes it look like stamina got increased by food
                    hunter_meal_effect:set_field("_MaxStaminaAdd", 50)
                end
                if stamina:get_MaxStamina() < 150 then
                    stamina:set_field("_RequestAddMaxStamina", 1)
                end
            end
        end

        -- Item Buffs
        if item_buffs ~= nil then
            if Module.data.item_buffs.dash_juice then
                item_buffs:set_field("_DashJuice_Timer", 600)
            end
            if Module.data.item_buffs.hot_drink then
                item_buffs:set_field("_HotDrink_Timer", 600)
            end
            if Module.data.item_buffs.cool_drink then
                item_buffs:set_field("_CoolerDrink_Timer", 600)
            end
            if Module.data.item_buffs.imunizer then
                item_buffs:set_field("_Immunizer_Timer", 300)
            end
            if Module.data.item_buffs.might_seed then
                item_buffs:set_field("_Kairiki_Timer", 180)
            end
            if Module.data.item_buffs.might_pill then
                item_buffs:set_field("_Kairiki_G_Timer", 90)
            end
            if Module.data.item_buffs.adamant_seed then
                item_buffs:set_field("_Nintai_Timer", 180)
            end
            if Module.data.item_buffs.adamant_pill then
                item_buffs:set_field("_Nintai_G_Timer", 90)
            end
            if Module.data.item_buffs.demon_drug then
                local demon_drug = item_buffs:get_field("_KijinDrink")
                if demon_drug:get_field("_Timer") <= 0 then
                    item_buffs:activateItemBuff(sdk.to_ptr(4), 1.0, 1.0)   
                end
            end
            if Module.data.item_buffs.mega_demondrug then 
                local demon_drug = item_buffs:get_field("_KijinDrink_G")
                if demon_drug:get_field("_Timer") <= 0 then
                    item_buffs:activateItemBuff(sdk.to_ptr(5), 1.0, 1.0)
                end
            end
            if Module.data.item_buffs.armor_skin then
                local armor_skin = item_buffs:get_field("_KoukaDrink")
                if armor_skin:get_field("_Timer") <= 0 then
                    item_buffs:activateItemBuff(sdk.to_ptr(10), 1.0, 1.0)        
                end
            end
            if Module.data.item_buffs.mega_armorskin then
                local armor_skin = item_buffs:get_field("_KoukaDrink_G")
                if armor_skin:get_field("_Timer") <= 0 then
                    item_buffs:activateItemBuff(sdk.to_ptr(11), 1.0, 1.0)
                end
            end

            if Module.data.item_buffs.demon_powder then
                item_buffs:set_field("_KijinPowder_Timer", 180)
            end
            if Module.data.item_buffs.hardshell_powder then
                item_buffs:set_field("_KoukaPowder_Timer", 180)
            end
        end

        -- Conditions
        if Module.data.blights_and_conditions.conditions.poison or Module.data.blights_and_conditions.conditions.all then
            local poison = conditions:get_field("_Poison")
            if poison:get_field("_DurationTimer") > 0 then
                poison:set_field("_DurationTimer", 0)
            end
        end
        if Module.data.blights_and_conditions.conditions.stench or Module.data.blights_and_conditions.conditions.all then
            local stench = conditions:get_field("_Stench")
            if stench:get_field("_DurationTimer") > 0 then
                stench:set_field("_DurationTimer", 0)
            end
        end
        if Module.data.blights_and_conditions.conditions.blast or Module.data.blights_and_conditions.conditions.all then
            local blast = conditions:get_field("_Blast")
            if blast:get_field("_CureAccumerator") > 0 then
                blast:set_field("_CureAccumerator", 0)
            end
        end
        if Module.data.blights_and_conditions.conditions.bleed or Module.data.blights_and_conditions.conditions.all then
            local bleed = conditions:get_field("_Bleed")
            if bleed:get_field("_CureTimer") > 0 then
                bleed:set_field("_CureTimer", 0)
            end
        end
        if Module.data.blights_and_conditions.conditions.defense_down or Module.data.blights_and_conditions.conditions.all then
            local def_Down = conditions:get_field("_DefDown")
            if def_Down:get_field("_DurationTimer") > 0 then
                def_Down:set_field("_DurationTimer", 0)
            end
        end
        if Module.data.blights_and_conditions.conditions.frenzy or Module.data.blights_and_conditions.conditions.all then -- Not far enough into story to know, will probably affect armor buff
            local frenzy = conditions:get_field("_Frenzy")
             -- _State (0 = Infect(Ready)), 1 = Outbreak(Bad)), 2 = Overcome(Good))
            -- _DurationTimer - counts down from _DurationTime
            -- _OvercomePoint - builds up on attack towards _OvercomeTargetPoint
            -- _PointReduceTimer - Builds up to 1 (Keeping at 0 stops _DurationTimer from counting down, if _State is 1)
            -- _OvercomeCount - (Tracks how many times you've overcome, increases _OvercomeTargetPoint by 10 per)
            if frenzy:get_field("_State") == 1 and frenzy:get_field("_DurationTimer") > 1.0 then
                frenzy:set_field("_DurationTimer", 0.2)
            end
           

            frenzy:set_field("_IsImmune", true)
        end
        if Module.data.blights_and_conditions.conditions.stun or Module.data.blights_and_conditions.conditions.all then
            local stun = conditions:get_field("_Stun")
            if stun:get_field("_ReduceTimer") < 6 then -- Maybe a Jewel or skill lowers this - not far enough to know
                stun:set_field("_ReduceTimer", 6)
            end
        end
        if Module.data.blights_and_conditions.conditions.paralyze or Module.data.blights_and_conditions.conditions.all then
            local paralyze = conditions:get_field("_Paralyze") -- Effect still plays
            if paralyze:get_field("_DurationTime") > 0 then
                paralyze:set_field("_DurationTime", 0)
                paralyze:set_field("_IsRestrainted", false)
            end
            if paralyze:get_field("_Accumulator") > 0 then
                paralyze:set_field("_Accumulator", 0)
            end
        end
        if Module.data.blights_and_conditions.conditions.sleep or Module.data.blights_and_conditions.conditions.all then
            local sleep = conditions:get_field("_Sleep") -- Effect probably still plays
            if sleep:get_field("_DurationTime") > 0 then
                sleep:set_field("_DurationTime", 0)
                sleep:set_field("_IsRestrainted", false)
            end
        end
        if Module.data.blights_and_conditions.conditions.sticky or Module.data.blights_and_conditions.conditions.all then
            local sticky = conditions:get_field("_Sticky") -- Effect probably still plays
            if sticky:get_field("_DurationTime") > 0 then
                sticky:set_field("_DurationTime", 0)
                sticky:set_field("_IsRestrainted", false)
            end
        end
        if Module.data.blights_and_conditions.conditions.frozen or Module.data.blights_and_conditions.conditions.all then
            local frozen = conditions:get_field("_Frozen") -- Effect still plays
            if frozen:get_field("_DurationTime") > 0 then
                frozen:set_field("_DurationTime", 0)
                frozen:set_field("_IsRestrainted", false)
            end
            if frozen:get_field("_Accumulator") > 0 then
                frozen:set_field("_Accumulator", 0)
            end
        end
        if Module.data.blights_and_conditions.conditions.bubble or Module.data.blights_and_conditions.conditions.all then
            local bubble = conditions:get_field("_Ex00") 
            if bubble:get_field("_DurationTimer") > 0 then -- Uses _DurationTimer instead of _DurationTime like the other conditions
                bubble:set_field("_DurationTimer", 0)
                bubble:set_field("_Type", 0)
            end
        end
        if Module.data.blights_and_conditions.blights.fire or Module.data.blights_and_conditions.blights.all then
            local fire = conditions:get_field("_Fire")
            if fire:get_field("_DurationTimer") > 0 then
                fire:set_field("_DurationTimer", 0)
            end
        end
        if Module.data.blights_and_conditions.blights.thunder or Module.data.blights_and_conditions.blights.all then
            local electric = conditions:get_field("_Elec")
            if electric:get_field("_DurationTimer") > 0 then
                electric:set_field("_DurationTimer", 0)
            end
        end
        if Module.data.blights_and_conditions.blights.water or Module.data.blights_and_conditions.blights.all then
            local water = conditions:get_field("_Water")
            if water:get_field("_DurationTimer") > 0 then
                water:set_field("_DurationTimer", 0)
            end
        end
        if Module.data.blights_and_conditions.blights.ice or Module.data.blights_and_conditions.blights.all then
            local ice = conditions:get_field("_Ice")
            if ice:get_field("_DurationTimer") > 0 then
                ice:set_field("_DurationTimer", 0)
            end
        end
        if Module.data.blights_and_conditions.blights.dragon or Module.data.blights_and_conditions.blights.all then
            local dragon = conditions:get_field("_Dragon")
            if dragon:get_field("_DurationTimer") > 0 then
                dragon:set_field("_DurationTimer", 0)
            end
        end

        
        if Module.data.stats.bonus_attack >= 0 then
            if hunter_meal_effect:get_field("_IsEffectActive") ~= true then
                hunter_meal_effect:set_field("_IsEffectActive", true)
            end

            if meal_effect ~= nil then
                meal_effect:set_field("_AttackAdd", Module.data.stats.bonus_attack)
            end
        end
        if Module.data.stats.bonus_defence >= 0 then
            if hunter_meal_effect:get_field("_IsEffectActive") ~= true then
                hunter_meal_effect:set_field("_IsEffectActive", true)
            end
            if meal_effect ~= nil then
                meal_effect:set_field("_DefenceAdd", Module.data.stats.bonus_defence)
            end
        end

        if Module.data.stats.element ~= -1 then
            local attack_power = managed:get_field("_AttackPower")
            if Module.old.stats.element == nil then
                Module.old.stats.element = attack_power:get_field("_WeaponAttrType")
            end
            attack_power:set_field("_WeaponAttrType", Module.data.stats.element)
        elseif Module.old.stats.element ~= nil then
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


    -- Hyper and Super Armor either don't work or I don't know what they do
    sdk.hook(sdk.find_type_definition("app.HunterCharacter"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("app.HunterCharacter") then return end
        if not managed:get_IsMaster() then return end

        if Module.data.invincible then
            managed:makeInvincible()
        end

    end, function(retval) end)


    -- Unlimited Consumables
    local skip_consumable_use = false
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

    local skip_slinger_use = false
    -- Used for consumables in both the slinger and item pouch
    sdk.hook(sdk.find_type_definition("app.savedata.cItemParam"):get_method("changeItemPouchNum(app.ItemDef.ID, System.Int16, app.savedata.cItemParam.POUCH_CHANGE_TYPE)"), function(args)
        if skip_consumable_use or skip_slinger_use then
            return sdk.PreHookResult.SKIP_ORIGINAL
        end
    end, function(retval) return retval end)
  
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
    
    -- Pickupable slinger ammo
    sdk.hook(sdk.find_type_definition("app.cSlingerAmmo"):get_method("useAmmo"), function(args)
        if skip_slinger_use then
            return sdk.PreHookResult.SKIP_ORIGINAL
        end
    end, function(retval) return retval end)


    sdk.hook(sdk.find_type_definition("app.mcActiveSkillController"):get_method("updateMain"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not managed then return end
        if not managed:get_field("_Hunter"):get_IsMaster() then return end

        local mantles = managed:get_field("_ActiveSkills")
        if mantles == nil then return end

        if Module.data.mantles.instant_cooldown or Module.data.mantles.unlimited_duration then
            local managed = sdk.to_managed_object(args[2])
            if not managed then return end
            if not managed:get_field("_Hunter"):get_IsMaster() then return end
    
            local mantles = managed:get_field("_ActiveSkills")
                for i, mantle in pairs(mantles) do
    
                    if not mantle:get_IsUse() and mantle:get_Timer() > 0 and Module.data.mantles.instant_cooldown then
                        mantle:crearTime()
                    elseif mantle:get_IsUse() and Module.data.mantles.unlimited_duration then
                        mantle:setTime(mantle:get_MaxEffectiveTime())
                    end
                end
        end
        
    end, function(retval) end)

end

function Module.draw()
    imgui.push_id(Module.title)
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    if imgui.collapsing_header(language.get(languagePrefix .. "title")) then
        imgui.indent(10)

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

                imgui.begin_table(Module.title .. "1", 2, nil, nil, nil)
                imgui.table_next_row()
                imgui.table_next_column()

                changed, Module.data.blights_and_conditions.blights.fire = imgui.checkbox(language.get(languagePrefix .. "fire"), Module.data.blights_and_conditions.blights.fire)
                any_changed = any_changed or changed

                changed, Module.data.blights_and_conditions.blights.thunder = imgui.checkbox(language.get(languagePrefix .. "thunder"),
                    Module.data.blights_and_conditions.blights.thunder)
                any_changed = any_changed or changed

                changed, Module.data.blights_and_conditions.blights.water =
                    imgui.checkbox(language.get(languagePrefix .. "water"), Module.data.blights_and_conditions.blights.water)
                any_changed = any_changed or changed

                imgui.table_next_column()

                changed, Module.data.blights_and_conditions.blights.ice = imgui.checkbox(language.get(languagePrefix .. "ice"), Module.data.blights_and_conditions.blights.ice)
                any_changed = any_changed or changed

                changed, Module.data.blights_and_conditions.blights.dragon = imgui.checkbox(language.get(languagePrefix .. "dragon"),
                    Module.data.blights_and_conditions.blights.dragon)
                any_changed = any_changed or changed

                changed, Module.data.blights_and_conditions.blights.all = imgui.checkbox(language.get(languagePrefix .. "all"), Module.data.blights_and_conditions.blights.all)
                any_changed = any_changed or changed

                imgui.end_table()
                imgui.tree_pop()
            end

            languagePrefix = Module.title .. ".blights_and_conditions.conditions."
            if imgui.tree_node(language.get(languagePrefix .. "title")) then

                imgui.begin_table(Module.title .. "2", 2, nil, nil, nil)
                imgui.table_next_row()
                imgui.table_next_column()

                changed, Module.data.blights_and_conditions.conditions.poison = imgui.checkbox(language.get(languagePrefix .. "poison"),
                    Module.data.blights_and_conditions.conditions.poison)
                any_changed = any_changed or changed

                changed, Module.data.blights_and_conditions.conditions.stench = imgui.checkbox(language.get(languagePrefix .. "stench"),
                    Module.data.blights_and_conditions.conditions.stench)
                any_changed = any_changed or changed

                changed, Module.data.blights_and_conditions.conditions.blast = imgui.checkbox(language.get(languagePrefix .. "blast"),
                    Module.data.blights_and_conditions.conditions.blast)
                any_changed = any_changed or changed

                changed, Module.data.blights_and_conditions.conditions.bleed = imgui.checkbox(language.get(languagePrefix .. "bleed"),
                    Module.data.blights_and_conditions.conditions.bleed)
                any_changed = any_changed or changed

                changed, Module.data.blights_and_conditions.conditions.defense_down = imgui.checkbox(language.get(languagePrefix .. "defense_down"),
                    Module.data.blights_and_conditions.conditions.defense_down)
                any_changed = any_changed or changed

                changed, Module.data.blights_and_conditions.conditions.frenzy = imgui.checkbox(language.get(languagePrefix .. "frenzy"),
                    Module.data.blights_and_conditions.conditions.frenzy)
                any_changed = any_changed or changed

                changed, Module.data.blights_and_conditions.conditions.all = imgui.checkbox(language.get(languagePrefix.."all"), Module.data.blights_and_conditions.conditions.all)
                any_changed = any_changed or changed

                imgui.table_next_column()

                changed, Module.data.blights_and_conditions.conditions.stun = imgui.checkbox(language.get(languagePrefix .. "stun"),
                    Module.data.blights_and_conditions.conditions.stun)
                any_changed = any_changed or changed

                changed, Module.data.blights_and_conditions.conditions.paralyze = imgui.checkbox(language.get(languagePrefix .. "paralyze"),
                    Module.data.blights_and_conditions.conditions.paralyze)
                any_changed = any_changed or changed

                changed, Module.data.blights_and_conditions.conditions.sleep = imgui.checkbox(language.get(languagePrefix .. "sleep"),
                    Module.data.blights_and_conditions.conditions.sleep)
                any_changed = any_changed or changed

                changed, Module.data.blights_and_conditions.conditions.sticky = imgui.checkbox(language.get(languagePrefix .. "sticky"),
                    Module.data.blights_and_conditions.conditions.sticky)
                any_changed = any_changed or changed

                changed, Module.data.blights_and_conditions.conditions.frozen = imgui.checkbox(language.get(languagePrefix .. "frozen"),
                    Module.data.blights_and_conditions.conditions.frozen)
                any_changed = any_changed or changed

                changed, Module.data.blights_and_conditions.conditions.bubble = imgui.checkbox(language.get(languagePrefix.."bubble"), Module.data.blights_and_conditions.conditions.bubble)
                any_changed = any_changed or changed
                
                changed, Module.data.blights_and_conditions.conditions.all = imgui.checkbox(language.get(languagePrefix .. "all"), Module.data.blights_and_conditions.conditions.all)
                any_changed = any_changed or changed

                imgui.end_table()
                imgui.tree_pop()
            end
            imgui.tree_pop()
        end

        languagePrefix = Module.title .. ".item_buffs."
        if imgui.tree_node(language.get(languagePrefix .. "title")) then

            imgui.begin_table(Module.title .. "3", 2, nil, nil, nil)
            imgui.table_next_row()
            imgui.table_next_column()

            changed, Module.data.item_buffs.might_seed = imgui.checkbox(language.get(languagePrefix .. "might_seed"), Module.data.item_buffs.might_seed)
            any_changed = any_changed or changed
            
            changed, Module.data.item_buffs.might_pill = imgui.checkbox(language.get(languagePrefix .. "might_pill"), Module.data.item_buffs.might_pill)
            any_changed = any_changed or changed
            
            changed, Module.data.item_buffs.demon_drug = imgui.checkbox(language.get(languagePrefix .. "demon_drug"), Module.data.item_buffs.demon_drug)
            any_changed = any_changed or changed

            changed, Module.data.item_buffs.mega_demondrug = imgui.checkbox(language.get(languagePrefix .. "mega_demondrug"), Module.data.item_buffs.mega_demondrug)
            any_changed = any_changed or changed

            changed, Module.data.item_buffs.demon_powder = imgui.checkbox(language.get(languagePrefix .. "demon_powder"), Module.data.item_buffs.demon_powder)
            any_changed = any_changed or changed

            changed, Module.data.item_buffs.hot_drink = imgui.checkbox(language.get(languagePrefix .. "hot_drink"), Module.data.item_buffs.hot_drink)
            any_changed = any_changed or changed

            changed, Module.data.item_buffs.dash_juice = imgui.checkbox(language.get(languagePrefix .. "dash_juice"), Module.data.item_buffs.dash_juice)
            any_changed = any_changed or changed

            imgui.table_next_column()
            
            changed, Module.data.item_buffs.adamant_seed = imgui.checkbox(language.get(languagePrefix .. "adamant_seed"), Module.data.item_buffs.adamant_seed)
            any_changed = any_changed or changed

            changed, Module.data.item_buffs.adamant_pill = imgui.checkbox(language.get(languagePrefix .. "adamant_pill"), Module.data.item_buffs.adamant_pill)
            any_changed = any_changed or changed
            
            changed, Module.data.item_buffs.armor_skin = imgui.checkbox(language.get(languagePrefix .. "armor_skin"), Module.data.item_buffs.armor_skin)
            any_changed = any_changed or changed

            changed, Module.data.item_buffs.mega_armorskin = imgui.checkbox(language.get(languagePrefix .. "mega_armorskin"), Module.data.item_buffs.mega_armorskin)
            any_changed = any_changed or changed

            changed, Module.data.item_buffs.hardshell_powder = imgui.checkbox(language.get(languagePrefix .. "hardshell_powder"), Module.data.item_buffs.hardshell_powder)
            any_changed = any_changed or changed

            changed, Module.data.item_buffs.cool_drink = imgui.checkbox(language.get(languagePrefix .. "cool_drink"), Module.data.item_buffs.cool_drink)
            any_changed = any_changed or changed

            changed, Module.data.item_buffs.imunizer = imgui.checkbox(language.get(languagePrefix .. "imunizer"), Module.data.item_buffs.imunizer)
            any_changed = any_changed or changed

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

            changed, Module.data.stats.bonus_attack = imgui.slider_int(language.get(languagePrefix .. "bonus_attack"), Module.data.stats.bonus_attack, -1, 400, Module.data.stats.bonus_attack == -1 and language.get("base.disabled") or "%d")
            any_changed = any_changed or changed

            changed, Module.data.stats.bonus_defence = imgui.slider_int(language.get(languagePrefix .. "bonus_defence"), Module.data.stats.bonus_defence, -1, 1000, Module.data.stats.bonus_defence == -1 and language.get("base.disabled") or "%d")
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
            
        if any_changed then config.save_section(Module.create_config_section()) end

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
