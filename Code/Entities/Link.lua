
--local soundLinkBroken = CS.FindAsset("Link Broken", "Sound")

function Behavior:Awake()
    self.gameObject.s = self
    self.gameObject:AddTag("link")
    self.color = "Red"
    
    self.startGradient = self.gameObject:GetChild("Start Gradient", true)
    self.endGradient = self.gameObject:GetChild("End Gradient", true)
    
    self.hitboxGO = self.gameObject:GetChild("Hitbox")
    self.hitboxGO:AddTag("link_hitbox")
    self.hitboxGO.OnClick = function() self:OnClick() end
      
    self.nodeGOs = {} -- filled in [Node/Link]
    --self.nodePositions = {} -- filled in [Node/Link], used in [Node/CanLink]
end


function Behavior:SetColor( color, endColor )
    self.gameObject:RemoveTag(self.color)
    
    if Asset("Gradients/"..color) ~= nil and Asset("Gradients/"..endColor) ~= nil then
        self.startGradient.modelRenderer.model = "Gradients/"..color
        self.endGradient.modelRenderer.model = "Gradients/"..endColor
    end
    
    self.color = color
    
    self.gameObject:AddTag(color)
end

-- Called when the player clicks on the node's hitbox
function Behavior:OnClick()
    -- prevent deleting a link when the mouse is actually over a node
    --[[local nodeRndrs = GameObject.GetWithTag("node_renderer")
    for i, rndr in pairs(nodeRndrs) do
        if rndr.isMouseOver then
            return
        end
    end]]
    
    --
    local node1 = self.nodeGOs[1]
    local node2 = self.nodeGOs[2]
    
    table.removevalue( node1.s.nodeGOs, node2 )
    table.removevalue( node2.s.nodeGOs, node1 )
    
    table.removevalue( node1.s.linkGOs, self.gameObject )
    table.removevalue( node2.s.linkGOs, self.gameObject )
    
    node1.s:UpdateLinkQueue()
    node2.s:UpdateLinkQueue()
    
    --soundLinkBroken:Play()
    --Game.deletedLinkCount = Game.deletedLinkCount + 1
    self.gameObject:Destroy()
end
