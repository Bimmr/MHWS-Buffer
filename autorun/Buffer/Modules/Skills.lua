local ModuleBase = require("Buffer.Misc.ModuleBase")
local Language = require("Buffer.Misc.Language")
local Utils = require("Buffer.Misc.Utils")

local Module = ModuleBase:new("skills",
    {
        protective_polish = false, -- Doesn't require skill
        jin_dahaads_revolt = false, -- Requires skill
        doshagumas_might = false, -- Requires skill
        xu_wus_vigor = false, --  Requires skill
        latent_power = false, --  Requires skill
        guardians_pulse = false, --  Requires skill
        offensive_guard = { -- Requires skill
            enabled = false,
            always_perfectly_timed = false
        },
        scale_layering = false, --  Requires skill
        buttery_leathercraft = false, --  Requires skill
        lords_fury = false, --  Untested, probably requires skill
        agitator = false, -- Requires skill
        counterstrike = false, -- Requires skill
        coalescence = false, --  Untested, probably requires skill
        uth_dans_cover = false, -- Requires skill
        maximum_might = false, -- Requires skill
        ambush = false, --  Untested, probably requires skill
        lords_favor = false, --  Untested, probably requires skill
        adrenaline_rush = false, --  Untested, probably requires skill
        peak_performance = false, -- Requires skill
        azure_bolt = { -- Requires skill
            enabled = false,
            no_cooldown = false
        },
        seregios_tenacity = false, -- Blade Sharp_Dodge
        synthetic_shield = false, -- Doesn't require skill
        darkside = { -- Requires skill
            enabled = false,
            no_cooldown = false
        },
        burst = { -- Requires skill
            enabled = false,
            infinite_interval = false,
            infinite_timer = false,
        },
        luck = false, -- Doesn't require skill,
        blackest_night_no_cooldown = false,
    }
)

function Module.create_hooks()

    Module:init_stagger("hunter_skill_update", 10)
    sdk.hook(sdk.find_type_definition("app.HunterCharacter"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("app.HunterCharacter") then return end
        if not managed:get_IsMaster() then return end

        if not Module:should_execute_staggered("hunter_skill_update") then return end

        local hunter_status = managed:get_HunterStatus()
        local hunter_skills = hunter_status:get_HunterSkill()

        local hunter_skill_params = hunter_skills:get_field("_HunterSkillParamInfo")

        if Module.data.protective_polish then
            if not hunter_skill_params:get_IsToishiBoostActive() then
                hunter_skill_params:beginSkillToishiBoost(300.0)
            end
        end

        -- Jin Dahaad's Revolt
        -- Increases attack after recovering from webbed status, frostblight, being pinned, or a Power Clash.
        if Module.data.jin_dahaads_revolt then
           if not hunter_skill_params:get_IsRebellionActive() then
               hunter_skill_params:beginSkillRebellion(300.0)
           end
        end

        -- Doshaguma's Might
        -- Increases attack after a successful Power Clash or Offset attack
        if Module.data.doshagumas_might then
            if not hunter_skill_params:get_IsMusclemanActive() then
                hunter_skill_params:beginSkillMuscleman(300.0)
            end
        end

        -- Xu Wu's Vigor
        -- Increases attack after eating items such as well-done steak.
        if Module.data.xu_wus_vigor then
            if not hunter_skill_params:get_IsBarbarianActive() then
                hunter_skill_params:beginSkillBarbarian(300.0)
            end
        end

        -- Latent Power
        -- Increases affinity and reduces stamina depletion
        if Module.data.latent_power then
            if not hunter_skill_params:get_IsPowerAwakeActive() then
                hunter_skill_params:beginPowerAwake(300.0)
            end
        end

        -- Guardian's Pulse
        -- Increases recovery speed of stamina and red gauge when near Wylkrystals
        if Module.data.guardians_pulse then
            if not hunter_skill_params:get_IsRyunyuActive() then
                hunter_skill_params:beginRyunyu(300.0)
            end
        end

        -- Offensive Guard
        -- Increases attack after a perfectly timed guard
        if Module.data.offensive_guard.enabled then
            if not hunter_skill_params:get_IsKnightActive() then 
                hunter_skill_params:beginKnight(true) -- Not sure what true/false does
            end
        end
        -- Offensive Guard - Always Perfectly Timed
        if Module.data.offensive_guard.always_perfectly_timed then
            local knight_info = hunter_skill_params:get_KnightInfo()
            knight_info:set_field("<IsNormalGuard>k__BackingField", false)
            knight_info:set_field("<IsSpGuard>k__BackingField", true)
            knight_info:set_field("<JustGuardTimer>k__BackingField", 0.35)
        end

        -- Scale Layering (Adrenaline)
        -- Reduces stamina depletion when health is at 40% or lower.
        if Module.data.scale_layering then
            if not hunter_skill_params:get_IsHunkiActive() then
                hunter_skill_params:beginHunki(300.0)
            end
        end

        -- Buttery Leathercraft
        -- Increases your affinity temporarily when sliding on terrain
        if Module.data.buttery_leathercraft then
            if not hunter_skill_params:get_IsSlidingPowerUpActive() then
                hunter_skill_params:beginSlidingPowerUp(300.0)
            end
        end

        -- Lord's Fury
        -- Increases attack when inflicted with ailments
        if Module.data.lords_fury then
            if not hunter_skill_params:get_IsActiveKatsu() then
                hunter_skill_params:beginKatsu() -- Lasts until a status ailment is removed
            end
        end

        -- Agitator
        -- Increases attack and affinity when monsters become enraged
        if Module.data.agitator then
            if not hunter_skill_params:get_IsActiveChallenger() then
                hunter_skill_params:set_field("_ChallengerLagTimer", 300.0)
                hunter_skill_params:beginChallenger()
                hunter_skill_params:set_field("_ChallengerLagTimer", 300.0)
            end
        end

        -- Counterstrike
        -- Temporarily increases attack power after being knocked back
        if Module.data.counterstrike then
            if not hunter_skill_params:get_IsActiveCounterAttack() then
                hunter_skill_params:beginCounterAttack(300.0)
            end
        end

        -- Coalescence
        -- Increases elemental values after recovering from conditions
        if Module.data.coalescence then
            if not hunter_skill_params:get_IsActiveDisaster() then
                hunter_skill_params:beginDisaster(300.0)
            end
        end


        -- Uth Dan's Cover
        -- Increases defence when using a mantle
        if Module.data.uth_dans_cover then
            if not hunter_skill_params:get_IsMantleStrengtheningActive() then
                hunter_skill_params:beginMantleStrengthening(300.0)
            end
        end

        -- Maximum Might
        -- Increases affinity if stamina is kept full for some time
        if Module.data.maximum_might then
            if not hunter_skill_params:get_IsActiveKonshin() then
                hunter_skill_params:beginKonshin()
            end
            if hunter_skill_params:get_field("_KonshinStaminaUseTime") > 1.0 then -- Resets the timer tracking how long stamina has been used
                hunter_skill_params:set_field("_KonshinStaminaUseTime", 0.0)
            end
        end

        -- Ambush
        -- Increases attack when striking monsters after a sneak attack
        if Module.data.ambush then
            local behind_attack = hunter_skill_params:get_field("_BegindAttackInfo") -- Spelling mistake in game's code
            if not behind_attack:get_IsActive() then
                hunter_skill_params:beginBehindAttack(300.0)
            end
        end

        -- Lord's Favor / Inspiration
        -- Increases attack power when using range support items (healing/dust)or Melody Effects that affect hunters/companions in range
        if Module.data.lords_favor then
            if not hunter_skill_params:get_IsYellActive() then
                hunter_skill_params:beginYell(300.0)
            end
        end

        -- Adrenaline Rush
        -- Increases attack after a perfectly-timed evade
        if Module.data.adrenaline_rush then
            if not hunter_skill_params:get_IsTechnicalAttackActive() then
                hunter_skill_params:beginTechnicalAttack(300.0)
            end
        end

        -- Peak Performance
        -- Increase attack when health is full
        if Module.data.peak_performance then
            local health_manager = hunter_status:get_Health():get_HealthMgr()
            if health_manager:get_Health() == health_manager:get_MaxHealth() and not hunter_skill_params:get_IsFullChargeActive() then
                hunter_skill_params:beginFullCharge()
            end
        end

        -- Azure Bolt
        -- Increases affinity and deal extra thunder damage
        local azure_bolt_info = nil
        if Module.data.azure_bolt.enabled or Module.data.azure_bolt.no_cooldown then
            azure_bolt_info = hunter_skill_params:get_field("_DischargeInfo")
        end
        -- Azure Bolt Enabled
        if Module.data.azure_bolt.enabled then
            if not hunter_skill_params:get_IsDischargActive() then -- Spelling mistake in game's code
                azure_bolt_info:set_field("_DischargeValue", 100.0)
            end
        end
        -- Azure Bolt No Cooldown
        if Module.data.azure_bolt.no_cooldown then
            if azure_bolt_info:get_field("_CoolTime") > 0.0 then
                azure_bolt_info:set_field("_CoolTime", 0.0)
            end
        end

        -- Seregios Tenacity
        -- Level 1 - Extends Adrenaline Rush duration. 
        -- Level 2 - Further increases attack
        if Module.data.seregios_tenacity then
            if not hunter_skill_params:get_IsTechnicalAttackActive() then
                hunter_skill_params:beginSkillBladeSharp_Dodge(300.0)
            end
        end

        -- Synthetic Shield
        -- Increases Defence by 30 and might also add to near by teammates (TODO: Needs testing)
        if Module.data.synthetic_shield then
            local synthetic_shield = hunter_skill_params:get_ShieldOptionInfo()
            if not synthetic_shield:get_IsActive() then
                hunter_skill_params:beginShieldOptionToPl() -- Plays the effect
                synthetic_shield:set_field("_Timer", 300.0) -- Set timer to longer duration
            end
        end

        -- Dark Blade
        -- Performing Lv 2 or higher charged attacks increases attack but also deals self-damage.
        if Module.data.darkside.enabled then
            local dark_blade = hunter_skill_params:get_DarkBladeInfo()
            if dark_blade:get_field("_CoolTime") > 0.0 and Module.data.darkside.no_cooldown then
                dark_blade:set_field("_CoolTime", 0.0)
            end
            if Module.data.darkside.enabled then
                hunter_skill_params:beginSkillDarkBlade(0, 300.0)
            end
        end

        -- Luck
        -- Increases quest rewards
        if Module.data.luck then
            if not hunter_skill_params:get_IsLuckActive() then
                hunter_skill_params:setLuckActive(true)
            end
        end

        -- Burst
        -- Multiple hits within a time window increases attack
        local burst_info = nil
        if Module.data.burst.enabled or Module.data.burst.infinite_interval or Module.data.burst.infinite_timer then
            burst_info = hunter_skill_params:get_field("_ContinuousAttackInfo")
        end
        -- Burst Enabled
        if Module.data.burst.enabled then
            if not hunter_skill_params:get_IsContinuousAttackActive() then
                burst_info:set_field("_HitCount", 5)
            end
        end
        -- Burst Infinite Interval
        if Module.data.burst.infinite_interval then
            if burst_info:get_field("_HitCount") > 0 and burst_info:get_field("_HitCount") < 5 and hunter_skill_params:get_IsCanContinuousAttackActive() then
                if burst_info:get_field("_Timer") < 15.0 then
                    burst_info:set_field("_Timer", 30.0)
                end
            end
        end
        -- Burst Infinite Timer
         if Module.data.burst.infinite_timer then
            if burst_info:get_field("_HitCount") == 5 and hunter_skill_params:get_IsContinuousAttackActive() then
                if burst_info:get_field("_Timer") < 30.0 then
                    burst_info:set_field("_Timer", 60.0)
                end
            end
        end

        -- Blackest Night No Cooldown
        if Module.data.blackest_night_no_cooldown then
            local exemote03 = managed:get_ExEmote03()
            if exemote03:get_field("<BarrierItemCDTimer>k__BackingField") > 0.0 then
                exemote03:set_field("<BarrierItemCDTimer>k__BackingField", 0.0)
            end
        end

    end, function(retval) end)

end

function Module.add_ui()
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    Utils.tooltip(Language.get(languagePrefix .. "tooltip"))

    changed, Module.data.protective_polish = imgui.checkbox(Language.get(languagePrefix .. "protective_polish"), Module.data.protective_polish)
    any_changed = any_changed or changed

    changed, Module.data.jin_dahaads_revolt = imgui.checkbox(Language.get(languagePrefix .. "jin_dahaads_revolt"), Module.data.jin_dahaads_revolt)
    any_changed = any_changed or changed

    changed, Module.data.doshagumas_might = imgui.checkbox(Language.get(languagePrefix .. "doshagumas_might"), Module.data.doshagumas_might)
    any_changed = any_changed or changed

    changed, Module.data.xu_wus_vigor = imgui.checkbox(Language.get(languagePrefix .. "xu_wus_vigor"), Module.data.xu_wus_vigor)
    any_changed = any_changed or changed

    changed, Module.data.latent_power = imgui.checkbox(Language.get(languagePrefix .. "latent_power"), Module.data.latent_power)
    any_changed = any_changed or changed

    changed, Module.data.guardians_pulse = imgui.checkbox(Language.get(languagePrefix .. "guardians_pulse"), Module.data.guardians_pulse)
    any_changed = any_changed or changed

    imgui.begin_table(Module.title .. "offensive_guard", 2, 0)
    local offensive_guard_text_size = imgui.calc_text_size(Language.get(languagePrefix .. "offensive_guard.enabled")).x
    local column_1_width = offensive_guard_text_size + 24 + 10  -- Text length + Checkbox sizing + padding
    imgui.table_setup_column("1", 16 + 4096, column_1_width)
    imgui.table_next_column()
    
    changed, Module.data.offensive_guard.enabled = imgui.checkbox(Language.get(languagePrefix .. "offensive_guard.enabled"), Module.data.offensive_guard.enabled)
    any_changed = any_changed or changed

    imgui.table_next_column()

    changed, Module.data.offensive_guard.always_perfectly_timed = imgui.checkbox(Language.get(languagePrefix .. "offensive_guard.always_perfectly_timed"), Module.data.offensive_guard.always_perfectly_timed)
    any_changed = any_changed or changed

    imgui.end_table()

    changed, Module.data.scale_layering = imgui.checkbox(Language.get(languagePrefix .. "scale_layering"), Module.data.scale_layering)
    any_changed = any_changed or changed

    changed, Module.data.buttery_leathercraft = imgui.checkbox(Language.get(languagePrefix .. "buttery_leathercraft"), Module.data.buttery_leathercraft)
    any_changed = any_changed or changed

    changed, Module.data.lords_fury = imgui.checkbox(Language.get(languagePrefix .. "lords_fury"), Module.data.lords_fury)
    any_changed = any_changed or changed

    changed, Module.data.agitator = imgui.checkbox(Language.get(languagePrefix .. "agitator"), Module.data.agitator)
    any_changed = any_changed or changed

    changed, Module.data.counterstrike = imgui.checkbox(Language.get(languagePrefix .. "counterstrike"), Module.data.counterstrike)
    any_changed = any_changed or changed

    changed, Module.data.coalescence = imgui.checkbox(Language.get(languagePrefix .. "coalescence"), Module.data.coalescence)
    any_changed = any_changed or changed

    changed, Module.data.uth_dans_cover = imgui.checkbox(Language.get(languagePrefix .. "uth_dans_cover"), Module.data.uth_dans_cover)
    any_changed = any_changed or changed

    changed, Module.data.maximum_might = imgui.checkbox(Language.get(languagePrefix .. "maximum_might"), Module.data.maximum_might)
    any_changed = any_changed or changed

    changed, Module.data.ambush = imgui.checkbox(Language.get(languagePrefix .. "ambush"), Module.data.ambush)
    any_changed = any_changed or changed

    changed, Module.data.lords_favor = imgui.checkbox(Language.get(languagePrefix .. "lords_favor"), Module.data.lords_favor)
    any_changed = any_changed or changed

    changed, Module.data.adrenaline_rush = imgui.checkbox(Language.get(languagePrefix .. "adrenaline_rush"), Module.data.adrenaline_rush)
    any_changed = any_changed or changed
    
    changed, Module.data.peak_performance = imgui.checkbox(Language.get(languagePrefix .. "peak_performance"), Module.data.peak_performance)
    any_changed = any_changed or changed

    imgui.begin_table(Module.title .. "azure_bolt", 2, 0)
    local azure_bolt_text_size = imgui.calc_text_size(Language.get(languagePrefix .. "azure_bolt.enabled")).x
    local column_1_width = azure_bolt_text_size + 24 + 10  -- Text length + Checkbox sizing + padding
    imgui.table_setup_column("1", 16 + 4096, column_1_width)
    imgui.table_next_column()

    changed, Module.data.azure_bolt.enabled = imgui.checkbox(Language.get(languagePrefix .. "azure_bolt.enabled"), Module.data.azure_bolt.enabled)
    any_changed = any_changed or changed

    imgui.table_next_column()

    changed, Module.data.azure_bolt.no_cooldown = imgui.checkbox(Language.get(languagePrefix .. "azure_bolt.no_cooldown"), Module.data.azure_bolt.no_cooldown)
    any_changed = any_changed or changed

    imgui.end_table()

    changed, Module.data.seregios_tenacity = imgui.checkbox(Language.get(languagePrefix .. "seregios_tenacity"), Module.data.seregios_tenacity)
    any_changed = any_changed or changed

    changed, Module.data.synthetic_shield = imgui.checkbox(Language.get(languagePrefix .. "synthetic_shield"), Module.data.synthetic_shield)
    any_changed = any_changed or changed

    imgui.begin_table(Module.title .. "darkside", 2, 0)
    local fast_charge_text_size = imgui.calc_text_size(Language.get(languagePrefix .. "darkside.enabled")).x

    local column_1_width = fast_charge_text_size + 24 + 10  -- Text length + Checkbox sizing + padding
    imgui.table_setup_column("1", 16 + 4096, column_1_width)
    imgui.table_next_column()

    changed, Module.data.darkside.enabled = imgui.checkbox(Language.get(languagePrefix .. "darkside.enabled"), Module.data.darkside.enabled)
    any_changed = any_changed or changed
    
    imgui.table_next_column()

    changed, Module.data.darkside.no_cooldown = imgui.checkbox(Language.get(languagePrefix .. "darkside.no_cooldown"), Module.data.darkside.no_cooldown)
    any_changed = any_changed or changed

    imgui.end_table()



    changed, Module.data.luck = imgui.checkbox(Language.get(languagePrefix .. "luck"), Module.data.luck)
    any_changed = any_changed or changed

    imgui.begin_table(Module.title .. "burst", 3, 0)
    local burst_enabled_text_size = imgui.calc_text_size(Language.get(languagePrefix .. "burst.enabled")).x
    local column_1_width = burst_enabled_text_size + 24 + 10
    imgui.table_setup_column("1", 16 + 4096, column_1_width)
    local burst_infinite_interval_text_size = imgui.calc_text_size(Language.get(languagePrefix .. "burst.infinite_interval")).x
    local column_2_width = burst_infinite_interval_text_size + 24 + 10
    imgui.table_setup_column("2", 16 + 4096, column_2_width)
    imgui.table_next_column()

    changed, Module.data.burst.enabled = imgui.checkbox(Language.get(languagePrefix .. "burst.enabled"), Module.data.burst.enabled)
    any_changed = any_changed or changed

    imgui.table_next_column()

    changed, Module.data.burst.infinite_interval = imgui.checkbox(Language.get(languagePrefix .. "burst.infinite_interval"), Module.data.burst.infinite_interval)
    any_changed = any_changed or changed

    imgui.table_next_column()

    changed, Module.data.burst.infinite_timer = imgui.checkbox(Language.get(languagePrefix .. "burst.infinite_timer"), Module.data.burst.infinite_timer)
    any_changed = any_changed or changed

    imgui.end_table()

    changed, Module.data.blackest_night_no_cooldown = imgui.checkbox(Language.get(languagePrefix .. "blackest_night_no_cooldown"), Module.data.blackest_night_no_cooldown)
    any_changed = any_changed or changed


    return any_changed
end

return Module