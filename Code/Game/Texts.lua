--[[PublicProperties
key string ""
/PublicProperties]]

-- Texts for tutorials and info windows (in options menu)

Texts = {

-- Tutorials

    goal = 
[[All the coloured nodes must be linked to one or several others so that they form a single (possibly ramified) chain.
Each node can be linked to other nodess of the same color or the two closest color.
Ie:]],

    controls = 
[[Hover on a node to select it, then hover on another node to link them together (when possible).]],
    
    maxLinks =
[[The white segments around a node represents the MAXIMUM number of links a node CAN make.

You can click on a link to remove it.]],

requiredLinks = [[The black segments around a node represents the number of links the node is REQUIRED to make to complete the level.

Also, links can't cross each others.]], --'


-- Options

    colorBlindMode = [[The color-blind mode adds number on top of the nodes so that you can still know how to link them together even without seing the colors:

1 link to 6, 1 and 2
2 link to 1, 2 and 3
...
6 link to 5, 6 and 1
]] 


}



function Behavior:Start()
    local rndr = self.gameObject.textArea or self.gameObject.textRenderer
    rndr.newLine = "\n"
    rndr.text = Texts[ self.key ]
end
