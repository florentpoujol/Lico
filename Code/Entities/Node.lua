--[[PublicProperties
color string ""
maxLinkCount number 0
/PublicProperties]]

local soundLinkSuccess = CS.FindAsset("Link Success", "Sound")
local soundNoAction = CS.FindAsset("No Action", "Sound")

function Behavior:Awake()
    -- if the game object only has a modelRenderer, it is a placeholder to be replaced by the real node
    self.overlayGO = self.gameObject:GetChild("Overlay")
    if self.overlayGO == nil then
        local realNode = Scene.Append("Entities/Node", self.gameObject.parent)
        realNode.transform.localPosition = self.gameObject.transform.localPosition
        
        if self.color == "" and self.gameObject.modelRenderer ~= nil then
            self.color = self.gameObject.modelRenderer.model.name
        end
        if self.color ~= "" then
            realNode.s:SetColor(self.color)
        end
    
        realNode.s.maxLinkCount = self.maxLinkCount
        realNode.s:InitLinksCounter() -- always call it, even if maxLinkCount is 0 (it will hide the links counter) 
        
        self.gameObject:Destroy()
        return
    end
        

    self.gameObject.s = self
    self.gameObject:AddTag("node")
    self.childrenByName = self.gameObject.childrenByName

    self:Select(false) -- set self.isSelected
    
    self.nodeGOs = {} -- nodes this node is connected to -- filled in Link()
    self.linkGOs = {}
end


-- in practice, only called from a node placeholder Awake()
function Behavior:InitLinksCounter()
    local linkGO = self.gameObject:GetChild("Links")
    
    if self.maxLinkCount > 0 then
        --linkGO.transform.localScale = 1
        
        local children = linkGO.childrenByName

        for i=self.maxLinkCount+1, 5 do
            children[tostring(i)].modelRenderer.opacity = 0
        end

        if self.maxLinkCount % 2 == 0 then
            linkGO.transform.localPosition = Vector3(0,-0.085,0)
        end
    
    elseif linkGO ~= nil then
        linkGO:Destroy()
    end
end


-- in practice, only called from a node placeholder Awake()
function Behavior:SetColor( color )
    self.gameObject:RemoveTag(self.color)
    self.gameObject:AddTag(color)
    self.color = color
        
    local colorGO = self.gameObject:GetChild("Color")
    --colorGO.modelRenderer.model = "Nodes/"..color
    colorGO.mapRenderer:LoadNewMap( function(map)
        map:SetBlockAt(0,0,0, BlockIdsByColor[ color ])
    end)
    
    colorGO:AddTag("node_model")
    colorGO.OnClick = function() self:OnClick() end
    colorGO.OnMouseOver = function()
        if not self.isSelected and not Game.levelEnded then
            self:OnClick()
        end
    end
    
    self.colorGO = colorGO
end


function Behavior:OnClick()
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
                    soundNoAction:Play()
                end
            end
        else
            if not Game.randomLevelGenerationInProgress then
                soundNoAction:Play()
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
        if selectedNode ~= nil then
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

    local nodeGOs = GameObject.GetWithTag( "node_model" )
    if self.colorGO ~= nil then
        table.removevalue( nodeGOs, self.colorGO )
    end
    if targetGO.s.colorGO ~= nil then
        table.removevalue( nodeGOs, targetGO.s.colorGO )
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
    
    local selfPosition = self.gameObject.transform.position
    local otherPosition = targetGO.transform.position 
    local direction = otherPosition - selfPosition
    local linkLength = direction:Length()
    
    linkGO.transform:Move( direction:Normalized() * 0.3 )
    
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
    
    linkGO.transform.localScale = Vector3(0.3,0.3, linkLength-0.6 )

    linkGO.s:SetColor( self.color, targetGO.s.color )
    
    --
       
    linkGO.s.nodeGOs = { self.gameObject, targetGO }
    linkGO.s.nodePositions = { selfPosition, otherPosition } -- used in CanLink()
    
    table.insert( self.nodeGOs, targetGO )
    table.insert( targetGO.s.nodeGOs, self.gameObject )
    
    table.insert( self.linkGOs, linkGO )
    table.insert( targetGO.s.linkGOs, linkGO )
    
    --
    if self.maxLinkCount > 0 and #self.nodeGOs >= self.maxLinkCount then
        self:Select(false)
    end
    
    if not Game.randomLevelGenerationInProgress then
        soundLinkSuccess:Play()
    end
    
    self:CheckVictory()
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
        
        for i, connectedDot in pairs( node.s.nodeGOs ) do
            if not connectedDot.wasVisited and not connectedDot.willBeVisited then
                table.insert( toBeVisited, connectedDot )
                connectedDot.willBeVisited = true
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
    local nodes = GameObject.GetWithTag("node")
    
    -- check that all nodes have all their link
    for i, node in pairs(nodes) do
        if node.s.maxLinkCount > 0 and #node.s.nodeGOs < node.s.maxLinkCount then
            return false
        end
    end

    local allNodesLinked = self:CheckAllNodesAreLinked()
    
    if allNodesLinked then
        Daneel.Event.Fire("EndLevel") -- catched by [Master Level/EndLevel]
    end
end
