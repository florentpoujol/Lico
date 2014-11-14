
function Behavior:Awake()
    local bg = Scene.Append("Main/Background")
    
    ---------
    
    SetRandomColors() -- set new random colors
    
    local uiMaskGO = GameObject.Get("UI Mask")
    uiMaskGO.s:Start() -- call [UI Mask/Start] function right away because I need it now (to know which color is the background)
    uiMaskGO.s:Animate(1,0) -- makes the mask hide everything
    Tween.Timer(0.5, function() uiMaskGO.s:Animate(0,0.5) end) -- now, the mask hides the whole level, wait 0.5sec to fade it out
    
    ----------
    -- Spawn level content
    
    Game.nodesByName = {} -- filled in [Node/Awake], used in [Master Level/ShowHint]
    
    local level = Game.levelToLoad or Levels[1]
    local levelNameGO = GameObject.Get("Level Name")
    levelNameGO.textRenderer.text = level.name
    
    local levelContent = Scene.Append( level.scenePath )
    
    -- reparent the nodes
    local nodes = levelContent:GetChild("Nodes")
    nodes.parent = GameObject.Get("Nodes Parent")
    nodes.transform.localPosition = Vector3(0)
    nodes.transform.localEulerAngles = Vector3(0)
    
    ----------
    -- Help/tutorial window
    
    local helpWindowGO = nil -- set below, used in Icons section
    
    local helpGO = levelContent:GetChild("Help")
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
            windowGO.parent = GameObject.Get("Help Window Parent")
            windowGO.transform.localPosition = Vector3(0)
            
            local contentGO = windowGO.child
            if contentGO.hud == nil then
                contentGO:AddComponent("Hud", { position = Vector2(0,40) } )
            end
        end
    end

    ----------
    -- Icons
    
    local menuIconGO = GameObject.Get("Icons.Main Menu.Renderer")
    menuIconGO.OnLeftClickReleased = function(go)
        uiMaskGO.s:Animate(1,0.5, function()
            Scene.Load("Main/Main Menu")
        end )
    end
    
    --
    local helpIconGO = GameObject.Get("Icons.Help.Renderer")
    
    if helpWindowGO ~= nil then
        helpIconGO:InitWindow(helpWindowGO, "mouseclick")
    else
        helpIconGO.parent:RemoveTag("icon")
        helpIconGO.parent:AddTag("inactive_icon")
    end
    
    
    --
    --[[
    local hintIconGO = GameObject.Get("Icons.Hint.Renderer")
    hintIconGO.parent:Destroy()
    hintIconGO = nil
    
    self.remainingHintCount = level.hintCount or 0
    if self.remainingHintCount > 0 then
        self.levelPaths = level.paths
    
        local oOnLeftClickReleased = hintIconGO.OnLeftClickReleased
        hintIconGO.OnLeftClickReleased = function(go)
            oOnLeftClickReleased(go)
            self:ShowHint()
        end
        
        if helpIconGO == nil then
            hintIconGO.parent.transform:MoveLocal(Vector3(-5,0,0))
        end
    else
        hintIconGO.parent:Destroy()
        hintIconGO = nil
    end
    ]]
    --
    local nextIconGO = GameObject.Get("Icons.Next Level.Renderer")
    self.nextIconGO = nextIconGO
    
    nextIconGO.OnLeftClickReleased = function(go)
        uiMaskGO.s:Animate(1,0.5, function()
            Scene.Load( Scene.current )
        end )
    end

    
    InitIcons() -- here to be called after InitWindow()
    
    if helpWindowGO ~= nil then
        local tooltip = helpIconGO.parent:GetChild("Tooltip")
        Tween.Timer(1.5, function()
            tooltip:Display()
        end)
        
        local coords = GameObject.Get("UI Camera").camera:WorldToScreenPoint( helpIconGO.transform.position )
        -- Note: Camera.Project() returns a bad Vector
        local beforePos = helpWindowGO.child.hud.position
        helpWindowGO.child.hud.position = Vector2(coords)
        helpWindowGO.child.hud.savedPosition = Vector2(coords)
                
        local oOnDisplay = helpWindowGO.OnDisplay
        helpWindowGO.OnDisplay = function(go)
            if oOnDisplay ~= nil then
                oOnDisplay(go)
            end

            local contentGO = go.child
            if go.isDisplayed then
                print(go.child.hud.position, go.child.hud.savedPosition)
            else
                
            end
        end
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


-- Called from Awake()
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


-- Called the Hint icon OnLeftMouseReleased event
-- Game.nodesByHint table is set in Awake(), filled in [Node/Awake]
function Behavior:ShowHint()   
    if self.remainingHintCount > 0 then
        local nodeNames = self.levelPaths[ math.random( #self.levelPaths ) ]
        local i = 0
        
        while i < 1000 do
            i = i + 1
            local startId = math.random( #nodeNames - 1 ) -- don't select the last item
            print( startId, nodeNames[ startId ] )
            local startNode = Game.nodesByName[ nodeNames[ startId ] ]
            local endNode = Game.nodesByName[ nodeNames[ startId + 1 ] ]
            
            if not table.containsvalue( startNode.s.nodeGOs, endNode ) then
                startNode.s:Link( endNode )
                break
            end
        end
        
        -- 08/10/2014 i can reach values of 20+ at the end of level 1.1 and 2.2
        
        -- TODO : don't rely on random tries
        -- split the paths with more than 2 item in multiple 2 items paths in Level script before runtime
        -- and remove the paths who have been discovered
        
        -- TODO : don't select and remove from possible paths links the player has already created
        
        -- TODO : hide Hint icon when no more hint available ?
        
        if i > 100 then
            print("MasterLevel:ShowHint() has looped "..i.." times !")
        end
        
        self.remainingHintCount = self.remainingHintCount - 1
    end
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
            Scene.Append("Entities/Leaf")
        end        
    end
end


-- Called when EndLevel event is Fired from [Node/CheckVictory]
function Behavior:EndLevel()
    Game.levelEnded = true
    
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
    self.nextIconGO.parent:RemoveTag("inactive_icon")
    local tooltip = self.nextIconGO.parent:GetChild("Tooltip")
    InitIcons( self.nextIconGO.parent )
    tooltip:Display()
    
    --self.nextIconGO:OnMouseEnter() -- makes the tooltip show so that the player nows what the new button is for
    --self.nextIconGO.parent.transform:MoveLocal(Vector3(0,0,-10))
end
