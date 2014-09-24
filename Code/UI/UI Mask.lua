
function Behavior:Awake()
    self.gameObject.s = self
    Daneel.Event.Listen("OnScreenResized", function() self:UpdateSize() end)
    self:UpdateSize()
end

function Behavior:Start()
    self.frontBackgroundGO = GameObject.GetWithTag("front_background")[1]
end

function Behavior:Animate( opacity, time, callback )
    self.gameObject.modelRenderer.model = self.frontBackgroundGO.modelRenderer.model  
    self.gameObject:Animate("opacity", opacity, time, callback)
end

-- Called when OnScreenResized event is fired
function Behavior:UpdateSize()
    local orthoScale = GameObject.Get("UI Camera").camera.orthographicScale
    self.gameObject.transform.localScale = Vector3( orthoScale * CS.Screen.aspectRatio, orthoScale, 0.1 )
end
