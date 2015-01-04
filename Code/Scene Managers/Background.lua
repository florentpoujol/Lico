
local nextColorId = math.random( #ColorList )

local motifModels = {
    --CS.FindAsset("Background Motifs/Damier")
}

local backgroundManager = nil -- scripted behavior instance of the game background


function Behavior:Awake()
    self.gameObject.s = self
end


function Behavior:Init( isUIMask )
    self.rendererGO = self.gameObject:GetChild("Renderer")    
    self.maskGO = self.rendererGO:GetChild("Mask")
    self.frontGO = self.rendererGO:GetChild("Front")
    self.backGO = self.rendererGO:GetChild("Back")
    --self.motifGO = self.gameObject:GetChild("Motif")
    
    
    if isUIMask == true then
        self.gameObject.parent = GameObject.Get("UI Mask Parent")
        self.gameObject.transform.localPosition = Vector3(0,0,-1)
        self.gameObject:AddTag("uimask") -- used by level cartridge
        
        --self.motifGO:Destroy()
        self.motifGO = nil
    else
        backgroundManager = self -- used by the script when it is the UI mask
                
        self.gameObject.parent = GameObject.Get("Game Background Parent")
        self.gameObject.transform.localPosition = Vector3(0,0,-50)
        
        -- randomize the starting color
        local backColorId = nextColorId - 1
        if backColorId < 1 then
            backColorId = #ColorList
        end
        local frontColorId = backColorId - 1
        if frontColorId < 1 then
            frontColorId = #ColorList
        end
        
        self.frontGO.modelRenderer.model = "Cubes/"..ColorList[frontColorId]
        self.backGO.modelRenderer.model = "Cubes/"..ColorList[backColorId]
        
        self.frontGO:Animate("opacity", 0, 6, {
            loops = -1,
            OnLoopComplete = function(t)
                self.frontGO.modelRenderer.model = self.backGO.modelRenderer.model
                self.backGO.modelRenderer.model = "Cubes/"..ColorList[nextColorId]

                nextColorId = nextColorId + 1
                if nextColorId > #ColorList then
                    nextColorId = 1
                end
            end,
        } )
        
        -- motif
        if #motifModels > 0 then
            self.motifGO.modelRenderer.model = motifModels[ math.random( #motifModels ) ]
            self.motifGO.transform:RotateLocalEulerAngles( Vector3( 0, 0, math.random(360) ) )
        end
    end
    
    --
    self.camera = nil
    local parent = self.gameObject.parent
    if parent.camera ~= nil then -- happens in the splash screen
        self.camera = parent.camera
    else
        self.camera = parent.parent.camera
    end
    
    self:Resize()
    Daneel.Event.Listen( "OnScreenResized", function() self:Resize() end )
end


-- Called once from Awake then when the "OnScreenResized" event is fired
function Behavior:Resize()
    local orthoScale = self.camera.orthographicScale + 1
    self.rendererGO.transform.localScale = Vector3( orthoScale * CS.Screen.aspectRatio, orthoScale, 1 )
    
    if self.motifGO ~= nil then
        local halfDiagonalSize = math.sqrt( (orthoScale/2)^2 + (orthoScale * CS.Screen.aspectRatio/2)^2 )
    
        -- 512 texture pixels = 32 (512/16) scene units = 1 scale
        local scale = halfDiagonalSize / 32 * self.motifGO.transform.localScale.x
        self.motifGO.transform.localScale = Vector3( scale, scale, 1 )
    end
end


-- Used when UI Mask
-- opacity is always 1 (hide the UI) or 0
function Behavior:Animate( opacity, time, callback )
    self.frontGO.modelRenderer.model = backgroundManager.frontGO.modelRenderer.model
    self.backGO.modelRenderer.model = backgroundManager.backGO.modelRenderer.model
    
    local maskOpacity = 0
    local frontOpacity = 0
    if opacity == 1 then
        maskOpacity = backgroundManager.maskGO.modelRenderer.opacity
        frontOpacity = backgroundManager.frontGO.modelRenderer.opacity
    end    

    if time > 0 then 
        self.maskGO:Animate("opacity", maskOpacity, time, callback)
        self.frontGO:Animate("opacity", frontOpacity, time)
        self.backGO:Animate("opacity", opacity, time)
    else
        self.maskGO.modelRenderer.opacity = maskOpacity
        self.frontGO.modelRenderer.opacity = frontOpacity
        self.backGO.modelRenderer.opacity = opacity
    end
end
