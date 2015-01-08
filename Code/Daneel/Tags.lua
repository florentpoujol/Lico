--[[PublicProperties
tags string ""
/PublicProperties]]
-- Tags.lua
-- Scripted behavior to add tags to game objects while in the scene editor.
--
-- Last modified for v1.3.0
-- Copyright © 2013-2014 Florent POUJOL, published under the MIT license.



function Behavior:Awake()
    if self.tags ~= "" then
        local tags = string.split( self.tags, "," )
        for i=1, #tags do
            tags[i] = string.trim( tags[i] )
        end
        self.gameObject:AddTag( tags )
    end
end

