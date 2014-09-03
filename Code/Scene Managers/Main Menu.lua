
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
                --windowGO.buttonGO:OnMouseExit()
                windowGO.buttonGO.backgroundGO:Display(false)
            end
        end
    end
    
    for i, windowGO in pairs( allWindows ) do   
        windowGO.OnDisplay = function( go )
            if go.isDisplayed then
                go.buttonGO.isSelected = true
                --windowGO.buttonGO:OnMouseEnter()
                windowGO.buttonGO.backgroundGO:Display()
                --print(go, windowGO.buttonGO.backgroundGO.isDisplayed)
                
                hideAllOtherWindows( go )
            end
        end
    end
    
    for i, iconGO in pairs( GameObject.Get("UI.Icons").children ) do
        iconGO.isSelected = false
        
        local oOnClick = iconGO.OnClick -- set by GameObject.InitWindow()
        -- overrride to prevent hiding a displayed window by clicking on the same button
        iconGO.OnClick = function()
            if not iconGO.windowGO.isDisplayed then -- ref to the windowGO is set in GameObject.InitWindow()               
                oOnClick( windowGO )
            end
        end
    end

end


function Behavior:Start()
    local levelsButton = GameObject.Get("Icons.Levels")
     levelsButton:OnClick() -- Select levels window
     --levelsButton:OnMouseExit()
end
