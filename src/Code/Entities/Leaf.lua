
function Behavior:Awake()
    self.gameObject.parent = "UI.Leaves"
    
    self.gameObject.transform.localPosition = Vector3(0)
    self.gameObject.transform.localScale = Vector3( math.randomrange(0.5,2), math.randomrange(0,2), math.randomrange(0.5,2) )
    
    self.gameObject.modelRenderer.model = "Flat Nodes/"..ColorList[math.random(#ColorList)]
    self.gameObject.modelRenderer.opacity = math.randomrange(0.2,0.8)
    
    --    
    self.rotation = Vector3( math.randomrange(0.1,0.5), math.randomrange(0.1,0.5), math.randomrange(0.1,0.5) )
    
    self.move = Vector3( math.randomrange(-0.1,0.1), math.randomrange(-0.1,0.1), 0 )
    self.gameObject.transform:MoveLocal( -self.move:Normalized() * 30 )
    
    --
    self.gameObject.EndLevel = function()
        if self.gameObject.lifeTimer ~= nil then
            self.gameObject.lifeTimer:Destroy()
            self.gameObject.lifeTimer = nil
        end
        self.gameObject:Destroy()
    end
    Daneel.Event.Listen( "EndLevel", self.gameObject )
    
    self.gameObject.lifeTimer = Tween.Timer( 10, function()
        self.gameObject.lifeTimer = nil
        Daneel.Event.StopListen( "EndLevel", self.gameObject )
        self.gameObject:Destroy()
    end )
end


function Behavior:Update()
    self.gameObject.transform:RotateLocalEulerAngles( self.rotation )
    self.gameObject.transform:MoveLocal( self.move )
end
