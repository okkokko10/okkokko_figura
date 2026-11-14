

--- todo: looks through the chat and matches

function CHATMATCH(str,count,plain)
    
    for i = 1, 50 do
        local msg = host:getChatMessage(i)
        if msg then
            local s, e, mt = msg.message:find(str,1,plain)
            if s then
                printJson("match found: ",msg.json,"\n")
                
                if count then
                    count = count - 1
                    if count <= 0 then
                        return
                    end
                end
            end
        end
        
    end

end

