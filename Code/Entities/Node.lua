--[[PublicProperties
color string ""
maxLinkCount number 0
requiredLinkCount number 0
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
        
        self.maxLinkCount = math.max( self.maxLinkCount, self.requiredLinkCount )
        if self.maxLinkCount == 0 then
            self.maxLinkCount = 4
        end
        realNode.s.maxLinkCount = self.maxLinkCount
        realNode.s.requiredLinkCount = self.requiredLinkCount
                
        if self.color == "" and self.gameObject.modelRenderer ~= nil then
            self.color = self.gameObject.modelRenderer.model.name
        end
        if self.color ~= "" then
            realNode.s:Init(self.color)
        end
        
        self.gameObject:Destroy()
        return
    end
    
    ----------

    self.gameObject.s = self
    self.gameObject:AddTag("node")
    self.childrenByName = self.gameObject.childrenByName

    self.isSelected = false  

    self.linkableNodes = {}
    self.nodeGOs = {} -- nodes this node is connected to -- filled in Link()
    self.linkGOs = {}
    
    self.frameCount = 0
end


-- In practice, only called from a node placeholder Awake()
function Behavior:Init( color )
    self.gameObject:RemoveTag(self.color)
    self.gameObject:AddTag(color)
    self.color = color
    
    self.shape = "Square"
    
    local rendererGO = self.gameObject:GetChild("Renderer")
    rendererGO.modelRenderer.model = "Flat Nodes/"..color
    
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
        numberGO.textRenderer.text = table.getkey( ColorList, self.color )
    else
        numberGO:Destroy()
    end
    
    ----------
    -- link marks
    
    local linkmarksGO = self.gameObject:GetChild("Links Queue")
    self.linkQueue = linkmarksGO
    local linkMarksAnimOffset = 0.2
    local op = { 0.8, 0.6, 0.4, 0.2 }
    local op = { 0.15, 0.3, 0.45, 0.6 }
    for i=1, self.maxLinkCount do
        --[[local linkMark = linkmarksGO:Append( "Entities/Flat Link Mark" )
        linkMark.transform:MoveLocal(Vector3(0,-i*0.1,0))
        linkMark.modelRenderer.model = "Flat Nodes/"..color
        --linkMark.modelRenderer.opacity = 0.6
        
        local mask = linkMark:GetChild("Mask")
        mask.modelRenderer.opacity = op[i]
        ]]
    end
    --linkmarksGO.transform:MoveLocal(Vector3(0,-0.5,0))
--    linkmarksGO.transform.localScale = ""
    
    ----------
    -- overlay
    
    self.overlayGO = self.gameObject:GetChild("Overlay")
    self.overlayGO.displayScale = self.overlayGO.transform.localScale
    self.overlayGO.transform.localScale = Vector3(1)
    
    local rendererGO = self.overlayGO:GetChild("Renderer")
    rendererGO.modelRenderer.model = "Flat Nodes/"..color
end


--------------------------------------

function Behavior:Start()
    if not self.gameObject.isDestroyed then -- true on the node placeholders, Start() is apparently called before the game object is actually destroyed
        
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
        --print( table.containsvalue( AllowedConnectionsByColor[ selectedNode.s.color ], self.color ) )
        --print(not table.containsvalue( selectedNode.s.nodeGOs, self.gameObject ))
        
        if 
            (self.maxLinkCount <= 0 
            or (self.maxLinkCount > 0 and #self.nodeGOs < self.maxLinkCount) ) -- prevent the node to be connected if it has no more connoction to make
            and
            
            table.containsvalue( AllowedConnectionsByColor[ selectedNode.s.color ], self.color ) -- colors of the nodes can connect
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
    end
    
    local animationTime = 0.1
    
    if select then
        -- prevent the node to be selected if it has no more link to make
        if self.maxLinkCount > 0 and #self.nodeGOs >= self.maxLinkCount then
            return
        end
        
        if self.overlayGO.animTweener ~= nil then
            self.overlayGO.animTweener:Destroy()
        end
        self.overlayGO.animTweener = self.overlayGO:Animate("localScale", self.overlayGO.displayScale, animationTime)

        self.isSelected = true
        
        local selectedNode = GameObject.GetWithTag("selected_node")[1]
        if selectedNode ~= nil and selectedNode ~= self.gameObject then
            selectedNode.s:Select(false)
        end
        self.gameObject:AddTag("selected_node")
    else
        if self.overlayGO.animTweener ~= nil then
            self.overlayGO.animTweener:Destroy()
        end
        self.overlayGO.animTweener = self.overlayGO:Animate("localScale", Vector3(1), animationTime)

        self.isSelected = false
        self.gameObject:RemoveTag("selected_node")
    end
end


-- Check there isn't a link or other node in between
function Behavior:CanLink( targetGO )  
do return true end
    -- check that the intersection point between the (potential) link line and al other links
    local selfPosition = self.gameObject.transform.position
    local otherPosition = targetGO.transform.position 
    
    local x1 = selfPosition.x
    local y1 = selfPosition.y
    local point1 = Vector2(x1,y1)
    
    local x2 = otherPosition.x
    local y2 = otherPosition.y
    local point2 = Vector2(x2,y2)  
    
    local linkGOs = GameObject.GetWithTag( "link" )
    for i, go in pairs(self.linkGOs) do
        table.removevalue( linkGOs, go )
    end
    for i, go in pairs(targetGO.s.linkGOs) do
        table.removevalue( linkGOs, go )
    end
    for i, linkGO in pairs( linkGOs ) do
        local x3 = linkGO.s.nodePositions[1].x
        local y3 = linkGO.s.nodePositions[1].y
        local point3 = Vector2(x3,y3)
        
        local x4 = linkGO.s.nodePositions[2].x
        local y4 = linkGO.s.nodePositions[2].y
        local point4 = Vector2(x4,y4)
        
        -- formula for line-line intersection from: 
        -- http://en.wikipedia.org/wiki/Line%E2%80%93line_intersection
        
        -- first, check if the lines are parralell
        local a = x1 - x2
        local b = y1 - y2
        local c = x3 - x4
        local d = y3 - y4
        local denominator = a * d - b * c
        
        if denominator ~= 0 then
            local e = (x1 * y2 - y1 * x2)
            local f = (x3 * y4 - y3 * x4)
            
            -- i for intersection
            local xi = ( e*c - a*f ) / denominator
            local yi = ( e*d - b*f ) / denominator
            local pointi = Vector2(xi,yi)
            
            -- now check if the point is inside both segments which means the links actually intersects.
            -- the point is inside a segment if the distance to the two points of the segment is no greater than the distance between the two points
            
            local link1SqrLength = (point1 - point2):GetSqrLength()
            local point1SqrDistance = (point1 - pointi):GetSqrLength()
            local point2SqrDistance = (point2 - pointi):GetSqrLength()
            
            local link2SqrLength = (point3 - point4):GetSqrLength()
            local point3SqrDistance = (point3 - pointi):GetSqrLength()
            local point4SqrDistance = (point4 - pointi):GetSqrLength()
            
            if 
                point1SqrDistance <= link1SqrLength and point2SqrDistance <= link1SqrLength and
                point3SqrDistance <= link2SqrLength and point4SqrDistance <= link2SqrLength
            then
                return false
            end
        end
    end
    
    -- check there isn't another node in between, too
    local ray = Ray:New(otherPosition, (selfPosition - otherPosition):Normalized() )

    local nodeGOs = GameObject.GetWithTag("node_renderer")
    if self.rendererGO ~= nil then
        table.removevalue( nodeGOs, self.rendererGO )
    end
    if targetGO.s.rendererGO ~= nil then
        table.removevalue( nodeGOs, targetGO.s.rendererGO )
    end
    
    local hit = ray:Cast( nodeGOs, true )[1]

    if hit == nil or hit.distance^2 > (selfPosition - otherPosition):GetSqrLength() then
        return true
    end
    return false
end

local linkPositionOffset = 0.5


function Behavior:Link( targetGO )
    local linkGO = Scene.Append("Entities/Link")
    linkGO.parent = "Links Parent"
    linkGO.transform.localEulerAngles = Vector3(0)
    
    local selfPosition = self.gameObject.transform.position
    local otherPosition = targetGO.transform.position
    
    local middlePosition = (selfPosition + otherPosition) / 2
    linkGO.transform.position = middlePosition
    --print(selfPosition, middlePosition, otherPosition)
    
    local direction = otherPosition - selfPosition
    local linkLength = direction:Length() - 1.5 -- -1 = - 0.5 * 2 = the length of the actual gap between the nodes renderer
    
    ----------
    -- rotate link if it is vertical
    local selfLocalPos = self.gameObject.transform.localPosition
    local otherLocalPos = targetGO.transform.localPosition
    
    if self.gameObject.transform.localPosition.x == targetGO.transform.localPosition.x then
        linkGO.transform.localEulerAngles = Vector3(0,90,0)
    end
    
    linkGO.transform.localScale = Vector3(0.8,1,0.8)

    linkGO.s:SetColor( self.color, targetGO.s.color )
    
    --
    linkGO.s.nodeGOs = { self.gameObject, targetGO }
    linkGO.s.nodePositions = { selfPosition, otherPosition } -- used in CanLink()
    
    table.insert( self.nodeGOs, targetGO )
    table.insert( targetGO.s.nodeGOs, self.gameObject )
    
    table.insert( self.linkGOs, linkGO )
    table.insert( targetGO.s.linkGOs, linkGO )
    
    --
    --self:UpdateLinkMarks()
    --targetGO.s:UpdateLinkMarks()
    
    if not Game.randomLevelGenerationInProgress then
        --soundLinkSuccess:Play()
    end
    
    --self:CheckVictory()
end

-- Called from Link() above and [Link/OnClick()]
function Behavior:UpdateLinkMarks()
    for i=1, #self.linkMarkGOs do
        if i <= #self.linkGOs then
            self.linkMarkGOs[i].modelRenderer.opacity = 0
        else
            self.linkMarkGOs[i].modelRenderer.opacity = 0.8
        end
    end
    
    if #self.nodeGOs >= self.maxLinkCount or #self.nodeGOs >= self.requiredLinkCount then
        self:Select(false)
    end
end


function Behavior:CheckAllNodesAreLinked()
    local nodes = GameObject.GetWithTag( "node" )
    
    -- quick-search for nodes without links
    for i, node in pairs( nodes ) do
        if #node.s.linkGOs == 0 then
            return false
        end
    end
    
    -- using simplified BFS (breadth-first search), check that all nodes are actually connected together
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
    
    if #visited == #nodes then
        return true
    end
    return false
end


function Behavior:CheckVictory()
    -- check that all nodes have all their link
    local nodes = GameObject.GetWithTag("node")
        
    for i, node in pairs(nodes) do
        if node.s.requiredLinkCount > 0 and #node.s.nodeGOs < node.s.requiredLinkCount then
            return false            
        end
    end
        
    local allNodesLinked = self:CheckAllNodesAreLinked()
    
    if allNodesLinked then
    
        -- check that all nodes have all their link
        --[[local nodes = GameObject.GetWithTag("node")
        local notCompletedNodeGOs = {}
        
        for i, node in pairs(nodes) do
            if node.s.maxLinkCount > 0 and #node.s.nodeGOs < node.s.maxLinkCount then
                table.insert( notCompletedNodeGOs, node )             
            end
        end
        
        if #notCompletedNodeGOs > 0 then
            for i, node in pairs(notCompletedNodeGOs) do
                if node.s.highlightTweener == nil then
                    node.s:Highlight()
                end
            end
            return false
        end]]
    
        Daneel.Event.Fire("EndLevel") -- catched by [Master Level/EndLevel]
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

    -- fade out link marks
    if Game.levelEnded and self.frameCount <= linkMarksFadeOutFrames then
        local opacity = math.lerp( 1, 0, self.frameCount/linkMarksFadeOutFrames )

        for i=1, self.maxLinkCount do
            if self.linkMarkGOs[i].modelRenderer.opacity ~= 0 then
                self.linkMarkGOs[i].modelRenderer.opacity = opacity
            end
        end
        
        self.frameCount = self.frameCount + 1
    end

end