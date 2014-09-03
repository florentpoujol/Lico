
function Behavior:Awake()
    Scene.Append( Scenes.background )
    
    --[[local startGO = GameObject.Get("Start")
    startGO:Animate("localScale", Vector3(0.35), 1, {
        loops = -1,
        loopType = "yoyo"
    } )]]
    
    CS.Input.OnTextEntered( function()
        CS.Input.OnTextEntered( nil )
        Scene.Load( Scenes.main_menu )
    end )
    
    local go = GameObject.Get("UI")
    --go:Display(false)
    --print("display false", go.isDisplayed)
end
