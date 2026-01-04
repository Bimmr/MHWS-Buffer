local Utils = {}

local chatManager
local player_manager
local game_input_manager

-- ================== Player Utils ==================

--- Check if the player is in battle
--- @return boolean True if in battle
function Utils.is_in_battle()
    local character = Utils.get_master_character()
    if not character then return false end
    return character:get_IsCombat()
end

--- Get the Master Player Info
--- @return userdata The master player info or nil if not found
function Utils.get_master_player_info()
    if not player_manager then
        player_manager = sdk.get_managed_singleton("app.PlayerManager")
    end
    if not player_manager then return nil end
    local player = player_manager:getMasterPlayerInfo()
    return player
end

--- Get the Master Character
--- @return userdata The master character or nil if not found
function Utils.get_master_character()
    local player = Utils.get_master_player_info()
    if not player then return nil end
    local character = player:get_Character()
    return character
end

--- Send a message to the in-game chat
--- @param text string The text to send
function Utils.send_message(text)
    if not chatManager then
        chatManager = sdk.get_managed_singleton("app.ChatManager")
    end
    if not chatManager then return end
    chatManager:addSystemLog(text)
end

--- Check if hunter has specific skill
--- @param character userdata The hunter character. If nil, will get master character
--- @param skill_index number The skill index to check
--- @return boolean True if skill is active
function Utils.has_skill(character, skill_index)
    if not character then character = Utils.get_master_character() end
    if not character then return false end
    
    local hunter_skill = character:get_HunterSkill()
    if not hunter_skill then return false end
    
    local next_skill_info = hunter_skill:get_field("_NextSkillInfo")
    if not next_skill_info then return false end
    
    local skills = next_skill_info:get_field("_items")
    if not skills then return false end
    
    for i = 0, skills:get_Length() - 1 do
        local skill = skills:get_Item(i)
        if skill and skill:get_SkillData():get_Index() == skill_index then
            return true
        end
    end
    
    return false
end

--- Get the Game Input Manager and Player Input
--- @return userdata|nil game_input_manager The game input manager
--- @return userdata|nil player_input The player input
function Utils.get_player_input()
    if not game_input_manager then
        game_input_manager = sdk.get_managed_singleton('app.GameInputManager')
    end
    if not game_input_manager then return nil, nil end
    
    local player_input = game_input_manager:get_PlayerInput()
    return game_input_manager, player_input
end

-- ================== General Utils ==================

--- Get the length of a table or array-like object
--- @param obj table The table or array-like object
--- @return integer The length of the table
function Utils.get_length(obj)
    local count = 0

    -- Count the items in the table
    for _ in pairs(obj) do count = count + 1 end
    return count
end

--- Split a string into an array based on a delimiter
--- @param text string The string to split
--- @param delim string The delimiter (one character only). Defaults to whitespace if nil
--- @return table An array of split strings
function Utils.split(text, delim)
    local result = {}
    local magic = "().%+-*?[]^$"

    if delim == nil then
        delim = "%s"
    elseif string.find(delim, magic, 1, true) then
        delim = "%" .. delim
    end

    local pattern = "[^" .. delim .. "]+"
    for w in string.gmatch(text, pattern) do table.insert(result, w) end
    return result
end

--- Generate an enum table from a type definition
--- @param typename string The type definition name (e.g., "app.WeaponType")
--- @return table A table mapping enum names to their values
function Utils.generate_enum(typename)
    local t = sdk.find_type_definition(typename)
    if not t then return {} end
    local fields = t:get_fields()
    local enum = {}
    for i, field in ipairs(fields) do
        if field:is_static() then
            local name = field:get_name()
            local raw_value = field:get_data(nil)
            enum[name] = raw_value
        end
    end
    return enum
end

--- Merge two tables, with values from newTable overwriting those in baseTable
--- @param baseTable table The base table to merge into
--- @param newTable table The new table to merge from
function Utils.merge_tables(baseTable, newTable)
    for k, v in pairs(newTable) do
        if type(v) == "table" and type(baseTable[k]) == "table" then
            Utils.merge_tables(baseTable[k], v)
        else
            baseTable[k] = v
        end
    end
end

--- Update a table with another table, only updating the values that exist in the base table
--- @param baseTable table The base table to update
--- @param newTable table The new table to update from
function Utils.update_table_with_existing_table(baseTable, newTable)
    for key, value in pairs(baseTable) do
        if type(value) == "table" and type(newTable[key]) == "table" then
            Utils.update_table_with_existing_table(value, newTable[key])
        elseif newTable[key] ~= nil then
            baseTable[key] = newTable[key]
        end
    end
end

-- ================== ImGui Utils ==================

--- Display a tooltip next to the last item
--- @param text string The tooltip text
function Utils.tooltip(text)
    imgui.same_line()
    imgui.text("(?)")
    if imgui.is_item_hovered() then imgui.set_tooltip("  "..text.."  ") end
end

return Utils