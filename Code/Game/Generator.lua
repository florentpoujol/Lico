
-- buggy levels
-- 442.1419354847   link rouge vers cyan  + 3 marks pour un node qui n'a que deux liens
--528781

Generator = {
    levelName = "", -- set in SetSeed(), used in Generator.level.initFunction()
    randomseed = 0, -- set in SetSeed(), used in Generate()
    userSeed = tostring( os.time() ), -- reset based on user input from [Generator Form/Start] or ProcessUserSeed()
    
    -- level properties    
    gridSize = Vector2(4),
    difficulty = 2, -- 1="easy", 3="hard"
    fromGeneratorForm = false, -- tell whether the Generator is init from the form (or from the level, via the "generate new level" button)
    
    -- object set to Game.levelToLoad when the Generate button in the generator form is clicked (see in [Generator Form/Start])
    level = {
        name = "level.seed", -- there for debug and because [Master Level/Awake] use the value before the seed is actually generated
        scenePath = "Levels/Random",
        isRandom = true,
        
        -- called from [Mater Level/Start] with the scripted behavior as first argument
        initFunction = function( masterLevelScript )
            if Generator.fromGeneratorForm == true then
                Generator.ProcessUserSeed()
            else
                Generator.SetSeed()
                -- set level name, user seed, random seed
            end
            Generator.fromGeneratorForm = false
            
            masterLevelScript.levelNameGO.textRenderer.text = Generator.levelName
            
            Daneel.Event.Listen("RandomLevelGenerated", function()
                masterLevelScript:ReparentNodes()
                masterLevelScript:UpdateLevelCamera()
            end) -- fired at the end of Generate()
            
            Generator.Generate()
        end
    },
}


function Generator.Generate()     
    math.randomseed( Generator.randomseed ) 
    --print("set randomseed", Generator.randomseed )
    math.random(); math.random(); math.random();
    
    SetRandomColors() -- re set them here so that the random colors are always the same for a given seed
    
    ----------
    -- Generate ordered list of nodes
    
    local nodes = { 
        { 
            position = Vector2(1),
            -- The components represents the positive offset of the node from the top right corner (which is 1,1)
            -- They are ordered in the array in the order they must be created for the rendering of the pillar to be OK
    
            isVisited = false,
            neighbours = {}, -- list of nodes reference
            linkedNeighbours = {},
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
                        },
                        linkedNeighbours = {}
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
    if difficulty == 1 then
        colorToSkip = 2
    elseif difficulty == 2 then
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
    
    if idToRemove == 7 and difficulty == 1 then
        -- idToRemove was 6, so only one element was removed
        -- remove the other one now
        table.remove( colorList, 1 )
    end
    
    if math.random(2) == 1 then
        colorList = table.reverse( colorList )
    end
    --print("#colorList", #colorList, idToRemove, difficulty)
    -- now colorList contains 4 to 6 colors.
   
    local colorId = math.random( #colorList )
    local colorIdModulation = { -1, 0, 1, 1, 1 }
    if difficulty ~= 1 then
        table.insert( colorIdModulation, 1 )
        table.insert( colorIdModulation, 1 )
    end
    if difficulty == 3 then
        -- add two more
        table.insert( colorIdModulation, 1 )
        table.insert( colorIdModulation, 1 )
        table.insert( colorIdModulation, 1 )
    end
    
    local i = 1
    while i<999 do
        i = i+1
        
        if addToQueue == true then
            table.insert( queue, node )
            node.isVisited = true
            
            local previousNode = node.previousNode
            if previousNode ~= nil and previousNode.colorName ~= nil then
                -- make sure that the color can link
                colorId = table.getkey( colorList, previousNode.colorName ) or 1
            end
            
            
            colorId = colorId + colorIdModulation[ math.random( #colorIdModulation ) ]
            
            if colorId < 1 then
                if #colorList == 6 then
                    colorId = #colorList
                    math.random( 2 ) -- this is here so that math.random() is called the same number of time whatever the difficulty is
                    -- and thus create the same maze
                else
                    -- remember that when #colorList<6 the first and last color are not linkable
                    colorList = table.reverse( colorList )
                    
                    local length = #colorList
                    colorId = math.random( length-1, length ) -- 1 is the same color as last time
                end
            elseif colorId > #colorList then
                if #colorList == 6 then
                    colorId = 1
                    math.random( 2 ) -- leave that here ! see above
                else
                    
                    colorList = table.reverse( colorList )
                    colorId = math.random( 2 )
                end
            else
                math.random( 2 ) -- leave that here ! see above
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
    -- 9x9 > i=163
    -- 10x10 > i=201
    
    
    -----------------------------------------------------------
    -- set 
    
    for i=1, #nodes do
        local node = nodes[i]
        local linkCount = #node.linkedNeighbours
        
        if node.previousNode ~= nil then -- always true except for the very first node
            linkCount = linkCount + 1
        end
        
        if difficulty == 1 then
            linkCount = math.max( linkCount, 2 )
            if math.random(3) == 1 then
                linkCount = linkCount + 1
            end
        elseif difficulty == 2 then
            if math.random(5) == 1 then
                linkCount = linkCount + 1
            end
        else
            --linkCount = math.max( linkCount, 2 ) -- this "hides" the nodes that would have only one link possible (start and end of path)
        end
        
        -- if node is on an edge
        if 
            node.position.x == 1 or node.position.x == Generator.gridSize.x or
            node.position.y == 1 or node.position.y == Generator.gridSize.y
        then
            linkCount = math.min( linkCount, 3 )
        
        elseif  -- if node is in a corner
            (node.position.x == 1 or node.position.x == Generator.gridSize.x) and
            (node.position.y == 1 or node.position.y == Generator.gridSize.y)
        then
            linkCount = math.min( linkCount, 2 )
        end
        
        node.linkCount = linkCount
    end
    
    
    -----------------------------------------------------------
    -- build grid
    
    local nodesParentGO = GameObject.Get("Level Root.Nodes")
    local nodesOriginGO = GameObject.Get("Level Root.Nodes.Origin")
    Generator.nodesCount = #nodes
    
    local useCoroutine = true
        
    local buildGrid = function()
        for i=1, #nodes do
            local node = nodes[i]
            local offset = node.position -- offset from top right corner of the grid      
            offset = offset - Vector2(1) -- now, offset is on base 0 (top right node is 0,0, node on the opposite side is {gridSize.x-1,gridSize.y-1})
            offset = offset * 2 -- nodes are actually two units appart (nodes are 1 unit squares, with 1 unit between each of them)
            
            local nodeGO = Scene.Append("Entities/Node", nodesOriginGO)
            local position = Vector3( -offset.x, 0, offset.y ) -- keep the variable, used in debug maze
            nodeGO.transform.localPosition = position
            
            nodeGO.s:SetMaxLinkCount( node.linkCount )
            nodeGO.s:Init( node.colorName )
            
            -- debug arrows
            if Daneel.Config.debug.enableDebug == true then
                -- double press F3 to reveal/hide arrows (code in [Master Level/Update])
                
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
                            modelRenderer = { model = "Debug/Arrow", opacity = 0 },
                            tags = {"debug_maze"}
                        } )
        
                        go.transform:LookAt( nodesOriginGO.transform:LocalToWorld( targetPosition ) )
                        local angles = go.transform.localEulerAngles
                        angles.z = 0
                        go.transform.localEulerAngles = angles
                    end
                end
            end
            
            if useCoroutine == true and i%2 == 0 then -- yield every 2 nodes
                coroutine.yield()
            end
        end
        
        -- center the level
        nodesOriginGO.transform.localPosition = Vector3( gridSize.x-1, 0, -(gridSize.y-1) )
        
        Daneel.Event.Fire("RandomLevelGenerated")
    end
    
    if useCoroutine == true then
        Generator.coroutine = coroutine.create( buildGrid )
        -- is resumed from [Master Level/Update]
    else
        Generator.coroutine = nil
        buildGrid()
    end
end


-- @param seed (string or number) [optional] The random seed to use (will be os.time() if arg isn't set)
function Generator.SetSeed( seed )
    seed = seed or os.time()
    
    Generator.levelName = Generator.gridSize.x..Generator.gridSize.y..Generator.difficulty.."."..seed 
    Generator.randomseed = tonumber( seed )
    Generator.userSeed = tostring( seed )
end


-- Extract the generator's properties from the first part of the seed
function Generator.ProcessUserSeed()
    local props, seed = unpack( Generator.userSeed:split(".") )
    if seed == nil then
        -- level properties are not included with the seed
        seed = props
        props = nil
    end
    
    if props ~= nil then
        Generator.gridSize = Vector2( tonumber( props:sub(1,1) ), tonumber( props:sub(2,2) ) )
        Generator.difficulty = tonumber( props:sub(3,3) )
    end
    -- if no parameters included in the seed, they are already set via the form
    
    Generator.SetSeed( seed )
end

Daneel.Debug.RegisterObject(Generator)
