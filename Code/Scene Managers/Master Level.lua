
function Behavior:Awake()
    local bg = Scene.Append("Background")
    --local mask = bg:GetChild("Mask", true)
    --mask.modelRenderer.opacity = 0.6 -- makes the background slighly darker so that the nodes stand out more
    
    ---------
    local uiMaskGO = GameObject.Get("UI Mask")
    uiMaskGO.s:Start() -- call [UI Mask/Start] function right away because I need it now (to know which color is the background)
    uiMaskGO.s:Animate(1,0) -- makes the mask hide everything
    Tween.Timer(0.5, function() uiMaskGO.s:Animate(0,0.5) end) -- fade the mask out

    
    ----------
    -- Spawn level content
    
    local level = Game.levelToLoad or Levels[1]
    local content = Scene.Append( level.scenePath )
    
    -- reparent the nodes
    local nodes = content:GetChild("Nodes")
    nodes.parent = GameObject.Get("Nodes Parent")
    nodes.transform.localPosition = Vector3(0)
    nodes.transform.localEulerAngles = Vector3(0)
    
    
    local levelNameGO = GameObject.Get("Level Name")
    levelNameGO.textRenderer.text = level.name
    
    ----------
    -- Help/tutorial window
    
    local helpWindowGO = nil -- set below, used in Icons section
    
    local helpGO = content:GetChild("Help")
    if helpGO ~= nil then
        local cameraPH = helpGO:GetChild("Camera Placeholder")
        if cameraPH ~= nil then
            cameraPH:Destroy()
        end
        
        local iconPH = helpGO:GetChild("Icon Placeholder")
        if iconPH ~= nil then
            iconPH:Destroy()
        end
        
        local windowGO = helpGO:GetChild("Window")
        if windowGO ~= nil then
            helpWindowGO = windowGO
            windowGO.parent = GameObject.Get("UI.Help Window")
            windowGO.transform.localPosition = Vector3(0)
        end
    end

    ----------
    -- Icons
    
    local helpIconGO = GameObject.Get("Icons.Help.Renderer")
    
    if helpWindowGO ~= nil then
        helpIconGO:InitWindow(helpWindowGO, "mouseclick")
        helpIconGO:OnLeftClickReleased() -- display window
    else
        helpIconGO.parent:Destroy()
        helpIconGO = nil
    end
    
    InitIcons() -- here to be called after InitWindow()
    
    if helpWindowGO ~= nil then
        helpIconGO:Display(1) -- highlight the the help icon
    end
    
    --
    local nextIconGO = GameObject.Get("Icons.Next Level.Renderer")
    self.nextIconGO = nextIconGO
    nextIconGO.transform:MoveLocal(Vector3(0,0,10)) -- hide the icon (and the tooltip) until the level ends
    
    nextIconGO.OnLeftClickReleased = function(go)
        uiMaskGO.s:Animate(1,0.5, function()
            Scene.Load("Master Level")
        end )
    end
              
    if helpWindowGO == nil then
        nextIconGO.parent.transform:Move(Vector3(-5,0,0))
    end
    
    -- 
    local menuIconGO = GameObject.Get("Icons.Main Menu.Renderer")
    menuIconGO.OnLeftClickReleased = function(go)
        uiMaskGO.s:Animate(1,0.5, function()
            Scene.Load("Main Menu")
        end )
    end

    ----------
    -- End level
    
    Game.levelEnded = false
    Daneel.Event.Listen( "EndLevel", self.gameObject ) -- fired from [Node/CheckVictory]
    self.levelStartTime = os.clock()
    Game.deletedLinkCount = 0 -- updated in [Link/OnClick], used in EndLevel() below
    
    self.endLevelGO = GameObject.Get("End Level")
    self.endLevelGO.transform.localPosition = Vector3(0,-40,0)
    
    
     --
    self:UpdateLevelCamera()
    Daneel.Event.Listen("RandomLevelGenerated", function() self:UpdateLevelCamera() end )
    
    self.worldGO = GameObject.Get("World") -- also used in Update()
    self.worldGO.modelRenderer:Destroy()
    
    --
    UpdateUISize()
    
    self.frameCount = 0
end


function Behavior:UpdateLevelCamera()
   local nodes = GameObject.GetWithTag("node")
    local maxValue = 0
    for i, node in pairs(nodes) do       
        local value = node.transform.position.y
        if value > maxValue then
            maxValue = value
        end
    end

    local scale = math.ceil(maxValue + 1) * 2
    GameObject.Get("World Camera").camera.orthographicScale = math.max( scale, 5 ) -- min=10

    if Game.levelToLoad.name == "Random" then
        GameObject.Get("World Camera").camera.orthographicScale = 20
        --print("set camera")
    end
end


function Behavior:SpawnLeaf()
    local leaf = GameObject.New("", {
        parent = "Leaves",
        transform = {
            localPosition = Vector3(0),
            localScale = Vector3( math.randomrange(0.5,2), math.randomrange(0,2), math.randomrange(0.5,2) )
        },
        modelRenderer = {
            model = "Flat Nodes/"..ColorList[math.random(#ColorList)],
            opacity = math.randomrange(0.2,0.8)
        },
        tags = "leaf",
        
        frameSpawned = self.frameCount,
        lifeTime = 600, -- 10 sec
    } )
    
    leaf.rotation = Vector3( math.randomrange(0.1,0.5), math.randomrange(0.1,0.5), math.randomrange(0.1,0.5) )
    leaf.move = Vector3( math.randomrange(-0.1,0.1), math.randomrange(-0.1,0.1), 0 )
    
    leaf.transform:Move( -leaf.move:Normalized() * 30 )
end


function Behavior:Update()
    self.frameCount = self.frameCount + 1
    
    if Game.levelEnded then
        self.worldGO.transform:RotateLocalEulerAngles(Vector3(0,0.1,0))
        
    else
        if CS.Input.WasButtonJustReleased( "Escape" ) then
            local sn = GameObject.GetWithTag("selected_node")[1]
            if sn ~= nil then
                sn.s:Select(false)
            end
        end
        
        ----------
        -- leaves
        
        if self.frameCount % 90 == 0 then -- spawn one evry 1.5 sec
            self:SpawnLeaf()
        end
    
        local leaves = GameObject.GetWithTag("leaf")
        for i, leaf in pairs( leaves ) do
            leaf.transform:RotateLocalEulerAngles( leaf.rotation )
            leaf.transform:MoveLocal( leaf.move )
            
            if self.frameCount > leaf.frameSpawned + leaf.lifeTime then -- 10 second lifetime
                leaf:Destroy()
            end
        end
        
    end
end


-- Called when EndLevel event is Fired from [Node/CheckVictory]
function Behavior:EndLevel()
    Game.levelEnded = true
    
    local leaves = GameObject.GetWithTag("leaf")
    for i, leaf in pairs( leaves ) do
        leaf:Destroy()
    end
    
    -- next level
    if Game.levelToLoad.name ~= "Random" then
        local currentLevel = GetLevel( Game.levelToLoad.name )
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
    
    --self.nextIconGO.rendererGO:Display(true)
    self.nextIconGO:OnMouseEnter() -- makes the tooltip show so that the player nows what the new button is for
    self.nextIconGO.parent.transform:MoveLocal(Vector3(0,0,-10))
end
