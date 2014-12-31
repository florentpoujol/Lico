--[[PublicProperties
colorName string ""
maxLinkCount number 4
/PublicProperties]]


local nodesBySGridPositions = {} -- Vector3:ToString() = GameObject

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
        
        realNode.s.gridPosition = self.gameObject.gridPosition -- set by the [Node Position Finder] script
        
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
    self.gridPosition = Vector2(0)
    
    self.nodeGOs = {} -- nodes this node is connected to -- filled in Link()
    self.linkGOs = {}
    
    self.isInit = false
end


function Behavior:Start()   
    if not self.gameObject.isDestroyed and not self.isInit then -- true on the node placeholders, Start() is apparently called before the game object is actually destroyed
        self:Init()
    end
end


function Behavior:Update()
    if self.isSelected == true and CS.Input.WasButtonJustPressed("LeftMouse") then
        -- check that the mouse is not over a link
        -- if not, then deselect node
        local links = GameObject.GetWithTag("link_renderer")
        for i=1, #links do 
            if links[i].isMouseOver == true then
                return
            end
        end
        self:Select(false)
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
    
    local gridOffsets = { x = Vector2(-1,0), y = Vector2(0,-1) }
    
    local gridSize = Game.levelToLoad.gridSize or Vector2(1,1)
    if Game.levelToLoad.isRandom == true then
        gridSize = Generator.gridSize
    end
    local maxNodeCount = math.max( self.gridPosition.x, self.gridPosition.y )

    for xOrY, gridOffset in pairs( gridOffsets ) do
        for i=1, self.gridPosition[ xOrY ] do -- limits the number of iteration
                
            local gridPositionToTest = self.gridPosition + gridOffset
            if gridPositionToTest[ xOrY ] < 1 then
                -- outside the grid
                break
            end

            local otherNode = nodesBySGridPositions[ gridPositionToTest:ToString() ]
            if otherNode ~= nil then
                table.insert( self.linkableNodes, otherNode )
                table.insert( otherNode.s.linkableNodes, self.gameObject )
                break
            else
                gridOffset = gridOffset + gridOffsets[ xOrY ]
            end
        end
    end
    
    nodesBySGridPositions[ self.gridPosition:ToString() ] = self.gameObject
    
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
            if selectedNode.s:CanLinkTo( self.gameObject ) then
                selectedNode.s:LinkTo( self.gameObject )
            end
        end
    end
    
    -- When the mouse hover the last node,
    -- the link is created and the level completed/ended
    -- before the node is actually selected
    if Game.levelEnded == false then
        self:Select(true)
    end
end


-- Called from OnMouseEnter() to selected this node
-- or from the newly selected node (to unselect this one).
function Behavior:Select( select )
    if Game.levelEnded == true then
        return
    end
    
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
function Behavior:CanLinkTo( targetGO )   
    if table.containsvalue( self.linkableNodes, targetGO ) then
        -- both node can link a priori
        -- now check that there isn't a link in between        
        local linkRndrGOs = GameObject.GetWithTag("link_renderer") 
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
function Behavior:LinkTo( targetGO )
    local linkGO = Scene.Append("Entities/Link")   
    linkGO.s:Init( self.gameObject, targetGO )
    
    self:RegisterLink( linkGO, targetGO )
    targetGO.s:RegisterLink( linkGO, self.gameObject )
end


-- Called from 
-- [Node/LinkTo] or
-- [Link/OnClick] when a link is removed
function Behavior:RegisterLink( linkGO, nodeGO, remove )
    local func = table.insert
    if remove == true then
        func = table.removevalue
    end
    func( self.nodeGOs, nodeGO )
    func( self.linkGOs, linkGO )
    
    self:UpdateLinkQueue()
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
    
    if self.isSelected == true and nodeLinkCount >= self.maxLinkCount then
        self:Select(false)
    end
end


-- Called on all nodes when EndLevel event is fired from one node's CheckVictory()
function Behavior:EndLevel()
    -- prevent nodes to be selected
    self.rendererGO:RemoveTag()
    self:Select(false)
    
    self:UpdateLinkQueue(99) -- do as if the node had 4 links, hidding all the link marks

    self.pillarGO:Destroy()
    
    -- hide the numbers
    if self.numberGO ~= nil then
        self.numberGO.textRenderer.opacity = 0
    end
    
    nodesBySGridPositions = {}
end

Daneel.Debug.RegisterScript(Behavior)
