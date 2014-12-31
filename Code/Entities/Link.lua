
--local soundLinkBroken = CS.FindAsset("Link Broken", "Sound")

function Behavior:Awake(s)
    if s ~= true then
        self:Awake(true)
        return
    end
    
    self.gameObject.s = self
    self.gameObject:AddTag("link")
    self.gameObject.transform.localScale = Vector3(1,1,0.01)
    
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


-- Called from [Node/Link] after the link has been spawned
function Behavior:Init( node, targetNode )   
    self.gameObject.parent = node
    self.gameObject.transform.localPosition = Vector3(0)
 
    -- set position
    local nodePosition = node.transform.position
    local targetNodePosition = targetNode.transform.position
    
    local direction = targetNodePosition - nodePosition
    local linkLength = direction:GetLength() -- not always == 2 ! (can be 2, 4, 6, 8, ...)
    
    self.gameObject.transform:LookAt( targetNodePosition )
    self.gameObject.transform:MoveOriented( Vector3(0,0, -0.5 ) )
    
    -- make the link appear in the same plane as the nodes
    local angles = self.gameObject.transform.localEulerAngles
    angles.z = 0
    self.gameObject.transform.localEulerAngles = angles
    
    -- scale
    local scale = Vector3(1,1, linkLength - 1 + 0.02 ) -- make it slighly longer than the gap between the nodes
    self.gameObject:Animate("localScale", scale, 0.4, { 
        easeType = "inExpo",
        OnComplete = function()
            if Game.levelEnded == false then
                MasterLevel:CheckVictory()
            end
        end
    })   
    
    -- color
    local color = node.s.color
    local endColor = targetNode.s.color
    
    self.sourceColorGO.modelRenderer.color = color
    
    if color == endColor then
        self.targetColorGO.modelRenderer.opacity = 0
    else
        self.targetColorGO.modelRenderer.color = endColor
    end
    
    self.nodeGOs = { node, targetNode }
end


-- Called when the player clicks on the target color's renderer
function Behavior:OnClick()   
    if Game.endLevel == true then 
        return
    end
    
    local function onAnimComplete()
        local node1 = self.nodeGOs[1]
        local node2 = self.nodeGOs[2]
        node1.s:RegisterLink( self.gameObject, node2, true ) -- true == remove link
        node2.s:RegisterLink( self.gameObject, node1, true )
        
        self.gameObject:Destroy() 
    end
    
    self.gameObject:Animate("localScale", Vector3(1,1,0), 0.4, { 
        easeType = "inExpo",
        OnComplete = onAnimComplete,
    } )
end


-- Called when the level ends
function Behavior:EndLevel()
    self.sourceColorGO:RemoveTag() -- prevent links to be removed
end

Daneel.Debug.RegisterScript(Behavior)
