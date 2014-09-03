
CS.Screen.SetSize(900, 506) -- 1.78 = 16:9   840x470
Screen.lastScreenSize = CS.Screen.GetSize()


Game = {
    levelToLoad = nil, -- set in [Level Cartridge/SetData levelNameGO OnClick event]
    deletedLinkCount = 0, -- updated in [Connection/OnClick], used in [Level Master/EndLevel]
    backgroundNextColorId = 1,
    
    colorBlindModeActive = false,
}


AllowedConnectionsByColor= {
    Red = { "Red", "Orange", "Purple", "White" },
    Yellow = { "Yellow", "Orange", "Green", "White" },
    Blue = { "Blue", "Green", "Purple", "White" },
    
    Orange = { "Orange", "Red", "Yellow", "White" },
    Green = { "Green", "Yellow", "Blue", "White" },
    Purple = { "Purple", "Red", "Blue", "White" },
    
    White = { "White", "Yellow", "Orange", "Red",  "Purple", "Blue", "Green"  },
}

SpecialColor = { White = true, Orange = true, Green = true,  Purple = true } -- their color is always used for the connections

Scenes = {
    main_menu = "Main Menu",
    background = "Background"
}

Daneel.UserConfig = {
    debug = {
        enableDebug = true,
        enableStackTrace = true,
    }
}

