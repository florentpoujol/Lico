
function Sound.Play( soundAssetOrPath, volume, pitch, pan )
    local sound = Asset.Get( soundAssetOrPath, "Sound", true )
    sound:oPlay( volume or 1, pitch or 0, pan or 0 )
end




local function GetTweenerProperty(tweener)
    if tweener.target ~= nil then
        Daneel.Debug.StackTrace.BeginFunction("GetTweenerProperty", tweener)
        local value = nil
        value = tweener.target[tweener.property]
        if value == nil then
            -- 04/06/2014 : this piece of code allows tweeners to work even on objects that do not have Daneel's dynamic getters and setters.
            local functionName = "Get"..string.ucfirst( tweener.property )
            if tweener.target[functionName] ~= nil then
                value = tweener.target[functionName](tweener.target)
            end
        end
        Daneel.Debug.StackTrace.EndFunction()
        return value
    end
end

Tween.Tweener.newTweeners = {}
Tween.Tweener.tweeners = {}

local o = Tween.Tweener.New
function Tween.Tweener.New(target, property, endValue, duration, onCompleteCallback, params)
    Daneel.Debug.StackTrace.BeginFunction("Tween.Tweener.New", target, property, endValue, duration, params)
    local errorHead = "Tween.Tweener.New(target, property, endValue, duration[, params]) : "
    
    local tweener = table.copy(Tween.Config.tweener)
    setmetatable(tweener, Tween.Tweener)
    tweener.id = Daneel.Utilities.GetId()

    -- three constructors :
    -- target, property, endValue, duration, [onCompleteCallback, params]
    -- startValue, endValue, duration, [onCompleteCallback, params]
    -- params
    local targetType = type( target )
    local mt = nil
    if targetType == "table" then 
        mt = getmetatable( target )
    end

    if 
        targetType == "number" or targetType == "string" or 
        mt == Vector2 or mt == Vector3
    then
        -- constructor n°2
        params = onCompleteCallback
        onCompleteCallback = duration
        duration = endValue
        endValue = property
        local startValue = target
        
        errorHead = "Tween.Tweener.New(startValue, endValue, duration[, onCompleteCallback, params]) : "

        Daneel.Debug.CheckArgType(duration, "duration", "number", errorHead)
        if type( onCompleteCallback ) == "table" then
            params = onCompleteCallback
            onCompleteCallback = nil
        end
        Daneel.Debug.CheckOptionalArgType(onCompleteCallback, "onCompleteCallback", "function", errorHead)
        Daneel.Debug.CheckOptionalArgType(params, "params", "table", errorHead)

        tweener.startValue = startValue
        tweener.endValue = endValue
        tweener.duration = duration
        if onCompleteCallback ~= nil then
            tweener.OnComplete = onCompleteCallback
        end
        if params ~= nil then
            tweener:Set(params)
        end
    elseif property == nil then
        -- constructor n°3
        Daneel.Debug.CheckArgType(target, "params", "table", errorHead)
        errorHead = "Tween.Tweener.New(params) : "
        tweener:Set(target)
    else
        -- constructor n°1
        Daneel.Debug.CheckArgType(target, "target", "table", errorHead)
        Daneel.Debug.CheckArgType(property, "property", "string", errorHead)
        Daneel.Debug.CheckArgType(duration, "duration", "number", errorHead)
        if type( onCompleteCallback ) == "table" then
            params = onCompleteCallback
            onCompleteCallback = nil
        end
        Daneel.Debug.CheckOptionalArgType(onCompleteCallback, "onCompleteCallback", "function", errorHead)
        Daneel.Debug.CheckOptionalArgType(params, "params", "table", errorHead)

        tweener.target = target
        tweener.property = property
        tweener.endValue = endValue
        tweener.duration = duration
        if onCompleteCallback ~= nil then
            tweener.OnComplete = onCompleteCallback
        end
        if params ~= nil then
            tweener:Set(params)
        end
    end

    if tweener.endValue == nil then
        error("Tween.Tweener.New(): 'endValue' property is nil for tweener: "..tostring(tweener))
    end
    
    if tweener.startValue == nil then
        tweener.startValue = GetTweenerProperty( tweener )
    end

    if tweener.target ~= nil then
        tweener.gameObject = tweener.target.gameObject
    end

    tweener.valueType = Daneel.Debug.GetType( tweener.startValue )

    if tweener.valueType == "string" then
        tweener.startStringValue = tweener.startValue
        tweener.stringValue = tweener.startStringValue
        tweener.endStringValue = tweener.endValue
        tweener.startValue = 1
        tweener.endValue = #tweener.endStringValue
    end
    
    Tween.Tweener.newTweeners[tweener.id] = tweener
    Daneel.Debug.StackTrace.EndFunction()
    return tweener
end


function Tween.Awake()
    -- In Awake() to let other modules update Tween.Config.propertiesByComponentName from their Load() function
    -- Actually this should be done automatically (without things to set up in the config) by looking up the functions on the components' objects
    local t = {}
    for compName, properties in pairs( Tween.Config.propertiesByComponentName ) do
        for i=1, #properties do
            local property = properties[i]
            t[ property ] = t[ property ] or {}
            table.insert( t[ property ], compName )
        end
    end
    Tween.Config.componentNamesByProperty = t

    -- destroy and sanitize the tweeners when the scene loads
    table.mergein( Tween.Tweener.tweeners, Tween.Tweener.newTweeners )
    Tween.Tweener.newTweeners = {}
    for id, tweener in pairs( Tween.Tweener.tweeners ) do
        if tweener.destroyOnSceneLoad then
            tweener:Destroy()
        end
    end
end

local o = Tween.Update
function Tween.Update()
    table.mergein( Tween.Tweener.tweeners, Tween.Tweener.newTweeners)
    Tween.Tweener.newTweeners = {}
    
    o()
end -- end Tween.Update
