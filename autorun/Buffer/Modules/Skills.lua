local ModuleBase = require("Buffer.Misc.ModuleBase")
local language = require("Buffer.Misc.Language")
local utils = require("Buffer.Misc.Utils")

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

    sdk.hook(sdk.find_type_definition("app.HunterCharacter"):get_method("update"), function(args)
        local managed = sdk.to_managed_object(args[2])
        if not managed:get_type_definition():is_a("app.HunterCharacter") then return end
        if not managed:get_IsMaster() then return end
        local hunter_skills = managed:get_HunterStatus():get_HunterSkills()
        local hunter_skill_params = hunter_skills:get_field("_HunterSkillParamInfo")

        if Module.data.peak_performance then
            if not hunter_skill_params:get_isActiveFullCharge() then
                hunter_skill_params:beginFullCharge()
            end
        end
        if Module.data.jin_dahaads_revolt then
           if not hunter_skill_params:get_IsRebellionActive() then
               hunter_skill_params:beginSkillRebellion(300) -- 300 seconds / 5 minutes
           end
        end
        if Module.data.doshagumas_might then
            if not hunter_skill_params:get_IsMusclemanActive() then
                hunter_skill_params:beginSkillMuscleman(300) -- 300 seconds / 5 minutes
            end
        end
        if Module.data.xu_wus_vigor then
            if not hunter_skill_params:get_IsBarbarianActive() then
                hunter_skill_params:beginSkillBarbarian(300) -- 300 seconds / 5 minutes
            end
        end
        if Module.data.dark_blade.enabled then
            local dark_blade = hunter_skill_params:get_DarkBladeInfo()
            if dark_blade:get_field("_CoolTime") then
                dark_blade:set_field("_CoolTime", 0.0)
            end
            if Module.data.dark_blade.enabled then
                hunter_skill_params:beginSkillDarkBlade(0, 300) -- 300 seconds / 5 minutes
            end
        end


    end, function(retval) end)

end

function Module.add_ui()
    local changed, any_changed = false, false
    local languagePrefix = Module.title .. "."

    

    return any_changed
end

return Module