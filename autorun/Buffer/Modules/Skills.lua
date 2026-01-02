local ModuleBase = require("Buffer.Misc.ModuleBase")
local Language = require("Buffer.Misc.Language")

local Module = ModuleBase:new("skills",
    {
        peak_performance = false,
        jin_dahaads_revolt = false,
        doshagumas_might = false,
        xu_wus_vigor = false,
        dark_blade = {
            enabled = false,
            no_cooldown = false
        },
        offensive_guard = false, -- KnightInfo - need to look into how offensive_guard works (has isNormalGuard:boolean, ISSpGuard:boolean, isOffensiveGuard:boolean, JustGuardTimer:single)
    }
)

function Module.create_hooks()

    -- Create stagger
    Module:init_stagger("hunter_skill_update", 10)
    sdk.hook(sdk.find_type_definition("app.HunterCharacter"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("app.HunterCharacter") then return end
        if not managed:get_IsMaster() then return end
        local hunter_skill = managed:get_HunterStatus():get_HunterSkill()
        local hunter_skill_param = hunter_skill:get_field("_HunterSkillParamInfo")

        if not Module:should_execute_staggered("hunter_skill_update") then return end

        -- Peak Performance
        -- Increase attack when health is full
        if Module.data.peak_performance then
            if not hunter_skill_param:get_IsActiveFullCharge() then
                hunter_skill:beginFullCharge() -- hunter_skill_param will crash game
            end
        end

        -- Jin Dahaad's Revolt
        -- Increases attack after recovering from webbed status, frostblight, being pinned, or a Power Clash.
        if Module.data.jin_dahaads_revolt then -- TODO: Will continue to reapply every frame
           if not hunter_skill_param:get_IsRebellionActive() then
               hunter_skill_param:beginSkillRebellion(300) -- 300 seconds / 5 minutes
           end
        end

        -- Doshaguma's Might
        -- Increases attack after a successful Power Clash or Offset attack
        if Module.data.doshagumas_might then
            if not hunter_skill_param:get_IsMusclemanActive() then
                hunter_skill_param:beginSkillMuscleman(300) -- 300 seconds / 5 minutes
            end
        end

        -- Xu Wu's Vigor
        -- Increases attack after eating items such as well-done steak.
        if Module.data.xu_wus_vigor then -- TODO: Will continue to reapply every frame
            if not hunter_skill_param:get_IsBarbarianActive() then
                hunter_skill_param:beginSkillBarbarian(300) -- 300 seconds / 5 minutes
            end
        end

        -- Dark Blade
        -- Performing Lv 2 or higher charged attacks increases attack but also deals self-damage.
        local dark_blade = hunter_skill_param:get_DarkBladeInfo()
        if Module.data.dark_blade.no_cooldown then
            if dark_blade:get_field("_CoolTime") > 15.0 then
                dark_blade:set_field("_CoolTime", 15.0)
            end
        end
        if Module.data.dark_blade.enabled and not hunter_skill_param:get_IsDarkBladeActive() then
            hunter_skill:beginSkillDarkBlade()
        end


    end, function(retval) end)

end

function Module.add_ui()
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."
    local row_width = imgui.calc_item_width()
    local max_width, col_width = 0, 0

    changed, Module.data.peak_performance = imgui.checkbox(Language.get(languagePrefix .. "peak_performance"), Module.data.peak_performance)
    any_changed = any_changed or changed

    changed, Module.data.jin_dahaads_revolt = imgui.checkbox(Language.get(languagePrefix .. "jin_dahaads_revolt"), Module.data.jin_dahaads_revolt)
    any_changed = any_changed or changed

    changed, Module.data.doshagumas_might = imgui.checkbox(Language.get(languagePrefix .. "doshagumas_might"), Module.data.doshagumas_might)
    any_changed = any_changed or changed

    changed, Module.data.xu_wus_vigor = imgui.checkbox(Language.get(languagePrefix .. "xu_wus_vigor"), Module.data.xu_wus_vigor)
    any_changed = any_changed or changed

    local DARK_BLADE_KEYS = {
        "dark_blade.enabled",
        "dark_blade.no_cooldown",
    }
    max_width = 0
    for _, key in ipairs(DARK_BLADE_KEYS) do
        local text = Language.get(languagePrefix .. key)
        max_width = math.max(max_width, imgui.calc_text_size(text).x)
    end
    col_width = math.max(max_width + 24 + 20, row_width / 2)

    imgui.begin_table(Module.title.."1", 3, 0)
    imgui.table_setup_column("1", 16 + 4096, col_width)
    imgui.table_setup_column("2", 16 + 4096, col_width)
    imgui.table_next_row()
    imgui.table_next_column()
    changed, Module.data.dark_blade.enabled = imgui.checkbox(Language.get(languagePrefix .. "dark_blade.enabled"), Module.data.dark_blade.enabled)
    any_changed = any_changed or changed
    imgui.table_next_column()
    changed, Module.data.dark_blade.no_cooldown = imgui.checkbox(Language.get(languagePrefix .. "dark_blade.no_cooldown"), Module.data.dark_blade.no_cooldown)
    any_changed = any_changed or changed
    imgui.end_table()


    

    return any_changed
end

return Module