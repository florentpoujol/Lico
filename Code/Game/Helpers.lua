
-- allow for mouse over effect other than the tooltip
-- used in [Main Menu/Awake] and [Master Level/Awake]
function InitIcons()
    local iconGOs = GameObject.Get("UI.Icons").children
    
    for i, iconGO in pairs( iconGOs ) do
        iconGO:Display(0.5)
        
        -- override OnMouseEnter/Exit set by GO.InitWindow()
        local onMouseEnter = iconGO.OnMouseEnter
        iconGO.OnMouseEnter = function(go)
            go:Display(1)
            onMouseEnter(go)
        end
        
        local onMouseExit = iconGO.OnMouseExit
        iconGO.OnMouseExit = function(go)
            if not go.windowGO.isDisplayed then
                go:Display(0.5)
            end
            onMouseExit(go)
        end
    end
end



function GameObject.InitWindow( go, gameObjectNameOrAsset, eventType, tag )
    if tag ~= nil then
        go:AddTag(tag)
    end
    
    local windowGO = gameObjectNameOrAsset
    if type(gameObjectNameOrAsset) == "string" then
        windowGO = go:GetChild( gameObjectNameOrAsset ) or GameObject.Get( gameObjectNameOrAsset )
    end
    
    --print(windowGO)
    if windowGO == nil then
        print("GameObject.InitWindow(): Window not found", go, gameObjectNameOrAsset, eventType, tag)
        return
    end
    
    go.windowGO = windowGO
    windowGO.buttonGO = go
    
    windowGO.transform.localPosition = Vector3(0)
    windowGO:Display(false, true)
    
    if eventType == "mouseover" then
        go.OnMouseEnter = function()
            windowGO:Show()
        end
        go.OnMouseExit = function()
            windowGO:Hide()
        end
        
    elseif eventType == "mouseclick" then
        go.OnClick = function()
            windowGO:Display( not windowGO.isDisplayed, true )
            
        end
    end

    windowGO.Show = function( go )
        windowGO.transform.localPosition = Vector3(0)
    end
    
    windowGO.Hide = function( go )
        windowGO.transform.localPosition = Vector3(0,0,99)
    end
end


-- quick fix for webplayer 
local ot = TextRenderer.SetText
function TextRenderer.SetText( tr, t )
ot( tr, tostring(t) )
end


function GetSelectedNodes()
    return GameObject.GetWithTag( "selected_node" )[1]
end

----------
-- GUI

function Vector2.ToPixel( vector, camera )
    local vec = Vector2.New(
        GUI.ToPixel( vector.x, "x", camera ),
        GUI.ToPixel( vector.y, "y", camera )
    )
    --print("Vector2.ToPixel", vec)
    return vec
end

function GUI.Hud.SetPosition(hud, position)
    position = position:ToPixel( hud.cameraGO.camera )
    local newPosition = hud.cameraGO.hudOriginGO.transform:GetPosition() +
    Vector3:New(
        position.x * hud.cameraGO.camera:GetPixelsToUnits(),
        -position.y * hud.cameraGO.camera:GetPixelsToUnits(),
        0
    )
    newPosition.z = hud.gameObject.transform:GetPosition().z
    --print("Hud.SetPos", position, newPosition, hud.cameraGO.camera:GetPixelsToUnits(), hud.position)
    hud.gameObject.transform:SetPosition( newPosition )
    --print(hud.gameObject.transform.position, hud.position)
end


function GameObject.Display( gameObject, value, forceUseLocalScale )
    local display = false
    if value ~= false and value ~= 0 and value ~= Vector3:New(0) then -- true or non 0 value
        display = true
    end

    local valueType = type(value)
    if valueType == "boolean" then
        value = nil
    end  

    local renderer = gameObject.textRenderer or gameObject.modelRenderer or gameObject.mapRenderer

    if valueType ~= "table" and not forceUseLocalScale and renderer ~= nil then
        if not display and renderer.displayOpacity == nil then
            renderer.displayOpacity = renderer:GetOpacity()
        end
        if display then
            value = value or renderer.displayOpacity or 1
        else
            value = value or 0
        end
        renderer:SetOpacity( value )
    else
        if not display and gameObject.transform.displayLocalScale == nil then
            gameObject.transform.displayLocalScale = gameObject.transform:GetLocalPosition()
        end
        if display then
            value = value or gameObject.transform.displayLocalScale or Vector3:New(0)
        else
            value = value or Vector3:New(0,0,999)
        end
        gameObject.transform:SetLocalPosition( value )
    end
    --[[else
        if not display and gameObject.transform.displayLocalScale == nil then
            gameObject.transform.displayLocalScale = gameObject.transform:GetLocalScale()
        end
        if display then
            value = value or gameObject.transform.displayLocalScale or Vector3:New(1)
        else
            value = value or Vector3:New(0.01)
        end
        gameObject.transform:SetLocalScale( value )
    end]]

    gameObject.isDisplayed = display 
end


local oDisplay = GameObject.Display
function GameObject.Display( go, arg1, arg2 )
    oDisplay( go, arg1, arg2 )
    --print("display", go)
    Daneel.Event.Fire( go, "OnDisplay", go )
end

function math.clamp( value, min, max )
    value = math.max( value, min )
    value = math.min( value, max )
    return value
end


------------------------------
-- keep uncommented to hide the backgrounds

Background = {}
Daneel.modules.Background = Background

function Background.Start()

    local gos = GameObject.GetWithTag("ui")
    for i, go in pairs (gos ) do
        local backgroundGO = go:GetChild("Background")
        if backgroundGO ~= nil then
            go.backgroundGO = backgroundGO
            backgroundGO:Display(false)
            
            --[[local oOnMouseEnter = go.OnMouseEnter
            go.OnMouseEnter = function()
                backgroundGO:Display()
                if oOnMouseEnter ~= nil then
                    oOnMouseEnter()
                end
            end
            
            local oOnMouseExit = go.OnMouseExit
            go.OnMouseExit = function()
                if not go.isSelected then
                    backgroundGO:Display(false)
                end
                if oOnMouseExit ~= nil then
                    oOnMouseExit()
                end
            end]]
        end
    end
end


------------------------------

--[[
function Vector2.ToPixel( vector, camera )
    local vec = Vector2.New(
        GUI.ToPixel( vector.x, "x", camera ),
        GUI.ToPixel( vector.y, "y", camera )
    )
    --print("Vector2.ToPixel", vec)
    return vec
end

function GUI.Hud.SetPosition(hud, position)
    position = position:ToPixel( hud.cameraGO.camera )
    local newPosition = hud.cameraGO.hudOriginGO.transform:GetPosition() +
    Vector3:New(
        position.x * hud.cameraGO.camera:GetPixelsToUnits(),
        -position.y * hud.cameraGO.camera:GetPixelsToUnits(),
        0
    )
    newPosition.z = hud.gameObject.transform:GetPosition().z
    --print("Hud.SetPos", position, newPosition, hud.cameraGO.camera:GetPixelsToUnits(), hud.position)
    hud.gameObject.transform:SetPosition( newPosition )
    --print(hud.gameObject.transform.position, hud.position)
end

function GUI.Hud.GetPosition(hud)
    local position = hud.gameObject.transform:GetPosition() - hud.cameraGO.hudOriginGO.transform:GetPosition()
    position = position / hud.cameraGO.camera:GetPixelsToUnits()
    --print("get pos", hud.gameObject.transform:GetPosition(), hud.cameraGO.hudOriginGO.transform:GetPosition(), hud.cameraGO.camera:GetPixelsToUnits(), position, math.round(position.x), math.round(-position.y))
    return Vector2.New(math.round(position.x), math.round(-position.y))
end

local oSP = Transform.SetPosition
function Transform.SetPosition( t, position )
    --print( "transform st pos", position)
    oSP( t, position )
end

local oGP = Transform.GetPosition
function Transform.GetPosition( t )
local pos = oGP( t )
    --print( "transform GET pos", pos)
return pos
end]]

