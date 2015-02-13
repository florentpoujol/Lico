
function Behavior:Awake()
    local nodeGOs = self.gameObject:GetChildren(true)
    local Xs = {}
    local Zs = {}
    
    for i=1, #nodeGOs do
        local node = nodeGOs[i]
        if node.modelRenderer ~= nil then
            local position = node.transform.position
            node.posX = math.round( position.x, 1 )
            node.posZ = math.round( position.z, 1 )
            table.insertonce(Xs, node.posX)
            table.insertonce(Zs, node.posZ)
        end
    end
    
    table.sort(Xs, function(a,b) return a>b end) -- sort in reverse order (big first)
    table.sort(Zs)
    
    for i=1, #nodeGOs do
        local node = nodeGOs[i]
        if node.modelRenderer ~= nil then
            node.gridPosition = Vector2( table.getkey( Xs, node.posX ), table.getkey( Zs, node.posZ ) )
            node.name = node.gridPosition.x.."."..node.gridPosition.y
        end
    end
    
    Game.levelToLoad.gridSize = Vector2( #Xs, #Zs )
end
