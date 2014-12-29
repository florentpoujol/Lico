
function Behavior:Awake(s)
    if s ~= true then
        self:Awake(true)
        return
    end
    
    Scene.Append("Main/Background")
    self.uiMaskGO = Scene.Append("Main/UI Mask")
    
    --
    local iconRndr = GameObject.Get("Credits.Icon.Renderer")
    local window = GameObject.Get("Credits.Window")
    iconRndr:InitWindow(window, "mouseclick")
    InitIcons(iconRndr.parent)
    
    
    ----------
    -- start nodes
    local startGO = GameObject.Get("Start")
    
    self.startNodeGO = startGO:GetChild("Start Node")
    self.middleNodeGOs = startGO:GetChild("Middle Nodes").children
    self.endNodeGO = startGO:GetChild("End Node")
    
    -- set color
    local colorId = math.random(6)
    self.startNodeGO.modelRenderer.color = ColorsByName[ ColorList[ colorId ] ]
        
    self.middleNodeGOs[1].modelRenderer.color = ColorsByName[ ColorList[ colorId ] ]
    self.middleNodeGOs[1]:Display(false)
    
    if colorId == 6 then
        colorId = 1
    else
        colorId = colorId + 1
    end
    
    self.middleNodeGOs[2].modelRenderer.color = ColorsByName[ ColorList[ colorId ] ]
    self.middleNodeGOs[2]:Display(false) -- this one has an opacity < 1, use Display(false) to save whatever value the opacity set to
        
    self.endNodeGO.modelRenderer.color = ColorsByName[ ColorList[ colorId ] ]
    
    -- mouse input
    self.startNodeGO:AddTag("ui")
    self.startNodeGO.OnMouseEnter = function()
        self.startNodeGO.isSelected = true
    end
    
    self.endNodeGO:AddTag("ui")
    self.endNodeGO.OnMouseEnter = function()
        if self.startNodeGO.isSelected == true and not self.endNodeGO.isSelected then
            self.endNodeGO.isSelected = true
            
            self.middleNodeGOs[1]:Display()
            self.middleNodeGOs[2]:Display()
            
            self:GoToMainMenu(1)
        end
    end
        
    ----------
    -- cursor    
    self.cursorGO = startGO:GetChild("Cursor")
    self.cursorGO.modelRenderer.opacity = 0
    
    local cursorLocalPosition = self.cursorGO.transform.localPosition
    local cursorEndLocalPosition = Vector3(cursorLocalPosition )
    cursorEndLocalPosition.x = -cursorEndLocalPosition.x
    
    self.cursorGO.animation = function()       
        self.cursorGO:Animate("localPosition", cursorEndLocalPosition, 2.5, {
            easeType = "inOutSine",
            OnComplete = function()
                -- restart
                self.cursorGO.transform.localPosition = cursorLocalPosition
                Tween.Timer(0.5, self.cursorGO.animation)
            end
        })
        
        self.cursorGO:Animate("opacity", 1, 0.5)
        self.cursorGO:Animate("opacity", 0, 0.5, { delay = 2, startValue = 1 })
    end
    
    Tween.Timer(2, self.cursorGO.animation)

end


function Behavior:Start()
    -- hide the node marks
    local nodeGOs = GameObject.GetWithTag("node")
    for i=1, #nodeGOs do
        local node = nodeGOs[i]
        
        for j =1, #node.s.linksQueue.marks do
            node.s.linksQueue.marks[j].modelRenderer.model = nil
        end
    end
    
    --
    local nodeGOs = {}
    local nodesParent = GameObject.Get("Nodes")
    table.mergein( nodeGOs, nodesParent:GetChild("L", true).children )
    table.mergein( nodeGOs, nodesParent:GetChild("I", true).children )
    table.mergein( nodeGOs, nodesParent:GetChild("C", true).children )
    table.mergein( nodeGOs, nodesParent:GetChild("O", true).children )
    
    for i=1, #nodeGOs do
        local node = nodeGOs[i]
        local name = node.name
        
        if name == "C1" then
            node.s:Link( nodeGOs[i+1] )
            node.s:Link( nodeGOs[i+4] )
        elseif name == "O6" then
            node.s:Link( nodeGOs[i-5] )
        elseif name ~= "C4" and name ~= "L4" and name ~= "I1" and name ~= "C5" then
            node.s:Link( nodeGOs[i+1] )
        end
    end
end


function Behavior:GoToMainMenu( duration )
    self.uiMaskGO.s:Animate(1, duration or 0.5, function()
        Game.fromSplashScreen = true
        Scene.Load("Main/Main Menu")
    end )
end

Daneel.Debug.RegisterScript(Behavior)
