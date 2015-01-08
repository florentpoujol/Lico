--[[PublicProperties
key string ""
/PublicProperties]]

-- Texts for tutorials and info windows (in options menu)

Texts = {

-- Tutorials

    goal = 
[[All the nodes must be linked to one or several others so that they form a single chain.
Each colors can be linked to the two closest colors, plus itself.]],

    controls = 
[[Hover on a node to select it, then hover on another node to link them together (if they can).
Click outside a node to deselect it.]],
    
    links =
[[The cubes inside each node shows the maximum number of links this node can make.

Click on a link to remove it.]],

-- Options

    colorBlindMode = [[The color-blind mode adds number on top of the nodes so that you can still know how to link them together even without distinguishing the colors:...

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
