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
    
    links =
[[Links:
Links can't cross each others.
Click on a link to remove it.

Some squares must have an exact number of links to complete the level

]]

}

function Behavior:Start()
    local rndr = self.gameObject.textArea or self.gameObject.textRenderer
    rndr.newLine = "\n"
    rndr.text = TutorialTexts[ self.key ]
end
