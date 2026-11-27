local ModuleBase = require("Buffer.Misc.ModuleBase")
local Language = require("Buffer.Misc.Language")
local Utils = require("Buffer.Misc.Utils")

local Module = ModuleBase:new("skills",
    {
        protective_polish = false, -- Doesn't require skill
            -- Keeps the whetstone sharpness boost (no sharpness loss) active
        jin_dahaads_revolt = false, -- Requires skill, but forces it at all times
            -- Attack boost normally gained after recovering from webbed, frostblight, being pinned, or a Power Clash
        doshagumas_might = false, -- Requires skill, Need to re-test
            -- Attack boost normally gained after a successful Power Clash or Offset attack
        latent_power = false, -- Requires skill, but forces it at all times
            -- Increases affinity and reduces stamina depletion
        guardians_pulse = false, --  Requires skill
            -- Faster stamina and red health recovery, normally only near Wylkrystals
        offensive_guard = { -- Requires skill to actually get the boost
            enabled = false, -- Forces the attack boost to be active at all times
                -- Attack boost normally gained after a perfectly timed guard
            always_perfectly_timed = false -- Forces every guard to be considered perfectly timed
                -- Makes every guard count as perfectly timed
        },
        scale_layering = false, --  Requires skill, but forces it at all times
            -- Reduced stamina depletion, normally only at 40% health or lower
        buttery_leathercraft = false, --  Requires skill, but forces it at all times
            -- Affinity boost normally gained when sliding on terrain




        lords_fury = false, --  UNTESTED, probably requires skill
            -- Attack boost normally gained while inflicted with an ailment
        agitator = false, -- Requires skill, but forces it at all times
            -- Attack and affinity boost normally only while the monster is enraged
        counterstrike = false, -- Requires skill, but forces it at all times
            -- Attack boost normally gained after being knocked back
        coalescence = false, --  Requires skill, but forces it at all times
            -- Elemental boost normally gained after recovering from a condition
        uth_dans_cover = false, -- Requires skill, but forces it at all times
            -- Defense boost normally only while wearing a mantle
        maximum_might = false, -- Requires skill, but forces it at all times
            -- Affinity boost normally gained after keeping stamina full for a while
        ambush = false, --  Requires skill, but forces it at all times
            -- Attack boost normally gained after a sneak attack
        lords_favor = false, --  UNTESTED, probably requires skill
            -- Attack boost normally gained after using ranged support items or Melody Effects on allies
        adrenaline_rush = false, --  UNTESTED, probably requires skill
            -- Attack boost normally gained after a perfectly timed evade
        peak_performance = false, -- Requires skill
            -- Attack boost while health is full (re-activates whenever health is full)
        azure_bolt = { -- Requires skill
            enabled = false,
                -- Fills the Azure Bolt gauge for its affinity boost and extra thunder damage
            no_cooldown = false
                -- Removes the cooldown between Azure Bolt activations
        },
        seregios_tenacity = false, -- Blade Sharp_Dodge
            -- Extends Adrenaline Rush and, at level 2, further increases attack
        synthetic_shield = false, -- Doesn't require skill
            -- Defense boost from the shield effect, with a long duration
        darkside = { -- Requires skill
            enabled = false,
                -- Keeps the Darkside attack boost from charged attacks active
            no_cooldown = false
                -- Removes the Darkside cooldown
        },
        burst = { -- Requires skill
            enabled = false,
                -- Starts Burst at full hit count for its attack boost
            infinite_interval = false,
                -- Keeps the window between hits from expiring while building up Burst
            infinite_timer = false,
                -- Keeps Burst from expiring once at full hit count
        },
        luck = false, -- Doesn't require skill,
            -- Increases quest rewards
        blackest_night_no_cooldown = false,
            -- Removes the cooldown on the Blackest Night barrier item emote
        critical_draw = false, --  Untested, probably requires skill
            -- Affinity boost for draw attacks
        punishing_draw = false, --  Untested, probably requires skill
            -- Draw attacks deal extra damage and stun
        convert_element_no_cooldown = false, --  Untested, probably requires skill
            -- Removes the Convert Element cooldown (still triggers normally)
        capture_master = false, --  Untested
            -- Increases capture rewards
        carving_master = false, --  Untested
            -- Increases carving rewards
        bubble_whetstone = false, --  Untested, probably requires skill (Mizutsune)
            -- Activates the bubble state from the Mizutsune skill
    }
)

function Module.create_hooks()

    Module:init_stagger("hunter_skill_update", 10)
    sdk.hook(sdk.find_type_definition("app.HunterCharacter"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("app.HunterCharacter") then return end
        if not managed:get_IsMaster() then return end
        local hunter_status = managed:get_HunterStatus()
        if hunter_status:get_IsNpc() then return end -- get_IsMaster returns true for NPC hunters too
        local hunter_skills = hunter_status:get_HunterSkill()
        local hunter_skill_params = hunter_skills:get_field("_HunterSkillParamInfo")

        -- Offensive Guard - Always Perfectly Timed (runs every frame, not staggered)
        -- JustGuardTimer starts at 0.35 when guarding and counts down; blocking while it's above 0 counts as perfectly timed.
        -- Keeping it at 0.35 makes every block count as perfectly timed.
        if Module.data.offensive_guard.always_perfectly_timed then
            local knight_info = hunter_skill_params:get_KnightInfo()
            if knight_info and knight_info:get_field("<JustGuardTimer>k__BackingField") < 0.35 then
                knight_info:set_field("<JustGuardTimer>k__BackingField", 0.35)
            end
        end

        if not Module:should_execute_staggered("hunter_skill_update") then return end

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
        -- Offensive Guard - Always Perfectly Timed is handled above, before the stagger check

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
            if not hunter_skill_params:get_IsBladeSharp_DodgeTime() then
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
            if not hunter_skill_params:get_IsDarkBladeActive() then
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

        -- Critical Draw (BattoWaza)
        -- Increases affinity for draw attacks
        if Module.data.critical_draw then
            if not hunter_skill_params:get_IsBattoWazaActive() then
                hunter_skill_params:beginBattoWaza(300.0)
            end
        end

        -- Punishing Draw (BattoPower)
        -- Draw attacks deal extra damage and stun
        if Module.data.punishing_draw then
            if not hunter_skill_params:get_IsCanBattoPower() then
                hunter_skill_params:setBattoPowerFlag(true)
            end
        end

        -- Convert Element - No Cooldown
        -- Element conversion still triggers normally, this just removes the cooldown
        if Module.data.convert_element_no_cooldown then
            local element_convert_info = hunter_skill_params:get_field("_ElementConvertInfo")
            if element_convert_info and element_convert_info:get_field("_CoolTime") > 0.0 then
                element_convert_info:set_field("_CoolTime", 0.0)
            end
        end

        -- Capture Master
        -- Increases capture rewards
        if Module.data.capture_master then
            if not hunter_skill_params:get_IsCaptureMasterActive() then
                hunter_skill_params:setCaptureMasterActive(true)
            end
        end

        -- Carving Master
        -- Increases carving rewards
        if Module.data.carving_master then
            if not hunter_skill_params:get_IsHagitoriMasterActive() then
                hunter_skill_params:setHagitoriMasterActive(true)
            end
        end

        -- Bubble Whetstone (BubbleToishi)
        -- Activates the bubble state from the Mizutsune skill (0 = WATER, 1 = BUBBLE)
        if Module.data.bubble_whetstone then
            if not hunter_skill_params:get_IsBubbleToishiActive_Bubble() then
                hunter_skill_params:beginBabbleToishi(1) -- Spelling mistake in game's code
            end
        end

    end, function(retval) end)

end

-- Skills that work without having the skill equipped, these get a (?) tooltip saying so
local NO_SKILL_REQUIRED = {
    protective_polish = true,
    synthetic_shield = true,
    luck = true,
}

-- Single toggle skills, shown in a two column grid
local SIMPLE_SKILLS = {
    "protective_polish",
    "jin_dahaads_revolt",
    "doshagumas_might",
    "latent_power",
    "guardians_pulse",
    "scale_layering",
    "buttery_leathercraft",
    "lords_fury",
    "agitator",
    "counterstrike",
    "coalescence",
    "uth_dans_cover",
    "maximum_might",
    "ambush",
    "lords_favor",
    "adrenaline_rush",
    "peak_performance",
    "seregios_tenacity",
    "synthetic_shield",
    "luck",
    "blackest_night_no_cooldown",
    "critical_draw",
    "punishing_draw",
    "convert_element_no_cooldown",
    "capture_master",
    "carving_master",
    "bubble_whetstone",
}

-- Skills with extra options, each shown on its own row with the options lined up in columns
local OPTION_SKILLS = {
    { key = "offensive_guard", options = { "enabled", "always_perfectly_timed" } },
    { key = "azure_bolt", options = { "enabled", "no_cooldown" } },
    { key = "darkside", options = { "enabled", "no_cooldown" } },
    { key = "burst", options = { "enabled", "infinite_interval", "infinite_timer" } },
}

function Module.add_ui()
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    Utils.tooltip(Language.get(languagePrefix .. "tooltip"))

    local function skill_checkbox(label_key, data_table, field, no_skill_required)
        changed, data_table[field] = imgui.checkbox(Language.get(languagePrefix .. label_key), data_table[field])
        any_changed = any_changed or changed
        if no_skill_required then
            Utils.tooltip(Language.get(languagePrefix .. "no_skill_required"))
        end
    end

    -- Single toggle skills
    imgui.begin_table(Module.title .. "_simple", 2, 0)
    for _, key in ipairs(SIMPLE_SKILLS) do
        imgui.table_next_column()
        skill_checkbox(key, Module.data, key, NO_SKILL_REQUIRED[key])
    end
    imgui.end_table()

    imgui.spacing()
    imgui.separator()
    imgui.spacing()

    -- Skills with options, size the first two columns to their widest label so everything lines up
    local column_widths = { 0, 0 }
    for _, skill in ipairs(OPTION_SKILLS) do
        for i = 1, 2 do
            local width = imgui.calc_text_size(Language.get(languagePrefix .. skill.key .. "." .. skill.options[i])).x + 24 + 10 -- Text length + Checkbox sizing + padding
            if width > column_widths[i] then column_widths[i] = width end
        end
    end

    imgui.begin_table(Module.title .. "_options", 3, 0)
    imgui.table_setup_column("1", 16 + 4096, column_widths[1])
    imgui.table_setup_column("2", 16 + 4096, column_widths[2])
    for _, skill in ipairs(OPTION_SKILLS) do
        imgui.push_id(skill.key) -- Options like "No Cooldown" share labels, so keep their IDs unique
        for i = 1, 3 do
            imgui.table_next_column()
            local option = skill.options[i]
            if option then
                skill_checkbox(skill.key .. "." .. option, Module.data[skill.key], option, false)
            end
        end
        imgui.pop_id()
    end
    imgui.end_table()

    return any_changed
end

return Module