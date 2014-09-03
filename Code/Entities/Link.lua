--[[PublicProperties
color string "Red"
/PublicProperties]]

local soundLinkBroken = CS.FindAsset("Link Broken", "Sound")

function Behavior:Awake()
    self.gameObject.s = self
    self.gameObject:AddTag("link")
    
    self.startGradient = self.gameObject:GetChild("Start Gradient")
    self.endGradient = self.gameObject:GetChild("End Gradient")
        
    self.nodeGOs = {} -- filled in [Node/Connect]
end


function Behavior:SetColor( color, endColor )
    self.gameObject:RemoveTag(self.color)
    
    self.gameObject.modelRenderer.model = "Links/"..color

    if Asset("Gradients/"..color) ~= nil and Asset("Gradients/"..endColor) ~= nil then
        self.startGradient.modelRenderer.model = "Gradients/"..color
        self.endGradient.modelRenderer.model = "Gradients/"..endColor
        self.gameObject.modelRenderer.model = "Links/Crystal White"
        self.gameObject.modelRenderer.opacity = 0
    end
    
    self.color = color
    
    self.gameObject:AddTag(color)
end


function Behavior:OnClick()
    local node1 = self.nodeGOs[1]  
    local node2 = self.nodeGOs[2]
    
    table.removevalue( node1.s.nodeGOs, node2 )
    table.removevalue( node2.s.nodeGOs, node1 )
    
    table.removevalue( node1.s.linkGOs, self.gameObject )
    table.removevalue( node2.s.linkGOs, self.gameObject )
    
    soundLinkBroken:Play()
    Game.deletedLinkCount = Game.deletedLinkCount + 1
    self.gameObject:Destroy()
end
