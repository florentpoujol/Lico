
function Behavior:Awake()
    local bg = Scene.Append("Background")
    local mask = bg:GetChild("Mask", true)
    --mask.modelRenderer.opacity = 0.6 -- makes the background slighly darker so that the nodes stand out more
    
    ----------
    -- Spawn level content
    
    local level = Game.levelToLoad or Levels[1]
    local content = Scene.Append( level.scenePath )
    
    -- reparent the nodes
    local nodes = content:GetChild("Nodes")
    nodes.parent = GameObject.Get("Nodes Parent")
    nodes.transform.localPosition = Vector3(0)
    
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

    local helpIconGO = GameObject.Get("Icons.Help")
    helpIconGO:InitWindow("Tooltip", "mouseover", "ui")
    
    InitIcons() -- in [Helpers]
    -- in this case, must be called after the Tooltip have been init.
    
    if helpWindowGO ~= nil then
        
        helpIconGO:InitWindow(helpWindowGO, "mouseclick")
        
        helpIconGO:OnClick() -- display the help window
        helpIconGO:OnMouseEnter() -- highlight the icon
        helpIconGO:OnMouseExit() -- hide the Tooltip
        
        -- can't decide if simuling mouse envents like that is smart or ugly
    else
        helpIconGO:Destroy()
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
    
    -- update the orthographic scale of the world camera so that the whole level but not more is visible
    
    
    --
    UpdateUISize()
end


function Behavior:UpdateLevelCamera()
   local nodes = GameObject.GetWithTag("node")
    local maxY = 0
    for i, node in pairs(nodes) do
        local y = math.abs( node.transform.position.y )
        if y > maxY then
            maxY = y
        end
    end

    GameObject.Get("World Camera").camera.orthographicScale = math.ceil(maxY + 1) * 2
    
    if Game.levelToLoad.name == "Random" then
        GameObject.Get("World Camera").camera.orthographicScale = 20
        --print("set camera")
    end
end


function Behavior:Update()
    if CS.Input.WasButtonJustReleased( "Escape" ) then
        local sd = GetSelectedNodes()
        if sd then
            sd.s:Select(false)
        end
    end
end


-- called when EndLevel event is Fired from [Node/CheckVictory]
function Behavior:EndLevel()
    Game.levelEnded = true
    
    -- prevent nodes to be selected
    local nodes = GameObject.GetWithTag("node")
    for i, node in pairs( nodes ) do
        node.s.rendererGO:RemoveTag("node_renderer")
        node.s:Select(false)
    end
    
    --
    Tween.Tweener(self.endLevelGO.transform, "localPosition", Vector3(0), 1.5, {
        easeType = "outElastic",
    } )
    
    --[[self.endLevelGO:Animate("localPosition", Vector3(0), 1, {
        easeType = "outElastic",
    } )]] 
    -- Animate doesn't work with "localPosition"
    
    local gos = self.endLevelGO:GetChild("Content").childrenByName
    
    --
    local timeGO = gos.Time.child
    local time = os.clock() - self.levelStartTime
    local minutes = math.floor( time/60 )
    if minutes < 10 then
        minutes = "0"..minutes
    end
    local seconds = math.round( time % 60 )
    if seconds < 10 then
        seconds = "0"..seconds
    end
    if time < 60 then
        timeGO.textRenderer.text = seconds.."s"
    else
        timeGO.textRenderer.text = minutes.."m "..seconds.."s"
    end
    
    gos.Link.child.textRenderer.text = #GameObject.GetWithTag( "link" )
    gos["Broken Link"].child.textRenderer.text = Game.deletedLinkCount
    
    -- next level
    if Game.levelToLoad.name == "Random" then
        gos["Next Level Help"].textRenderer.text = ""
        gos["Next Level"].textRenderer.text = ""
        
        local playGO = gos.Play
        playGO.textRenderer.text = "0" -- refresh
        local textGO = playGO:GetChild("Text", true)
        textGO.textRenderer.text = "Generate again"

    else
        local currentLevel = GetLevel( Game.levelToLoad.name )
        currentLevel.isCompleted = true
        SaveCompletedLevels()
        
        local nextLevel = nil
        for i, level in ipairs( Levels ) do
            if not level.isCompleted then
                nextLevel = level
                break
            end
        end
        if nextLevel == nil then
            nextLevel = Levels[ math.random( #Levels ) ]
        end
        Game.levelToLoad = nextLevel
        gos["Next Level"].textRenderer.text = nextLevel.name
    end
end
