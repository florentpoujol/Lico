
Levels = {

    {
        name = "1.1",
        scenePath = "Levels/1.1",
        hintCount = 4,
        
        paths = {
            { 1.1, 2.1, 3.1, 4.1, 5.1, 6.1, 5.2, 4.4, 3.3, 4.2, 3.2, 2.2, 1.1 } -- list of node names that can be linked together
        }
    },
    {
        name = "1.2",
        scenePath = "Levels/1.2",
        hintCount = 20,
        paths = {
            { 3.3, 2.2, 1.1, 2.1, 3.1, 4.1, 5.1, 4.2, 3.2, 2.2 }
        }
    },
    {
        name = "1.3",
        scenePath = "Levels/1.3",
    },
    {
        name = "2.1",
        scenePath = "Levels/2.1",
    },
    
    {
        name = "2.2",
    },
    {
        name = "2.3",
    },
    {
        name = "2.4",
    },
    {
        name = "2.5",
    },
    
    {
        id = -3,
        name = "Test2",
        scenePath = "Levels/Test2",     
    },
    
    {
        id = -2,
        name = "Random",
        scenePath = "Levels/Random",
        isRandom = true,      
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

--table.rprint( Levels )

--table.mergein( Levels, table.copy(Levels))
--table.mergein( Levels, table.copy(Levels))
--table.mergein( Levels, table.copy(Levels))
--table.mergein( Levels, table.copy(Levels))

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
    --print(field, nameOrId)
    for i, level in pairs( Levels ) do
        --print(level[ field ] == nameOrId
        if level[ field ] == nameOrId then
            return level
        end
    end
end
