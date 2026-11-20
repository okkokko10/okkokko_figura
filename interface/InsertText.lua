

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


InsertText = {}



local test_text = {
    "line 1",
    "@[part: line1, dx: 10]",
    "@[dy: 10, newline]"
}

InsertText.test_text2 = {

    main = {
        text = '["json", " ", "allowed"]',
        height = 15
    },

    -- position(right) := e_x * width(main)
    right = {
        main = {
            key = "line2", -- sets this part and its ModelPart to be findable in a table
            -- model = {
            --     atlas = "name1" -- automatically adds the ModelPart from a table as a child.
            --     -- you could also just find this ModelPart and add a new child
            -- },
            model = "name1",
            width = 10
        },
        scale = vec(1,2),
        right = {
            text = "right"
        }
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
---@field model ModelPart|string?
---@field key string?
---@field onClick fun(pos:Vector3)?



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





---creates parts
---@param part ModelPart
---@param textHierarchy TextHierarchy
---@param state {atlas: {[string]: ModelPart}, names: {[string]: ModelPart}}
function InsertText.init(part,textHierarchy,state)

    part:newBlock("dummy"):block("minecraft:target"):setScale(1/16)

    if textHierarchy.main then
        InsertText.init(
            part:newPart("main"),
            textHierarchy.main,
            state
        )
    end

    local main_corner = InsertText.dimensions(textHierarchy.main)

    if textHierarchy.right then
        
        InsertText.init(
            part:newPart("main"):setPos(-main_corner.x__),
            textHierarchy.right,
            state
        )
        
    end
    if textHierarchy.below then
        InsertText.init(
            part:newPart("main"):setPos(-main_corner._y_),
            textHierarchy.below,
            state
        )
        
    end
    if textHierarchy.corner then
        
        InsertText.init(
            part:newPart("main"):setPos(-main_corner.xy_),
            textHierarchy.corner,
            state
        )
    end

    local text = textHierarchy.json and toJson(textHierarchy.json) or textHierarchy.text
    if text then
        part:newText("text"):setWidth(textHierarchy.width):setWrap(textHierarchy.wrap):setText(text)
    end
    
    local model = textHierarchy.model
    if type(model) == "string" then
        model = state.atlas[model] or state.names[model]
    end
    if model then
        part:addChild(model)
    end

    if textHierarchy.key then
        state.names[textHierarchy.key] = part
    end
    
    
    

end



---comment
---@param part ModelPart
---@param text_hierarchy table
function InsertText.render(part,text_hierarchy,atlas)

    local state = {atlas = atlas or {}, names = {}}
    InsertText.init(part,text_hierarchy,state)

    return state.names

end




