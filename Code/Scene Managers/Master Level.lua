
MasterLevel = nil -- scripted behavior instance

function Behavior:Awake( s )
    if s ~= true then
        self:Awake(true)
        return
    end
    
    MasterLevel = self
    -- MasterLevel is accessed from the initfunction of the random level 
    -- and to call CheckVictory() from [Link/Init], when the link animation has completed
    
    SetRandomColors() -- set new random colors
    
    local bg = Scene.Append("Main/Background")
    bg.s:Init()
    
    local uiMaskGO = Scene.Append("Main/Background")
    uiMaskGO.s:Init(true)
    uiMaskGO.s:Animate(1,0) -- makes the mask hide everything
    Tween.Timer(1, function() uiMaskGO.s:Animate(0,0.5) end) -- now, the mask hides the whole level, wait 0.5sec to fade it out
    
    ----------
    -- Spawn level content
    
    Game.nodesByName = {} -- used in Nodes, leave it there
    
    Game.levelToLoad = Game.levelToLoad or Levels[1]
    local level = Game.levelToLoad -- Game.levelToLoad is set to one entry of the Levels table in a level cartridge OnLeftClickReleased event listener

    Game.nodesBySGridPositions = {}
    self.levelRoot = Scene.Append( level.scenePath )
    
    self.levelNameGO = GameObject.Get("Level Name")
    if not level.isRandom then
        self.levelNameGO.textRenderer.text = level.name
        self:ReparentNodes()
    end
    -- when level is random, reparenting will be done when the node have been generated in Generator.randomLevel.initFunction()

    ----------
    -- Help/tutorial window
    
    local helpWindowGO = nil -- set below, used in Icons section
    
    local helpGO = self.levelRoot:GetChild("Help")
    if helpGO ~= nil then
        local cameraPH = helpGO:GetChild("Camera Placeholder")
        if cameraPH ~= nil then
            cameraPH:Destroy()
        end
        
        local iconPH = helpGO:GetChild("Icon Placeholder")
        if iconPH ~= nil then
            iconPH:Destroy()
        end
        
        helpWindowGO = helpGO:GetChild("Window")
        if helpWindowGO ~= nil then
            GameObject.Get("Help Window Parent"):Append(helpWindowGO)
        end
    end

    ----------
    -- Icons
    
    local menuIconGO = GameObject.Get("Icons.Main Menu.Renderer")
    self.menuIconGO = menuIconGO -- used in EndLevel()
    
    if Game.levelToLoad.isRandom == true then
        self.menuIconGO.textRenderer.text = "#"
    end
    
    menuIconGO:AddEventListener( "OnLeftClickReleased", function(go)
        Daneel.Event.Fire( Game.levelToLoad, "OnEnd" )
        
        uiMaskGO.s:Animate(1,0.5, function()
            Scene.Load("Main/Main Menu")
        end )
    end )
    
    --
    local helpIconGO = GameObject.Get("Icons.Help.Renderer")
    
    if helpWindowGO ~= nil then
        helpIconGO:InitWindow(helpWindowGO, "mouseclick")
        local originGO = helpWindowGO.child -- "Origin" 
    else
        helpIconGO.parent:RemoveTag("icon")
        helpIconGO.parent:AddTag("inactive_icon")
    end
    
    --
    local nextIconGO = GameObject.Get("Icons.Next Level.Renderer")
    self.nextIconGO = nextIconGO -- used in EndLevel()
    
    if Game.levelToLoad.isRandom == true then
        nextIconGO.textRenderer.text = "%" -- "refresh" icon
        
        local tooltipTextGO = nextIconGO.parent:GetChild("Text", true) -- Icons.Next Level.Tooltip.Content.Text
        tooltipTextGO.textRenderer.text = "Generate new level"
    end
    
    nextIconGO:AddEventListener( "OnLeftClickReleased", function(go)
        uiMaskGO.s:Animate(1,0.5, function()
            Scene.Load( Scene.current )
        end )
    end )
    
    InitIcons()
    
    --
    if helpWindowGO ~= nil then
        -- makes the "Help" tooltip appear a few secnds after the beginning of the level, 
        -- so that players notice the icon and the help they can get
        local tooltip = helpIconGO.parent:GetChild("Tooltip")
        Tween.Timer(2, function()
            tooltip:Display()
        end)
        
        -- reposition the help window at 
        --helpWindowGO.child.hud.position = Vector2(0,40)
    end
     
    ----------
    -- End of level
    
    Game.levelEnded = false
    Daneel.Event.Listen( "EndLevel", self.gameObject ) -- fired from CheckVictory()
    self.levelStartTime = os.clock()
     
    ----------
    
    local randomGeneratorMask = GameObject.Get("Random Generator Mask")
    
    if Game.levelToLoad.isRandom == true then
        randomGeneratorMask:GetChild("Model").transform.localScale = Vector3(500,500,0.1)
        
        Daneel.Event.Listen("RandomLevelGenerated", function()
            randomGeneratorMask:Destroy()
        end)
        
        self.progressbarGO = GameObject.Get("Bars.Front")
        self.progressbarGO:AddComponent("ProgressBar", {
            minLength = 0,
            maxLength = 28,
            value = 0,
        } )
    else
        randomGeneratorMask:Destroy()
    end
    
    ----------
    
    self.worldGO = GameObject.Get("World") -- also used in Update()
    --self.worldGO:GetChild("Placeholder"):Destroy()
    self.worldGOEndLevelRotation = Vector3(0,0.1,0)
    
    UpdateUISize()
    
    if not level.isRandom then
        self:UpdateLevelCamera() 
    end
    -- when random level, is done from Generator.randomLevel.initFunction()
    
    SoundManager.PlayMusic()
end


function Behavior:Start()    
    Daneel.Event.Fire( Game.levelToLoad, "OnStart" )
    
    if Game.levelToLoad.isRandom then
        self.progressbarGO.progressBar.maxValue = Generator.nodesCount
    end
end


-- Reparent the nodes from the level content's root to the world's node parent
-- Called from Awake() or Generator.initFunction()
function Behavior:ReparentNodes()
    local nodes = self.levelRoot:GetChild("Nodes")
    nodes.parent = GameObject.Get("World.Nodes Parent")
    nodes.transform.localPosition = Vector3(0)
    nodes.transform.localEulerAngles = Vector3(0)
end


-- Updates the World camera's orthographic scale so that the whole level (not more, not less) just fit in the viewport
-- Nodes must have been reparented with ReparentNodes() before.
-- Called from Awake() or Generator.rendomLevel.initFunction()
function Behavior:UpdateLevelCamera()
   local nodes = GameObject.GetWithTag("node")
    local maxValue = 0
    for i, node in pairs(nodes) do       
        local value = math.abs( node.transform.position.y )
        if value > maxValue then
            maxValue = value
        end
    end
    
    local scale = math.ceil(maxValue + 1) * 2

    GameObject.Get("World Camera").camera.orthographicScale = math.max( 6, scale ) -- min=6
end


local maxCooldown = 2 -- frames
local coroutineCooldown = maxCooldown
-- this makes the coroutine only resume every X frames 
-- to prevent a noticeable lag with the background colors
-- note: the lag still happens when there is a lot of nodes

local mazeDebugCooldown = 0
local linksDebugCooldown = 0

function Behavior:Update()
    if Game.levelEnded == true then
        self.worldGO.transform:RotateLocalEulerAngles(self.worldGOEndLevelRotation)
    else
        if CS.Input.WasButtonJustReleased( "Escape" ) then
            local sn = GameObject.GetWithTag("selected_node")[1]
            if sn ~= nil then
                sn.s:Select(false)
            end
        end      
    end
    
    if Generator.coroutine ~= nil then
        coroutineCooldown = coroutineCooldown - 1
        if coroutine.status(Generator.coroutine) ~= "dead" then
            if coroutineCooldown <= 0 then
                coroutineCooldown = maxCooldown
                coroutine.resume(Generator.coroutine)
                
                self.progressbarGO.progressBar.value = #GameObject.GetWithTag("node")
            end
        else
            Generator.coroutine = nil
        end
        
        --[[if CS.Input.WasButtonJustPressed("F2") then
            if coroutine.status(Generator.coroutine) ~= "dead" then
                coroutine.resume(Generator.coroutine)
                self.progressbarGO.progressBar:UpdateValue( #GameObject.GetWithTag("node") )
                print(#GameObject.GetWithTag("node"))
            else
                Generator.coroutine = nil
            end
        end]]
    end
    
    
    linksDebugCooldown = linksDebugCooldown - 1
    if CS.Input.WasButtonJustPressed( "F2" ) then
        if linksDebugCooldown > 0 then
            local nodes = GameObject.GetWithTag("node")
            for i=1, #nodes do
                nodes[i].s:DebugLinkableNodes( not nodes[i].s.debugLinkableNodes )
            end            
        end
        linksDebugCooldown = 20
    end
    
    mazeDebugCooldown = mazeDebugCooldown - 1
    if CS.Input.WasButtonJustPressed( "F3" ) then
        if mazeDebugCooldown > 0 then
            local arrows = GameObject.GetWithTag("debug_maze")
            local opacity = 0
            if #arrows > 0 and arrows[1].modelRenderer.opacity == 0 then
                opacity = 1
            end
            for i=1, #arrows do
                arrows[i].modelRenderer.opacity = opacity
            end            
        end
        mazeDebugCooldown = 20
    end
end


-- Called from [Link.Init] when a link animation has completed
function Behavior:CheckVictory()
    if Game.levelEnded == true then
        return
    end
    
    local nodes = GameObject.GetWithTag("node")
    
    for i, node in pairs( nodes ) do
        -- quick-search for nodes without links
        if #node.s.linkGOs == 0 then
            return
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
        return
    end
    
    -- By now all nodes are OK and linked together
    Daneel.Event.Fire("EndLevel") -- catched by [Master Level]'s, all node's and all link's EndLevel()
end


-- Called when EndLevel event is fired from CheckVictory()
function Behavior:EndLevel()
    Game.levelEnded = true
    
    Daneel.Event.Fire( Game.levelToLoad, "OnEnd" )
    
    -- next level
    if not Game.levelToLoad.isRandom then
        local currentLevel = GetLevel( Game.levelToLoad.name )
        if currentLevel ~= nil then -- is nil for random level
            if not currentLevel.isCompleted then
                currentLevel.isCompleted = true
                SaveCompletedLevels()
            end
            
            local nextLevel = nil
            for i=1, #Levels do
                local level = Levels[i]
                if not level.isCompleted and level.id > currentLevel.id then
                    nextLevel = level
                    break
                end
            end
            
            if nextLevel == nil then
                -- all levels must have been completed already, get next level
                nextLevel = GetLevel( currentLevel.id + 1 )
            end
            
            -- if nextLevel is still nill, 
            --if nextLevel == nil then
                --nextLevel = Levels[ math.random( #Levels ) ]
            ---end
            Game.levelToLoad = nextLevel
        end
    end
    
    local iconGO = nil
    
    if Game.levelToLoad ~= nil then
        local nextIconParent = self.nextIconGO.parent -- self.nextIconGO is the renderer, with the actual icon
        nextIconParent:RemoveTag("inactive_icon")
        InitIcons( nextIconParent )
    
        iconGO = self.nextIconGO
    else
        iconGO = self.menuIconGO    
    end
    
    if iconGO ~= nil then
        Tween.Timer(1.5, function()
            iconGO:FireEvent("OnMouseEnter", iconGO)
        end)
    end
end

Daneel.Debug.RegisterScript(Behavior)
