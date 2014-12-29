
-- The UI Mask makes the transition between menus or scene seamless by:
-- taking the color of the background, 
-- hiding progressively the UI, 
-- making the transition when nothing is visible,
-- then fading out to reveal the new content

-- The child "opacity mask" must have an opacity similar to the opacity mask of the background (set in the the Main/Background scene)

-- Must be spawned after the background

function Behavior:Awake()
    self.gameObject.parent = "UI Mask Origin"
    self.gameObject.transform.localPosition = Vector3(0)
    
    self.gameObject.s = self
    Daneel.Event.Listen("OnScreenResized", function() self:UpdateSize() end)
    self:UpdateSize()
    
    self.opacityMask = self.gameObject.child
    self.opacityMask.fullOpacity = self.opacityMask.modelRenderer.opacity
    
    self.gameObject.modelRenderer.opacity = 0
    self.opacityMask.modelRenderer.opacity = 0
    
    self.frontBackgroundGO = GameObject.GetWithTag("front_background")[1]
    -- The "Background/Front" game object from the "Main/Background" scene
end

function Behavior:Animate( opacity, time, callback )
    self.gameObject.modelRenderer.model = self.frontBackgroundGO.modelRenderer.model
    local maskOpacity = opacity
    if opacity == 1 then
        maskOpacity = self.opacityMask.fullOpacity
    end
    

    if time > 0 then 
        self.gameObject:Animate("opacity", opacity, time, callback)
        self.opacityMask:Animate("opacity", maskOpacity, time)
        
    else
        self.gameObject.modelRenderer.opacity = opacity
        self.opacityMask.modelRenderer.opacity = maskOpacity
    end
end

-- Called once from Awake then when the "OnScreenResized" event is fired
function Behavior:UpdateSize()
    local orthoScale = GameObject.Get("UI Camera").camera.orthographicScale + 1
    self.gameObject.transform.localScale = Vector3( orthoScale * CS.Screen.aspectRatio, orthoScale, 0.1 )
end
