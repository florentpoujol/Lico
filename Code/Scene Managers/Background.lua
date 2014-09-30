
function Behavior:Awake()
    self.gameObject.parent = GameObject.Get("Game Background")
    self.gameObject.transform.localPosition = Vector3(0,0,-50)
    
    self:ResizeBackground()
    Daneel.Event.Listen( "OnScreenResized", function() self:ResizeBackground() end )
    
    self.frontGO = self.gameObject:GetChild("Front")
    self.frontGO:AddTag("front_background")
    self.backGO = self.gameObject:GetChild("Back")
    
    -- randomize the starting color
    local backColorId = math.random( 1, #ColorList )
    local frontColorId = backColorId - 1
    if frontColorId == 0 then
        frontColorId = #ColorList
    end
    
    self.frontGO.modelRenderer.model = "Nodes/"..ColorList[frontColorId]
    self.backGO.modelRenderer.model = "Nodes/"..ColorList[backColorId]
    
    self.nextColorId = backColorId + 1
    if self.nextColorId > #ColorList then
        self.nextColorId = 1
    end
    
    self.frontGO:Animate("opacity", 0, 6, {
        loops = -1,
        OnLoopComplete = function(t)
            self.frontGO.modelRenderer.model = self.backGO.modelRenderer.model
            self.backGO.modelRenderer.model = "Nodes/"..ColorList[self.nextColorId]

            self.nextColorId = self.nextColorId + 1
            if self.nextColorId > #ColorList then
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
