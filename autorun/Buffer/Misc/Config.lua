local utils = require("Buffer.Misc.Utils")
local configPath = "Buffer/Config.json"
local config = {}

-- Helper function to navigate nested config structure by key path
-- Returns the parent table and the final key
local function navigate_to_key(config_table, key)
    if string.find(key, ".") == nil then
        return config_table, key
    end
    
    local keys = utils.split(key, ".")
    local current = config_table
    
    for i = 1, #keys - 1 do
        if current[keys[i]] == nil then
            current[keys[i]] = {}
        end
        current = current[keys[i]]
    end
    
    return current, keys[#keys]
end

-- Get the config file - return config as JSON or nil if not found
function config.get_config()
    if json ~= nil then return json.load_file(configPath) end
    return nil
end

-- Save the current table into the config
function config.save_section(config_section)
    local current_config = config.get_config() or {}

    -- Should only be one key but this way we can grab the key 
    for key, value in pairs(config_section) do
        local config_section_key = key
        current_config[config_section_key] = value
    end

    json.dump_file(configPath, current_config)
end

-- Get the section from the config that matches the provided key
function config.get_section(config_section_key)
    local current_config = config.get_config()
    if current_config == nil then return nil end
    return current_config[config_section_key] or {}
end

-- Set a single key and value into the config
-- If a key with a . is given, it will update it in the section
function config.set(key, value)
    local current_config = config.get_config() or {}
    local parent, final_key = navigate_to_key(current_config, key)
    parent[final_key] = value
    json.dump_file(configPath, current_config)
end

-- Get a single value from the config from the provided key
-- If a key with a . is given, it will return the value from the section
function config.get(key)
    local current_config = config.get_config()
    if current_config == nil then return nil end
    
    if string.find(key, ".") == nil then
        return current_config[key]
    end
    
    local keys = utils.split(key, ".")
    local value = current_config
    for i = 1, #keys do
        value = value[keys[i]]
        if value == nil then return nil end
    end
    return value
end

return config

