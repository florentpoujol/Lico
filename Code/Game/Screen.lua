
-- Allow to save hud component's position when the windows is resized in order to automatically reposition them

Screen = { 
    lastScreenSize = CS.Screen.GetSize() -- updated in [Config]
}
Daneel.modules.Screen = Screen

function Screen.Load()
    local OriginalHudNew = GUI.Hud.New
    
    -- override GUI.Hud.New so that hud component update their position whevever the screen is resized
    function GUI.Hud.New( gameObject, params )
        params = params or {}
        local savedPosition = params.position
        local hud = OriginalHudNew( gameObject, params )
        hud.savedPosition = savedPosition
        
        -- after the new originGO has been created
        hud.OnScreenResized = function()
            if hud.savedPosition ~= nil then
                hud.position = hud.savedPosition
                --print("OnScreenResized", hud.gameObject, hud.savedPosition, hud.position, hud.gameObject.transform.localPosition, hud.gameObject.transform.position)
            end
        end
        Daneel.Event.Listen( "OnScreenResized", hud )
        -- SaveHudPosition and OnScreenResized are fired from Update() below
        
        return hud
    end
end

local frameCount = 0

function Screen.Update() 
    frameCount = frameCount + 1
    
    if frameCount % 30 == 0 then
        -- detect that the screen has been resized
        local screenSize = CS.Screen.GetSize()

        if screenSize ~= Screen.lastScreenSize then
            -- create a new origin GO for cameras
            Screen.RecreateOriginGO()
            
            Daneel.Event.Fire( "OnScreenResized" )
            Screen.lastScreenSize = screenSize
        end
    end
end

function Screen.RecreateOriginGO()
    local cameraGO = GameObject.Get("UI Camera")
    if cameraGO.hudOriginGO ~= nil then
        cameraGO.hudOriginGO:Destroy()
    end
    GUI.Hud.CreateOriginGO( cameraGO )
end
