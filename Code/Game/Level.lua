
local function colorTutorialsOnStart()
    -- hide the node marks
    local nodeGOs = GameObject.GetWithTag("node")
    for i=1, #nodeGOs do
        local node = nodeGOs[i]
        for j=1, #node.s.linksQueue.marks do
            node.s.linksQueue.marks[j].modelRenderer.model = nil
        end
        
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


Levels = {
    {
        name = "Colors 1",
        scenePath = "Levels/Colors",
        OnStart = colorTutorialsOnStart,
        OnEnd = colorTutorialsOnEnd
    },
    
    {
        name = "Colors 2",
        scenePath = "Levels/Colors 2",
        OnStart = colorTutorialsOnStart,
        OnEnd = colorTutorialsOnEnd
    },
    
    {
        name = "Links 1",
        scenePath = "Levels/Links",
    },
    
    {
        name = "Links 2",
        scenePath = "Levels/Links 2",
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
