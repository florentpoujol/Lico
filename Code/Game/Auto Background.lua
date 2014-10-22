--[[PublicProperties
width string ""
height string ""
/PublicProperties]]
function Behavior:Awake()
    self:SetSize( self.width, self.height )
    
end

function Behavior:SetSize( width, height )
    local size = Vector3( tonumber(width), tonumber(height), 0.1 )

    local position = size / 2
    position.y = -position.y
    position.z = -0.5
    self.gameObject.transform.localPosition = position
    self.gameObject.transform.localScale = size
end
