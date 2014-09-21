--[[PublicProperties
key string ""
/PublicProperties]]

-- Texts for tutorials and info windows (in options menu)

Texts = {

-- Tutorials

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

Also, links can't cross each others.]], --'


-- Options

    colorBlindMode = [[The color-blind mode adds number on top of the squares so that color-blind people can still know which color they are and how they can be linked to the other squares of the level.

Red = 1  Orange = 2   Yellow = 3  Green = 4  Blue = 5  Purple = 6

As explained in the first tutorial, squares can be linked to other squares of the same color or the two closest color.
This doesn't change with numbers :
   
1 link to 6, 1 and 2
2 link to 1, 2 and 3
3 link to 2, 3 and 4
4 link to 3, 4 and 5
5 link to 4, 5 and 6
6 link to 5, 6 and 1
]] -- '

}
-- '
function Behavior:Start()
    local rndr = self.gameObject.textArea or self.gameObject.textRenderer
    rndr.newLine = "\n"
    rndr.text = Texts[ self.key ]
end
