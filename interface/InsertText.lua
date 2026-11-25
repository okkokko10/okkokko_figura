

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
        text = '["main", " ", "part"]',
        -- height = 15
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
            width = 16,
        },
        height = 16,
        
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
                " ",
                "row",
                " ",
                "here"
            }
        },
        below = {
            text = "row 3"
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
---@field scale? Vector3|number
---@field invisible boolean? -- should this change the dimensions to 0?
---@field model ModelPart|string?
---@field key string?
---@field onClick fun(pos:Vector3)? -- todo
---@field offset Vector2|Vector3? -- offsets the main's position (and the rest by extension)
---@field _part ModelPart
---@field hitbox Hitbox
---@field onChangeHover fun(entered:boolean)? -- when exited or entered


---recursively calculates the dimensions, ie the position of the bottom right corner in pixels
---@param textHierarchy TextHierarchy | ModelPart?
---@param noScale boolean?
---@return Vector2
function InsertText.dimensions(textHierarchy,noScale)
    if not textHierarchy then
        return vec(0,0)
    end
    if type(textHierarchy) == "ModelPart" then -- todo
        return vec(0,0)
    end
    if textHierarchy.width and textHierarchy.height then
        return vec(textHierarchy.width,textHierarchy.height)
        -- should this use scale_x?
    end
    local main = InsertText.dimensions(textHierarchy.main)
    if textHierarchy.offset then
        main = main + textHierarchy.offset.xy
    end

    local max_x = math.max(main.x,0)
    local max_y = math.max(main.y,0)

    
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

    local out = vec(textHierarchy.width or max_x,textHierarchy.height or max_y)

    if textHierarchy.scale and not noScale then
        if type(textHierarchy.scale) == "number" then
            return out  * (textHierarchy.scale)
        else
            return out * textHierarchy.scale.xy
        end
    end
    
    return out

end



---@class TextHierarchy.RenderState
---@field atlas {[string]: ModelPart}
---@field names  {[string]: ModelPart}
---@field withHitbox TextHierarchy[]
---@field raycastHit HitboxRaycastOutput?


---creates parts
---@param part ModelPart
---@param textHierarchy TextHierarchy|ModelPart
---@param state TextHierarchy.RenderState
---@param local_pos Vector3?
---@param matrix Matrix4
function InsertText.init(part,textHierarchy,state, local_pos, matrix)
    
    local debugging = true
    if local_pos then
        part:setPos(-local_pos)
    end

    if debugging then
        part:newBlock("dummy"):block("minecraft:target"):setScale(1/16):setPos(-1,-1,-1)
    end
    if type(textHierarchy) == "ModelPart" then
        part:addChild(textHierarchy)
        return
    end
    textHierarchy._part = part
    
    if textHierarchy.json then
        textHierarchy.text = toJson(textHierarchy.json)
    end

    
    if textHierarchy.scale then
        if type(textHierarchy.scale) == "Vector2" then
            part:setScale(textHierarchy.scale:augmented(1))
        else
            part:setScale(textHierarchy.scale)
        end
    end
    

    if local_pos then
        
        matrix = matrix * matrices.translate4(-local_pos)
    end


    local matrix_children = matrix * matrices.scale4(textHierarchy.scale)

    


    local offset = vec(0,0,0)
    if textHierarchy.offset then
        offset = vectors.vec3(textHierarchy.offset:unpack())
    end

    if debugging then
        offset = offset + vec(0,0,2)
    end
    if textHierarchy.main then
        local main_part = Utils.parts.child(part,"main")
        -- if offset then
        --     main_part:setPos(-offset)
        -- end
        InsertText.init(
            main_part,
            textHierarchy.main,
            state,
            offset,
            matrix_children
        )
    end

    local corner_position = InsertText.dimensions(textHierarchy.main):augmented(0) + (offset or 0)
    local own_corner = InsertText.dimensions(textHierarchy,true):augmented(0)

    
    if textHierarchy.onClick or true then
        textHierarchy.hitbox = Hitbox:create(matrix,Rect.fromEndpoints(-own_corner,-offset))
        table.insert(state.withHitbox,textHierarchy)
    end


    
    -- -@class BlockTask: HasSetScalePos

    if debugging then
        
        Rect.fromEndpoints(-corner_position,vec(0,0,0)):setCornerBlockTo(part:newBlock("background"):block("minecraft:blue_stained_glass"))
        -- Rect.fromEndpoints(-own_corner,vec(0,0,0)):setCornerBlockTo(part:newBlock("background2"):block("minecraft:green_wool"))

        local hover_part = Rect.fromEndpoints(-own_corner,vec(0,0,0)):setCornerBlockTo(part:newBlock("hover"):block("minecraft:red_wool")):setVisible(false)
        textHierarchy.onChangeHover = function (entered)
            hover_part:setVisible(entered)
        end
    end


    if textHierarchy.right then
        
        InsertText.init(
            Utils.parts.child(part,"right"),
            textHierarchy.right,
            state,
            corner_position.x_z,
            matrix_children
        )
        -- corner_position = InsertText.dimensions(textHierarchy.right)
    end


    if textHierarchy.below then
        InsertText.init(
            Utils.parts.child(part,"below"),
            textHierarchy.below,
            state,
            corner_position._yz,
            matrix_children
        )
        
    end
    if textHierarchy.corner then
        
        InsertText.init(
            Utils.parts.child(part,"corner"),
            textHierarchy.corner,
            state,
            corner_position.xyz,
            matrix_children
        )
    end

    local text = textHierarchy.text --textHierarchy.json and toJson(textHierarchy.json) or textHierarchy.text
    if text then
        (part:getTask("text") or part:newText("text")):setWidth(textHierarchy.width):setWrap(textHierarchy.wrap):setText(text)
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
---@param startPos Vector3
---@param endPos Vector3
---@param textHierarchy TextHierarchy
---@param state TextHierarchy.RenderState
function InsertText.raycast(startPos,endPos,textHierarchy,state)

    local r = Hitbox.raycastsOriented(startPos,endPos,state.withHitbox)

    local oldOwner = state.raycastHit and state.raycastHit.owner --[[@as TextHierarchy?]]
    local newOwner = r and r.owner --[[@as TextHierarchy?]]
    local owner_changed = oldOwner ~= newOwner

    if oldOwner and owner_changed then
            if oldOwner.onChangeHover then
                oldOwner.onChangeHover(false)
            end
    end
    if newOwner and owner_changed then
        
        if newOwner.onChangeHover then
            newOwner.onChangeHover(true)
        end
    end
    state.raycastHit = r

    
end


---comment
---@param part ModelPart
---@param text_hierarchy table
function InsertText.render(part,text_hierarchy,atlas)

    local state = {atlas = atlas or {}, names = {}, withHitbox = {}}
    InsertText.init(part,text_hierarchy,state,nil,matrices.mat4())

    part:setPostRender(function (delta, context, part2)
        
        local origin = client.getCameraPos()
        local direction = client.getCameraDir()
        local destination = origin + direction * 1000
        local wtpm = part2:partToWorldMatrix():inverted()
        local loc_origin = wtpm:apply(origin)
        local loc_destination = wtpm:apply(destination)
        InsertText.raycast(loc_origin,loc_destination,text_hierarchy,state)
        

    end)

    return state

end


---@alias Insertable Insertable[] | string | ModelPart 

---no plan yet
---@param out TextHierarchy
---@param insertables Insertable[]
---@param index integer
function InsertText.parse(out,insertables,index,stop)
    out = out or {}
    
    local first = insertables[index]
    if not first then
        return index
    end
    if first == "\n" then
        return index + 1
    end
    
    -- out.main = {}
    -- local index_main = InsertText.parse(out.main,insertables,index+1)



    
    for i = index, #insertables do
        local value = insertables[i]
        local t = type(value)
        if t == "ModelPart" then
            return -- todo
        elseif t == "string" then
            if t == "\n" then
                
            end
            return
        end
    end

end



--[[

idea: 2d table for rows, columns.

with capability to nest


]]

---@alias TextCell.code {code:string,value:any}

---@alias TextCell string|ModelPart|TextCell.code

---
---@param rows {[integer]: {[integer] : TextCell, head: TextHierarchy?}}
---@return TextHierarchy
function InsertText.parseCells(rows)

    ---@type TextHierarchy
    local row_hierarchy = {}
    local out = row_hierarchy
    for y, row in ipairs(rows) do
        row_hierarchy.below = {}
        ---@type TextHierarchy
        row_hierarchy = row_hierarchy.below
        row_hierarchy.main = row.head or {}
        ---@type TextHierarchy
        local column_hierarchy = row_hierarchy.main
        for x, cell in ipairs(row) do

            local t = type(cell)
            column_hierarchy.right = {}

            if t == "table" and cell.head then
                column_hierarchy.right = cell.head
            end

            ---@type TextHierarchy
            column_hierarchy = column_hierarchy.right

            if t == "string" then
                column_hierarchy.main = {
                    text = cell
                }
            elseif t == "ModelPart" then
                column_hierarchy.main = cell
            elseif t == "table" and not cell.head then
                column_hierarchy.main = cell
            end
            
        end
        
    end

    return out
    

    

end