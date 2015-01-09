
function Behavior:Awake()
    self.gameObject.s = self
end

-- Called from [Menus/Levels/BuildLevelGrid]
-- level argument is on entry of the Levels table
function Behavior:Init( level )
    self.levelNameGO = self.gameObject:GetChild("Level Name", true)
    self.levelNameGO.textRenderer.text = level.name
    self.levelNameGO.levelName = level.name
    
    --
    self.bgGO = self.gameObject:GetChild("Background", true)
    self.bgModel = self.bgGO.modelRenderer.model
    self.colorModel = "Cubes/"..ColorList[ math.random( #ColorList ) ]
    
    self.bgGO:AddTag("ui")
    self.bgGO:AddEventListener("OnMouseEnter", function(go)
        self.bgGO.modelRenderer.model = self.colorModel
    end)
    
    self.bgGO:AddEventListener("OnMouseExit", function(go)
        self.bgGO.modelRenderer.model = self.bgModel
    end)
    
    self.bgGO:AddEventListener("OnLeftClickReleased", function(go)
        local uiMaskGO = GameObject.GetWithTag("uimask")[1]
        uiMaskGO.s:Animate( 1, 0.5, function()
            Game.levelToLoad = level
            Scene.Load("Main/Master Level")
        end )
    end)
    
    --
    if not level.isCompleted then
        self.completedGO = self.gameObject:GetChild("Completed", true)
        self.completedGO:Destroy()
    end
end
