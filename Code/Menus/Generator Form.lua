
function Behavior:Awake()
    self.gameObject.parent.camera:Destroy()
    
    local contentGO = self.gameObject.parent:GetChild("Origin")
    
    -- grid size
    local onValidate = function(input)
        Generator.gridSize[ input.component ] = tonumber( input.gameObject.textRenderer.text )
    end
    
    local onFocus = function(input)
        if input.isFocused then
            --input.backgroundGO:Display(0.5)
            input.backgroundGO.modelRenderer.model = "Cubes/Grey 100"
            self.focusedInputId = table.getkey( self.inputs, input )
        else
            --input.backgroundGO:Display(1)
            input.backgroundGO.modelRenderer.model = "Cubes/Black"
            input:OnValidate()
        end
    end
    
        
    local xInput = contentGO:GetChild("Grid Size.X.Input").input
    xInput.component = "x"
    xInput.OnFocus = onFocus
    xInput.OnValidate = onValidate
    
    xInput.defaultValue = tostring(Generator.gridSize.x)
    xInput.gameObject.textRenderer.text = xInput.defaultValue
    
    local yInput = contentGO:GetChild("Grid Size.Y.Input").input
    yInput.component = "y"
    yInput.OnFocus = onFocus
    yInput.OnValidate = onValidate
    
    yInput.defaultValue = tostring(Generator.gridSize.y)
    yInput.gameObject.textRenderer.text = yInput.defaultValue
    
    ----------
    -- Difficulty
    
    self.difficultyGOs = contentGO:GetChild("Difficulty.Radios").children
    local onUpdate = function(t)
        if t.isChecked == true then
            Generator.difficulty = t.difficulty
        end
    end
    
    local uncheckedModel = self.difficultyGOs[1].modelRenderer.model
    
    for i=1, #self.difficultyGOs do
        local toggle = GUI.Toggle.New(self.difficultyGOs[i], {
            group = "generator_difficulty",
            checkedModel = "Cubes/Grey 50",
            uncheckedModel = uncheckedModel,
        })
        toggle.difficulty = i
        if i == Generator.difficulty then
            toggle:Check(true)
        end
        toggle.OnUpdate = onUpdate
    end
    
    
    ----------
    -- user seed input
    
    local input = contentGO:GetChild("Seed Input", true).input
    --input.defaultValue = tostring( os.time()-10 ) -- -10 so that it's not the same as the first Generator.userSeed
    input.OnFocus = onFocus
    input.OnValidate = function(input)
        local text = input.gameObject.textRenderer.text
        if string.trim( text ) == "" then
            text = Generator.userSeed
            input.gameObject.textRenderer.text = text
        end
        Generator.userSeed = text
    end
    input.gameObject.textRenderer.text = Generator.userSeed
    
    
    local newButton = contentGO:GetChild("New Seed Button", true)
    newButton:AddTag("icon")
    newButton.child:AddEventListener("OnLeftClickReleased", function(go)
        Generator.userSeed = tostring( os.time() )
        input.gameObject.textRenderer.text = Generator.userSeed
    end )
    
    
    local buttonGO = contentGO:GetChild("Seed.Info Icon")
    buttonGO:AddTag("icon")
    buttonGO.child:InitWindow("Window", "mouse")

    ----------
    -- generate button
    
    local genButton = GameObject.Get("Generate Button")
    genButton:AddTag("icon")
    
    local rendererGO = genButton.child    
    rendererGO:AddEventListener("OnLeftClickReleased", function(go)
        Generator.fromGeneratorForm = true
        Game.levelToLoad = Generator.level
        Scene.Load("Main/Master Level")
    end)
    --[[
    genButton:AddEventListener("OnMouseEnter", function()
        genButton.transform.localScale = Vector3(1.1)
    end)
    genButton:AddEventListener("OnMouseExit", function()
        genButton.transform.localScale = Vector3(1)
    end)
    ]]
    
    ---------
    -- switch between inputs via tabs
    
    self.inputs = {
        xInput, yInput, input
    }
    self.focusedInputId = 0
end

function Behavior:Update()
    if CS.Input.WasButtonJustPressed("Tab") then
        if self.inputs[ self.focusedInputId ] ~= nil then
            self.inputs[ self.focusedInputId ]:Focus(false)

            self.focusedInputId = self.focusedInputId + 1
            if self.focusedInputId > 3 then
                self.focusedInputId = 1
            end
            
            self.inputs[ self.focusedInputId ]:Focus(true)
        end
    end
end

Daneel.Debug.RegisterScript(Behavior)

