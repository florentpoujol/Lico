

-------------------------------------------------------------------------------

function Sound.Play( soundAssetOrPath, volume, pitch, pan )
    local sound = Asset.Get( soundAssetOrPath, "Sound", true )
    sound:oPlay( volume or 1, pitch or 0, pan or 0 )
end

-------------------------------------------------------------------------------

local knownKeysByPrintedTable = {}
local currentlyPrintedTable = nil

--- Recursively print all key/value pairs within the provided table.
-- Fully prints the tables that have no metatable found as values.
-- @param t (table) The table to print.
-- @param maxLevel (number) [default=10] The max recursive level. Clamped between 1 and 10.
-- @param reprint (boolean) [default=false] Tell whether to print again the content of already printed table. If false a message "Already printed table with key" will be displayed as the table's value. /!\ See above for warning when maxLevel argument is -1.
function table.printr( t, maxLevel, reprint, currentLevel  )
    maxLevel = math.clamp( maxLevel or 10, 1, 10 )
    if reprint == nil then
        reprint = false
    end
    currentLevel = currentLevel or 1
    local sLevel = string.rep( "| - - - ", currentLevel-1 ) -- string level

    if t == nil then
        print(level.."table.printr2( t ) : Provided table is nil.")
        return
    end

    if currentLevel == 1 then
        for i=1, #t do
            local value = t[i]
            if type( value ) == "table" and getmetatable( value ) == nil then
                --knownKeysByPrintedTable[ value ] = i
            end
        end
    
    
        print("~~~~~ table.printr("..tostring(t)..") ~~~~~ Start ~~~~~")       
        if currentlyPrintedTable == nil then
          currentlyPrintedTable = t
        end
    end   

    local func = pairs
    if table.getlength(t) == 0 then
        print(level, "Table is empty.")
    elseif table.isarray(t) then
        func = ipairs -- just to be sure that the entries are printed in order
    end
    
    for key, value in func(t) do
        if type(key) == "string" then
            key = '"'..key..'"'
        end
        if type(value) == "string" then
            value = '"'..value..'"'
        end
        --knownKeysByPrintedTable = {}
        if type( value ) == "table" and getmetatable( value ) == nil then
            local knownKey = nil
            if reprint == false then
                knownKey = knownKeysByPrintedTable[ value ]
            end
            
            if value == currentlyPrintedTable then
                print(sLevel..tostring(key), "Table currently being printed: "..tostring(value) )
            elseif knownKey ~= nil then
                print(sLevel..tostring(key), "Already printed table with key "..knownKey..": "..tostring(value) )
                
            elseif currentLevel <= maxLevel then
                if reprint == false then
                    knownKeysByPrintedTable[ value ] = key
                end
                print(sLevel..tostring(key), value, "#"..table.getlength(value))
                
                table.printr( value, maxLevel, reprint, currentLevel + 1)
            else
                print(sLevel..tostring(key), value, "#"..table.getlength(value))
            end
        else
            print(sLevel..tostring(key), value)
        end
    end

    if currentLevel == 1 then
        print("~~~~~ table.printr("..tostring(t)..") ~~~~~ End ~~~~~")
        knownKeysByPrintedTable = {}
        currentlyPrintedTable = nil
    end
end


-------------------------------------------------------------------------------



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
