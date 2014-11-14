
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
                if go.isScaleDown then -- scale may be up if the click happens then the cursor exit then re-enter the icon
                    go:scaleUp()
                end

                if onLeftClickReleased ~= nil then
                    onLeftClickReleased(go)
                end
            end

            -- makes the tooltip BG and arrow slighly transparent
            if tooltipGO ~= nil then
                local contentGO = tooltipGO:GetChild("Content")
                tooltipGO.textGO = tooltipGO:GetChild("Text", true)
                tooltipGO.bar1GO = tooltipGO:GetChild("Background", true)
                tooltipGO.bar2GO = tooltipGO:GetChild("Arrow", true)
                
                local oOnDisplay = tooltipGO.OnDisplay
                tooltipGO.OnDisplay = function(go)
                    if oOnDisplay ~= nil then
                        -- oOnDisplay always exists because the tooltip windows are set in the icon_tooltip group
                        oOnDisplay(go)
                    end
                    
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
                end -- tooltipGO.OnDisplay = functin(go)
                
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
        
        oFunc = windowGO.OnDisplay
        windowGO.OnDisplay = function( go )
            if go.isDisplayed then
                local gos = GameObject.GetWithTag( group )
                for i, otherGO in pairs( gos ) do
                    if otherGO ~= go and otherGO.isDisplayed then
                        otherGO:Display(false)
                    end
                end
            end
            
            if oFunc ~= nil then
                oFunc(go)
            end
        end
    end

    --   
    if eventType == "mousehover" then
        oFunc = go.OnMouseEnter
        go.OnMouseEnter = function(go)
            windowGO:Display()
            if oFunc ~= nil then
                oFunc(go)
            end
        end
        
        oFunc = go.OnMouseExit
        go.OnMouseExit = function(go)
            windowGO:Display(false)
            if oFunc ~= nil then
                oFunc(go)
            end
        end
        
    elseif eventType == "mouseclick" then
        go.windowGO = windowGO
        
        oFunc = go.OnLeftClickReleased
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
            
            if oFunc ~= nil then
                oFunc(go)
            end
        end
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


-------------------------------------------------

function Daneel.Event.Fire( object, eventName, ... )
    local arg = {...}
    Daneel.Debug.StackTrace.BeginFunction( "Daneel.Event.Fire", object, eventName, ... )
    local errorHead = "Daneel.Event.Fire( [object, ]eventName[, ...] ) : "

    local argType = type( object )
    if argType == "string" then
        -- no object provided, fire on the listeners
        if eventName ~= nil then
            table.insert( arg, 1, eventName )
        end
        eventName = object
        object = nil
    
    elseif argType ~= "nil" then
        Daneel.Debug.CheckArgType( object, "object", "table", errorHead )
        Daneel.Debug.CheckArgType( eventName, "eventName", "string", errorHead )
    end


    local listeners = { object }
    if object == nil then
        if Daneel.Event.events[ eventName ] ~= nil then
            listeners = Daneel.Event.events[ eventName ]
        end
        if Daneel.Event.persistentEvents[ eventName ] ~= nil then
            listeners = table.merge( listeners, Daneel.Event.persistentEvents[ eventName ] )
        end
    end

    local listenersToBeRemoved = {}
    for i=1, #listeners do
        local listener = listeners[i]

        local listenerType = type( listener )
        if listenerType == "function" or listenerType == "userdata" then
            if listener( unpack( arg ) ) == false then
                table.insert( listenersToBeRemoved, listener )
            end

        else -- an object
            local mt = getmetatable( listener )
            local listenerIsAlive = not listener.isDestroyed
            if mt == GameObject and listener.inner == nil then
                listenerIsAlive = false
            end
            if listenerIsAlive then -- ensure that the event is not fired on a dead game object or component
                local functions = {} -- list of listener functions attached to this object
                if listener.listenersByEvent ~= nil and listener.listenersByEvent[ eventName ] ~= nil then
                    functions = listener.listenersByEvent[ eventName ]
                end

                -- Look for the value of the EventName property on the object
                local func = rawget( listener, eventName )
                -- Using rawget() prevent a 'Behavior function' to be called as a regular function when the listener is a ScriptedBehavior
                -- because the function exists on the Script object and not on the ScriptedBehavior (the listener),
                -- in which case rawget() returns nil
                if func ~= nil then
                    table.insert( functions, func )
                end

                -- call all listener functions
                for j=1, #functions do
                    functions[j]( ... )
                end

                -- always try to send the message if the object is a game object
                if mt == GameObject then
                    listener:SendMessage( eventName, arg )
                end
            end
        end

    end -- end for listeners

    
    for i=1, #listenersToBeRemoved do
        Daneel.Event.StopListen( eventName, listenersToBeRemoved[i] )
    end
    Daneel.Debug.StackTrace.EndFunction()
end

--- Fire an event at the provided game object.
-- @param gameObject (GameObject) The game object.
-- @param eventName (string) The event name.
-- @param ... [optional] Some arguments to pass along.
function GameObject.FireEvent( gameObject, eventName, ... )
    Daneel.Event.Fire( gameObject, eventName, ... )
end

--- Add a listener function for the specified local event on this object.
-- @param object (table) The object.
-- @param eventName (string) The name of the event to listen to.
-- @param listener (function or userdata) The listener function.
function Daneel.Event.AddEventListener( object, eventName, listener )
    if object.listenersByEvent == nil then
        object.listenersByEvent = {}
    end
    if object.listenersByEvent[ eventName ] == nil then
        object.listenersByEvent[ eventName ] = {}
    end
    if not table.containsvalue( object.listenersByEvent[ eventName ], listener ) then
        table.insert( object.listenersByEvent[ eventName ], listener )
    elseif Daneel.Debug.enableDebug == true then
        print("Daneel.Event.AddEventListener(): Function "..tostring(listener).." already listen for event '"..eventName.."' on object: ", object)
    end
end

--- Add a listener function for the specified local event on this game object.
-- Alias of Daneel.Event.AddEventListener().
-- @param gameObject (GameObject) The game object.
-- @param eventName (string) The name of the event to listen to.
-- @param listener (function or userdata) The listener function.
function GameObject.AddEventListener( gameObject, eventName, listener )
    Daneel.Event.AddEventListener( gameObject, eventName, listener )
end

--- Remove the specified listener for the specified local event on this object
-- @param object (table) The object.
-- @param eventName (string) The name of the event.
-- @param listener (function or userdata) [optional] The listener function to remove. If nil, all listeners will be removed for the specified event.
function Daneel.Event.RemoveEventListener( object, eventName, listener )
    if object.listenersByEvent ~= nil and object.listenersByEvent[ eventName ] ~= nil then
        if listener ~= nil then
            table.removevalue( object.listenersByEvent[ eventName ], listener )
        else
            object.listenersByEvent[ eventName ] = nil
        end
    end
end

--- Remove the specified listener for the specified local event on this game object.
-- Alias of Daneel.Event.RemoveEventListener().
-- @param gameObject (GameObject) The game object.
-- @param eventName (string) The name of the event. May be nil or have the value of the 'listener' argument: the listener will be removed from all events.
-- @param listener (function or userdata) [optional] The listener function to remove. If nil, all listeners will be removed for the specified event.
function GameObject.RemoveEventListener( gameObject, eventName, listener )
    Daneel.Event.RemoveEventListener( gameObject, eventName, listener )
end

local s = "string"
local f = "function"
local u = "userdata"
local t = "table"

table.mergein( Daneel.Debug.functionArgumentsInfo, {
    ["Daneel.Event.Listen"] = { { "eventName", { s, t } }, { "functionOrObject", {t, f, u} }, { "isPersistent", defaultValue = false } },
    ["GameObject.FireEvent"] = { { "gameObject", "GameObject" }, { "eventName", s } },
    ["Daneel.Event.AddEventListener"] = { { "object", "table" }, { "eventName", s }, { "listener", { f, u } } },
    ["GameObject.AddEventListener"] =   { { "gameObject", "GameObject" }, { "eventName", s }, { "listener", { f, u } } },
    ["Daneel.Event.RemoveEventListener"] = { { "object", "table" }, { "eventName", s }, { "listener", { f, u }, isOptional = true } },
    ["GameObject.RemoveEventListener"] = { { "gameObject", "GameObject" }, { "eventName", s }, { "listener", { f, u }, isOptional = true } },
} )
