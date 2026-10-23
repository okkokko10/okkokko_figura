require"invoke.Invoke"

--- returns a table to be converted to json.
Invoke:registerWithArgs("bar",{"current","max?","color_bar?","color_empty?","character_bar?"},function (self, rest, input)


    local left = math.max(math.ceil(input.current or 0),0)
    local right = math.max(math.ceil(input.max or 0) - left,0)
    local character = input.character_bar or "|"
    
    return self:newmutable{
        {
            color = input.color_bar or "#0000FF",
            text = string.rep(character,left)
        },
        {
            color = input.color_empty or "#AAAAAA",
            text = string.rep(character,right)
        }
    }
end)