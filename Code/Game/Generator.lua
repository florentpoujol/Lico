
Generator = {
    seed = nil, -- set in [Generator.GenerateSeed], user in [Generator.Generate]
    userSeed = nil, -- set in [Generator Form/Start]
    gridSize = Vector2(4),
    
    -- object set to Game.levelToLoad when the Generate button in the generator form is clicked (see in [Generator Form/Start])
    randomLevel = {
        name = "seed", -- there for debug and because [Master Level/Awake] use the value before the seed is actually generated
        scenePath = "Levels/Random",
        isRandom = true,
        
        -- called from [Mater Level/Start] with the scripted behavior as first argument
        initFunction = function( masterLevelScript )
            if Generator.userSeed ~= nil and Generator.userSeed ~= "" then
                Generator.SetPropertiesFromSeed()
            else
                Generator.GenerateSeed()
            end
            
            masterLevelScript.levelNameGO.textRenderer.text = Generator.seed

            --do return end
            
            Generator.Generate()
            
            masterLevelScript:ReparentNodes()
            
            masterLevelScript:UpdateLevelCamera()
            
        end
    },
}


-- Generate the level
-- Produce a table that describe the position and color of the nodes
function Generator.Generate()     
    math.randomseed( tonumber(Generator.seed) )
    
    -- gri
    
    -- Array of Vector2
    -- The components represents the positive offset of the node from the top right corner (which is 1,1)
    -- They are ordered in the array in the order they must be created for the rendering of the pillar to be OK
    local nodesOffsets = { Vector2(1) }  
    local gridSize = Generator.gridSize
    
    for i=1, gridSize.x * gridSize.y do
        local currentOffset = nodesOffsets[i]
        
        local left = currentOffset + Vector2(1,0)       
        if left.x <= gridSize.x then
            table.insertonce( nodesOffsets, left )
        end
        
        local down = currentOffset + Vector2(0,1)
        if down.y <= gridSize.y then
            table.insertonce( nodesOffsets, down )
        end
    end
    
    local positions = {} -- Array of Vector3()
        
    -- actual grid size in scene units
    -- Generator.gridSize is more a *node per side*
    local actualHalfGridSize = Vector2( gridSize.x * 2 - 2, gridSize.y * 2 - 2 ) / 2
    local nodesParentGO = GameObject.Get("Level Root.Nodes")
    
    for i=1, #nodesOffsets do
        
        local offset = nodesOffsets[i]
        offset = ( offset - Vector2(1) ) * 2
        
        local position = offset - actualHalfGridSize
        table.insert( positions, position )
        
        local node = Scene.Append("Entities/Node", nodesParentGO)
        node.transform.localPosition = Vector3(position)
    end
end


-- Generate the random seed which will be used to generate the level
-- a seed is a floating point number build like this : [properties].[random seed]
function Generator.GenerateSeed()
    local seed = ""
    
    -- grid size
    local x = tostring(Generator.gridSize.x)
    if #x == 1 then
        x = "0"..x
    end
    local y = tostring(Generator.gridSize.y)
    if #y == 1 then
        y = "0"..y
    end
    seed = seed..x..y
    
    --
    
    Generator.seed = seed.."."..os.time()
end


-- Extract the gnerator's properties from the first part of the seed
function Generator.SetPropertiesFromSeed( seed )
    local originalSeed = seed
    seed = seed or Generator.userSeed
    
    if seed ~= nil then
        local sSeed = tostring(seed)
        local props = sSeed:split(".")[1]
        
        if props ~= nil and props ~= "" then
            -- FIXME : check the value of each properties
            Generator.gridSize = Vector2( props:sub(1,2), props:sub(3,4) )            
            
            Generator.seed = seed
        else
            print("Generator.BuildPropertiesFromSeed(): Bad properties:", props, seed)
        end
    else
        print("Generator.BuildFromSeed(): Seed is nil")
    end
end

