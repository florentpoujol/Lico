
function Behavior:Awake()
    Scene.Append("Background")
    
    ----------
    -- Icons / Windows
    
    self.windowMaskGO = GameObject.Get("Window Mask")
    Game.updateWindowMask = function() self:UpdateWindowMask() end
    Daneel.Event.Listen("OnScreenResized", Game.updateWindowMask)
    
    local windowAnimation = function( windowGO )
        self.windowMaskGO.modelRenderer.model = frontBackgroundModel
        self.windowMaskGO:Animate("opacity", 1, 0.5, function()
            windowGO:Display( not windowGO.isDisplayed, true ) -- optionsWindowGO
            self.windowMaskGO:Animate("opacity", 0, 0.5)
        end )
    end
    
    local creditsGO = GameObject.Get("UI.Icons.Credits")
    creditsGO:InitWindow("Tooltip", "mouseover")
    creditsGO:InitWindow("Windows.Credits", "mouseclick", "ui", windowAnimation)
   
    
    --
    local optionsWindowGO = GameObject.Get("Windows.Options")
    local contentGO = Scene.Append("Menus/Options")
    contentGO.parent = optionsWindowGO
    contentGO.transform.localPosition = Vector3(0)
    
    local buttonGO = GameObject.Get("Icons.Options")
    buttonGO:InitWindow("Tooltip", "mouseover")
    buttonGO:InitWindow(optionsWindowGO, "mouseclick", "ui", windowAnimation)
    
    --
    local windowGO = GameObject.Get("Windows.Levels")
    local contentGO = Scene.Append("Menus/Levels")
    contentGO.parent = windowGO
    contentGO.transform.localPosition = Vector3(0)
    
    local buttonGO = GameObject.Get("Icons.Levels")
    buttonGO:InitWindow("Tooltip", "mouseover")
    buttonGO:InitWindow(windowGO, "mouseclick", "ui", windowAnimation)
    
    --
    local allWindows =  GameObject.Get("UI.Windows").children
            
    local hideAllOtherWindows = function( meGO )
        for i, windowGO in pairs( allWindows ) do
            if windowGO ~= meGO and windowGO.isDisplayed then
                windowGO:Display(false, true)
                
                windowGO.buttonGO.isSelected = false -- 19/09 is it used ?
                --windowGO.buttonGO:Display(0.5)
                windowGO.buttonGO.rendererGO:Display(0.5)
            end
        end
    end
    
    for i, windowGO in pairs( allWindows ) do       
        windowGO.OnDisplay = function( go )
            if go.isDisplayed then
                go.buttonGO.isSelected = true -- 19/09 is it used
                --go.buttonGO:Display(1)
                windowGO.buttonGO.rendererGO:Display(1)
                
                hideAllOtherWindows( go )
            end
        end
    end
    
    --
    local allIcons = GameObject.Get("UI.Icons").children
    
    for i, iconGO in pairs( allIcons ) do
        iconGO.isSelected = false
        
        local oOnClick = iconGO.OnLeftClickReleased -- set by GameObject.InitWindow()
        -- overrride to prevent hiding a displayed window by clicking on the same button
        iconGO.OnLeftClickReleased = function()
            if not iconGO.windowGO.isDisplayed then -- ref to the windowGO is set in GameObject.InitWindow()               
                oOnClick( windowGO )
            end
        end
    end
    
    InitIcons()
    
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
    print("update window mask", orthoScale, CS.Screen.aspectRatio )
end


function Behavior:Start()
    local levelsButton = GameObject.Get("Icons.Levels")
    levelsButton:OnClick()
    levelsButton:OnLeftClickReleased() -- Select levels window
     --levelsButton:OnMouseExit()
end
