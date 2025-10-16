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
    if imgui.collapsing_header("    " .. language.get(self.title .. ".title")) then

        -- Draw the module content
        imgui.indent(10)
        any_changed = self:add_ui()
        imgui.unindent(10)

    end

    -- Draw the icon
    local pos = imgui.get_cursor_pos()
    imgui.set_cursor_pos({header_pos.x + 18, header_pos.y + 2})
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
