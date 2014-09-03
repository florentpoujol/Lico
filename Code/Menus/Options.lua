function Behavior:Awake()
    self.gameObject.camera:Destroy() -- removes placeholder
    
    ----------
    -- UI Size
    
    local UICameraGO = GameObject.Get("UI Camera")
    local UISizeGO = GameObject.Get("UI Size")
    UISizeGO.sizeValue = 6 -- 1 to 10
    
    local sizeValueGO = UISizeGO:GetChild("Value", true)
    sizeValueGO.textRenderer.text = 6
    
    local plusGO = UISizeGO:GetChild("+", true)
    plusGO:AddTag("ui")
    
    local minusGO = UISizeGO:GetChild("-", true)
    minusGO:AddTag("ui")
    
    local increment = function( increment )
        local value = UISizeGO.sizeValue + increment
        value = math.clamp( value, 1, 10 )
        sizeValueGO.textRenderer.text = value
        UISizeGO.sizeValue = value
        
        -- size = ortho scale
        -- 1 = 100
        -- 5 = 60
        -- 10 = 10
        -- a = (10-100)/(10-1) = -10
        -- y = ax + b <=> b = y - ax <=> b = 110
        
        local orthoScale = -10 * value + 110
        UICameraGO.camera.orthographicScale = orthoScale
        Screen.RecreateOriginGO()
        print(orthoScale)
        Tween.Timer( 0.1, function()
            Daneel.Event.Fire("OnScreenResized")
        end )
    end
    
    plusGO.OnClick = function() increment(1) end
    minusGO.OnClick = function() increment(-1) end
    
    
    
    
end

function Behavior:Start()
    ----------
    -- ColorBlind mode
    
    local checkboxGO = GameObject.Get("Color Blind Mode.Checkbox")
    checkboxGO:AddTag("ui")
    checkboxGO.toggle.OnUpdate = function(toggle)
        Game.colorBlindModeActive = toggle.isChecked
    end
    
end
