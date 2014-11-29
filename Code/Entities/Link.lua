
--local soundLinkBroken = CS.FindAsset("Link Broken", "Sound")

function Behavior:Awake()
    self.gameObject.s = self
    self.gameObject:AddTag("link")

    self.sourceColorGO = self.gameObject:GetChild("Source Color")
    self.targetColorGO = self.gameObject:GetChild("Target Color")
    self.targetColorGO:AddTag("link_renderer")
    self.targetColorGO.OnClick = function()
        self:OnClick()
    end

    self.nodeGOs = {} -- filled in [Node/Link]
    --self.nodePositions = {} -- filled in [Node/Link], used in [Node/CanLink]
end


function Behavior:SetColor( color, endColor )
    self.sourceColorGO.modelRenderer.color = color
    self.targetColorGO.modelRenderer.color = endColor    
end

-- Called when the player clicks on the node's hitbox
function Behavior:OnClick()   
    if Game.endLevel == true then 
        return
    end
    
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
