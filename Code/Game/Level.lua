
Levels = {
    -- original level
    {
        id = 1,
        name = "T1",
        scenePath = "Levels/T1",
    },
    {
        id = 2,
        name = "2",
        scenePath = "Levels/2",
    },
    {
        id = 3,
        name = "T3",
        scenePath = "Levels/T3",
    },
    {
        id = 4,
        name = "4",
        scenePath = "Levels/4",
    },
    {
        id = 5,
        name = "T5",
        scenePath = "Levels/T5",
    },
    {
        id = 6,
        name = "6",
        scenePath = "Levels/6",
    },
    
    
        
    {
        id = -1,
        name = "Test",
        scenePath = "Levels/Test",     
    },
    
    {
        id = -2,
        name = "Random",
        scenePath = "Levels/Random",
        isRandom = true,      
    },
}


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
