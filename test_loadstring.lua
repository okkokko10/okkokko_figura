
---`loadstring` doesn't work correctly with the output from string.sub
---@param message string
local function test_load(message)
    if type(message) ~= "string" then return message end
    local substring = string.sub(message,2,-2)
    log("substring is:", substring)
    log("substring is equal to \"return\":", substring == "return")
    log("\"return\" loads: ",loadstring("return"))
    log("substring loads: ", loadstring(substring))
    local sf = string.format("%s",substring)
    log("string.format(\"%s\",substring) is ",sf, loadstring(sf))
    local sf2 = string.format(" %s",substring)
    log("string.format(\" %s\",substring) is ",sf2, loadstring(sf2))
    local substring2 = string.match(message,".(.+).")
    log('string.match(message,".(.+).") is equal to \"return\":', substring2 == "return")
    log('string.match(message,".(.+).") loads: ', loadstring(substring2))
    log('""..substring.."" loads: ', loadstring(""..substring..""))
    log('substring.." " loads: ', loadstring(substring.." "))
    
    
    do return message end
end
-- local x = string.sub(".return.",2,-2);
-- log("test load: ",x,x=="return",load("return"),load(x))

-- local function tst(r)
--     local y = string.sub(r,2,-2);
--     log("test load: ",y,y=="return",load("return"),load(y))
-- end
-- tst(".return.")


-- events.CHAT_SEND_MESSAGE:register(test_load)