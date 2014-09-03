--[[PublicProperties
color string "Default"
connectionCount number 0
/PublicProperties]]

local soundLinkSuccess = CS.FindAsset("Link Success", "Sound")
local soundNoAction = CS.FindAsset("No Action", "Sound")

function Behavior:Awake()
    self.gameObject.s = self
    self.gameObject:AddTag("node")
    self.childrenByName = self.gameObject.childrenByName
    
    --
    self.overlayGO = self.gameObject:GetChild("Overlay")
    if self.overlayGO == nil then
        self.overlayGO = GameObject.New("Overlay", {
            parent = self.gameObject, -- was origin instead of self.gameObejct
            transform = {
                localPosition = Vector3(0),
                localScale = Vector3(1.2,1.2,0.1)
            },
            modelRenderer = { model = "Cubes/White" } 
        } )
    end
    
    ----------
    -- links
    
    self.linkCount = 0
    self:SetLinksCount()

    --
    self.isSelected = false
    self:Select(false)
    
    if (self.color == "" or self.color == "Default") and self.gameObject.modelRenderer then
        self.color = self.gameObject.modelRenderer.model.name
    end
    if self.color ~= "" and self.color ~= "Default" then
        self:SetColor( self.color )
    end
    
    self.nodeGOs = {} -- nodes this node is connected to -- filled in Connect()
    self.linkGOs = {}
end


function Behavior:Start()
    
end

function Behavior:SetLinksCount()
    local linkGO = self.gameObject:GetChild("Links")
    
    if self.linkCount > 0 then
        if linkGO == nil then
            linkGO = GameObject.New("Entities/Links")
            linkGO.parent = self.gameObject
            linkGO.transform.localPosition = Vector3(0)
        end
        linkGO.transform.localScale = 1
        
        local children = linkGO.childrenByName

        for i=self.linkCount+1, 5 do
            children[tostring(i)].modelRenderer.opacity = 0
        end

        if self.linkCount % 2 == 0 then
            linkGO.transform.localPosition = Vector3(0,-0.085,0)
        end
    
    elseif linkGO ~= nil then
        linkGO.transform.localScale = 0
    end
end

function Behavior:SetColor( color )
    self.gameObject:RemoveTag(self.color)
    
    local colorGO = self.gameObject:GetChild("Color")
    
    if colorGO == nil then
        colorGO = GameObject.New("Color", {
            parent = self.gameObject,
            transform = {
                localPosition = Vector3(0),
            },
            modelRenderer = {
                model = "Nodes/"..color
            },
        })
        
        self.gameObject.modelRenderer:Destroy()
    else

        colorGO.modelRenderer.model = "Nodes/"..color
    end
    colorGO:AddTag("node_model")
    colorGO.OnClick = function() self:OnClick() end
    self.colorGO = colorGO
    self.color = color
    
    self.gameObject:AddTag(color)
end


function Behavior:OnClick()
    local selectedNode = GameObject.GetWithTag("selected_node")[1]
    if selectedNode ~= nil and selectedNode ~= self.gameObject then -- there is a selected node and it's not this one
        --print(selectedDot, self.gameObject)
        --print((self.linkCount <= 0 or (self.linkCount > 0 and #self.nodeGOs < self.linkCount) ))
        --print( table.containsvalue( AllowedConnectionsByColor[ selectedDot.s.color ], self.color ) )
        --print(not table.containsvalue( selectedDot.s.nodeGOs, self.gameObject ))
        
        if 
            (self.linkCount <= 0 
            or (self.linkCount > 0 and #self.nodeGOs < self.linkCount) ) -- prevent the node to be connected if it has no more connoction to make
            and
            
            table.containsvalue( AllowedConnectionsByColor[ selectedDot.s.color ], self.color ) -- colors of the nodes can connect
            and
            
            not table.containsvalue( selectedDot.s.nodeGOs, self.gameObject ) -- if they are not already connected
        then
            
            -- check there isn't a bar in between
            if selectedDot.s:CanConnect( self.gameObject ) then
                selectedDot.s:Connect( self.gameObject )
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
        if self.linkCount > 0 and #self.nodeGOs >= self.linkCount then
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


-- check there isn't a bar in between
function Behavior:CanConnect( targetGO )
    -- check there isn't a bar in between
    local selfPosition = self.gameObject.transform.position
    local otherPosition = targetGO.transform.position 
    local ray = Ray:New(otherPosition, (selfPosition - otherPosition):Normalized() )
    
    local barGOs = GameObject.GetWithTag( "link" )
    -- remove from barGOs the links of the selected node
    for i, go in pairs(self.linkGOs) do
        table.removevalue( barGOs, go )
    end
    for i, go in pairs(targetGO.s.linkGOs) do
        table.removevalue( barGOs, go )
    end
    
    table.mergein( barGOs, GameObject.GetWithTag( "node_model" ) )
    if self.colorGO then
        table.removevalue( barGOs, self.colorGO )
    end
    if targetGO.s.colorGO then
        table.removevalue( barGOs, targetGO.s.colorGO )
    end

    
    local hit = ray:Cast( barGOs, true )[1]

    if hit == nil or hit.distance > (selfPosition - otherPosition):GetLength() then
        return true
    end
    return false
end


function Behavior:Connect( targetGO )
    local barGO = GameObject.New("Entities/Link")
    barGO.parent = self.gameObject
    barGO.transform.localPosition = Vector3(0,0,0)
    
    local selfPosition = self.gameObject.transform.position
    local otherPosition = targetGO.transform.position 
    local direction = otherPosition - selfPosition
    local linkLength = direction:Length()
    
    barGO.transform:Move( direction:Normalized() * 0.5 )
    
    barGO.transform:LookAt( otherPosition )
    local angles = barGO.transform.localEulerAngles
    local y = math.round( angles.y )
    
    if y == 90 then
        -- links that goes upward
        angles.z = -180
        barGO.transform.localEulerAngles = angles
    elseif y == 0 then
        -- totally vertical link
        angles.z = 90 -- totally wild guess
        barGO.transform.localEulerAngles = angles
    end
    
    barGO.transform.localScale = Vector3(0.3,0.3, linkLength-1 )

    barGO.s:SetColor( self.color, targetGO.s.color )
    
    --
       
    barGO.s.nodeGOs = { self.gameObject, targetGO }
    
    table.insert( self.nodeGOs, targetGO )
    table.insert( targetGO.s.nodeGOs, self.gameObject )
    
    table.insert( self.linkGOs, barGO )
    table.insert( targetGO.s.linkGOs, barGO )
    
    --
    if self.linkCount > 0 and #self.nodeGOs >= self.linkCount then
        self:Select(false)
    end
    
    if not Game.randomLevelGenerationInProgress then
        soundLinkSuccess:Play()
    end
    
    self:CheckVictory()
end


function Behavior:CheckAllDotsConnected()
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
        if node.s.linkCount > 0 and #node.s.nodeGOs < node.s.linkCount then
            return false
        end
    end

    local allDotsConnected = self:CheckAllDotsConnected()
    
    if allDotsConnected then
        Daneel.Event.Fire("EndLevel")
    end
end
