
function Behavior:Awake()
    self.gameObject.parent = GameObject.Get("Game Background")
    self.gameObject.transform.localPosition = Vector3(0,0,-50)
    
    self:ResizeBackground()
    Daneel.Event.Listen( "OnScreenResized", function() self:ResizeBackground() end )
    
    self.frontGO = self.gameObject:GetChild("Front")
    self.frontGO:AddTag("front_background") -- used by the UI Mask to get the game object
    self.backGO = self.gameObject:GetChild("Back")
    
    -- randomize the starting color
    local backColorId = math.random( #ColorList )
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

-- Called once from Awake then when the "OnScreenResized" event is fired
function Behavior:ResizeBackground()
    local orthoScale = GameObject.Get("UI Camera").camera.orthographicScale + 1
    self.gameObject.transform.localScale = Vector3( orthoScale * CS.Screen.aspectRatio, orthoScale, 1 )
end
