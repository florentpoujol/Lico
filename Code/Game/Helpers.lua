
-- Allow for mouse over effect other than the tooltip
-- Used in [Main Menu/Awake] and [Master Level/Awake]
function InitIcons( iconGOs )
    if iconGOs ~= nil then
        if getmetatable( iconGOs ) == GameObject then
            iconGOs = { iconGOs }
        end
        
        for i, iconGO  in pairs( iconGOs ) do
            iconGO.isInit = false
        end
    end
    
    --
    if iconGOs == nil then
        iconGOs = GameObject.GetWithTag("icon")
    end
    
    for i, iconGO in pairs( iconGOs ) do
        if not iconGO.isInit then
            iconGO.isInit = true
            
            local rendererGO = iconGO:GetChild("Renderer")
            rendererGO:AddTag("ui")
            
            local tooltipGO = iconGO:GetChild("Tooltip")
            if tooltipGO ~= nil then
                rendererGO:InitWindow(tooltipGO, "mousehover", nil, nil, "icon_tooltip")
            end
            
            rendererGO:Display(0.5)
            
            rendererGO:AddEventListener( "OnMouseEnter", function(go) go:Display(1) end )
            
            rendererGO:AddEventListener( "OnMouseExit", function(go)
                if go.windowGO == nil or not go.windowGO.isDisplayed then -- in this last case go.windowGO is the actual window that is displayed via mouseclick event (not the tooltip)
                    go:Display(0.5)
                end
                
                if go.isScaleDown then
                    -- icon has been clicked but the mouse exited it before the OnLeftClickReleased event
                   go:scaleUp()
                end
            end )
            
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
            
            rendererGO:AddEventListener( "OnLeftClickReleased", function(go)
                if go.isScaleDown then -- scale may be up if the click happens then the cursor exit then re-enter the icon
                    go:scaleUp()
                end
            end )

            -- makes the tooltip BG and arrow slighly transparent
            if tooltipGO ~= nil then
                local contentGO = tooltipGO:GetChild("Content")
                tooltipGO.textGO = tooltipGO:GetChild("Text", true)
                tooltipGO.bar1GO = tooltipGO:GetChild("Background", true)
                tooltipGO.bar2GO = tooltipGO:GetChild("Arrow", true)
                
                tooltipGO:AddEventListener( "OnDisplay", function(go)                   
                    if go.isDisplayed then
                        tooltipGO.textGO:Display(0)
                        tooltipGO.bar1GO:Display(0)
                        tooltipGO.bar2GO:Display(0)
                        
                        tooltipGO.textGO:Animate("opacity", 1, 0.5)
                        tooltipGO.bar1GO:Animate("opacity", 1, 0.5)
                        tooltipGO.bar2GO:Animate("opacity", 1, 0.5)
                    else
                        -- "un-hide" the tooltip
                        tooltipGO.transform.localPosition = Vector3(0)
                        
                        tooltipGO.textGO:Animate("opacity", 0, 0.3)
                        tooltipGO.bar1GO:Animate("opacity", 0, 0.3)
                        tooltipGO.bar2GO:Animate("opacity", 0, 0.3, function()
                            -- "re-hide" the tooltip
                            tooltipGO.transform.localPosition = Vector3(0,0,999)
                            
                            tooltipGO.textGO:Display(1)
                            tooltipGO.bar1GO:Display(1)
                            tooltipGO.bar2GO:Display(1)
                        end)
                    end -- if go.isDisplayed 
                end )
                
                --rendererGO:InitWindow(tooltipGO, "mousehover", nil, nil, "icon_tooltip")
            end -- if tooltipGO ~= nil
        end -- if not iconGO.isInit
    end -- for i, iconGO in pairs( iconGOs )
    
    --
    local iconGOs = GameObject.GetWithTag("inactive_icon")
    
    for i, iconGO in pairs( iconGOs ) do
        if not iconGO.isInit then
            iconGO.isInit = true
            
            local rendererGO = iconGO:GetChild("Renderer")
            rendererGO:Display(0.1)
            
            local tooltipGO = iconGO:GetChild("Tooltip")
            tooltipGO.transform.localPosition = Vector3(0)
            tooltipGO:Display(false)
        end
    end
end -- InitIcons()



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
    local oFunc = nil -- orginal function
        
    if group ~= nil then
        windowGO:AddTag(group)
        
        windowGO:AddEventListener( "OnDisplay", function( go )
            if go.isDisplayed then
                local gos = GameObject.GetWithTag( group )
                for i, otherGO in pairs( gos ) do
                    if otherGO ~= go and otherGO.isDisplayed then
                        otherGO:Display(false)
                    end
                end
            end
        end )
    end

    --   
    if eventType == "mousehover" then
        go:AddEventListener( "OnMouseEnter", function(go)
            windowGO:Display()
        end )
        
        go:AddEventListener( "OnMouseExit", function(go)
            windowGO:Display(false)
        end )
        
    elseif eventType == "mouseclick" then
        go.windowGO = windowGO
        
        go:AddEventListener( "OnLeftClickReleased", function()
            if animationFunction == nil then
                if group ~= nil and not windowGO.isDisplayed then
                    windowGO:Display()
                else
                    windowGO:Display( not windowGO.isDisplayed )
                end
            else
                animationFunction( windowGO )
            end
        end )
    end
end

---------------------------


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

local o = ModelRenderer.GetOpacity
function ModelRenderer.GetOpacity( r)
    return math.round( o(r), 4 )
end

--- Returns a string representation of the vector's component's values.
-- ie: For a vector {-6.5,10}, the returned string would be "-6.5 10".
-- Such string can be converted back to a vector with string.tovector()
-- @param vector (Vector2) The vector.
-- @return (string) The string.
function Vector2.ToString( vector )
    for i, comp in pairs({"x", "y"}) do
        if tostring(vector[comp]) == "-0" then
            vector[comp] = 0
        end
    end
    return vector.x.." "..vector.y
end