local Icons = {
    Icon = {
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
        miscellaneous = "\u{e904}",

        info = "\u{1F6C8}"

    },
    font = nil
}
local language = require("Buffer.Misc.Language")


function Icons.loadIcons()
    Icons.font = imgui.load_font('Monster-Hunter-Icons.ttf', language.font.size+2, {0xE900, 0xE9FF, 0x1F6C8, 0})
end

function Icons.drawIcon(icon)
    if Icons.font == nil then Icons.loadIcons() end
    imgui.push_font(Icons.font)
    local code = Icons.Icon[icon] or "?"
    local pos = imgui.get_cursor_pos()
    for _, char in utf8.codes(code) do
        imgui.set_cursor_pos(pos)
        imgui.text(utf8.char(char))
    end
    
    imgui.pop_font()
end

return Icons