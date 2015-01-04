--[[PublicProperties
target string ""
tag string ""
/PublicProperties]]
--[[PublicProperties
target string ""
tag string ""
/PublicProperties]]
function Behavior:Awake()
    self.gameObject:AddTag(self.tag)
    
    local target = self.target
    if target == "" then
        target = self.gameObject.textRenderer.text
    end
    if not string.startswith( target, "http://" ) and not string.startswith( target, "https://" ) then
        target = "http://"..target
    end
    self.gameObject.OnLeftClickReleased = function()
        CS.Web.Open( target )
    end
    
    self.gameObject.OnMouseEnter = function()
        self.gameObject:Display(0.5)
    end
    
    self.gameObject.OnMouseExit = function()
        self.gameObject:Display(1)
    end
end
