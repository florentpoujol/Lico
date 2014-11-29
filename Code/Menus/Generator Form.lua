

function Behavior:Awake()
    
end

function Behavior:Start()
    
    -- grid size
    local onValidate = function(input)
        Generator.gridSize[ input.component ] = tonumber( input.gameObject.textRenderer.text )
    end
    
    local onFocus = function(input)
        if input.focus then
            input.backgroundGO:Display(0.7)
        else
            input.backgroundGO:Display(1)           
            input:OnValidate()
        end
    end
    
        
    local xInput = GameObject.Get("Generator Form.Grid Size.X.Input").input
    xInput.component = "x"
    xInput.OnFocus = onFocus
    xInput.OnValidate = onValidate
    
    xInput.defaultValue = Generator.gridSize.x
    xInput.gameObject.textRenderer.text = xInput.defaultValue
    
    local yInput = GameObject.Get("Generator Form.Grid Size.Y.Input").input
    yInput.component = "y"
    yInput.OnFocus = onFocus
    yInput.OnValidate = onValidate
    
    yInput.defaultValue = Generator.gridSize.y
    yInput.gameObject.textRenderer.text = yInput.defaultValue
    
    
    ----------
    -- user seed input
    
    local input = GameObject.Get("Seed Input").input
    input.OnFocus = onFocus
    input.OnValidate = function(input)
       Generator.userSeed = tonumber( input.gameObject.textRenderer.text  )
    end
    
    --
    local genButton = GameObject.Get("Generate Button")
    
    genButton:AddEventListener("OnLeftClickReleased", function(go)       
        Game.levelToLoad = Generator.randomLevel
        Scene.Load("Main/Master Level")
    end )
    
    --InitIcon(genButton)
end
