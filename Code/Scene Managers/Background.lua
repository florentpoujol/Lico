
local nextColorId = math.random( #ColorList )

function Behavior:Awake()
    self.gameObject.parent = GameObject.Get("Game Background")
    self.gameObject.transform.localPosition = Vector3(0,0,-50)
    
    self:ResizeBackground()
    Daneel.Event.Listen( "OnScreenResized", function() self:ResizeBackground() end )
    
    self.frontGO = self.gameObject:GetChild("Front")
    self.frontGO:AddTag("front_background") -- used by the UI Mask to get the game object
    self.backGO = self.gameObject:GetChild("Back")
    
    -- randomize the starting color
    local backColorId = nextColorId - 1
    if backColorId < 1 then
        backColorId = #ColorList
    end
    local frontColorId = backColorId - 1
    if frontColorId < 1 then
        frontColorId = #ColorList
    end
    
    self.frontGO.modelRenderer.model = "Cubes/"..ColorList[frontColorId]
    self.backGO.modelRenderer.model = "Cubes/"..ColorList[backColorId]
    
    self.frontGO:Animate("opacity", 0, 6, {
        loops = -1,
        OnLoopComplete = function(t)
            self.frontGO.modelRenderer.model = self.backGO.modelRenderer.model
            self.backGO.modelRenderer.model = "Cubes/"..ColorList[nextColorId]

            nextColorId = nextColorId + 1
            if nextColorId > #ColorList then
                nextColorId = 1
            end
        end,
    } )
end

-- Called once from Awake then when the "OnScreenResized" event is fired
function Behavior:ResizeBackground()
    local orthoScale = GameObject.Get("UI Camera").camera.orthographicScale + 1
    self.gameObject.transform.localScale = Vector3( orthoScale * CS.Screen.aspectRatio, orthoScale, 1 )
end
