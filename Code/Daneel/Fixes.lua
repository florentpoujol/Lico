

--- Overload a function to call debug functions before and after it is itself called.
-- Called from Daneel.Load()
-- @param name (string) The function name
-- @param argsData (table) Mostly the list of arguments. may contains the 'includeInStackTrace' key.
function Daneel.Debug.RegisterFunction( name, argsData )
    if not Daneel.Config.debug.enableDebug then return end

    local includeInStackTrace = true
    if not Daneel.Config.debug.enableStackTrace then
        includeInStackTrace = false
    elseif argsData.includeInStackTrace ~= nil then
        includeInStackTrace = argsData.includeInStackTrace
    end

    local originalFunction = nil
    local originalFunctionName = name
    
    local script = argsData.script -- asset. if set the function is a public behavior function
    if script ~= nil then
        originalFunction = script[ name ]
        name = script:GetPath()..":"..name -- "Folder/ScriptName:FunctionName"
    else
        originalFunction = table.getvalue( _G, name )
    end

    local errorHead = name.."( "
    for i, arg in ipairs( argsData ) do
        if arg.name == nil then arg.name = arg[1] end
        errorHead = errorHead..arg.name..", "
    end

    errorHead = errorHead:sub( 1, #errorHead-2 ) -- removes the last coma+space
    errorHead = errorHead.." ) : "

    --
    if originalFunction ~= nil then
        local newFunction = function( ... )
            local funcArgs = { ... }

            if includeInStackTrace then
                Daneel.Debug.StackTrace.BeginFunction( name, ... )
            end

            for i, arg in ipairs( argsData ) do
                if arg.type == nil then
                    arg.type = arg[2]
                    if arg.type == nil and arg.defaultValue ~= nil then
                        arg.type = type( arg.defaultValue )
                    end
                end

                if arg.type ~= nil then
                    if arg.defaultValue ~= nil or arg.isOptional == true then
                        funcArgs[ i ] = Daneel.Debug.CheckOptionalArgType( funcArgs[ i ], arg.name, arg.type, errorHead, arg.defaultValue )
                    else
                        Daneel.Debug.CheckArgType( funcArgs[ i ], arg.name, arg.type, errorHead )
                    end

                elseif funcArgs[ i ] == nil and not arg.isOptional then
                    error( errorHead.."Argument '"..arg.name.."' is nil." )
                end

                if arg.value ~= nil then
                    funcArgs[ i ] = Daneel.Debug.CheckArgValue( funcArgs[ i ], arg.name, arg.value, errorHead, arg.defaultValue )
                end
            end

            local returnValues = { originalFunction( unpack( funcArgs ) ) } -- use unpack here to take into account the values that may have been modified by CheckOptionalArgType()

            if includeInStackTrace then
                Daneel.Debug.StackTrace.EndFunction()
            end

            return unpack( returnValues )
        end

        if script ~= nil then
            script[ originalFunctionName ] = newFunction
        else
            table.setvalue( _G, name, newFunction )
        end
    else
        print( "Daneel.Debug.RegisterFunction() : Function with name '"..name.."' was not found in the global table _G." )
    end
end

--- Register all functions of a scripted behavior to be included in the stacktrace.
-- Within a script, the 'Behavior' variable is the script asset.
-- @param script (Script) The script asset.
function Daneel.Debug.RegisterScript( script )
    if type( script ) ~= "table" or getmetatable( script ) ~= Script then
        error("Daneel.Debug.SetupScript(script): Provided argument is not a script asset. Within a script, the 'Behavior' variable is the script asset.")
    end
    local infos = Daneel.Debug.functionArgumentsInfo
    local forbiddenNames = { "Update", "inner" }
    for name, func in pairs( script ) do
        if 
            not name:startswith("__") and
            not table.containsvalue( forbiddenNames, name ) and
            infos[name] == nil
        then
            infos[name] = { script = script }
        end
    end
end

function Daneel.Load()
    if Daneel.isLoaded then return end
    Daneel.isLoading = true

    -- load Daneel config
    local userConfig = nil
    if Daneel.UserConfig ~= nil then
        table.mergein( Daneel.Config, Daneel.UserConfig(), true )
    end

    -- load modules config
    for i, name in ipairs( Daneel.modules.moduleNames ) do
        local module = Daneel.modules[ name ]

        if module.isConfigLoaded ~= true then
            module.isConfigLoaded = true

            if module.Config == nil then
                if module.DefaultConfig ~= nil then
                    module.Config = module.DefaultConfig()
                else
                    module.Config = {}
                end
            end

            if module.UserConfig ~= nil then
                table.mergein( module.Config, module.UserConfig(), true )
            end

            if module.Config.objectsByType ~= nil then
                table.mergein( Daneel.Config.objectsByType, module.Config.objectsByType )
            end

            if module.Config.componentObjectsByType ~= nil then
                table.mergein( Daneel.Config.componentObjectsByType, module.Config.componentObjectsByType )
                table.mergein( Daneel.Config.objectsByType, module.Config.componentObjectsByType )
            end
        end
    end

    table.mergein( Daneel.Config.objectsByType, Daneel.Config.componentObjectsByType, Daneel.Config.assetObjectsByType )

    -- Enable nice printing + dynamic access of getters/setters on components
    for componentType, componentObject in pairs( Daneel.Config.componentObjectsByType ) do
        Daneel.Utilities.AllowDynamicGettersAndSetters( componentObject, { Component } )

        if componentType ~= "ScriptedBehavior" then
            componentObject["__tostring"] = function( component )
                return componentType .. ": " .. component:GetId()
            end
        end
    end

    table.mergein( Daneel.Config.componentTypes, table.getkeys( Daneel.Config.componentObjectsByType ) )

    -- Enable nice printing + dynamic access of getters/setters on assets
    for assetType, assetObject in pairs( Daneel.Config.assetObjectsByType ) do
        Daneel.Utilities.AllowDynamicGettersAndSetters( assetObject, { Asset } )

        assetObject["__tostring"] = function( asset )
            return  assetType .. ": " .. Daneel.Utilities.GetId( asset ) .. ": '" .. Map.GetPathInPackage( asset ) .. "'"
        end
    end
    
    if Daneel.Config.debug.enableDebug then
        if Daneel.Config.debug.enableStackTrace then
            Daneel.Debug.SetNewError()
        end

        -- overload functions with debug (error reporting + stacktrace)
        for funcName, data in pairs( Daneel.Debug.functionArgumentsInfo ) do
            Daneel.Debug.RegisterFunction( funcName, data )
        end
    end

    CS.IsWebPlayer = type( Camera.ProjectionMode.Orthographic ) == "number" -- "userdata" in native runtimes

    Daneel.Debug.StackTrace.BeginFunction( "Daneel.Load" )

    -- Load modules
    for i, name in ipairs( Daneel.modules.moduleNames ) do
        local module = Daneel.modules[ name ]
        if module.isLoaded ~= true then
            module.isLoaded = true
            if type( module.Load ) == "function" then
                module.Load()
            end
        end
    end

    Daneel.isLoaded = true
    Daneel.isLoading = false
    if Daneel.Config.debug.enableDebug then
        print( "~~~~~ Daneel loaded ~~~~~" )
    end

    -- check for module update functions
    Daneel.moduleUpdateFunctions = {}
    for i, name in ipairs( Daneel.modules.moduleNames ) do
        local module = Daneel.modules[ name ]
        if module.doNotCallUpdate ~= true then
            if type( module.Update ) == "function" and not table.containsvalue( Daneel.moduleUpdateFunctions, module.Update ) then
                table.insert( Daneel.moduleUpdateFunctions, module.Update )
            end
        end
    end

    Daneel.Debug.StackTrace.EndFunction()
end -- end Daneel.Load()





local _transform = { "transform", "Transform" }
local v3 = "Vector3"
table.mergein( Daneel.Debug.functionArgumentsInfo, {

    -- every CS functions that are not 
    ["Transform.SetPosition"] =             { _transform, { "position", v3 } },
    ["Transform.SetLocalPosition"] =        { _transform, { "position", v3 } },
    ["Transform.SetEulerAngles"] =          { _transform, { "angles", v3 } },
    ["Transform.SetLocalEulerAngles"] =     { _transform, { "angles", v3 } },
    ["Transform.Move"] =                    { _transform, { "offset", v3 } },
    ["Transform.MoveLocal"] =               { _transform, { "offset", v3 } },
    ["Transform.MoveOriented"] =            { _transform, { "offset", v3 } },
    ["Transform.RotateEulerAngles"] =       { _transform, { "angles", v3 } },
    ["Transform.RotateLocalEulerAngles"] =  { _transform, { "angles", v3 } },
    ["Transform.LookAt"] =                  { _transform, { "target", v3 } },
    ["Transform.SetOrientation"] =      { _transform, { "orientation", "Quaternion" } },
    ["Transform.SetLocalOrientation"] = { _transform, { "orientation", "Quaternion" } },
    ["Transform.Rotate"] =              { _transform, { "orientation", "Quaternion" } },
    ["Transform.RotateLocal"] =         { _transform, { "orientation", "Quaternion" } },

} )