function Behavior:Awake()
    self.gameObject.s = self
    
    self.completedGO = self.gameObject:GetChild("Completed")
    
    local bgGO = self.gameObject:GetChild("Background")
    local color = AllowedConnectionsByColor.White[ math.random(2, #AllowedConnectionsByColor.White) ]
    bgGO.modelRenderer.model = "Nodes/"..color
end

function Behavior:SetData( level )
    local children = self.gameObject.childrenByName
    local levelNameGO = children["Level Name"]
    levelNameGO.textRenderer.text = level.name
    levelNameGO.levelName = level.name
    
    levelNameGO:AddTag("ui")
    levelNameGO.OnMouseEnter = function(go)
        go.textRenderer.text = "          Play          "
    end
    levelNameGO.OnMouseExit = function(go)
        go.textRenderer.text = go.levelName
    end
    
    levelNameGO.OnClick = function(go)
        Game.levelToLoad = level
        Scene.Load("Master Level")
    end
    
    if not level.isCompleted then
        self.completedGO:Display(false)
    end
end
