
function Behavior:Awake()
    local bg = GameObject.New("Background")
    local mask = bg:GetChild("Mask", true)
    mask.modelRenderer.opacity = 0.6 -- makes the background slighly darker so that the nodes stand out more
    
    ----------
    -- spawn level content
    
    local level = Game.levelToLoad or Levels[1]
    local content = Scene.Append( level.scenePath )
    
    --
    local nodes = content:GetChild("Nodes")
    nodes.parent = GameObject.Get("Nodes Parent")
    nodes.transform.localPosition = Vector3(0)
    
    --
    local helpWindowGO = nil -- used below on Icons section
    
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
    
    --
    if level.tutoText ~= nil then
        --self:SetupTuto( level )
    end
    
    self:UpdateLevelCamera()
    Daneel.Event.Listen("RandomLevelGenerated", function() self:UpdateLevelCamera() end )
    
    -- update the orthographic scale of the world camera so that the whole level but not more is visible
    
    ----------
    -- Icons
    
    local helpGO = GameObject.Get("Icons.Help")
    helpGO:InitWindow("Tooltip", "mouseover", "ui")
    
    if helpWindowGO ~= nil then
        helpGO:InitWindow(helpWindowGO, "mouseclick")
    end
    
    InitIcons() -- in [Helpers]
    
    
    ----------
    -- end level
    
    Game.levelEnded = false
    Daneel.Event.Listen( "EndLevel", self.gameObject ) -- fired from [Node/CheckVictory]
    self.levelStartTime = os.clock()
    Game.deletedLinkCount = 0 -- updated in [Link/OnClick], used in EndLevel() below
    
    self.endLevelGO = GameObject.Get("End Level")
    self.endLevelGO.transform.localPosition = Vector3(0,-40,0)
    
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
        node.s.colorGO:RemoveTag("node_model")
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


function Behavior:SetupTuto( level )
    local tutoUICameraGO = GameObject.New("Levels/Tuto UI")
    tutoUICameraGO.transform.position = Vector3(-500,0,0)
    
    local uiGO = tutoUICameraGO:GetChild("Tuto UI")
    local infoGO = uiGO:GetChild("Info")
    local iconGO = infoGO:GetChild("Icon")
    iconGO:AddTag("tutoui")
    iconGO:InitWindow("Tooltip", "mouseclick")
    
    local textGO = infoGO:GetChild("Text Area", true)
    textGO:AddComponent("TextArea", {
        font = "Calibri",
        newLine = "\n",
        alignment = "left",
        lineHeight = 2.5/0.2,
        areaWidth = 57/0.2,
        wordWrap = true,
        text = level.tutoText    
    })
    
    if level.scenePath == "Levels/Tuto 1" then
        -- put the fnodes in a perfect circle
        local radius = 5
        local nodes = GameObject.Get("Tuto 1 Nodes").children
        
        -- equation of a circle
        -- x=rcosθ, y=rsinθ
        local angle = 0
        local angleOffset = 360/#nodes

        for i, go in ipairs( nodes ) do
            go.transform.localPosition = Vector3(
                radius * math.cos( math.rad( angle ) ),
                radius * math.sin( math.rad( angle ) ),
                0
            )
            angle = angle + angleOffset
        end
    
    elseif level.scenePath == "Levels/Tuto 2" then
        -- put the fnodes in a perfect circle
        local radius = 5
        local nodes = GameObject.Get("Tuto 2 Nodes").children
        table.remove( nodes ) -- remove "Others" game object
        
        -- equation of a circle
        -- x=rcosθ, y=rsinθ
        local angle = 75
        local angleOffset = 360/#nodes

        for i, go in ipairs( nodes ) do
            go.transform.localPosition = Vector3(
                radius * math.cos( math.rad( angle ) ),
                radius * math.sin( math.rad( angle ) ),
                0
            )
            angle = angle + angleOffset
        end
    end
end

