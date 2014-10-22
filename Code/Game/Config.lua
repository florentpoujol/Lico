
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


AllowedConnectionsByColor= {
    Red = { "Red", "Orange", "Purple", "White" },
    Orange = { "Orange", "Red", "Yellow", "White" },
    Yellow = { "Yellow", "Orange", "Green", "White" },
    Green = { "Green", "Yellow", "Blue", "White" },
    Blue = { "Blue", "Green", "Purple", "White" },
    Purple = { "Purple", "Red", "Blue", "White" },
    
    White = { "White", "Red", "Orange", "Yellow", "Green", "Blue", "Purple" },
}

ColorList = { "Red", "Orange", "Yellow", "Green", "Blue", "Purple" } -- used for color blind mode and background


-------

Daneel.UserConfig = {
    debug = {
        enableDebug = true,
        enableStackTrace = true,
    }
}
