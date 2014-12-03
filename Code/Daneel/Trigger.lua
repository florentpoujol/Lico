--[[PublicProperties
tags string ""
range number 1
updateInterval number 5
/PublicProperties]]



function Behavior:Awake()
    print("trigger behavior")
end

function Behavior:Update()
    
end

CS.CreateGameObject("whatever"):oCreateScriptedBehavior(Behavior)
