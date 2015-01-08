
function Behavior:Awake(s)
    if s ~= true then
        self:Awake(true)
        return
    end
    
    local bg = Scene.Append("Main/Background")  
    bg.s:Init()
    
    local uiMaskGO = Scene.Append("Main/Background")
    uiMaskGO.s:Init( true ) -- true == isUIMask
    
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
    buttonGO:InitWindow(windowGO, "mouseclick", nil, windowAnimation, "main_menu_window")
    self.levelsButtonGO = buttonGO -- used in Start()
        
    -- generator
    local windowGO = GameObject.Get("Windows.Generator Form")
    windowGO:Append("Menus/Generator Form")
    
    local buttonGO = GameObject.Get("Icons.Generator.Renderer")
    buttonGO:InitWindow(windowGO, "mouseclick", nil, windowAnimation, "main_menu_window")
    self.generatorButtonGO = buttonGO
    
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

    Daneel.Event.Listen("OptionsLoaded", function()
        CS.Screen.SetSize(Options.screenSize.x, Options.screenSize.y)
        SoundManager.PlayMusic()
    end )
end


function Behavior:Start()
    local buttonGO = self.levelsButtonGO
    if Game.levelToLoad ~= nil and Game.levelToLoad.isRandom == true then
        buttonGO = self.generatorButtonGO
    end
    buttonGO:FireEvent("OnLeftClickReleased", buttonGO) -- Select levels window
end

Daneel.Debug.RegisterScript(Behavior)
