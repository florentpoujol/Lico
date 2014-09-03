
local frenchFont = CS.FindAsset("Calibri French", "Font")
frenchFont.specialCharSwapTable = {
    -- lang-specific char = ascii char
    ["é"] = "!",
}


local oSetText = TextRenderer.SetText
function TextRenderer.SetText( textRenderer, text )
    local font = textRenderer.font
    if font ~= nil and font.specialCharSwapTable ~= nil then
        local oldText = text
        text = ""
        for i=1, #oldText do
            local char = oldText:sub(i,i)
            char = font.specialCharSwapTable[ char ] or char
            text = text..char
        end
    end
    oSetText( textRenderer, text )
end


