
--local soundLinkBroken = CS.FindAsset("Link Broken", "Sound")

function Behavior:Awake()
    self.gameObject.s = self
    self.gameObject:AddTag("link")

    self.sourceColorGO = self.gameObject:GetChild("Source Color")
    self.sourceColorGO:AddTag("link_renderer")
    self.sourceColorGO.OnClick = function()
        self:OnClick()
    end
    self.targetColorGO = self.gameObject:GetChild("Target Color")
    
    self.nodeGOs = {} -- filled in [Node/Link]
    --self.nodePositions = {} -- filled in [Node/Link], used in [Node/CanLink]
    
    Daneel.Event.Listen("EndLevel", self.gameObject) 
    -- do not register a function as it will still be registered if the link is removed,
    -- throwing a error on end level, trying to remove the tags on the dead source color GO
end

function Behavior:SetColor( color, endColor )
    self.sourceColorGO.modelRenderer.color = color
    
    if color == endColor then
        self.targetColorGO.modelRenderer.opacity = 0
    else
        self.targetColorGO.modelRenderer.color = endColor
    end
end

-- Called when the player clicks on the target color's renderer
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
    self.gameObject:Destroy()
    
    -- add again the tag so that the code in Node:Update() 
    -- still finds the link renderer and prevent the node to be deselected
    self.sourceColorGO:AddTag("link_renderer")
end

-- Called when the level ends
function Behavior:EndLevel()
    self.sourceColorGO:RemoveTag() -- prevent links to be removed
end
