function Behavior:Awake()
    self.gameObject.s = self
    self.completedGO = self.gameObject:GetChild("Completed")
    
    local bgGO = self.gameObject:GetChild("Background")
    bgGO.modelRenderer.model = "Cubes/"..ColorList[ math.random( #ColorList ) ]
end

-- Called from [Levels/BuildLevelGrid]
-- level argument is on entry of the Levels table
function Behavior:SetData( level )
    local children = self.gameObject.children
    local levelNameGO = children[1]
    levelNameGO.textRenderer.text = level.name
    levelNameGO.levelName = level.name
    
    local bg = children[2]
    bg:AddTag("ui")
    bg.OnMouseEnter = function(go)
        levelNameGO.textRenderer.text = "          Play          "
    end
    bg.OnMouseExit = function(go)
        levelNameGO.textRenderer.text = levelNameGO.levelName
    end
    
    bg.OnLeftClickReleased = function(go)
        local uiMaskGO = GameObject.Get("UI Mask")
        uiMaskGO.s:Animate( 1, 0.5, function()
            Game.levelToLoad = level
            Scene.Load("Main/Master Level")
        end )
    end
    
    if not level.isCompleted then
        self.completedGO:Display(false)
    end
end
