
function Behavior:Awake()
    Scene.Append("Background")
    
    ----------
    -- Icons / Windows
    
    local creditsGO = GameObject.Get("UI.Icons.Credits")
    creditsGO:AddTag("ui")
    creditsGO:InitWindow("Tooltip", "mouseover")
    creditsGO:InitWindow("Windows.Credits", "mouseclick")
    
    
    --
    local optionsWindowGO = GameObject.Get("Windows.Options")
    local contentGO = Scene.Append("Menus/Options")
    contentGO.parent = optionsWindowGO
    contentGO.transform.localPosition = Vector3(0)
    
    local buttonGO = GameObject.Get("Icons.Options")
    buttonGO:InitWindow("Tooltip", "mouseover")
    buttonGO:InitWindow(optionsWindowGO, "mouseclick", "ui")
    
    --
    local windowGO = GameObject.Get("Windows.Levels")
    local contentGO = Scene.Append("Menus/Levels")
    contentGO.parent = windowGO
    contentGO.transform.localPosition = Vector3(0)
    
    local buttonGO = GameObject.Get("Icons.Levels")
    buttonGO:InitWindow("Tooltip", "mouseover")
    buttonGO:InitWindow(windowGO, "mouseclick", "ui")
    
    --
    local allWindows =  GameObject.Get("UI.Windows").children
            
    local hideAllOtherWindows = function( meGO )
        for i, windowGO in pairs( allWindows ) do
            if windowGO ~= meGO and windowGO.isDisplayed then
                windowGO:Display(false, true)
                
                windowGO.buttonGO.isSelected = false
                windowGO.buttonGO:Display(0.5)
            end
        end
    end
    
    for i, windowGO in pairs( allWindows ) do       
        windowGO.OnDisplay = function( go )
            if go.isDisplayed then
                go.buttonGO.isSelected = true
                go.buttonGO:Display(1)
                
                hideAllOtherWindows( go )
            end
        end
    end
    
    --
    local allIcons = GameObject.Get("UI.Icons").children
    
    for i, iconGO in pairs( allIcons ) do
        iconGO.isSelected = false
        
        local oOnClick = iconGO.OnClick -- set by GameObject.InitWindow()
        -- overrride to prevent hiding a displayed window by clicking on the same button
        iconGO.OnClick = function()
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


function Behavior:Start()
    local levelsButton = GameObject.Get("Icons.Levels")
     levelsButton:OnClick() -- Select levels window
     --levelsButton:OnMouseExit()
end
