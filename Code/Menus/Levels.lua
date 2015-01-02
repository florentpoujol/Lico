function Behavior:Awake()
    self.gameObject.camera:Destroy()
    
    LoadCompletedLevels()
    
    --    
    self.gridGO = self.gameObject:GetChild("Grid Origin", true)
    self.gridLayout = { x = 7, y = 4 }
    self.gridElemCount = self.gridLayout.x * self.gridLayout.y
    
    local UICamera = GameObject.Get("UI Camera")
    local screenSize = CS.Screen.GetSize()
    local pixelsToUnits = UICamera.camera.pixelsToUnits 
    self.cartridgeWidth = ( (screenSize.x - 30) / self.gridLayout.x) * pixelsToUnits - 1   -- width of a cartridge in pixels
    self.cartridgeHeight = ( (screenSize.y - 70) / self.gridLayout.y) * pixelsToUnits
    
    self.firstLevelIndex = 1
    self.lastFirstLevelIndex = -999

    ----------
    Daneel.Event.Listen("CompletedLevelsLoaded", function() 
        if self.firstLevelIndex ~= nil then
            self:BuildLevelGrid()
        end
    end )
        
    self:BuildLevelGrid()
    
    ------------
    -- spawn random generator form
    GameObject.Get("Generator Form Origin"):Append("Menus/Generator Form")
end


function Behavior:BuildLevelGrid()
    if self.firstLevelIndex < 1 then
        self.firstLevelIndex = 1
    end
    
    self.lastFirstLevelIndex = self.firstLevelIndex
    
    ---------
    -- destroy the existing grid
    for i, go in pairs( self.gridGO.children ) do
        go:Destroy()
    end
    
    ----------
    -- build the new grid
    local x = 0
    local y = 0
    
    for i=1, #Levels do
        if i >= self.firstLevelIndex then
            local cartridgeGO = self.gridGO:Append("Entities/Level Cartridge")
            cartridgeGO.transform.localPosition = Vector3( self.cartridgeWidth * x, -self.cartridgeHeight * y, 0 )
            
            cartridgeGO.s:Init( Levels[i] )
            
            x = x + 1
            if x >= self.gridLayout.x then
                x = 0
                y = y + 1
            end
            
            if y >= self.gridLayout.y then
                break
            end
        end
    end
end

