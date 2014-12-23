
function Behavior:Awake(s)
    if s ~= true then
        self:Awake(true)
        return
    end
    
    Scene.Append("Main/Background")  
    
    local uiMaskGO = Scene.Append("Main/UI Mask")
    if Game.fromSplashScreen == true then
        uiMaskGO.s:Animate(1,0) -- makes the mask hide everything
    end
    
    ----------
    -- Icons / Windows
    
    local windowAnimation = function( windowGO )
        if not windowGO.isDisplayed then
            -- fade the UI mask in then change the window game object 
            -- then fade the ui mask back out
            uiMaskGO.s:Animate( 1, 0.5, function()
                windowGO:Display()
                uiMaskGO.s:Animate(0, 0.5)
            end )
        end
    end
    
    -- options
    local optionsWindowGO = GameObject.Get("Windows.Options")
    optionsWindowGO:Append("Menus/Options")
    
    local buttonGO = GameObject.Get("Icons.Options.Renderer")
    buttonGO:InitWindow(optionsWindowGO, "mouseclick", nil, windowAnimation, "main_menu_window")
    
    -- levels
    local windowGO = GameObject.Get("Windows.Levels")
    windowGO:Append("Menus/Levels")
    
    local buttonGO = GameObject.Get("Icons.Levels.Renderer")
    self.levelsButtonGO = buttonGO -- used in Start()
    buttonGO:InitWindow(windowGO, "mouseclick", nil, windowAnimation, "main_menu_window")
    
    --
    local allWindows = GameObject.Get("UI.Windows").children
    for i=1, #allWindows do
        allWindows[i]:AddEventListener( "OnDisplay", function( go )
            -- highlight/hide the window's button when the window is displayed/hidden          
            if go.isDisplayed then
                go.buttonGO:Display(1)
            else
                go.buttonGO:Display(0.5)
            end
        end )
    end
    
    InitIcons() -- setup everythings so that the icons react to the mouse and show the desired window

    --
    Daneel.Event.Listen("OnScreenResized", SaveOptions, true ) -- save the new resolution/ui size, whenever the resolution/ui size are modified 
    Daneel.Event.Listen("OptionsLoaded", function()
        CS.Screen.SetSize(Options.screenSize.x, Options.screenSize.y)
    end )
end

function Behavior:Start()
    self.levelsButtonGO:FireEvent("OnLeftClickReleased", self.levelsButtonGO) -- Select levels window
end

Daneel.Debug.RegisterScript(Behavior)
