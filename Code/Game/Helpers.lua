
-- Allow for mouse over effect other than the tooltip
-- Used in [Main Menu/Awake] and [Master Level/Awake]
function InitIcons()
    local iconGOs = GameObject.GetWithTag("icon")
    
    for i, iconGO in pairs( iconGOs ) do
        if not iconGO.isInit then
        print("init icon", iconGO)
            iconGO.isInit = true
            
            local rendererGO = iconGO:GetChild("Renderer")
            rendererGO:AddTag("ui")
            
            local tooltipGO = iconGO:GetChild("Tooltip")
            rendererGO:InitWindow(tooltipGO, "mousehover", nil, nil, "icon_tooltip")
            
            rendererGO:Display(0.5)
            
            -- override OnMouseEnter/Exit set by GO.InitWindow()
            local onMouseEnter = rendererGO.OnMouseEnter
            rendererGO.OnMouseEnter = function(go)
                rendererGO:Display(1)               
                onMouseEnter(go)
            end
            
            local onMouseExit = rendererGO.OnMouseExit
            rendererGO.OnMouseExit = function(go)
                if go.windowGO == nil or not go.windowGO.isDisplayed then -- in this last case go.windowGO is the actual window that is displayed via mouseclick event (not the tooltip)
                    go:Display(0.5)
                end
                
                if go.isScaleDown then
                    -- icon has been clicked but the mouse exited it before the OnLeftClickReleased event
                   go:scaleUp()
                end
                
                onMouseExit(go)
            end
            
            -- on left click pressed, scale down the icon
            local scaleModifier = 0.8
            rendererGO.isScaleDown = false
            
            function rendererGO.scaleUp(go)
                local scale = go.transform.localScale
                go.transform.localScale = scale / scaleModifier
                go.isScaleDown = false
            end
            function rendererGO.scaleDown(go)
                local scale = go.transform.localScale
                go.transform.localScale = scale * scaleModifier
                go.isScaleDown = true
            end
            
            rendererGO.OnClick = function(go)
                go:scaleDown()
            end
            
            local onLeftClickReleased = rendererGO.OnLeftClickReleased -- set by GO.InitWindow()
            rendererGO.OnLeftClickReleased = function(go)
                print("OnLeftClickReleased", go, go.isScaleDown)
                if go.isScaleDown then -- scale may be up if the click happens then the cursor exit then re-enter the icon
                    go:scaleUp()
                end

                if onLeftClickReleased ~= nil then
                    onLeftClickReleased()
                end
            end

            -- makes the tooltip BG and arrow slighly transparent
            local tooltipGO = iconGO:GetChild("Tooltip")
            if tooltipGO ~= nil then
                local bg = tooltipGO:GetChild("Background", true)
                bg.modelRenderer.opacity = 0.6
                tooltipGO:GetChild("Arrow", true).textRenderer.opacity = 0.6
            end
        end
    end
end



function GameObject.InitWindow( go, gameObjectNameOrAsset, eventType, tag, animationFunction, group )
    local windowGO = gameObjectNameOrAsset
    if type(gameObjectNameOrAsset) == "string" then
        windowGO = go:GetChild( gameObjectNameOrAsset ) or GameObject.Get( gameObjectNameOrAsset )
    end
    
    if windowGO == nil then
        print("GameObject.InitWindow(): Window not found", go, gameObjectNameOrAsset, eventType, tag)
        return
    end
    
    --
    windowGO.buttonGO = go

    windowGO.transform.localPosition = Vector3(0)
    windowGO:Display(false)
    
    --
    if tag ~= nil then
        go:AddTag(tag)
    end

    --  
    if group ~= nil then
        windowGO:AddTag(group)
        windowGO.OnDisplay = function( go )

            if go.isDisplayed then
                local gos = GameObject.GetWithTag( group )
                for i, otherGO in pairs( gos ) do
                    if otherGO ~= go and otherGO.isDisplayed then
                        otherGO:Display(false)
                    end
                end
            end
        end
    end

    --
    if eventType == "mousehover" then
        go.OnMouseEnter = function()
            windowGO:Display()
        end
        go.OnMouseExit = function()
            windowGO:Display(false)
        end
        
    elseif eventType == "mouseclick" then
        go.windowGO = windowGO
        
        go.OnLeftClickReleased = function()
            if animationFunction == nil then
                if group ~= nil and not windowGO.isDisplayed then
                    windowGO:Display()
                else
                    windowGO:Display( not windowGO.isDisplayed )
                end
            else
                animationFunction( windowGO )
            end
        end
    end
end



---------------------------

-- Used in [Main Menu].
-- Parent the provided child to the game object and set the child at a position of 0,0,0
-- The child can be the path of a scene.
function GameObject.Append( gameObject, gameObjectNameOrInstanceOrScenePath )
    local child = gameObjectNameOrInstanceOrScenePath
    if type( child ) == "string" then
        child = GameObject.Get( gameObjectNameOrInstanceOrScenePath )
        if child == nil then
            child = Scene.Append( gameObjectNameOrInstanceOrScenePath )
        end
        if child == nil then
            print("warning: GameObject.Append() child is nil", gameObject, gameObjectNameOrInstanceOrScenePath )
        end
    end
    
    child.parent = gameObject
    child.transform:SetLocalPosition( Vector3:New(0,0,0) )
    return child
end


------------------------

-- IMPORTANT
-- because some menu elements are position on the X,Y plane via a Hud component, 
-- they must be Displayed/hidden by being moving them on the Z axis only

function GameObject.Display( gameObject, value, forceUseLocalPosition )
    local display = false
    if value ~= false and value ~= 0 then -- nil, true or non 0 value
        display = true
    end

    local valueType = type(value)
    if valueType == "boolean" then
        value = nil
    elseif valueType == "number" and forceUseLocalPosition == true then
        value = Vector3:New(value)
        valueType = "table"
    end  

    --
    local renderer = gameObject.textRenderer or gameObject.modelRenderer or gameObject.mapRenderer
    
    if renderer ~= nil and forceUseLocalPosition ~= true and valueType == "number" then
        if not display and gameObject.displayOpacity == nil then
            gameObject.displayOpacity = renderer:GetOpacity()
        end
        if display then
            value = value or gameObject.displayOpacity or 1
        else
            value = value or 0
        end
        renderer:SetOpacity( value )
    else
        if not display and gameObject.displayLocalPosition == nil then
            gameObject.displayLocalPosition = gameObject.transform:GetLocalPosition()
        end
        if display then
            value = value or gameObject.displayLocalPosition or Vector3:New(0)
        else
            value = value or Vector3:New(0,0,999) -- See important notice above
        end
        gameObject.transform:SetLocalPosition( value )
    end

    gameObject.isDisplayed = display 
    Daneel.Event.Fire( gameObject, "OnDisplay", gameObject )
end


-----------------


-- quick fix for webplayer 
local ot = TextRenderer.SetText
function TextRenderer.SetText( tr, t )
    ot( tr, tostring(t) )
end


function GetPositionOnCircle( radius, angle )
    return 
    radius * math.cos( math.rad( angle ) ),
    radius * math.sin( math.rad( angle ) )
end
