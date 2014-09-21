
-- Allow for mouse over effect other than the tooltip
-- Used in [Main Menu/Awake] and [Master Level/Awake]
function InitIcons()
    local iconGOs = GameObject.GetWithTag("icon")
    
    for i, iconGO in pairs( iconGOs ) do
        if not iconGO.isInit then
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
                if not go.windows[1].isDisplayed then
                    go:Display(0.5)
                end
                onMouseExit(go)
            end
            
            -- on left click pressed, scale down the icon
            local scaleModifier = 0.8
            rendererGO.OnClick = function(go)
                local scale = go.transform.localScale
                go.transform.localScale = scale * scaleModifier
            end
            
            local onLeftClickReleased = rendererGO.OnLeftClickReleased -- set by GO.InitWindow()
            rendererGO.OnLeftClickReleased = function(go)
                local scale = go.transform.localScale
                go.transform.localScale = scale / scaleModifier
                
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
    
    --print(windowGO)
    if windowGO == nil then
        print("GameObject.InitWindow(): Window not found", go, gameObjectNameOrAsset, eventType, tag)
        return
    end
    
    --
    go.windows = go.windows or {}
    table.insert( go.windows, windowGO )
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


function GameObject.Append( gameObject, gameObjectNameOrInstanceOrScenePath )
    local child = gameObjectNameOrInstanceOrScenePath
    if type( child ) == "string" then
        child = GameObject.Get( gameObjectNameOrInstanceOrScenePath )
        if child == nil then
            child = Scene.Append( gameObjectNameOrInstanceOrScenePath )
        end
        if child == nil then
            print("warning")
        end
    end
    
    child.parent = gameObject
    child.transform:SetLocalPosition( Vector3:New(0,0,0) )
    return child
end


-- quick fix for webplayer 
local ot = TextRenderer.SetText
function TextRenderer.SetText( tr, t )
ot( tr, tostring(t) )
end


function GetSelectedNodes()
    return GameObject.GetWithTag( "selected_node" )[1]
end

function GetPositionOnCircle( radius, angle )
    return 
    radius * math.cos( math.rad( angle ) ),
    radius * math.sin( math.rad( angle ) )
end

---------------
-- screen

CraftStudio.Screen.oSetSize = CraftStudio.Screen.SetSize

--- Sets the size of the screen, in pixels.
-- @params x (number or table) The width of the screen or a table representing the width and height as x and and y components.
-- @params y (number) [optional] The height of the screen (optional when the "x" argument is a table).
function CraftStudio.Screen.SetSize( x, y )
    if type( x ) == "table" then
        y = x.y
        x = x.x
    end
    CraftStudio.Screen.oSetSize( x, y )
    -- done here so that the aspecty ratio doesn't change is the window is not rezisable
    CraftStudio.Screen.GetSize() -- reset aspect ratio
end

--- Return the size of the screen, in pixels.
-- @return (Vector2) The screen's size.
function CraftStudio.Screen.GetSize()
    local screenSize = CraftStudio.Screen.oGetSize()
    CraftStudio.Screen.aspectRatio = screenSize.x / screenSize.y
    return setmetatable( screenSize, Vector2 )
end
CraftStudio.Screen.GetSize() -- set aspect ratio


----------
-- GUI


function GUI.TextArea.SetText( textArea, text )
    textArea.Text = text

    local lines = { text }
    if textArea.newLine ~= "" then
        lines = string.split( text, textArea.NewLine )
    end

    local textAreaScale = textArea.gameObject.transform:GetLocalScale()

    -- areaWidth is the max length in units of each line
    local areaWidth = textArea.AreaWidth
    if areaWidth ~= nil and areaWidth > 0 then
        -- cut the lines based on their length
        local tempLines = table.copy( lines )
        lines = {}

        for i = 1, #tempLines do
            local line = tempLines[i]

            if textArea.textRuler:GetTextWidth( line ) * textAreaScale.x > areaWidth then
                local newLine = ""

                for j = 1, #line do
                    local char = line:sub(j,j)
                    newLine = newLine..char

                    if textArea.textRuler:GetTextWidth( newLine ) * textAreaScale.x > areaWidth then
                        
                        if char == " " then
                            table.insert( lines, newLine:sub( 1, #newLine-1 ) )
                            newLine = char
                        else
                            -- a word is cut
                            -- go backward to find the first space char
                            local word = ""
                            for k = #newLine, 1, -1 do
                                local wordLetter = newLine:sub(k,k)
                                if wordLetter == " " then
                                    break
                                else
                                    word = wordLetter..word
                                end
                            end
                            
                            table.insert( lines, newLine:sub( 1, #newLine-#word ) )
                            newLine = word
                        end

                        if not textArea.WordWrap then
                            newLine = nil
                            break
                        end
                    end
                end

                if newLine ~= nil then
                    table.insert( lines, newLine )
                end
            else
                table.insert( lines, line )
            end
        end -- end loop on lines
    end

    if type( textArea.linesFilter ) == "function" then
        lines = textArea.linesFilter( textArea, lines ) or lines
    end
    
    local linesCount = #lines
    local lineGOs = textArea.lineGOs
    local oldLinesCount = #lineGOs
    local lineHeight = textArea.LineHeight / textAreaScale.y
    local gameObject = textArea.gameObject
    local textRendererParams = {
        font = textArea.Font,
        alignment = textArea.Alignment,
        opacity = textArea.Opacity,
    }

    -- calculate position offset of the first line based on vertical alignment and number of lines
    -- the offset is decremented by lineHeight after every lines
    local offset = -lineHeight / 2 -- verticalAlignment = "top"
    if textArea.VerticalAlignment == "middle" then
        offset = lineHeight * linesCount / 2 - lineHeight / 2
    elseif textArea.VerticalAlignment == "bottom" then
        offset = lineHeight * linesCount - lineHeight / 2
    end

    for i=1, linesCount do
        local line = lines[i]    
        textRendererParams.text = line

        if lineGOs[i] ~= nil then
            lineGOs[i].transform:SetLocalPosition( Vector3:New( 0, offset, 0 ) )
            lineGOs[i].textRenderer:Set( textRendererParams )
        else
            local newLineGO = CS.CreateGameObject( "TextArea" .. textArea.id .. "-Line" .. i, gameObject )
            newLineGO.transform:SetLocalPosition( Vector3:New( 0, offset, 0 ) )
            newLineGO.transform:SetLocalScale( Vector3:New(1) )
            newLineGO:CreateComponent( "TextRenderer" )
            newLineGO.textRenderer:Set( textRendererParams )
            table.insert( lineGOs, newLineGO )
        end

        offset = offset - lineHeight 
    end

    -- this new text has less lines than the previous one
    if linesCount < oldLinesCount then
        for i = linesCount + 1, oldLinesCount do
            lineGOs[i].textRenderer:SetText( "" ) -- don't destroy the line game object, just remove any text
        end
    end

    Daneel.Event.Fire( textArea, "OnUpdate", textArea )
end


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
    hud.gameObject.transform:SetPosition( newPosition )
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

    if valueType ~= "table" and forceUseLocalScale ~= true and renderer ~= nil then
        if display then
            value = value or renderer.displayOpacity or 1
        else
            if renderer.displayOpacity == nil then
                renderer.displayOpacity = renderer:GetOpacity()
            end
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

    gameObject.isDisplayed = display 
    Daneel.Event.Fire( gameObject, "OnDisplay", gameObject )
end


function math.clamp( value, min, max )
    value = math.max( value, min )
    value = math.min( value, max )
    return value
end

