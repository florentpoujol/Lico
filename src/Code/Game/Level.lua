
local function colorTutorialsOnStart()
    -- hide the link marks
    local nodeGOs = GameObject.GetWithTag("node")
    for i=1, #nodeGOs do
        local node = nodeGOs[i]
        node.s:HideLinkMarks()
        
        if node.s.maxLinkCount == 4 then
            node.s.maxLinkCount = 2
        end
    end
    
    -- prevent links to be removed
    local linkScript = Asset("Entities/Link", "Script")
    linkScript.oOnClick = linkScript.OnClick
    linkScript.OnClick = function() end
    -- the function is replaced and not nillified because 
    -- it is still called when the click happens on the link's renderer
end

local function colorTutorialsOnEnd()
    local linkScript = Asset("Entities/Link", "Script")
    linkScript.OnClick = linkScript.oOnClick
end

local function changeNodeColor()
    local nodeGOs = GameObject.GetWithTag("node")
    local colorName = ColorList[ math.random( #ColorList ) ]
    local color = ColorsByName[ colorName ]


    for i=1, #nodeGOs do
        local node = nodeGOs[i]
        node.s.colorName = colorName
        node.s.color = color
        
        node.s.pillarGO.modelRenderer.color = color
        node.s.rendererGO.modelRenderer.color = color        
    end
end



Levels = {
    {
        name = "T1.0",
        scenePath = "Levels/T1.0",
        OnStart = colorTutorialsOnStart,
        OnEnd = colorTutorialsOnEnd
    },
    
    {
        name = "1.1",
        scenePath = "Levels/1.1",
        OnStart = colorTutorialsOnStart,
        OnEnd = colorTutorialsOnEnd
    },
    
    {
        name = "T2.0",
        scenePath = "Levels/T2.0",
        OnStart = changeNodeColor,
    },
    {
        name = "2.1",
        scenePath = "Levels/2.1",
        OnStart = changeNodeColor,
    },
    
    {
        name = "2.2",
        scenePath = "Levels/2.2",
    },
    
    {
        name = "2.3",
        scenePath = "Levels/2.3",
    },
    
    {
        name = "2.4",
        scenePath = "Levels/2.4",
    },
    
    {
        name = "GT",
        scenePath = "Levels/Level Game Title",
        OnStart =function()
            -- hide the link marks
            local nodeGOs = GameObject.GetWithTag("node")
            for i=1, #nodeGOs do
                local node = nodeGOs[i]
                node.s:HideLinkMarks()
                
                node.s.maxLinkCount = 4 
            end
            
            GameObject.Get("World Camera").camera.orthographicScale = 15
        end
    },
}


for i, level in ipairs( Levels ) do
    level.id = level.id or i
    level.hintCount = level.hintCount or 3
    if level.scenePath == nil then
        level.scenePath = "Levels/"..level.name
    end
    
    if level.paths ~= nil then
        local newPaths = {}
        local idsToRemove = {}
        
        for i, path in pairs( level.paths ) do
            for j, name in pairs( path ) do
                path[j] = tostring( name )
            end
            
            if #path > 2 then
                local k = 0
                local newPath = {}
                table.insert( idsToRemove, i )
                
                --for j=1, #path do
                local j = 0
                while true do
                    j = j + 1
                    local name = path[j]
                    k = k + 1
                    
                    if k == 1 then
                        newPath = { name }
                        
                    elseif k == 2 then
                        table.insert( newPath, name )
                        table.insert( newPaths, newPath )

                        if j == #path then
                            break
                        end
                        
                        j = j - 1
                        k = 0
                    end
                end -- end for path
            end
        end -- end for level.Paths
        
        if #newPaths > 0 then
            for i=1, #idsToRemove do
                table.remove( level.paths, idsToRemove[i] )
            end
            table.mergein( level.paths, newPaths )
        end
    end
end


-- Called from [Levels/Awake]
function LoadCompletedLevels()
    CS.Storage.Load("CompletedLevels", function(e, completedLevelIds)
        if e ~= nil then
            print("ERROR loading options from storage: ", e.message)
            return
        end
        
        if completedLevelIds ~= nil then
            for i, level in pairs( Levels ) do
                if table.containsvalue( completedLevelIds, level.id ) then
                    level.isCompleted = true
                end
            end
            Daneel.Event.Fire("CompletedLevelsLoaded") -- Rebuild the level list
        end
    end )
end


-- Called from [Master Level/EndLevel]
function SaveCompletedLevels()
    local ids = {}
    for i, level in pairs( Levels ) do
        if level.isCompleted then
            table.insert(ids, level.id)
        end
    end
    
    CS.Storage.Save("CompletedLevels", ids, function(e)
        if e ~= nil then
            print("ERROR saving completed levels in storage: ", e.message)
        end
    end )
end


function GetLevel( nameOrId )
    local field = "name"
    if type( nameOrId ) == "number" then
        field = "id"
    end
    for i, level in pairs( Levels ) do
        if level[ field ] == nameOrId then
            return level
        end
    end
end
