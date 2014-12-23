
function Behavior:Awake(s)
    if s ~= true then
        self:Awake(true)
        return
    end
    
    Scene.Append("Main/Background")
    self.uiMaskGO = Scene.Append("Main/UI Mask")  
end


function Behavior:Start()
    local nodeGOs = GameObject.GetWithTag("node")
    for i=1, #nodeGOs do
        local node = nodeGOs[i]
        
        for j =1, #node.s.linksQueue.marks do
            node.s.linksQueue.marks[j].modelRenderer.model = nil
        end
    end
    
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


function Behavior:GoToMainMenu()
    self.uiMaskGO.s:Animate(1,0.5, function()
        Game.fromSplashScreen = true
        Scene.Load("Main/Main Menu")
    end )
end


function Behavior:Update()
    if CS.Input.WasButtonJustPressed("LeftMouse") then
        self:GoToMainMenu()
    end
end

Daneel.Debug.RegisterScript(Behavior)
