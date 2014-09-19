
 frontBackgroundModel = nil -- used in [Main Menu/Awake] to set the Window Mask model
 
function Behavior:Awake()
    local camGO = GameObject.Get("Game Background")
    self.gameObject.parent = camGO
    self.gameObject.transform.localPosition = Vector3(0,0,-50)
    
    self:ResizeBackground()
    Daneel.Event.Listen( "OnScreenResized", function() self:ResizeBackground() end )
    
    self.frontGO = self.gameObject:GetChild("Front")
    self.backGO = self.gameObject:GetChild("Back")
    
    -- randomize the starting color
    local backColorId = math.random( 1, #AllowedConnectionsByColor.White )
    local frontColorId = backColorId - 1
    if frontColorId == 0 then
        frontColorId = #AllowedConnectionsByColor.White
    end
    
    self.frontGO.modelRenderer.model = "Nodes/"..AllowedConnectionsByColor.White[frontColorId]
    frontBackgroundModel = self.frontGO.modelRenderer.model
    self.backGO.modelRenderer.model = "Nodes/"..AllowedConnectionsByColor.White[backColorId]
    
    self.nextColorId = backColorId + 1
    if self.nextColorId > #AllowedConnectionsByColor.White then
        self.nextColorId = 1
    end
    
    self.frontGO:Animate("opacity", 0, 6, {
        loops = -1,
        OnLoopComplete = function(t)
            self.frontGO.modelRenderer.model = self.backGO.modelRenderer.model
            frontBackgroundModel = self.frontGO.modelRenderer.model
            self.backGO.modelRenderer.model = "Nodes/"..AllowedConnectionsByColor.White[self.nextColorId]

            self.nextColorId = self.nextColorId + 1
            if self.nextColorId > #AllowedConnectionsByColor.White then
                self.nextColorId = 1
            end
        end,
    } )
end

function Behavior:ResizeBackground()
    local orthoScale = GameObject.Get("UI Camera").camera.orthographicScale
    local screenSize = CS.Screen.GetSize()
    local aspectRatio = screenSize.x / screenSize.y
    
    local scale = Vector3( orthoScale * math.ceil( aspectRatio ), orthoScale + 1, 1 )
    self.gameObject.transform.localScale = scale
end
