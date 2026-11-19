

--- text that you can insert breaks into that correspond to children
--- also control sequences that set the absolute position of the latter text.
--- 
--- make it possible to resize text
--- 
--- 
--- `@[newline]` is short for `@[x: 0, dy: LINE_HEIGHT]`

--- `@[dx: var1]` basically makes the rest a child of a part at the right end of the prior
--- `@[dx: var2]`
--- ``
--- 
--- first interpret into a format where the hierarchy is clear

--- nesting
--- 


local InsertText = {}



local test_text = {
    "line 1",
    "@[part: line1, dx: 10]",
    "@[dy: 10, newline]"
}

local test_text2 = {

    main = {
        text = '["json", "allowed"]',
        height = 15
    },

    -- position(right) := e_x * width(main)
    right = {
        main = {
            key = "line2", -- sets this part and its ModelPart to be findable in a table
            model = {
                atlas = "name1" -- automatically adds the ModelPart from a table as a child.
                -- you could also just find this ModelPart and add a new child
            },
            width = 10
        },
        scale = vec(1,2)
    },
    -- position(below) := e_y * height(main)
    below = {
        main = {
            json = {
                "next",
                "row"
            }
        }
    },
    -- position(extra) := e_0
    extra = {

    },
    -- position(corner) := e_x * width(main) + e_y * height(main)
    corner = {
        
    }

    -- width(self) := max [width(main) + max[width(right),width(corner)], width(below) ]

}

---@class TextMain
---@field text string?
---@field maxwidth integer? -- for text. todo: make a special value that tracks a point.
---@field wrap boolean? -- for text
---@field json table?

---@class TextHierarchy: TextMain
---@field main? any
---@field right? TextHierarchy
---@field below? TextHierarchy
---@field corner? TextHierarchy
---@field width? number
---@field height? number
---@field scale? Vector2|number
---@field invisible boolean? -- should this change the dimensions to 0?




---recursively calculates the dimensions, ie the position of the bottom right corner in pixels
---@param textHierarchy TextHierarchy?
---@return Vector2
function InsertText.dimensions(textHierarchy)
    if not textHierarchy then
        return vec(0,0)
    end
    if textHierarchy.width and textHierarchy.height then
        return vec(textHierarchy.width,textHierarchy.height)
        -- should this use scale_x?
    end
    local main = InsertText.dimensions(textHierarchy.main)
    local max_x = main.x
    local max_y = main.y

    
    if textHierarchy.text then
        local a = client.getTextDimensions(textHierarchy.text,textHierarchy.maxwidth,textHierarchy.wrap)
        max_x = math.max(max_x, a.x)
        max_y = math.max(max_y, a.y)
    end

    if textHierarchy.right then
        local a = main.x_ + InsertText.dimensions(textHierarchy.right)
        max_x = math.max(max_x, a.x)
        max_y = math.max(max_y, a.y)
    end
    if textHierarchy.corner then
        local a = main + InsertText.dimensions(textHierarchy.corner)
        max_x = math.max(max_x, a.x)
        max_y = math.max(max_y, a.y)
    end
    if textHierarchy.below then
        local a = main._y + InsertText.dimensions(textHierarchy.below)
        max_x = math.max(max_x, a.x)
        max_y = math.max(max_y, a.y)
    end
    
    return vec(textHierarchy.width or max_x,textHierarchy.height or max_y) * (textHierarchy.scale or 1)

end



---comment
---@param part ModelPart
---@param textHierarchy table
function InsertText.init(part,textHierarchy)

    if textHierarchy.main then
        InsertText.init(
            part:newPart("main"),
            textHierarchy.main
        )
    end

    local main_corner = InsertText.dimensions(textHierarchy.main)
    
    
    

end



---comment
---@param part ModelPart
---@param text_hierarchy table
function InsertText.render(part,text_hierarchy)


end