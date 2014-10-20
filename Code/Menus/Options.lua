function Behavior:Awake()
    self.gameObject.camera:Destroy() -- removes placeholder
    
    ----------
    -- UI Size
    
    self.UICameraGO = GameObject.Get("UI Camera") -- used in SetUISize()
    local UISizeGO = GameObject.Get("UI Size")
    Options.uiSize = 6 -- 1 to 10
    
    local sizeValueGO = UISizeGO:GetChild("Value", true)
    self.uiSizeValueGO = sizeValueGO -- used in UpdateMenu()
    sizeValueGO.textRenderer.text = 6
    
    local plusGO = UISizeGO:GetChild("+", true)
    plusGO:AddTag("ui")
    
    local minusGO = UISizeGO:GetChild("-", true)
    minusGO:AddTag("ui")
    
    local increment = function( increment )
        local value = Options.uiSize + increment
        value = math.clamp( value, 1, 9 )
        sizeValueGO.textRenderer.text = value
        
        Options.uiSize = value
        UpdateUISize() --The new UI size and Options are saved when the "OnScreenResized" event is fired from UpdateUISize() (event listened from [Main Menu/Awake])
    end
    
    plusGO.OnClick = function() increment(1) end
    minusGO.OnClick = function() increment(-1) end
    
    -- ColorBlind mode
    local infoIconGO = GameObject.Get("Color Blind Mode.Info Icon.Renderer")
    infoIconGO:InitWindow("Color Blind Mode.Info Window", "mouseclick")
    -- do not put that code in Start because InitWindow would be called after InitIcons() (in [Main Menu]) and overwrite onLeftClickReleased()
end


function Behavior:Start()
    -- ColorBlind mode
    local checkboxGO = GameObject.Get("Color Blind Mode.Checkbox")
    checkboxGO:AddTag("ui")
    checkboxGO.toggle.OnUpdate = function(toggle)
        Options.colorBlindModeActive = toggle.isChecked
        SaveOptions()
    end
    self.colorBlindToggle = checkboxGO.toggle -- used in UpdateMenu()
    
    --
    Daneel.Event.Listen("OptionsLoaded", function() self:UpdateMenu() end )    
    LoadOptions() -- fire "OptionsLoaded" event
    -- should be done as early as possible
    
    --InitIcons()
end


function LoadOptions()
    CS.Storage.Load("Options", function(e, data)
        if e ~= nil then
            print("ERROR loading options from storage: ", e.message)
            return
        end
        
        if data ~= nil then
            table.mergein( Options, data )
            Options.loadedFromStorage = true
            Daneel.Event.Fire("OptionsLoaded")
        end
    end )
end


function SaveOptions()
    Options.screenSize = CS.Screen.GetSize()
    CS.Storage.Save("Options", Options, function(e)
        if e ~= nil then
            print("ERROR saving options in storage: ", e.message)
        end
    end )
end


function Behavior:UpdateMenu()
    UpdateUISize()
    self.uiSizeValueGO.textRenderer.text = Options.uiSize
    
    self.colorBlindToggle:Check( Options.colorBlindModeActive )
end


function UpdateUISize()
    -- size = ortho scale
    -- 1 = 100
    -- 5 = 60
    -- 10 = 10
    -- a = (10-100)/(10-1) = -10
    -- y = ax + b <=> b = y - ax <=> b = 110
    
    local orthoScale = -10 * Options.uiSize + 110
    GameObject.Get("UI Camera").camera.orthographicScale = orthoScale
    Screen.RecreateOriginGO()
    
    Tween.Timer( 0.1, function()
        Daneel.Event.Fire("OnScreenResized")
    end )
end

