
Background = {}
Daneel.modules.Background = Background

function Background.Start()
    local gos = GameObject.GetWithTag("ui")
    for i, go in pairs (gos ) do
        local backgroundGO = go:GetChild("Background")
        if backgroundGO ~= nil then
            go.backgroundGO = backgroundGO
            backgroundGO:Display(false)
            
            local oOnMouseEnter = go.OnMouseEnter
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
            end
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
        windowGO.transform.localScale = 1
    end
    
    windowGO.Hide = function( go )
        windowGO.transform.localScale = 0
    end
end

local oDisplay = GameObject.Display
function GameObject.Display( go, arg1, arg2 )
    oDisplay( go, arg1, arg2 )
    --print("display", go)
    Daneel.Event.Fire( go, "OnDisplay", go )
end



-- quick fix for webplayer 
local ot = TextRenderer.SetText
function TextRenderer.SetText( tr, t )
ot( tr, tostring(t) )
end


function GetSelectedNodes()
    return GameObject.GetWithTag( "selected_node" )[1]
end


function Vector2.ToPixel( vector, camera )
    return Vector2.New(
        GUI.ToPixel( vector.x, "x", camera ),
        GUI.ToPixel( vector.y, "y", camera )
    )

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
    hud.gameObject.transform:SetPosition( newPosition )
end

function math.clamp( value, min, max )
    value = math.max( value, min )
    value = math.min( value, max )
    return value
end
