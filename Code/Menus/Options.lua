function Behavior:Awake()
    self.gameObject.camera:Destroy() -- removes placeholder
    
    ----------
    -- UI Size
    
    local UICameraGO = GameObject.Get("UI Camera")
    local UISizeGO = GameObject.Get("UI Size")
    UISizeGO.sizeValue = 5 -- 1 to 10
    
    local sizeValueGO = UISizeGO:GetChild("Value", true)
    sizeValueGO.textRenderer.text = 5
    
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
        -- 1 = 90
        -- 5 = 50
        -- 10 = 20
        -- a = (20-90)/(10-1) = -7.7778
        -- y = ax + b <=> b = y - ax <=> b = 90 + 7.7778
        
        local orthoScale = -70/9 * value + 90 + 70/9
        UICameraGO.camera.orthographicScale = orthoScale
        Screen.RecreateOriginGO()
        
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
