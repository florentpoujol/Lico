

-- Allow for mouse over effect other than the tooltip
-- Used in [Main Menu/Awake] and [Master Level/Awake]
-- Ideally call after InitWindow()
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
            
            local iconType = 1
            if iconGO:HasTag("icon_type_2", true) then
                iconType = 2
            end
            
            if iconType == 1 then

                local rendererGO = iconGO:GetChild("Renderer")
                if rendererGO == nil then
                    print("no renderer GO on icon", iconGO)
                end
                rendererGO:AddTag("ui")
                
                
                
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
                
                rendererGO:AddEventListener( "OnClick", function(go)
                    go:scaleDown()
                end )
                
                rendererGO:AddEventListener( "OnLeftClickReleased", function(go)
                    if go.isScaleDown then -- scale may be up if the click happens then the cursor exit then re-enter the icon
                        go:scaleUp()
                    end
                end )
                
                
                local tooltipGO = iconGO:GetChild("Tooltip")
                               
                -- makes the tooltip BG and arrow slighly transparent
                if tooltipGO ~= nil then
                    rendererGO:InitWindow(tooltipGO, "mousehover", nil, nil, "icon_tooltip")
                
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
                end -- if tooltipGO ~= nil
            
            
            elseif iconType == 2 then
                
                local backgroundGO = iconGO.child:GetChild("Background")
                local color = NiceColorsByName[ backgroundGO.modelRenderer.model.name:lower() ]
                backgroundGO.modelRenderer.color = color

                local hiddenPosition = iconGO.transform.localPosition
                local displayPosition = hiddenPosition + Vector3(0,0.7,0)

                backgroundGO:AddTag("ui")
                
                backgroundGO:AddEventListener( "OnMouseEnter", function(go)
                    if go.windowGO == nil or not go.windowGO.isDisplayed then
                        --backgroundGO.modelRenderer.opacity = 1
                        iconGO.transform.localPosition = displayPosition
                    end
                end )
                
                backgroundGO:AddEventListener( "OnMouseExit", function(go)
                    if go.windowGO == nil or not go.windowGO.isDisplayed then -- in this last case go.windowGO is the actual window that is displayed via mouseclick event (not the tooltip)
                        --backgroundGO.modelRenderer.opacity = 0
                        iconGO.transform.localPosition = hiddenPosition
                    end
                end )
                
                if backgroundGO.windowGO ~= nil then
                    backgroundGO.windowGO:AddEventListener( "OnDisplay", function(go)
                        if go.isDisplayed == true then
                            --backgroundGO.modelRenderer.opacity = 1
                            iconGO.transform.localPosition = displayPosition
                        else
                            --backgroundGO.modelRenderer.opacity = 0
                            iconGO.transform.localPosition = hiddenPosition
                        end
                    end)
                end
                
                local tooltipGO = iconGO:GetChild("Tooltip")
                if tooltipGO ~= nil then
                    backgroundGO:InitWindow(tooltipGO, "mousehover", nil, nil, "icon_tooltip")
                    tooltipGO:GetChild("Background", true).modelRenderer.color = color
                end
            end -- if iconType
            
        end -- if not iconGO.isInit
    end -- for iconGOs
    
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



function GameObject.InitWindow( buttonGO, gameObjectNameOrAsset, eventType, buttonTag, animationFunction, group )
    local windowGO = gameObjectNameOrAsset
    if type(gameObjectNameOrAsset) == "string" then
        windowGO = buttonGO:GetChild( gameObjectNameOrAsset ) or GameObject.Get( gameObjectNameOrAsset )
    end
    
    if windowGO == nil then
        print("GameObject.InitWindow(): Window not found", buttonGO, gameObjectNameOrAsset, eventType, buttonTag)
        return
    end
    
    --
    windowGO.buttonGO = buttonGO
    windowGO.transform.localPosition = Vector3(0)
    windowGO:Display(false)
    
    --
    if buttonTag ~= nil then
        print("add tag on button", buttonTag, buttonGO, windowGO)
        buttonGO:AddTag(buttonTag)
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
        buttonGO:AddEventListener( "OnMouseEnter", function(go)
            windowGO:Display()
        end )
        
        buttonGO:AddEventListener( "OnMouseExit", function(go)
            windowGO:Display(false)
        end )
        
    elseif eventType == "mouseclick" then
        buttonGO.windowGO = windowGO
        
        buttonGO:AddEventListener( "OnLeftClickReleased", function()
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
    
    elseif eventType == "mouse" then
        buttonGO.windowGO = windowGO
        buttonGO.hideOnMouseExit = true
           
        buttonGO:AddEventListener( "OnMouseEnter", function(go)
            go.windowGO:Display()
        end )
        
        buttonGO:AddEventListener("OnMouseExit", function(go)
            if go.hideOnMouseExit == true then
                go.windowGO:Display(false)
            end
        end)
        
        buttonGO:AddEventListener( "OnLeftClickReleased", function(go)
            go.hideOnMouseExit = not go.hideOnMouseExit
        end )
    end
end

---------------------------

-- Used in [Main Menu].
-- Parent the provided child to the game object and set the child at a position of 0,0,0
-- The child can be the path of a scene.
function GameObject.Append( gameObject, gameObjectNameOrInstanceOrScenePath, localPosition )
    local child = gameObjectNameOrInstanceOrScenePath
    if type( child ) == "string" then
        child = GameObject.Get( gameObjectNameOrInstanceOrScenePath )
        if child == nil then
            child = Scene.Append( gameObjectNameOrInstanceOrScenePath )
        end
        if child == nil then
            print("GameObject.Append(): WARNING: child is nil", gameObject, gameObjectNameOrInstanceOrScenePath )
        end
    end
    
    child.parent = gameObject
    localPosition = localPosition or Vector3.New(0,0,0)
    child.transform:SetLocalPosition( localPosition )
    return child
end

------------------------

function Vector2.GetDistance( a, b )
    return ( b - a ):GetLength()
end

function Vector2.GetSqrDistance( a, b )
    return ( b - a ):GetSqrLength()
end

local frameCount = 0

function MouseInput.Update( mouseInput )
    local forceUpdate = false
    local components = MouseInput.components
    if mouseInput ~= nil then
        forceUpdate = true
        components = { mouseInput }
    end
    if #components == 0 then
        return
    end
    
    local mouseDelta = CS.Input.GetMouseDelta()
    local mouseIsMoving = false
    if mouseDelta.x ~= 0 or mouseDelta.y ~= 0 then
        mouseIsMoving = true
    end
    local levelMousePosition = Game.levelMousePosition

    local leftMouseJustPressed = false
    local leftMouseDown = false
    local leftMouseJustReleased = false
    if MouseInput.buttonExists.LeftMouse then
        leftMouseJustPressed = CS.Input.WasButtonJustPressed( "LeftMouse" )
        leftMouseDown = CS.Input.IsButtonDown( "LeftMouse" )
        leftMouseJustReleased = CS.Input.WasButtonJustReleased( "LeftMouse" )
    end

    local rightMouseJustPressed = false
    if MouseInput.buttonExists.RightMouse then
        rightMouseJustPressed = CS.Input.WasButtonJustPressed( "RightMouse" )
    end

    local wheelUpJustPressed = false
    if MouseInput.buttonExists.WheelUp then
        wheelUpJustPressed = CS.Input.WasButtonJustPressed( "WheelUp" )
    end

    local wheelDownJustPressed = false
    if MouseInput.buttonExists.WheelDown then
        wheelDownJustPressed = CS.Input.WasButtonJustPressed( "WheelDown" )
    end
    
    if 
        forceUpdate == true or
        mouseIsMoving == true or
        leftMouseJustPressed == true or 
        leftMouseDown == true or
        leftMouseJustReleased == true or 
        rightMouseJustPressed == true or
        wheelUpJustPressed == true or
        wheelDownJustPressed == true
    then
        frameCount = frameCount + 1
        if 
            forceUpdate == false and
            mouseIsMoving == true and
            leftMouseJustPressed == false and
            leftMouseDown == false and
            leftMouseJustReleased == false and
            rightMouseJustPressed == false and
            wheelUpJustPressed == false and
            wheelDownJustPressed == false and
            frameCount % 3 == 0
        then
            return
        end
    
        local doubleClick = false
        if leftMouseJustPressed then
            doubleClick = ( Daneel.Time.frameCount <= MouseInput.lastLeftClickFrame + MouseInput.Config.doubleClickDelay )   
            MouseInput.lastLeftClickFrame = Daneel.Time.frameCount
        end

        local reindexComponents = false
        
        for i=1, #components do
            local component = components[i]
            local mi_gameObject = component.gameObject -- mouse input game object

            if mi_gameObject.inner ~= nil and not mi_gameObject.isDestroyed and mi_gameObject.camera ~= nil then
                local ray = mi_gameObject.camera:CreateRay( CS.Input.GetMousePosition() )
                
                for j=1, #component._tags do
                    local tag = component._tags[j]
                    local gameObjects = GameObject.GetWithTag( tag )

                    for k=1, #gameObjects do
                        local gameObject = gameObjects[k]
                        -- gameObject is the game object whose position is checked against the raycasthit
                        
                        local raycastHit = nil
                        
                        if tag == "node" then
                            local boundaries = nil
                            if gameObject.s ~= nil then
                                boundaries = gameObject.s.nodeBoundaries
                            end
                            local nodeLevelPlane = gameObject.levelPlane
                            
                            if 
                                nodeLevelPlane ~= nil and nodeLevelPlane == Game.hoveredLevelPlane and
                                boundaries ~= nil and
                                levelMousePosition.x >= boundaries.min.x and levelMousePosition.x <= boundaries.max.x and
                                levelMousePosition.y >= boundaries.min.y and levelMousePosition.y <= boundaries.max.y
                            then
                                raycastHit = {}
                            end    
                        else
                            raycastHit = ray:IntersectsGameObject( gameObject )
                        end
                        
                        if gameObject.name == "Level Plane" then
                            --print("level plane", raycastHit, boundaries)
                        end
                        
                        if raycastHit ~= nil then
                            -- the mouse pointer is over the gameObject
                            if not gameObject.isMouseOver then
                                gameObject.isMouseOver = true
                                Daneel.Event.Fire( gameObject, "OnMouseEnter", gameObject )
                            end

                        elseif gameObject.isMouseOver == true then
                            -- the gameObject was still hovered the last frame
                            gameObject.isMouseOver = false
                            Daneel.Event.Fire( gameObject, "OnMouseExit", gameObject )
                        end
                        
                        if gameObject.isMouseOver == true then
                            Daneel.Event.Fire( gameObject, "OnMouseOver", gameObject, raycastHit )
                            
                            if leftMouseJustPressed == true then
                                Daneel.Event.Fire( gameObject, "OnClick", gameObject )

                                if doubleClick == true then
                                    Daneel.Event.Fire( gameObject, "OnDoubleClick", gameObject )
                                end
                            end

                            if leftMouseDown == true and mouseIsMoving == true then
                                Daneel.Event.Fire( gameObject, "OnDrag", gameObject )
                            end

                            if leftMouseJustReleased == true then
                                Daneel.Event.Fire( gameObject, "OnLeftClickReleased", gameObject )
                            end

                            if rightMouseJustPressed == true then
                                Daneel.Event.Fire( gameObject, "OnRightClick", gameObject )
                            end

                            if wheelUpJustPressed == true then
                                Daneel.Event.Fire( gameObject, "OnWheelUp", gameObject )
                            end
                            if wheelDownJustPressed == true then
                                Daneel.Event.Fire( gameObject, "OnWheelDown", gameObject )
                            end
                        end
                    end -- for gameObjects with current tag
                end -- for component._tags
            else
                -- this component's game object is dead or has no camera component
                components[i] = nil
                reindexComponents = true
            end -- gameObject is alive
        end -- for components

        if reindexComponents == true and mouseInput == nil then
            MouseInput.components = table.reindex( components )
        end
    end -- if mouseIsMoving, ...
end -- end MouseInput.Update()

------------------------

-- IMPORTANT
-- because some menu elements are position on the X,Y plane via a Hud component, 
-- they must be Displayed/hidden by being moved on the Z axis only

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