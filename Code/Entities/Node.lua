--[[PublicProperties
colorName string ""
maxLinkCount number 4
/PublicProperties]]

local nodesByPositions = {}

function Behavior:Awake(s)
    if s ~= true then
        self:Awake(true)
        return
    end
    
    -- if the game object only has a modelRenderer, it is a placeholder to be replaced by the real node
    local rendererGO = self.gameObject:GetChild("Renderer")
    if rendererGO == nil then
        local realNode = Scene.Append("Entities/Node", self.gameObject.parent)
        realNode.transform.localPosition = self.gameObject.transform.localPosition
        
        local name = self.gameObject.name
        Game.nodesByName[ name ] = realNode -- for hints ([Master Level/Show Hint]
        realNode.name = name
        
        realNode.s:SetMaxLinkCount( self.maxLinkCount )
        if self.colorName == "" and self.gameObject.modelRenderer ~= nil then
            local model = self.gameObject.modelRenderer.model
            if model ~= nil then
                self.colorName = self.gameObject.modelRenderer.model.name
            end
        end
        realNode.s:Init(self.colorName)
             
        self.gameObject:Destroy()
        return
    end

    self.gameObject.s = self
    self.gameObject:AddTag("node")
    
    Daneel.Event.Listen("EndLevel", self.gameObject) -- fired from CheckVictory(), cateched by EndLevel()
    
    self.isSelected = false  

    self.linkableNodes = {}
    self.nodeGOs = {} -- nodes this node is connected to -- filled in Link()
    self.linkGOs = {}
    
    self.frameCount = 0
    
    self.isInit = false
end


function Behavior:Start()   
    if not self.gameObject.isDestroyed then -- true on the node placeholders, Start() is apparently called before the game object is actually destroyed
        if not self.isInit then
            self:Init()
        end
    end
end


function Behavior:SetMaxLinkCount( count )
    count = count or 4
    self.maxLinkCount = math.clamp( count, 1, 4 )
end


-- In practice, only called from a node placeholder Awake()
function Behavior:Init( colorName )
    if self.isInit == true then
        return
    end
    
    local rendererGO = self.gameObject:GetChild("Renderer")
    
    if colorName == "" or colorName == nil then
        if rendererGO.modelRenderer ~= nil and rendererGO.modelRenderer.model ~= nil then
           colorName = rendererGO.modelRenderer.model.name
        else
            error( "Node/Init(), no color name "..tostring(self.gameObject))   
        end
    end
    
    self.gameObject:RemoveTag(colorName)
    self.gameObject:AddTag(colorName)
    self.colorName = colorName
    
    self.color = ColorsByName[ colorName ]
    
    rendererGO.modelRenderer.color = self.color
    rendererGO:AddTag("node_renderer")
    rendererGO.OnMouseEnter = function() self:OnMouseEnter() end
    self.rendererGO = rendererGO
    
    ----------
    -- color Blind
    
    local numberGO = self.gameObject:GetChild("Color Blind")
    
    if Options.colorBlindModeActive == true then
        self.numberGO = numberGO
        numberGO.textRenderer.text = NumbersByColorName[ colorName ]
        rendererGO.child.modelRenderer.opacity = 0.5
    else
        numberGO:Destroy()
        rendererGO.child:Destroy()
    end
    
    ----------
    -- Link Queue
    -- The Link Queue chldren must be ordered from 4 (top) to 1 (bootom)
    
    self.linksQueue = self.gameObject:GetChild("Links Queue")
    local marks = self.linksQueue.children
    self.linksQueue.marks = {}
        
    for i=1, #marks do -- loop on children from 1 to 6
        local go = marks[i]
        if i <= self.maxLinkCount then
            table.insert( self.linksQueue.marks, go )
        else
            go:Destroy()
        end
    end
    self.linksQueue.marks = table.reverse( self.linksQueue.marks )
    
    ----------
    -- pillar
    
    self.pillarGO = self.gameObject:GetChild("Pillar")
    self.pillarGO.modelRenderer.color = self.color
    
    ----------
    -- get linkable nodes
    
    local offsets = { Vector3(-2, 0, 0), Vector3(2, 0, 0), Vector3(0, 0, -2), Vector3(0, 0, 2) }
    local position = self.gameObject.transform.position 
    
    for i=1, 4 do
        local positionToTest = (position + offsets[i]):ToString()
        local otherNode = nodesByPositions[ positionToTest ]
        if otherNode ~= nil then
            table.insertonce( self.linkableNodes, otherNode )
            table.insertonce( otherNode.s.linkableNodes, self.gameObject )
        end
    end
    
    nodesByPositions[ position:ToString() ] = self.gameObject
    
    --
    self.isInit = true
end


-- Called when left click or mouse hover the node's renderer.
-- See in Init() above.
function Behavior:OnMouseEnter()
     if self.isSelected == true or Game.levelEnded == true then -- click when mouse over and already selected
        return
    end
     
    local selectedNode = GameObject.GetWithTag("selected_node")[1]
    if selectedNode ~= nil and selectedNode ~= self.gameObject then -- there is a selected node and it's not this one        
        if
            #self.nodeGOs < self.maxLinkCount and  -- prevent the node to be connected if it has no more connoction to make
            table.containsvalue( AllowedConnectionsByColor[ selectedNode.s.colorName ], self.colorName ) and -- colors of the nodes can connect
            not table.containsvalue( selectedNode.s.nodeGOs, self.gameObject ) -- if they are not already connected
        then
            -- check there isn't a bar in between
            if selectedNode.s:CanLink( self.gameObject ) then
                selectedNode.s:Link( self.gameObject )
            end
        end
    end
   
    self:Select(true)
end


-- Called from OnMouseEnter() to selected this node
-- or from the newly selected node (to unselect this one).
function Behavior:Select( select )
    if select == nil then
        select = not self.isSelected
        -- false if true (un select if already selected)
        -- true if false (select if not already selected)
    elseif select == self.isSelected then
        return
    end
    
    if select == true then
        -- prevent the node to be selected if it has no more link to make
        if #self.nodeGOs >= self.maxLinkCount then
            return
        end
        
        self.pillarGO:Animate("opacity", 0.5, 0.5)
        self.isSelected = true
        
        local selectedNode = GameObject.GetWithTag("selected_node")[1]
        if selectedNode ~= nil and selectedNode ~= self.gameObject then
            selectedNode.s:Select(false)
        end
        self.gameObject:AddTag("selected_node")
    else

        self.pillarGO:Animate("opacity", 0.05, 0.5)
        self.isSelected = false
        self.gameObject:RemoveTag("selected_node")
    end
end


-- Called from OnMouseEnter()
-- Check there isn't a link or other node in between
function Behavior:CanLink( targetGO )   
    if table.containsvalue( self.linkableNodes, targetGO ) then
        -- both node can link a priori
        -- now check that there isn't a link in between        
        local linkRndrGOs = GameObject.GetWithTag("link_hitbox") 
        if #linkRndrGOs == 0 then
            return true
        end
        
        local selfPosition = self.gameObject.transform.position
        local targetPosition = targetGO.transform.position
        local direction = targetPosition - selfPosition
        
        local ray = Ray:New(selfPosition, direction:Normalized() )
        local hit = ray:Cast( linkRndrGOs, true )[1]
        
        if hit == nil or hit.distance > direction:GetLength() then -- note: direction:GetLength() always = 2
            return true
        end
    end
    return false
end


-- Called from OnMouseEnter()
function Behavior:Link( targetGO )
    local linkGO = Scene.Append("Entities/Link")   
    linkGO.parent = self.gameObject
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
            
            
            if not go.isHidden then
                --go:Display(0)
                
                --go:Animate("opacity", 0.5, 0.5, function(tweener) 
                    --tweener.target.opacity = 0 
                --end)
                go.displayAnimOriginalScale = go.displayAnimOriginalScale or go.transform.localScale
                if go.scaleAnim ~= nil then
                    go.scaleAnim:Destroy()
                end
                go.scaleAnim = go:Animate("localScale", Vector3(0, go.displayAnimOriginalScale.y, 0), 0.5)
                go.isHidden = true
            end
        else
            if go.isHidden == true then
                if go.scaleAnim ~= nil then
                    go.scaleAnim:Destroy()
                end
                go.scaleAnim = go:Animate("localScale", go.displayAnimOriginalScale, 0.5)
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
    self.rendererGO:RemoveTag()
    self:Select(false)
    
    self:UpdateLinkQueue(99) -- do as if the node had 4 links, hidding all the link marks

    --self.pillarGO.transform.localScale = 0 -- using the opacity is not enough as the last node get somehow automatically reselected
    self.pillarGO:Destroy()
    
    -- hide the numbers
    if self.numberGO ~= nil then
        self.numberGO.textRenderer.opacity = 0
    end
end

Daneel.Debug.RegisterScript(Behavior)
