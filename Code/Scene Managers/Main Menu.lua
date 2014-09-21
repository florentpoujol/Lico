
function Behavior:Awake()
    Scene.Append("Background")
    
    ----------
    -- Icons / Windows
    
    self.windowMaskGO = GameObject.Get("Window Mask")
    Game.updateWindowMask = function() self:UpdateWindowMask() end
    Daneel.Event.Listen("OnScreenResized", Game.updateWindowMask)
    
    local windowAnimation = function( windowGO )
        if not windowGO.isDisplayed then
            self.windowMaskGO.modelRenderer.model = frontBackgroundModel -- frontBackgroundModel is set in [Background/Awake]
            self.windowMaskGO:Animate("opacity", 1, 0.5, function()
                windowGO:Display()
                self.windowMaskGO:Animate("opacity", 0, 0.5)
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


-- Called when OnScreenResized event is fired
-- Can be called via Game.updateWindowMask() (but not used as of 19/09/14)
function Behavior:UpdateWindowMask()
    local orthoScale = GameObject.Get("UI Camera").camera.orthographicScale
    self.windowMaskGO.transform.localScale = Vector3( orthoScale * CS.Screen.aspectRatio, orthoScale, 0.1 )
end


function Behavior:Start()
    local levelsButton = GameObject.Get("Icons.Levels.Renderer")
    levelsButton:OnLeftClickReleased() -- Select levels window
end
