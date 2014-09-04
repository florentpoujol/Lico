
Levels = {
    -- original level
    {
        id = 1,
        name = "T1",
        scenePath = "Levels/Tuto 1",
        tutoText = 
[[Link all the nodes together !

Red can connect to Red, Orange, Purple or White
Yellow can connect to Yellow, Orange, Green or White
Blue can connect to Blue, Green or Purple
And so on...

Click on a node to select it (Echap or click again to unselect).
Click on a node while one is selected to link the two together.]]
    },
    
    {
    
        id = 2,
        name = "T2",
        scenePath = "Levels/Tuto 2",
        tutoText = 
[[Some nodes are required to have a specified number of links.

Two links can not cross each other.
Click on a link to remove it.

White nodes can connect to everyone.]]
    },
    
    {
        id = -1,
        name = "Random",
        scenePath = "Levels/Random",
        isRandom = true,
        tutoText = 
[[Random generation MAY produce unsolvable level.]]        
    },
}

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
