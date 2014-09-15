--[[PublicProperties
key string ""
/PublicProperties]]


TutorialTexts = {
    goal = 
[[Goal:
All the coloured squares must be linked to one or several others so that they form a single (possibly ramified) chain.
Each square can connect to other squares of the same color or the two closest color.
Ie:]],

    controls = 
[[Controls:
Hover on a square to select it (press the Escape key to unselect it).
Hover another node to link them together (when possible).]],
    
    maxLinks =
[[The white segments around a node represents the MAXIMUM number of links a node CAN make.

You can click on a link to remove it.]],

requiredLinks = [[The black segments around a node represents the number of links the node is REQUIRED to make to complete the level.

Also, links can't cross each others.]],


}

function Behavior:Start()
    local rndr = self.gameObject.textArea or self.gameObject.textRenderer
    rndr.newLine = "\n"
    rndr.text = TutorialTexts[ self.key ]
end
