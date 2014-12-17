
Levels = {
    {
        name = "1.1",
        scenePath = "Levels/1.1",
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
