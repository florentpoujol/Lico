
function Behavior:Start()
    -- grid size
    local onValidate = function(input)
        Generator.gridSize[ input.component ] = tonumber( input.gameObject.textRenderer.text )
    end
    
    local onFocus = function(input)
        if input.isFocused then
            --input.backgroundGO:Display(0.5)
            input.backgroundGO.modelRenderer.model = "Cubes/Focused Input Background"
            self.focusedInputId = table.getkey( self.inputs, input )
        else
            --input.backgroundGO:Display(1)
            input.backgroundGO.modelRenderer.model = "Cubes/Black"
            input:OnValidate()
        end
    end
    
        
    local xInput = GameObject.Get("Generator Form.Grid Size.X.Input").input
    xInput.component = "x"
    xInput.OnFocus = onFocus
    xInput.OnValidate = onValidate
    
    xInput.defaultValue = tostring(Generator.gridSize.x)
    xInput.gameObject.textRenderer.text = xInput.defaultValue
    
    local yInput = GameObject.Get("Generator Form.Grid Size.Y.Input").input
    yInput.component = "y"
    yInput.OnFocus = onFocus
    yInput.OnValidate = onValidate
    
    yInput.defaultValue = tostring(Generator.gridSize.y)
    yInput.gameObject.textRenderer.text = yInput.defaultValue
    
    ----------
    -- Difficulty
    
    local difficultyGOs = self.gameObject:GetChild("Difficulty").children
    table.remove(difficultyGOs, 1)
    local difficulties = {"easy", "med", "hard"}
    
    for i=1, #difficultyGOs do
        local go = difficultyGOs[i]
        go.backgroundGO = go.child
        go.backgroundGO:AddComponent("Toggle", {
            group = "random_difficulty",
            checkedModel = "Cubes/Focused Input Background",
            uncheckedModel = "Cubes/Black",
            difficulty = difficulties[i],
            OnUpdate = function(t)
                if t.isChecked == true then
                    Generator.difficulty = t.difficulty
                end
            end
        })
    end
    difficultyGOs[2].backgroundGO.toggle:Check(true)
    
    
    ----------
    -- user seed input
    
    local input = GameObject.Get("Seed Input").input
    input.OnFocus = onFocus
    input.OnValidate = function(input)
        local text = input.gameObject.textRenderer.text
        if text == input.defaultValue then
            text = ""
        end
        Generator.userSeed = text
    end
    if Generator.userSeed ~= "" then
        input.gameObject.textRenderer.text = Generator.userSeed
    end
    
    
    --
    local genButton = GameObject.Get("Generate Button")
    
    genButton:AddEventListener("OnLeftClickReleased", function(go)
        Generator.fromGeneratorForm = true
        Game.levelToLoad = Generator.randomLevel
        Scene.Load("Main/Master Level")
    end )
    
    --InitIcon(genButton)
    
    
    self.inputs = {
        xInput, yInput, input
    }
    self.focusedInputId = 0
end

function Behavior:Update()
    if CS.Input.WasButtonJustPressed("Tab") then
        if self.inputs[ self.focusedInputId ] ~= nil then
            self.inputs[ self.focusedInputId ]:Focus(false)
            --print(self.inputs[ self.focusedInputId ], self.focusedInputId)
            self.focusedInputId = self.focusedInputId + 1
            if self.focusedInputId > 3 then
                self.focusedInputId = 1
            end
            
            self.inputs[ self.focusedInputId ]:Focus(true)
        end
    end
end

Daneel.Debug.RegisterScript(Behavior)

