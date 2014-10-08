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
    
    local bg = children.Background
    bg:AddTag("ui")
    bg.OnMouseEnter = function(go)
        levelNameGO.textRenderer.text = "          Play          "
    end
    bg.OnMouseExit = function(go)
        levelNameGO.textRenderer.text = levelNameGO.levelName
    end
    
    bg.OnLeftClickReleased = function(go)
        local transitionAnimation = function()
            local uiMaskGO = GameObject.Get("UI Mask")
            uiMaskGO.s:Animate( 1, 0.5, function()
                Game.levelToLoad = level
                Scene.Load("Main/Master Level")
            end )
        end
        transitionAnimation()
    end
    
    if not level.isCompleted then
        self.completedGO:Display(false)
    end
end
