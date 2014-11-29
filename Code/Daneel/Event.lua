
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
