
CS.Screen.SetSize(900, 506) -- 1.78 = 16:9   840x470
Screen.lastScreenSize = CS.Screen.GetSize()

Game = {
    levelToLoad = nil, -- set in [Level Cartridge/SetData levelNameGO OnClick event]
    deletedLinkCount = 0, -- updated in [Connection/OnClick], used in [Level Master/EndLevel]
    backgroundNextColorId = 1,
    
    nodesByName = nil, -- set/init in [Master Level/Awake], filled in [Node/Awake], used in [Master Level/ShowHint]
}


Options = {
    loadedFromStorage = false,
    
    screenSize = CS.Screen.GetSize(),
    uiSize = 6,
    colorBlindModeActive = false,
} -- filled by LoadOptions() in [Options]


AllowedConnectionsByColor = {
    Red = { "Red", "Yellow", "Magenta" },
    Yellow = { "Yellow", "Red", "Green" },
    Green = { "Green", "Yellow", "Cyan" },
    Cyan = { "Cyan", "Green", "Blue" },
    Blue = { "Blue", "Cyan", "Magenta" },
    Magenta = { "Magenta", "Blue", "Red" },
}

ColorList = { "Red", "Yellow", "Green", "Cyan", "Blue", "Magenta" }

ColorsByName = nil -- set by SetRandomColors()
NumbersByColorName = nil -- set by SetRandomColors()

-- Called once below and also from [Master Level/Awake]
function SetRandomColors()
    ColorsByName = {}
    NumbersByColorName = {}
    local numberOffset = 0
    
    for i, name in ipairs( ColorList ) do
        NumbersByColorName[ name ] = math.random(1,16) + numberOffset
        numberOffset = numberOffset + 16
    
        --
        local color = Color( Color.colorsByName[ name:lower() ] )
        
        -- now color is one of the primary or secondary color, with one or two components at 0
        -- make them non-zero, at random
        if table.containsvalue( {"Blue", "Red", "Green" }, name ) then
            -- regarding components that are == 0, either :
            -- 1) set one of them between 0 and 128
            -- 2) or set both components with the same value between 0 and 128
        
            -- find the components == 0
            local nullComps = {}
            for i=1, 3 do
                if color[i] == 0 then
                    table.insert( nullComps, i )
                end
            end
            -- nullComps == { 1, 2 }, { 1, 3 } or { 2, 3 }
            -- now sets one or the two of the components to the random value
            local value = math.random(0,128)
            for i=1, math.random(2) do
                color[ table.remove( nullComps, math.random( #nullComps ) ) ] = value
            end
            
        else
            -- in this case two comps == 255, one == 0
            local fullComps = {}
            for i=1, 3 do
                if color[i] == 255 then
                    table.insert( fullComps, i )
                end
            end
            local value = math.random(128,255)
            color[ fullComps[ math.random(2) ] ] = value
        end
        
        ColorsByName[ name ] = color
    end -- end for
end
SetRandomColors() 


-------

Daneel.UserConfig = {
    debug = {
        enableDebug = true,
        enableStackTrace = true,
    }
}

Color.colorAssetsFolder = "Flat Nodes/" -- also set/reset several times in [Node/Init]
