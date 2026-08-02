

-- this is a cheat

local hitKey = keybinds:newKeybind("Hit", "key.mouse.left", false)

function hitKey.press(mods,kb)
    if (player:getHeldItem().id:match("sword")) and (host:getAttackCharge() < 0.99 or (not host:getPickEntity())) then
        return true
    end
end


local blank = models:newPart("blankItem","Item")

blank:newPart("text","BILLBOARD"):newText("text"):setText("")


--- make the extendo_grip invisible

function events.item_render(item, mode, pos, rot, scale, left)
    -- log(item)
    -- return models.blankItem
    if item.id == "create:extendo_grip" --and mode ~= "FIRST_PERSON" 
    then
        return models.blankItem
        -- return true
    end
end