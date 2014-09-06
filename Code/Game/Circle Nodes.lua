--[[PublicProperties
radius number 5
startAngle number 0
/PublicProperties]]
function Behavior:Awake()
    -- put the fnodes in a perfect circle
    local nodes = self.gameObject.children
    
    -- equation of a circle
    -- x=rcosθ, y=rsinθ
    local angle = self.startAngle
    local angleOffset = 360/#nodes

    for i, go in ipairs( nodes ) do
        go.transform.localPosition = Vector3(
            self.radius * math.cos( math.rad( angle ) ),
            self.radius * math.sin( math.rad( angle ) ),
            0
        )
        angle = angle + angleOffset
    end
end
