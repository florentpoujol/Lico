
CS.Screen.SetSize(900, 506) -- 1.78 = 16:9   840x470
Screen.lastScreenSize = CS.Screen.GetSize()

Game = {
    isOnSplashScreen = false, -- set to true [Splash Screen/Awake], set to false [Splash Screen/GoToMainMenu], used in [Node/Init]
    
    levelToLoad = nil, -- set in [Level Cartridge/SetData levelNameGO OnClick event]
    levelEnded = false,
    
    deletedLinkCount = 0, -- updated in [Connection/OnClick], used in [Level Master/EndLevel]
    backgroundNextColorId = 1,
    fromSplashScreen = false, -- true when the main menu is loaded after the splash screen. Set in [Splash Screen], used in [Main Menu].
    
    nodesBySGridPositions = {}, -- Vector3:ToString() = GameObject   
    -- value is reset in [Master Level/Awake] before the level content (the nodes) is spawned
    
    nodesByName = {}, -- set/init in [Master Level/Awake], filled in [Node/Awake], used in [Master Level/ShowHint]
}


Options = {
    loadedFromStorage = false,
    
    screenSize = CS.Screen.GetSize(),
    uiSize = 6,
    colorBlindModeActive = false,
    
    musicVolume = 0.4,
    soundVolume = 0.4,
} -- filled by LoadOptions() in [Menus/Options]


NiceColorsByName = {
    red = Color(225, 0, 30),
    yellow = Color(190, 190, 0),
    green = Color(0, 210, 45),
    cyan = Color(0, 220, 220),
    blue = Color(0, 100, 255),
    magenta = Color(255, 30, 255),    
}

AllowedConnectionsByColor = {
    Red = { "Red", "Yellow", "Magenta" },
    Yellow = { "Yellow", "Red", "Green" },
    Green = { "Green", "Yellow", "Cyan" },
    Cyan = { "Cyan", "Green", "Blue" },
    Blue = { "Blue", "Cyan", "Magenta" },
    Magenta = { "Magenta", "Blue", "Red" },
}

ColorList = { "Red", "Yellow", "Green", "Cyan", "Blue", "Magenta" }

-- Set of color instance
ColorsByName = nil -- set by SetRandomColors()

-- Numbers used when the color blind mode is active, used instaed of the color to recognize the nodes
NumbersByColorName = nil -- set by SetRandomColors()

-- Generate a new set of random colors
-- Called once below and also from [Master Level/Awake]
function SetRandomColors()
    ColorsByName = {}
    NumbersByColorName = {}
    local numberOffset = 0
    
    for i=1, #ColorList do
        local name = ColorList[i]
        NumbersByColorName[ name ] = math.random(1,16) + numberOffset
        numberOffset = numberOffset + 16
        
        local color = Color.New( Color.colorsByName[ name:lower() ] )
        
        -- now color is one of the primary or secondary color, with one or two components at 0
        -- make them non-zero, at random
        if table.containsvalue( {"Blue", "Red", "Green" }, name ) then
            -- regarding components that are == 0, either :
            -- 1) set one of them between 0 and 128
            -- 2) or set both components with the same value between 0 and 128
            -- Or set the comp == 255 less than 255
            
            local nullComps = {}
            local fullComp = nil
            for i=1, 3 do
                if color[i] == 0 then
                    table.insert( nullComps, i )
                elseif color[i] == 255 then
                    fullComp = i
                end
            end
            
            if math.random(2) == 1 then
                -- find the components == 0
                local nullComps = {}
                for i=1, 3 do
                    if color[i] == 0 then
                        table.insert( nullComps, i )
                    end
                end
                
                -- nullComps == { 1, 2 }, { 1, 3 } or { 2, 3 }
                -- now sets one or the two of the components to the random value
                local value = math.random(0,127)
                for i=1, math.random(2) do
                    color[ table.remove( nullComps, math.random( #nullComps ) ) ] = value
                end
            else
                color[fullComp] = math.random(129,255)
            end
            
            -- in either case, could also make the other component equidistant from 128
            
        else
            -- in this case two comps == 255, one == 0
            local fullComps = {}
            for i=1, 3 do
                if color[i] == 255 then
                    table.insert( fullComps, i )
                end
            end
            -- set one of the full component's value between 128 and 255
            local value = math.random(129,255)
            color[ fullComps[ math.random(2) ] ] = value
            
            -- could also make the comp == 0 equidistant from 128
        end
        
        ColorsByName[ name ] = color
    end -- end for ColorList
end
SetRandomColors() 


-------

function Daneel.UserConfig()
    return {
        debug = {
            enableDebug = true,
            enableStackTrace = true,
        }
    }
end
