local icons = require("Buffer.Misc.Icons")
local utils = require("Buffer.Misc.Utils")
local config = require("Buffer.Misc.Config")
local language = require("Buffer.Misc.Language")


--- ModuleBase
--- Base class for all Buffer modules providing common functionality
--- @class ModuleBase
local ModuleBase = {}
ModuleBase.__index = ModuleBase

--- Create a new module instance
--- @param title string The module identifier (used for language keys and config)
--- @param data table The module's data structure
--- @return table The new module instance
function ModuleBase:new(title, data, old)
    local module = {
        title = title,
        data = data or {},
        old = old or {},
    }
    
    setmetatable(module, self)

    return module
end

--- Initialize the module - load config and create hooks
--- Can be overridden in child modules for custom initialization.
--- If overriding, must call ModuleBase.init(self) to ensure proper initialization:
--- @example
---   function Module:init()
---       ModuleBase.init(self)  -- Call parent init first
---       -- Custom initialization here
---   end
function ModuleBase:init()
    self:load_config()
    self:create_hooks()
end

-- To be overridden in child modules
function ModuleBase:create_hooks() end
function ModuleBase:add_ui() end
function ModuleBase:reset() end


--- Cache and update a single field value, with ability to restore original
--- Caches the original field value on first call, then updates it.
--- Pass -1 (or any negative value) as new_value to restore the original.
--- @param cache_key string The cache key to store the original value
--- @param managed userdata The managed object containing the field
--- @param field_name string The field name to update
--- @param new_value number The new value to set (-1 or negative to restore original)
function ModuleBase:cache_and_update_field(cache_key, managed, field_name, new_value)
    if self.old[cache_key] == nil then
        self.old[cache_key] = managed:get_field(field_name)
    end
    
    if new_value >= 0 then 
        managed:set_field(field_name, new_value) 
    else
        if self.old[cache_key] ~= nil then
            managed:set_field(field_name, self.old[cache_key])
            self.old[cache_key] = nil
        end
    end
end

--- Cache and update a field on multiple array items with a boolean toggle
--- Caches the original field values for each item in an array, then updates them.
--- Pass false as enabled to restore originals.
--- @param cache_key string The cache key to store the array values under
--- @param array userdata|table Array-like table or managed array of objects
--- @param field_name string The field name to update on each item
--- @param enabled boolean True to cache and set field to true, false to restore originals
function ModuleBase:cache_and_update_array_toggle(cache_key, array, field_name, enabled)
    if enabled then
        -- Cache and update all items
        if not self.old[cache_key] then
            self.old[cache_key] = {}
            -- Handle both Lua tables and managed arrays
            if type(array) == "table" then
                for i, item in ipairs(array) do
                    self.old[cache_key][i] = item:get_field(field_name)
                    item:set_field(field_name, true)
                end
            else
                -- Managed array: use numeric indices starting at 0
                for i = 0, #array do
                    local item = array[i]
                    if item then
                        self.old[cache_key][i] = item:get_field(field_name)
                        item:set_field(field_name, true)
                    end
                end
            end
        end
    elseif self.old[cache_key] then
        -- Restore originals
        if type(array) == "table" then
            for i, item in ipairs(array) do
                if self.old[cache_key][i] ~= nil then
                    item:set_field(field_name, self.old[cache_key][i])
                end
            end
        else
            -- Managed array: use numeric indices starting at 0
            for i = 0, #array do
                local item = array[i]
                if item and self.old[cache_key][i] ~= nil then
                    item:set_field(field_name, self.old[cache_key][i])
                end
            end
        end
        self.old[cache_key] = nil
    end
end

--- Cache and update a field on multiple array items with a numeric value
--- Caches the original field values for each item in an array, then updates them.
--- Pass -1 (or any negative value) as new_value to restore originals.
--- @param cache_key string The cache key to store the array values under
--- @param array userdata|table Array-like table or managed array of objects
--- @param field_name string The field name to update on each item
--- @param new_value number The new value to set on each item (-1 or negative to restore originals)
function ModuleBase:cache_and_update_array_value(cache_key, array, field_name, new_value)
    if new_value >= 0 then
        -- Cache original values once, then update all items every frame
        if not self.old[cache_key] then
            self.old[cache_key] = {}
            -- Handle both Lua tables and managed arrays
            if type(array) == "table" then
                for i, item in ipairs(array) do
                    self.old[cache_key][i] = item:get_field(field_name)
                end
            else
                -- Managed array: use numeric indices starting at 0
                for i = 0, #array do
                    local item = array[i]
                    if item then
                        self.old[cache_key][i] = item:get_field(field_name)
                    end
                end
            end
        end
        
        -- Always update to the new value every frame
        if type(array) == "table" then
            for i, item in ipairs(array) do
                item:set_field(field_name, new_value)
            end
        else
            -- Managed array: use numeric indices starting at 0
            for i = 0, #array do
                local item = array[i]
                if item then
                    item:set_field(field_name, new_value)
                end
            end
        end
    elseif self.old[cache_key] then
        -- Restore originals
        if type(array) == "table" then
            for i, item in ipairs(array) do
                if self.old[cache_key][i] ~= nil then
                    item:set_field(field_name, self.old[cache_key][i])
                end
            end
        else
            -- Managed array: use numeric indices starting at 0
            for i = 0, #array do
                local item = array[i]
                if item and self.old[cache_key][i] ~= nil then
                    item:set_field(field_name, self.old[cache_key][i])
                end
            end
        end
        self.old[cache_key] = nil
    end
end


--- Save current configuration
function ModuleBase:save_config()
    config.save_section({
        [self.title] = self.data
    })
end

-- Load configuration from the config file
function ModuleBase:load_config()
    utils.update_table_with_existing_table(self.data, config.get_section(self.title))
end

--- Create a standard weapon hook guard
--- Checks if managed object is valid, correct type, has hunter, and is master player
--- @param managed userdata The managed object
--- @param weapon_class string The weapon class to check (e.g., "app.cHunterWp11Handling")
--- @return boolean True if all checks pass
function ModuleBase:weapon_hook_guard(managed, weapon_class)
    if not managed then return false end
    if not managed:get_type_definition():is_a(weapon_class) then return false end
    if not managed:get_Hunter() then return false end
    if not managed:get_Hunter():get_IsMaster() then return false end
    return true
end


function ModuleBase:draw_module()
    local any_changed = false
    local header_pos = imgui.get_cursor_pos()

    -- Setup id for imgui elements
    imgui.push_id(self.title)

    -- Draw the header. Add spaces to the left to add space for the icon
    if imgui.collapsing_header("     " .. language.get(self.title .. ".title")) then

        -- Draw the module content
        imgui.indent(10)
        any_changed = self:add_ui()
        imgui.unindent(10)

    end

    -- Draw the icon
    local pos = imgui.get_cursor_pos()
    -- Scale icon x offset based on font size (19 at size 16, 23 at size 24)
    local icon_x_offset = 11 + (language.font.size * 0.5)
    imgui.set_cursor_pos({header_pos.x + icon_x_offset, header_pos.y + 2})
    icons.draw_icon(self.title)
    imgui.set_cursor_pos(pos)

    -- Pop the id
    imgui.pop_id()

    -- Save config if anything changed
    if any_changed then 
        self:save_config() 
    end

end

return ModuleBase
