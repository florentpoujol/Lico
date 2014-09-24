
--local soundLinkBroken = CS.FindAsset("Link Broken", "Sound")

function Behavior:Awake()
    self.gameObject.s = self
    self.gameObject:AddTag("link")
    self.color = "Red"
    
    self.startGradient = self.gameObject:GetChild("Start Gradient")
    self.endGradient = self.gameObject:GetChild("End Gradient")
        
    self.nodeGOs = {} -- filled in [Node/Link]
    self.nodePositions = {} -- filled in [Node/Link], used in [Node/CanLink]
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


function Behavior:OnClick()
    -- prevent deleting a link when the mouse is actually over a node
    local nodeRndrs = GameObject.GetWithTag("node_renderer")
    for i, rndr in pairs(nodeRndrs) do
        if rndr.isMouseOver then
            return
        end
    end
    
    --
    local node1 = self.nodeGOs[1]  
    local node2 = self.nodeGOs[2]
    
    table.removevalue( node1.s.nodeGOs, node2 )
    table.removevalue( node2.s.nodeGOs, node1 )
    
    table.removevalue( node1.s.linkGOs, self.gameObject )
    table.removevalue( node2.s.linkGOs, self.gameObject )
    
    node1.s:UpdateLinkMarks()
    node2.s:UpdateLinkMarks()
    
    --soundLinkBroken:Play()
    Game.deletedLinkCount = Game.deletedLinkCount + 1
    self.gameObject:Destroy()
end
