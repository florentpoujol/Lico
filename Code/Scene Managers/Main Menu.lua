
function Behavior:Awake()
    Scene.Append("Background")
    
    ----------
    local uiMaskGO = GameObject.Get("UI Mask")
    uiMaskGO.s:Start() -- call [UI Mask/Start] function right away because I need it now (to know which color is the background)
    uiMaskGO.s:Animate(1,0) -- makes the mask hide everything
    Tween.Timer(0.5, function() uiMaskGO.s:Animate(0,0.5) end) -- fade the mask out
    
    ----------
    -- Icons / Windows
    
    local uiMaskGO = GameObject.Get("UI Mask")
    
    local windowAnimation = function( windowGO )
        if not windowGO.isDisplayed then
            uiMaskGO.s:Animate( 1, 0.5, function()
                windowGO:Display()
                uiMaskGO.s:Animate(0, 0.5)
            end )
        end
    end
    
    -- credit window   
    local creditsGO = GameObject.Get("Icons.Credits.Renderer")
    creditsGO:InitWindow("Windows.Credits", "mouseclick", nil, windowAnimation, "main_menu_window")

    -- options
    local optionsWindowGO = GameObject.Get("Windows.Options")
    optionsWindowGO:Append("Menus/Options")
  
    local buttonGO = GameObject.Get("Icons.Options.Renderer")
    buttonGO:InitWindow(optionsWindowGO, "mouseclick", nil, windowAnimation, "main_menu_window")
    
    -- levels
    local windowGO = GameObject.Get("Windows.Levels")
    windowGO:Append("Menus/Levels")
    
    local buttonGO = GameObject.Get("Icons.Levels.Renderer")
    buttonGO:InitWindow(windowGO, "mouseclick", nil, windowAnimation, "main_menu_window")
    
    --
    local allWindows =  GameObject.Get("UI.Windows").children
    
    for i, windowGO in pairs( allWindows ) do
        local oOnDisplay = windowGO.OnDisplay -- set by GameObject.InitWindow()
        windowGO.OnDisplay = function( go )
            oOnDisplay(go)
            
            if go.isDisplayed then
                go.buttonGO:Display(1)
            else
                go.buttonGO:Display(0.5)
            end
        end
    end
   
    InitIcons() -- actually this will be called latter in [Options/Start]

    --
    Daneel.Event.Listen("OnScreenResized", SaveOptions, true ) -- save the new resolution/ui size, whenever the resolution/ui size are modified 
    Daneel.Event.Listen("OptionsLoaded", function()
        CS.Screen.SetSize(Options.screenSize.x, Options.screenSize.y)
    end )
end



function Behavior:Start()
    local levelsButton = GameObject.Get("Icons.Levels.Renderer")
    levelsButton:OnLeftClickReleased() -- Select levels window
end
