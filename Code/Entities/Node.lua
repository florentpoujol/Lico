--[[PublicProperties
color string ""
maxLinkCount number 0
requiredLinkCount number 0
/PublicProperties]]

--local soundLinkSuccess = CS.FindAsset("Link Success", "Sound")
--local soundNoAction = CS.FindAsset("No Action", "Sound")

function Behavior:Awake()
    -- if the game object only has a modelRenderer, it is a placeholder to be replaced by the real node
    self.overlayGO = self.gameObject:GetChild("Overlay")
    if self.overlayGO == nil then
        local realNode = Scene.Append("Entities/Node", self.gameObject.parent)
        realNode.transform.localPosition = self.gameObject.transform.localPosition
        
        self.maxLinkCount = math.max( self.maxLinkCount, self.requiredLinkCount )
        if self.maxLinkCount == 0 then
            self.maxLinkCount = 6
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
    

    self.gameObject.s = self
    self.gameObject:AddTag("node")
    self.childrenByName = self.gameObject.childrenByName

    self:Select(false) -- set self.isSelected
    
    self.nodeGOs = {} -- nodes this node is connected to -- filled in Link()
    self.linkGOs = {}
    
    self.frameCount = 0
end


-- In practice, only called from a node placeholder Awake()
function Behavior:Init( color )
    self.gameObject:RemoveTag(self.color)
    self.gameObject:AddTag(color)
    self.color = color
    
    self.shape = "Circle"
    --[[if self.maxLinkCount > 0 then
        if self.maxLinkCount == 3 then
            self.shape = "Triangle"
        elseif self.maxLinkCount == 4 then
            self.shape = "Square"
        end
    end]]
    
    local rendererGO = self.gameObject:GetChild("Renderer")
    rendererGO.mapRenderer:LoadNewMap( function(map)
        map:SetBlockAt(0,0,0, BlockIds[ self.shape ][ color ])
    end)
    
    rendererGO:AddTag("node_renderer")
    rendererGO.OnClick = function() self:OnClick() end
    rendererGO.OnMouseOver = function()
        if not self.isSelected and not Game.levelEnded then
            self:OnClick()
        end
    end
    
    self.rendererGO = rendererGO
    
    --
    -- max and required links
    
    
    --
    --[[
    self.overlayGO = self.gameObject:GetChild("Overlay")
    self.overlayGO.mapRenderer:LoadNewMap( function(map)
        map:SetBlockAt(0,0,0, BlockIds[ self.shape ].White)
    end)
    ]]
    
    --[[self.overlayGO.mapRenderer.map = nil
    self.overlayGO:Set({ modelRenderer = { model = "Big Overlay"} })
    self.overlayGO.transform.eulerAngles = Vector3(0)
    self.overlayGO.transform.localScale = Vector3(0.012, 0.012, 1)
    ]]
    
    --
    self:InitLinkMarks()
end

-- called from Init()
function Behavior:InitLinkMarks()
    
    self.linkMarksGO = self.gameObject:GetChild("Link Marks") -- used below and in Update()

    local maxLinkCount = self.maxLinkCount
    local requiredLinkCount = self.requiredLinkCount
    --if self.requiredLinkCount > 0 then
        --linkCount = self.requiredLinkCount
    --end
    
    -- default linkCount is 6 (default self.maxLinkCount)
    local angleOffset = 360/maxLinkCount
    local angle = 0
    self.linkMarkGOs = {} -- use in UpdateLinkMarks()
    
    for i=1, maxLinkCount do
        angle = angle + angleOffset
        local x, y = GetPositionOnCircle( 0.6, angle )
        
        local modelPath = "Cubes/White"
        if requiredLinkCount > 0 then
            modelPath = "Cubes/Black"
            requiredLinkCount = requiredLinkCount - 1
        end
        
        local linkMark = GameObject.New("Link Mark", {
            parent = self.linkMarksGO,
            modelRenderer = { 
                model = modelPath,
                opacity = 0.8
            },
            transform = {
                localPosition = Vector3( x, y, 0 ),
                localScale = Vector3( 0.5, 0.5, 0.1 )
            }
        } )
        
        linkMark.transform:LookAt( self.linkMarksGO.transform.position )
        table.insert( self.linkMarkGOs, linkMark )
    end
    
    self.linkMarksGO.transform:RotateLocalEulerAngles(Vector3(0,0,math.random(0,359)))
    

    --[[local linkGO = Scene.Append("Entities/Links")
    linkGO.parent = self.gameobject
    
    if self.maxLinkCount > 0 then
        --linkGO.transform.localScale = 1
        
        local children = linkGO.childrenByName

        for i=self.requiredLinkCount+1, 5 do
            children[tostring(i)].modelRenderer.opacity = 0
        end

        if self.requiredLinkCount % 2 == 0 then
            linkGO.transform.localPosition = Vector3(0,-0.085,0)
        end
    
    elseif linkGO ~= nil then
        linkGO:Destroy()
    end
    
    self.linkMarkGOs = linkGO.children]]
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
    
    if select then
        -- prevent the node to be selected if it has no more link to make
        if self.maxLinkCount > 0 and #self.nodeGOs >= self.maxLinkCount then
            return
        end
        
        self.overlayGO:Display()     
        self.isSelected = true
        
        local selectedNode = GameObject.GetWithTag("selected_node")[1]
        if selectedNode ~= nil and selectedNode ~= self.gameObject then
            selectedNode.s:Select(false)
        end
        self.gameObject:AddTag("selected_node")
    else
        self.overlayGO:Display(false)
        
        self.isSelected = false
        self.gameObject:RemoveTag("selected_node")
    end
end


-- Check there isn't a link or other node in between
function Behavior:CanLink( targetGO )  
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


function Behavior:Link( targetGO )
    local linkGO = Scene.Append("Entities/Link")
    linkGO.parent = self.gameObject
    linkGO.transform.localPosition = Vector3(0,0,0)
    linkGO.parent = "Links Parent"
    
    local selfPosition = self.gameObject.transform.position
    local otherPosition = targetGO.transform.position 
    local direction = otherPosition - selfPosition
    local linkLength = direction:Length()
    
    local linkPositionOffset = 0.7
    linkGO.transform:Move( direction:Normalized() * linkPositionOffset )
    
    linkGO.transform:LookAt( otherPosition )
    local angles = linkGO.transform.localEulerAngles
    local y = math.round( angles.y )
    
    -- x direction
    -- -90 = totally bottom
    -- <0  toward bottom
    -- 0 = totally flat
    -- >0 toward up
    -- 90 = totally up   
    
    -- y  direction
    -- 0 vertical
    -- -90 toward right
    -- 90 toward left
    
    
    if y == 0 then
        -- totally upward link
        if angles.x < 0 then -- toward bottom
            angles.z = 270 
        elseif angles.x > 0 then -- toward up
            angles.z = 90
        end
        linkGO.transform.localEulerAngles = angles
    elseif y == 90 then
        angles.z = -180
        linkGO.transform.localEulerAngles = angles
    end
    
    linkGO.transform.localScale = Vector3(0.1,0.5, linkLength - linkPositionOffset*2 )

    linkGO.s:SetColor( self.color, targetGO.s.color )
    
    --
    linkGO.s.nodeGOs = { self.gameObject, targetGO }
    linkGO.s.nodePositions = { selfPosition, otherPosition } -- used in CanLink()
    
    table.insert( self.nodeGOs, targetGO )
    table.insert( targetGO.s.nodeGOs, self.gameObject )
    
    table.insert( self.linkGOs, linkGO )
    table.insert( targetGO.s.linkGOs, linkGO )
    
    --
    self:UpdateLinkMarks()
    targetGO.s:UpdateLinkMarks()
    
    if not Game.randomLevelGenerationInProgress then
        --soundLinkSuccess:Play()
    end
    
    self:CheckVictory()
end

-- Called from Link() above and [Link/OnClick()]
function Behavior:UpdateLinkMarks()
    --if self.requiredLinkCount > 0 then
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
    --end
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


-- Highlight the node y scaling up and down the overlay.
-- used to highlight nodes with less links than required
--[[function Behavior:Highlight( highlight )
    if highlight == nil then
        highlight = true
    end
    
    if highlight then
        
    else
        
    end
end]]


local linkMarksRotation = Vector3(0,0,0.7)
local linkMarksFadeOutFrames = 60 -- 1 sec

function Behavior:Update()
    -- rotate link marks when selected
    if self.isSelected then
        self.linkMarksGO.transform:RotateLocalEulerAngles( linkMarksRotation )
    end
    
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
            self.linkMarkGOs[i].modelRenderer.opacity = opacity
        end
        
        self.frameCount = self.frameCount + 1
    end

end