--[[PublicProperties
damage number 0
/PublicProperties]]


function Behavior:Awake( a )
    do return end
    if a ~= true then
        --print("redirecting")
        --self:Awake( true )
        --return
    end
    
    Daneel.Debug.StackTrace.BeginFunction("TestSB:Awake", self)
    
    

    if self.damage > 5 then
        self.damage = tostring( self.damage )
    else
        --error("whatever 1 ")
    end
    
    self.TestFunc( self.damage )
    
    Daneel.Debug.StackTrace.EndFunction()
end


function Behavior:TestFunc( damage )

    --error("whatever 2 ")
--    self.gameObject.transform.position = Vector2(0)
end

--Daneel.Debug.functionArgumentsInfo.TestFunc = { script = Behavior }

Daneel.Debug.RegisterScript( Behavior )
