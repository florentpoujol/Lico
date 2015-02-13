Area = {}
Area.__index = Area

function Area.New( gameObject )
    local area = setmetatable( {}, Area )
    
    area.rulerGO = gameObject:GetChild("Area Ruler", true)
    if area.rulerGO == nil then
        print("no area ruler")
        return
    end
    area.rulerGO.modelRenderer.opacity = 0
    
    area.gameObject = gameObject
    gameObject.area = area
    
    Daneel.Event.Listen("OnScreenResized", function(go)
        print("resize area")
        area:Resize()
    end)
    
    return area
end

function Area.Resize( area )
    -- get the size in scene unit of the area
    
    local rulerScale = area.rulerGO.transform.localScale
    local areaSize = Vector2(rulerScale) 
    --print("areaSize", areaSize, rulerScale, area:GetScale())
    
    -- get the size left for the area, taking resolution and UI scale into account
    local screenSize = CS.Screen.GetSize()
    
    local position = Vector2(0)
    local camera = GameObject.Get("UI Camera").camera
    
    if area.gameObject.hud ~= nil then
        position = area.gameObject.hud.position
    else
        position = Vector2( camera:WorldToScreenPoint( area.gameObject.transform.position ) )
    end
    
    local pixelsLeft = screenSize - position
    local areaType = area.gameObject.areaType
    
    if areaType == "bottomleft" then
        pixelsLeft.y = position.y
        
    elseif areaType == "topright" then
        pixelsLeft.x = position.x
        
    elseif areaType == "bottomright" then
        pixelsLeft = position
    end
    --print("pixelsLeft", pixelsLeft, screenSize, position, areaType)
    
    
    local unitsLeft = pixelsLeft * camera.pixelsToUnits 
    --print("unitssLeft", unitsLeft)    
    
    --
    local shrinkFactors = Vector2(0)
    shrinkFactors = unitsLeft / areaSize
        
    local factor = math.min( shrinkFactors.x, shrinkFactors.y )
    --print("factor", shrinkFactors, factor)
    
    local scale = Vector3(1)
    if factor < 1 then
        scale = Vector3( factor, factor, 1 )
    end
    area.gameObject.transform.localScale = scale
end


function Area.GetScale( area )
    -- get the size in scene unit of the area
    return Vector2( area.gameObject.transform.localScale )
end


function Behavior:Awake()
    if self.gameObject.area == nil then       
        Area.New( self.gameObject )
    end
end
