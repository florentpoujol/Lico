
CS.Screen.SetSize(900, 506) -- 1.78 = 16:9   840x470
Screen.lastScreenSize = CS.Screen.GetSize()

Game = {
    levelToLoad = nil, -- set in [Level Cartridge/SetData levelNameGO OnClick event]
    deletedLinkCount = 0, -- updated in [Connection/OnClick], used in [Level Master/EndLevel]
    backgroundNextColorId = 1,
}


Options = {
    loadedFromStorage = false,
    
    screenSize = CS.Screen.GetSize(),
    uiSize = 6,
    colorBlindModeActive = false,
} -- filled by LoadOptions() in [Options]


AllowedConnectionsByColor= {
    Red = { "Red", "Orange", "Purple", "White" },
    Yellow = { "Yellow", "Orange", "Green", "White" },
    Blue = { "Blue", "Green", "Purple", "White" },
    
    Orange = { "Orange", "Red", "Yellow", "White" },
    Green = { "Green", "Yellow", "Blue", "White" },
    Purple = { "Purple", "Red", "Blue", "White" },
    
    White = { "White", "Yellow", "Orange", "Red",  "Purple", "Blue", "Green"  },
}

---------

local blockId = 0
BlockIds = {
    Square = {
        White = blockId,
        Purple = blockId +1,
        Green = blockId + 2,
        Orange = blockId + 3,
        Blue = blockId + 4,
        Yellow = blockId + 5,
        Red = blockId + 6,
   },
}

blockId = blockId + 16
BlockIds.Triangle = {
    White = blockId,
    Purple = blockId +1,
    Green = blockId + 2,
    Orange = blockId + 3,
    Blue = blockId + 4,
    Yellow = blockId + 5,
    Red = blockId + 6,
}

blockId = blockId + 16
BlockIds.Circle = {
    White = blockId,
    Purple = blockId +1,
    Green = blockId + 2,
    Orange = blockId + 3,
    Blue = blockId + 4,
    Yellow = blockId + 5,
    Red = blockId + 6,
}




Scenes = {
    main_menu = "Main Menu",
    background = "Background"
}

-------

Daneel.UserConfig = {
    debug = {
        enableDebug = true,
        enableStackTrace = true,
    }
}

table.insert( Daneel.functionsDebugInfo["Vector2.New"][1][2], "Vector3" )


