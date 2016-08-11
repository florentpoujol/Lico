
function Behavior:Awake(s)
    if s ~= true then
        self:Awake(true)
        return
    end
    
    local bg = Scene.Append("Main/Background")
    bg.s:Init()
    
    self.uiMaskGO = Scene.Append("Main/Background")
    self.uiMaskGO.s:Init(true)
    self.uiMaskGO.s:Animate(0,0)    
    
    local iconRndr = GameObject.Get("Credits.Icon.Renderer")
    iconRndr:InitWindow("Credits.Window", "mouseclick")
    InitIcons(iconRndr.parent)
    
    
    -----------
    --[[
    local p = CS.CreateGameObject("P")
    local c1 =  CS.CreateGameObject("C1", p)
    local c2 = CS.CreateGameObject("C2", p)
    
    for i, child in ipairs(p:GetChildren()) do
        print("children", i, child:GetName())
    end
    print(p:GetChild("C1"):GetName(), p:GetChild("C2"):GetName())
    
    CS.Destroy(c1)
    
    for i, child in ipairs(p:GetChildren()) do
        print("children", i, child:GetName())
    end
    print(p:GetChild("C1"):GetName(), p:GetChild("C2"):GetName())]]
    
    ----------
    -- Game title
    
    Game.isOnSplashScreen = true
    GameObject.Get("Game Title Parent"):Append("Entities/Game Title")
    
    -- hide the node marks
    local nodeGOs = GameObject.GetWithTag("node")
    for i=1, #nodeGOs do
        nodeGOs[i].s:HideLinkMarks()
    end
    
    --
    local nodeGOs = {}
    local nodesParent = GameObject.Get("Nodes")
    table.mergein( nodeGOs, nodesParent:GetChild("L").children )
    table.mergein( nodeGOs, nodesParent:GetChild("I").children )
    table.mergein( nodeGOs, nodesParent:GetChild("C").children )
    table.mergein( nodeGOs, nodesParent:GetChild("O").children )
    
    for i=1, #nodeGOs do
        local node = nodeGOs[i]
        node.s.rendererGO:RemoveTag()
        local name = node.name
        
        
        if name == "C1" then
            node.s:LinkTo( nodeGOs[i+1] )
            node.s:LinkTo( nodeGOs[i+4] )
        elseif name == "O6" then
            node.s:LinkTo( nodeGOs[i-5] )
        elseif name ~= "C4" and name ~= "L4" and name ~= "I1" and name ~= "C5" then
            node.s:LinkTo( nodeGOs[i+1] )
        end
    end
    
    
    ----------
    -- start nodes
    
    local startGO = GameObject.Get("Start")
    startGO:Append("Entities/Start Game")
    
    startGO = startGO.child -- "Start Game" game object
    local children = startGO.children
    self.startNodeGO = children[2]
    self.endNodeGO = children[3]
    
    self.startNodeGO.transform.localScale = Vector3(1.5,1,1.5)
    self.endNodeGO.transform.localScale = Vector3(1.5,1,1.5)
    
    self.startNodeGO.s:HideLinkMarks()
    self.endNodeGO.s:HideLinkMarks()
    
    local function onNewLink(link)
        local scale = Vector3(1)
        link.transform.localScale = Vector3(1,1,0)
        link:Animate("localScale", scale, 0.4, { 
            easeType = "inExpo",
            OnComplete = function()
                Tween.Timer(1, function()
                    self:GoToMainMenu(1.5)
                end)
            end
        })
    end
    
    self.startNodeGO.OnNewLink = onNewLink
    self.endNodeGO.OnNewLink = onNewLink
    
    self.startNodeGO.s.linkableNodes = { self.endNodeGO }
    self.endNodeGO.s.linkableNodes = { self.startNodeGO }
           
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
        
        self.cursorGO:Animate("opacity", 0.7, 0.5)
        self.cursorGO:Animate("opacity", 0, 0.5, { delay = 2, startValue = 1 })
    end
    
    Tween.Timer(2, self.cursorGO.animation)
end


function Behavior:GoToMainMenu( maskDuration )
    Game.isOnSplashScreen = false
    
    self.uiMaskGO.s:Animate(1, maskDuration or 0.5, function()    
        Scene.Load("Main/Main Menu")
    end )
end

Daneel.Debug.RegisterScript(Behavior)
