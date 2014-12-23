
function Behavior:Awake( s )
    if s ~= true then
        self:Awake(true)
        return
    end
    
    SetRandomColors() -- set new random colors
    
    Scene.Append("Main/Background")

    local uiMaskGO = GameObject.Get("UI Mask")
    uiMaskGO.s:Start() -- call [UI Mask/Start] function right away because I need it now (to know which color is the background)
    uiMaskGO.s:Animate(1,0) -- makes the mask hide everything
    Tween.Timer(1, function() uiMaskGO.s:Animate(0,0.5) end) -- now, the mask hides the whole level, wait 0.5sec to fade it out
    
    ----------
    -- Spawn level content
    
    Game.nodesByName = {} -- used in Nodes, leave it there
    
    local level = Game.levelToLoad or Levels[1] -- Game.levelToLoad is set to one entry of the Levels table in a level cartridge OnLeftClickReleased event listener
    self.levelNameGO = GameObject.Get("Level Name")
    
    self.levelRoot = Scene.Append( level.scenePath )
    --self.levelRoot.transform.position = Vector3(0)
    
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
            
            -- add a hud component on the help window's content game object
            
        end
    end

    ----------
    -- Icons
    
    local menuIconGO = GameObject.Get("Icons.Main Menu.Renderer")
    menuIconGO:AddEventListener( "OnLeftClickReleased", function(go)
        uiMaskGO.s:Animate(1,0.5, function()
            Scene.Load("Main/Main Menu")
        end )
    end )
    
    --
    local helpIconGO = GameObject.Get("Icons.Help.Renderer")
    
    if helpWindowGO ~= nil then
        helpIconGO:InitWindow(helpWindowGO, "mouseclick")
        local contentGO = helpWindowGO.child 
        if contentGO.hud == nil then
            GUI.Hud.New(contentGO)
        end
        contentGO.hud.position = Vector2(0,40) 
    else
        helpIconGO.parent:RemoveTag("icon")
        helpIconGO.parent:AddTag("inactive_icon")
    end
    
    --
    local nextIconGO = GameObject.Get("Icons.Next Level.Renderer")
    self.nextIconGO = nextIconGO -- used in EndLevel()
    
    if Game.levelToLoad.isRandom == true then
        nextIconGO.textRenderer.text = "0" -- "refresh" icon
        
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
    Daneel.Event.Listen( "EndLevel", self.gameObject ) -- fired from [Node/CheckVictory]
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
end


function Behavior:Start()    
    local func = Game.levelToLoad.initFunction 
    if func ~= nil then
        func( self )
    end
    
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


-- Called when EndLevel event is fired from [Node/CheckVictory]
function Behavior:EndLevel()
    Game.levelEnded = true
    
    -- next level
    if not Game.levelToLoad.isRandom then
        local currentLevel = GetLevel( Game.levelToLoad.name )
        if currentLevel ~= nil then -- is nil for random level
            currentLevel.isCompleted = true
            SaveCompletedLevels()
            
            local nextLevel = nil
            for i, level in ipairs( Levels ) do
                if not level.isCompleted and level.id > currentLevel.id then
                    nextLevel = level
                    break
                end
            end
            if nextLevel == nil then
                nextLevel = Levels[ math.random( #Levels ) ]
            end
            Game.levelToLoad = nextLevel
        end
    end
    
    local nextIconParent = self.nextIconGO.parent -- self.nextIconGO is the renderer, with the actual icon
    nextIconParent:RemoveTag("inactive_icon")
    InitIcons( nextIconParent )
    
    --local tooltip = nextIconParent:GetChild("Tooltip")
    self.nextIconGO:FireEvent("OnMouseEnter", self.nextIconGO)
end

Daneel.Debug.RegisterScript(Behavior)
