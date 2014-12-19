
Generator = {
    seed = nil, -- set in [Generator.GenerateSeed], user in [Generator.Generate]
    userSeed = "", -- set in [Generator Form/Start]
    gridSize = Vector2(4),
    difficulty = "med", -- "easy", "hard"
    fromGeneratorForm = false, -- tell whether the Generator is init from the 
    
    -- object set to Game.levelToLoad when the Generate button in the generator form is clicked (see in [Generator Form/Start])
    randomLevel = {
        name = "seed", -- there for debug and because [Master Level/Awake] use the value before the seed is actually generated
        scenePath = "Levels/Random",
        isRandom = true,
        
        -- called from [Mater Level/Start] with the scripted behavior as first argument
        initFunction = function( masterLevelScript )
            if Generator.userSeed ~= "" and Generator.fromGeneratorForm == true then
                Generator.SetPropertiesFromSeed()
            else
                Generator.GenerateSeed()
            end
            Generator.fromGeneratorForm = false
            
            masterLevelScript.levelNameGO.textRenderer.text = Generator.seed
            
            Daneel.Event.Listen("RandomLevelGenerated", function()
                masterLevelScript:ReparentNodes()
                masterLevelScript:UpdateLevelCamera()
            end) -- fired at the end of Generate()
            
            Generator.Generate()
        end
    },
}


-- Generate the level
-- Produce a table that describe the position and color of the nodes
function Generator.Generate()     
    math.randomseed( Generator.randomseed ) 
    --print("set randomseed", Generator.randomseed )
    math.random(); math.random(); math.random();
    
    SetRandomColors() -- re set them here so that the random colors are always the same or a given seed
    
    -- Generate ordered list of nodes
    local nodes = { 
        { 
            position = Vector2(1),
            -- The components represents the positive offset of the node from the top right corner (which is 1,1)
            -- They are ordered in the array in the order they must be created for the rendering of the pillar to be OK
    
            isVisited = false,
            neighbours = {}, -- list of nodes reference
        }
    }
    
    local function nodeExistsInList( list, node )
        for i=1, #list do
            if list[i].position == node.position then
                return true
            end
        end
        return false
    end
    
    local function getByPosition( list, pos ) 
        for i=1, #list do
            if list[i].position == pos then
                return list[i]
            end
        end
    end
    
    --
    local gridSize = Generator.gridSize
    local offsetByComponent = { x = Vector2(1,0), y = Vector2(0,1) }
    
    for i=1, gridSize.x * gridSize.y do
        local currentNode = nodes[i]
        
        for comp, offset in pairs( offsetByComponent ) do
            local position = currentNode.position + offset
            
            if position[ comp ] <= gridSize[ comp ] then
                
                local node = getByPosition( nodes, position ) 
                if node == nil then
                    node = {
                        position = position,
                        isVisited = false,
                        neighbours = {
                            currentNode
                        }
                    }
                    
                    table.insert( nodes, node )
                end
                
                if not nodeExistsInList( currentNode.neighbours, node ) then               
                    table.insert( currentNode.neighbours, node )
                end           
            end
        end
    end
    
    -- loop on nodes and make sure all nodes have their neighbours    
    for i=1, #nodes do
        local node = nodes[i]
        if #node.neighbours < 4 then
            -- expected neighbours
            local en = {
                getByPosition( nodes, node.position + Vector2(1,0) ),
                getByPosition( nodes, node.position + Vector2(-1,0) ),
                getByPosition( nodes, node.position + Vector2(0,1) ),
                getByPosition( nodes, node.position + Vector2(0,-1) ),
            }            
            
            for j, _node in pairs(en) do
                if not nodeExistsInList( node.neighbours, _node ) then
                    table.insert( node.neighbours, _node )
                end
            end
        end
    end
    
    -----------------------------------------------------------   
    -- Maze
    
    -- Depth-first Search (DFS)
    --[[
    http://www.algosome.com/articles/maze-generation-depth-first.html
    
    1 Randomly select a node (or cell) N.
    2 Push the node N onto a queue Q.
    3 Mark the cell N as visited.
    4.1 Randomly select an adjacent cell A of node N that has not been visited. 
        4.2 If all the neighbors of N have been visited: Continue to pop items off the queue Q until a node is encountered with at least one non-visited neighbor - assign this node to N and go to step 4.
        4.3 If no nodes exist: stop.
    5 Break the wall between N and A.
    6 Assign the value A to N.
    7 Go to step 2.
    ]]
    
    

   
    local queue = {}
    local node = nodes[ math.random(#nodes) ]
    local nextNode = nil
    local addToQueue = true
    
    -- ColorList = { "Red", "Yellow", "Green", "Cyan", "Blue", "Magenta" }
    -- On difficulty easy or normal, there is only 4 and 5 colors respectively
    -- build a colorList so that the colors that folow each other are linkable
    -- it's only when #colorList<6, that the first and last color are not linkable
    local colorList = {}
    local idToRemove = math.random(6)
    
    local difficulty = Generator.difficulty
    local colorToSkip = 0
    if difficulty == "easy" then
        colorToSkip = 2
    elseif difficulty == "med" then
        colorToSkip = 1
    end
    
    local index = nil
    for i=1, #ColorList do
        if i == idToRemove and colorToSkip > 0 then
            idToRemove = idToRemove + 1
            colorToSkip = colorToSkip - 1
            index = 1
        else
            if index == nil then
                table.insert( colorList, ColorList[i] )
            else
                table.insert( colorList, index, ColorList[i] )
                index = index + 1
            end
        end
    end
    
    if idToRemove == 6 and difficulty == "easy" then
        table.remove( colorList, 1 ) -- removes the red
    end
    
    if math.random(2) == 1 then
        colorList = table.reverse( colorList )
    end
    -- now colorList contains 4 to 6 colors.
   
    local colorId = math.random( #colorList )
    
    local i = 1
    while i<9999 do
        i = i+1
        
        if addToQueue == true then
            table.insert( queue, node )
            node.isVisited = true
            
            local previousNode = node.previousNode
            if previousNode ~= nil and previousNode.colorName ~= nil then
                -- make sure that the color can link
                colorId = table.getkey( colorList, previousNode.colorName ) or 1
            end
            
            local idMod = { -1, -1, 0, 0, 1, 1, 1, 1 }
            --local idMod = {1 }
            colorId = colorId + idMod[ math.random( #idMod ) ]
            
            if colorId < 1 then
                if #colorList == 6 then
                    colorId = #colorList
                else
                    -- remember that when #colorList<6 the first and last color are not linkable
                    colorList = table.reverse( colorList )
                    colorId = math.random( 2 ) -- 1 is the same color as last time
                end
            elseif colorId > #colorList then
                if #colorList == 6 then
                    colorId = 1
                else
                    colorList = table.reverse( colorList )
                    colorId = math.random( 2 )
                end
            end
            
            node.colorName = colorList[colorId]
        end

        local neighbours = table.copy( node.neighbours )
        -- remove neighbours thare are already visited
        for i, node in pairs(node.neighbours) do
            if node.isVisited == true then
                table.removevalue( neighbours, node )
            end
        end
        
        if #neighbours > 0 then
            nextNode = neighbours[ math.random( #neighbours ) ]
            addToQueue = true
            
            node.linkedNeighbours = node.linkedNeighbours or {}
            table.insert( node.linkedNeighbours, nextNode )
            
            nextNode.previousNode = node
        
        elseif #queue > 0 then
            nextNode = table.remove( queue, 1 )
            addToQueue = false
        else
            break
        end
    
        node = nextNode
    end
    
    -- print("end loop", i)    
    -- 4x4 > i=33
    -- 10x10 > i=201
    -- 50x50 > i=5001
    
    
    -----------------------------------------------------------
    -- generate grid
    
    local nodesParentGO = GameObject.Get("Level Root.Nodes")
    local nodesOriginGO = GameObject.Get("Level Root.Nodes.Origin")
    local debugMaze = true
    
    local useCoroutine = true
        
    local generate_grid = function()
        for i=1, #nodes do
            local node = nodes[i]
            local offset = node.position -- offset from top right corner of the grid      
            offset = offset - Vector2(1) -- now, offset is on base 0 (top right node is 0,0, node on the opposite side is {gridSize.x-1,gridSize.y-1})
            offset = offset * 2 -- nodes are actually two units appart (nodes are 1 unit squares, with 1 unit between each of them)
            
            local nodeGO = Scene.Append("Entities/Node", nodesOriginGO)
            local linkedNeighbours = nodes[i].linkedNeighbours
            local linkCount = 4 -- this is to confuse
            if linkedNeighbours ~= nil and #linkedNeighbours > 0 then
                linkCount = #linkedNeighbours*2
            end
            nodeGO.s:SetMaxLinkCount( linkCount )
            nodeGO.s:Init( node.colorName )
            
            local position = Vector3( -offset.x, 0, offset.y ) -- keep the variable, used in debug maze
            nodeGO.transform.localPosition = position
            
            if debugMaze == true then
                local linkedNeighbours = nodes[i].linkedNeighbours
                if linkedNeighbours ~= nil and #linkedNeighbours > 0 then
                    for j=1, #linkedNeighbours do
                        offset = linkedNeighbours[j].position
                        offset = ( offset - Vector2(1) ) * 2
                        local targetPosition = Vector3( -offset.x, 0, offset.y )
                        
                        local go = GameObject.New("", {
                            parent = nodeGO,
                            transform = {
                                localPosition = Vector3(0,0.1,0),
                                localScale = Vector3(0.5,1,targetPosition:Distance(position))
                            },
                            modelRenderer = { model = "Cubes/Arrow", opacity = 0.8 }
                        } )
        
                        go.transform:LookAt( nodesOriginGO.transform:LocalToWorld( targetPosition ) )
                        local angles = go.transform.localEulerAngles
                        angles.z = 0
                        go.transform.localEulerAngles = angles
                    end
                end
            end
            
            if useCoroutine == true then
                coroutine.yield()
            end
        end
        
        -- center the level
        nodesOriginGO.transform.localPosition = Vector3( gridSize.x-1, 0, -(gridSize.y-1) )
        
        if useCoroutine == true then
            coroutine.yield()
        end
            
        Daneel.Event.Fire("RandomLevelGenerated")
    end
    
    if useCoroutine == true then
        Generator.coroutine = coroutine.create( generate_grid )
        -- is resumed from [Master Level/Update]
    else
        Generator.coroutine = nil
        generate_grid()
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
    Generator.seed = seed.."."..os.time() -- used for the name of the level   
    Generator.randomseed = os.time()
end


-- Extract the gnerator's properties from the first part of the seed
function Generator.SetPropertiesFromSeed( seed )
    local originalSeed = seed
    seed = seed or Generator.userSeed
    
    if seed ~= nil then
        local sSeed = tostring(seed)
        local props, time = unpack( sSeed:split(".") )

        if props ~= nil and props ~= "" then
            -- FIXME : check the value of each properties

            Generator.gridSize = Vector2( tonumber(props:sub(1,2)), tonumber(props:sub(3,4)) )
            
            Generator.seed = seed
            Generator.randomseed = tonumber(time)
        else
            print("Generator.BuildPropertiesFromSeed(): Bad properties:", props, seed)
        end
    else
        print("Generator.BuildFromSeed(): Seed is nil")
    end
end

Daneel.Debug.RegisterObject(Generator)
