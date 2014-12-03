--[[PublicProperties
colorName string ""
maxLinkCount number 6
/PublicProperties]]
--[[
goal : check if a node can connect to another
- check color

find nodes the node can link to using rays in the 4 (or 8 in case of octogon) directions
results must be updated when the node is turned 45°
in all case nodes can connect only if they the ray intersects and they have the same rotation (or are octogon)
each node has a reference to the nodes it can link to
once a node has 4 references, remove it from

CanLink function must also check if there isn't a link in between

]]


function Behavior:Awake()
    -- if the game object only has a modelRenderer, it is a placeholder to be replaced by the real node
    local rendererGO = self.gameObject:GetChild("Renderer")
    if rendererGO == nil then
        local realNode = Scene.Append("Entities/Node", self.gameObject.parent)
        realNode.transform.localPosition = self.gameObject.transform.localPosition
        
        local name = self.gameObject.name
        Game.nodesByName[ name ] = realNode -- for hints ([Master Level/Show Hint]
        realNode.name = name
        
        realNode.s.maxLinkCount = self.maxLinkCount
        if self.colorName == "" and self.gameObject.modelRenderer ~= nil then
            self.colorName = self.gameObject.modelRenderer.model.name
        end
        realNode.s:Init(self.colorName)
             
        self.gameObject:Destroy()
        return
    end
    

    ----------

    self.gameObject.s = self
    self.gameObject:AddTag("node")
    
    Daneel.Event.Listen("EndLevel", self.gameObject) -- fired from CheckVictory(), cateched by EndLevel()
    
    self.linksParentGO = self.gameObject:GetChild("Links Parent")

    self.isSelected = false  

    self.linkableNodes = {}
    self.nodeGOs = {} -- nodes this node is connected to -- filled in Link()
    self.linkGOs = {}
    
    self.frameCount = 0
    
    self.isInit = false
end


-- In practice, only called from a node placeholder Awake()
function Behavior:Init( colorName )
    if self.isInit == true then
        return
    end
    
    if colorName == "" or colorName == nil then
        if self.gameObject.modelRenderer ~= nil and self.gameObject.modelRenderer.model ~= nil then
           colorName = self.gameObject.modelRenderer.model.name
        else
            error( "Node/Init(), no color name "..tostring(self.gameObject))   
        end
    end

    self.gameObject:RemoveTag(colorName)
    self.gameObject:AddTag(colorName)
    self.colorName = colorName
    
    self.color = ColorsByName[ colorName ]
    
    local rendererGO = self.gameObject:GetChild("Renderer")
    rendererGO.modelRenderer.color = self.color
    
    rendererGO:AddTag("node_renderer")
    rendererGO.OnClick = function() self:OnClick() end
    rendererGO.OnMouseOver = function()
        if not self.isSelected and not Game.levelEnded then
            self:OnClick()
        end
    end
    
    self.rendererGO = rendererGO
    
    ----------
    -- color Blind
    
    local numberGO = self.gameObject:GetChild("Color Blind")
    
    if Options.colorBlindModeActive then
        self.numberGO = numberGO
        numberGO.textRenderer.text = NumbersByColorName[ colorName ]
    else
        numberGO:Destroy()
    end
    
    ----------
    -- Link Queue
    -- The Link Queue chldren must be ordered from 4 (top) to 1 (bootom)
    
    self.linksQueue = self.gameObject:GetChild("Links Queue")
    local marks = self.linksQueue.children
    self.linksQueue.marks = {}
        
    for i, go in ipairs( marks ) do -- loop on children from 1 to 6
        if i <= self.maxLinkCount then
            table.insert( self.linksQueue.marks, go )
            go.modelRenderer.color = self.color
        else
            go:Destroy()
        end
    end
    self.linksQueue.marks = table.reverse( self.linksQueue.marks )
    
    -----------
    -- pillar
    
    self.pillarGO = self.gameObject:GetChild("Pillar")
    --Color.colorAssetsFolder = "Nodes/"
    
    self.pillarGO.modelRenderer.color = self.color
    self.pillarGO.modelRenderer.opacity = 0.05
    --self.pillarGO.transform:Move(Vector3(0,-5,0))
    --self.pillarGO.transform.localScale = Vector3(1,10,1)
    
    self.isInit = true
end


--------------------------------------

function Behavior:Start()
    if not self.gameObject.isDestroyed then -- true on the node placeholders, Start() is apparently called before the game object is actually destroyed
        
        if not self.isInit then
            self:Init()
        end
        
        -- by now all nodes of the level have been Init
        self:GetLinkableNodes()
    end
end


function Behavior:GetLinkableNodes()
    if #self.linkableNodes >= 4 then --TODO check if node is octogon
        -- save a little performance by ending the function now if it doesn't need to run
        return
    end
    
    local nodeRndrs = GameObject.GetWithTag("node_renderer")
    table.removevalue( nodeRndrs, self.rendererGO )   
    
    local nodePosition = self.gameObject.transform.position
    local directionGOs = self.gameObject:GetChild("Ray Directions").children
    local directions = {}
    for i, go in pairs(directionGOs) do
        table.insert( directions, go.transform.position - nodePosition )
    end

    
    --[[
    local oherDirections = {
        Vector3(1,0,1),
        Vector3(1,0,-1),
        Vector3(-1,0,1),
        Vector3(-1,0,-1),
    }
    
    if node is turned 45° then
        directions = oherDirections
    end
    
    if node is octogon then
        table.mergein( directions, otherDirections )
    end
    ]]
    
    local ray = Ray( self.gameObject.transform.position, Vector3(0) )
    for i, direction in pairs(directions) do
        ray.direction = direction
        
        local raycastHit = ray:Cast( nodeRndrs, true )[1] -- true = sort by distance
        -- TODO for efficiency :
        -- get only the nodes actually in the direction and compute the distance via their coordinate (closest = smallest relative coords)
        
        if raycastHit ~= nil then
            local otherNode = raycastHit.gameObject.parent
            
            -- TODO : check orientation of other node's renderer
            if not table.containsvalue( self.linkableNodes, otherNode ) then
                table.insert( self.linkableNodes, otherNode ) -- raycatHit.gameObject is the rendererGO
            end
            if not table.containsvalue( otherNode.s.linkableNodes, self.gameObject ) then
                table.insert( otherNode.s.linkableNodes, self.gameObject )
            end
        end
        
    end

end

--------------------------------------

-- Called when left click or mouse over the node's renderer.
-- See in Init() above.
function Behavior:OnClick()
    if self.isSelected and self.rendererGO.isMouseOver then -- click when mouse over and already selected
        return
    end
    
    local selectedNode = GameObject.GetWithTag("selected_node")[1]
    if selectedNode ~= nil and selectedNode ~= self.gameObject then -- there is a selected node and it's not this one
        --print(selectedDot, self.gameObject)
        --print((self.maxLinkCount <= 0 or (self.maxLinkCount > 0 and #self.nodeGOs < self.maxLinkCount) ))
        --print( table.containsvalue( AllowedConnectionsByColor[ selectedNode.s.colorName ], self.colorName ) )
        --print(not table.containsvalue( selectedNode.s.nodeGOs, self.gameObject ))
        
        if 
            (self.maxLinkCount <= 0 
            or (self.maxLinkCount > 0 and #self.nodeGOs < self.maxLinkCount) ) -- prevent the node to be connected if it has no more connoction to make
            and
            
            table.containsvalue( AllowedConnectionsByColor[ selectedNode.s.colorName ], self.colorName ) -- colors of the nodes can connect
            and
            
            not table.containsvalue( selectedNode.s.nodeGOs, self.gameObject ) -- if they are not already connected
        then
            
            -- check there isn't a bar in between
            if selectedNode.s:CanLink( self.gameObject ) then
                selectedNode.s:Link( self.gameObject )
            else
                if not Game.randomLevelGenerationInProgress then
                    --soundNoAction:Play()
                end
            end
        else
            if not Game.randomLevelGenerationInProgress then
                --soundNoAction:Play()
            end
        end
    end
    
    self:Select()
end


function Behavior:Select( select )
    if select == nil then
        select = not self.isSelected
        -- false if true (un select if already selected)
        -- true if false (select if not already selected)
    elseif select == self.isSelected then
        return
    end
    
    local animationTime = 0.1
    
    if select then
        -- prevent the node to be selected if it has no more link to make
        if self.maxLinkCount > 0 and #self.nodeGOs >= self.maxLinkCount then
            return
        end
        
        --self.pillarGO.modelRenderer.opacity = 0.5
        self.pillarGO:Animate("opacity", 0.5, 0.5)
        --print("0.5", self.pillarGO.modelRenderer.opacity, self.pillarGO.frontColorRenderer.opacity)

        self.isSelected = true
        
        local selectedNode = GameObject.GetWithTag("selected_node")[1]
        if selectedNode ~= nil and selectedNode ~= self.gameObject then
            selectedNode.s:Select(false)
        end
        self.gameObject:AddTag("selected_node")
    else
        
        --self.pillarGO.modelRenderer.opacity = 0.05
        --print("0.05", self.pillarGO.modelRenderer.opacity, self.pillarGO.frontColorRenderer.opacity)
        self.pillarGO:Animate("opacity", 0.05, 0.5)
        
        self.isSelected = false
        self.gameObject:RemoveTag("selected_node")
    end
end


-- Check there isn't a link or other node in between
function Behavior:CanLink( targetGO )   
    if table.containsvalue( self.linkableNodes, targetGO ) then
        -- both node can link apriori
        -- now check that there isn't a link in between        
        local nodeRndrGOs = GameObject.GetWithTag("link_hitbox") 
        table.removevalue( nodeRndrGOs, self.rendererGO )
        table.removevalue( nodeRndrGOs, targetGO.s.rendererGO )
        
        if #nodeRndrGOs == 0 then
            return true
        end
        
        local selfPosition = self.gameObject.transform.position
        local targetPosition = targetGO.transform.position
        local direction = targetPosition - selfPosition
        
        local ray = Ray:New(selfPosition, direction:Normalized() )
        local hit = ray:Cast( nodeRndrGOs, true )[1]
        
        if hit == nil or hit.distance > direction:GetLength() then -- note: direction:GetLength() always = 2
            return true
        end
    end
    return false
end


function Behavior:Link( targetGO )
    local linkGO = Scene.Append("Entities/Link")   
    linkGO.parent = self.linksParentGO
    linkGO.transform.localPosition = Vector3(0)
    
    local selfPosition = self.gameObject.transform.position
    local otherPosition = targetGO.transform.position
    
    local direction = otherPosition - selfPosition
    local linkLength = direction:GetLength() -- not always == 2 ! (can be 2, 4, 6, 8, ...)
    
    linkGO.transform:LookAt(otherPosition)
    linkGO.transform:MoveOriented(Vector3(0,0, -linkLength/2 ))   
    linkGO.transform.localScale = Vector3(1,1, linkLength - 1 + 0.02 ) -- make it slighly longer than the gap between the nodes
    
    -- make the link appear in the same plane as the nodes
    local angles = linkGO.transform.localEulerAngles
    angles.z = 0
    linkGO.transform.localEulerAngles = angles
    
    --
    linkGO.s:SetColor( self.color, targetGO.s.color )
    
    linkGO.s.nodeGOs = { self.gameObject, targetGO }
    --linkGO.s.nodePositions = { selfPosition, otherPosition } -- used in CanLink()
    
    table.insert( self.nodeGOs, targetGO )
    table.insert( targetGO.s.nodeGOs, self.gameObject )
    
    table.insert( self.linkGOs, linkGO )
    table.insert( targetGO.s.linkGOs, linkGO )
    
    --
    self:UpdateLinkQueue()
    targetGO.s:UpdateLinkQueue()
    
    self:CheckVictory()
end

-- Called from Link() and [Link/OnClick()]
function Behavior:UpdateLinkQueue( nodeLinkCount )
    nodeLinkCount = nodeLinkCount or #self.nodeGOs
    local marks = self.linksQueue.marks

    for i, go in ipairs( marks ) do 
        -- loop on the existing marks in rfrom biggest num to 1
        if i <= nodeLinkCount then
            -- hide the link
            --go:Display(0)
            --f go.modelRenderer.opacity ~= 0 then
            if not go.isHidden then
                go:Animate("opacity", 0.5, 0.5, function(tweener) 
                    tweener.target.opacity = 0 
                end)
                go.isHidden = true
            end
        else
            --if go.modelRenderer.opacity == 0 then
            if go.isHidden == true then
                --go:Display(01)
                go.modelRenderer.opacity = 0.5
                go:Animate("opacity", 0.01, 0.5)
                go.isHidden = false
            end
        end
    end
    
    if nodeLinkCount >= self.maxLinkCount then
        self:Select(false)
    end
end

-- Called at the end of Link()
function Behavior:CheckVictory()   
    local nodes = GameObject.GetWithTag("node")
    
    for i, node in pairs( nodes ) do
        -- quick-search for nodes without links
        if #node.s.linkGOs == 0 then
            return false
        end
    end
    
    
    -- check that all nodes are actually connected together, using simplified BFS (breadth-first search), 
    -- if all nodes are connected, the algo must find as many nodes as they are
    
    local visited = {}
    local toBeVisited = { nodes[1] }
    
    while #toBeVisited > 0 do
        local node = table.remove( toBeVisited, 1 )
        table.insert( visited, node )
        node.wasVisited = true
        
        for i, linkedNode in pairs( node.s.nodeGOs ) do
            if not linkedNode.wasVisited and not linkedNode.willBeVisited then
                table.insert( toBeVisited, linkedNode )
                linkedNode.willBeVisited = true
            end
        end
    end
    
    for i, node in pairs(nodes) do
        node.wasVisited = nil
        node.willBeVisited = nil        
    end
    
    if #visited ~= #nodes then
        return false
    end
    
    -- By now all nodes are OK and linked together
    Daneel.Event.Fire("EndLevel") -- catched by [Master Level/EndLevel] and all node's EndLevel()
end

-- Called on all nodes when EndLevel event is fired from one node's CheckVictory()
function Behavior:EndLevel()
    -- prevent nodes to be selected
    self.rendererGO:RemoveTag("node_renderer")
    
    -- prevent links to be removed
    --for i, link in pairs( self.linkGOs ) do
        --link.s.hitboxGO:RemoveTag("link_hitbox")
    --end
    
    self:UpdateLinkQueue(99) -- do as if the node had 4 links, hidding all the link marks

    self.pillarGO.transform.localScale = 0 -- using the opacity is not enough as the last node get somehow automatically reselected
    
    -- hide the numbers
    if self.numberGO ~= nil then
        self.numberGO.textRenderer.opacity = 0
    end
end


local linkMarksFadeOutFrames = 60 -- 1 sec

function Behavior:Update()
    -- unselect selected node when click outside a node
    if CS.Input.WasButtonJustPressed("LeftMouse") then
        local selectedNode = GameObject.GetWithTag("selected_node")[1]
        if selectedNode ~= nil then
            local nodes = GameObject.GetWithTag("node_renderer")
            for i, node in pairs(nodes) do
                if node.isMouseOver then
                    return
                end
            end
        
            -- the mouse is not over any node, just deselected
            selectedNode.s:Select(false)
        end
    end
end


table.mergein( Daneel.Debug.functionArgumentsInfo, {
    ["GetLinkableNodes"] = { script = Behavior },
    ["CanLink"] = { script = Behavior },
} )

Daneel.Debug.RegisterScript( Behavior )
