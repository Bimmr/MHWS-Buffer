local language = require("Buffer.Misc.Language")

local Icons = {
    glyphs = {
        great_sword = "\u{e917}",
        sword_and_shield = "\u{e939}",
        dual_blades = "\u{e918}",
        long_sword = "\u{e91a}\u{e91b}\u{e91c}",
        hammer = "\u{e91e}\u{e91f}",
        hunting_horn = "\u{e921}",
        lance = "\u{e924}",
        gunlance = "\u{e925}\u{e926}",
        switch_axe = "\u{e929}\u{e92a}",
        charge_blade = "\u{e92b}",
        insect_glaive = "\u{e92e}\u{e92f}",
        bow = "\u{e931}",
        light_bowgun = "\u{e933}\u{e934}",
        heavy_bowgun = "\u{e936}\u{e937}",

        character = "\u{e900}",
        miscellaneous = "\u{e904}"

    },
    font = nil,
    loaded_font_size = nil  -- Track the font size we loaded with
}

--- Loads the icon font with the current language font size
function Icons.load_icons()
    Icons.font = imgui.load_font('Monster-Hunter-Icons.ttf', language.font.size+2, {0xE900, 0xE9FF, 0x1F6C8, 0})
    Icons.loaded_font_size = language.font.size
end

--- Reload icons if the language font size has changed
function Icons.reload_if_needed()
    if Icons.loaded_font_size ~= language.font.size then
        Icons.load_icons()
    end
end

--- Draws the specified icon at the current cursor position
--- @param icon string The icon identifier (e.g., "great_sword", "dual_blades")
function Icons.draw_icon(icon)
    if Icons.font == nil then 
        Icons.load_icons() 
    else
        Icons.reload_if_needed()
    end
    
    imgui.push_font(Icons.font)
    local code = Icons.glyphs[icon] or "?"
    local pos = imgui.get_cursor_pos()
    for _, char in utf8.codes(code) do
        imgui.set_cursor_pos(pos)
        imgui.text(utf8.char(char))
    end
    
    imgui.pop_font()
end

return Icons
