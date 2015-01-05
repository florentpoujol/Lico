function Behavior:Awake()
    self.gameObject.parent.camera:Destroy() -- removes placeholder
    
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
    
    ----------
    -- ColorBlind mode
    
    local go = GameObject.Get("Color Blind Mode.Info Icon.Renderer")
    go:InitWindow("Color Blind Mode.Info Window", "mouseclick")   

    local checkboxGO = GameObject.Get("Color Blind Mode.Checkbox")
    checkboxGO.toggle.OnUpdate = function(toggle)
        Options.colorBlindModeActive = toggle.isChecked
        SaveOptions()
        
        if toggle.isChecked == true then
            --toggle.gameObject.modelRenderer.color = Color(0,200,55)
        else
            --toggle.gameObject.modelRenderer.color = Color(255,0,50)
        end
    end
    self.colorBlindToggle = checkboxGO.toggle -- used in UpdateMenu()
    
        
    ----------    
    -- sound and music
    local onUpdate = function(t)
        if t.isChecked == true then
            Options[ t.volumeProperty ] = t.volume
            SaveOptions()
        end
    end
    
    self.musicGOs = GameObject.Get("Music Volume.Radios").children
    for i=1, #self.musicGOs do
        local toggle = self.musicGOs[i].toggle
        toggle.volumeProperty = "musicVolume"
        toggle.volume = tonumber( toggle.gameObject.name ) / 10
        if toggle.volume == Options.musicVolume then
            toggle:Check(true)
        end
        toggle.OnUpdate = onUpdate
    end
    
    self.soundGOs = GameObject.Get("Sound Volume.Radios").children
    for i=1, #self.soundGOs do
        local toggle = self.soundGOs[i].toggle
        toggle.volumeProperty = "soundVolume"
        toggle.volume = tonumber( toggle.gameObject.name ) / 10
        if toggle.volume == Options.soundVolume then
            toggle:Check(true)
        end
        toggle.OnUpdate = onUpdate
    end
    
    
    ---------
    
    Daneel.Event.Listen("OptionsLoaded", function() 
        self:UpdateMenu() 
        Daneel.Event.Listen("OnScreenResized", SaveOptions) -- save the new resolution/ui size, whenever the resolution/ui size are modified 
    end )
    
    LoadOptions() -- fire "OptionsLoaded" event
end


-- Called wen the "OptionsLoaded" event is fired from LoadOptions()
function Behavior:UpdateMenu()
    UpdateUISize()
    self.uiSizeValueGO.textRenderer.text = Options.uiSize
    
    self.colorBlindToggle:Check( Options.colorBlindModeActive )
    
    for i=1, #self.musicGOs do
        local toggle = self.musicGOs[i].toggle
        if toggle.volume == Options.musicVolume then
            toggle:Check(true)
        end
    end
    
    for i=1, #self.soundGOs do
        local toggle = self.soundGOs[i].toggle
        if toggle.volume == Options.soundVolume then
            toggle:Check(true)
        end
    end
end


function LoadOptions( callback )
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

