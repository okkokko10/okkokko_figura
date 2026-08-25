require"invoke.Invoke"


Invoke:register("gsub",function (self, value, rest, plr)
    if rest == "freeze" then
        self:freezegsub()
    elseif rest == "unfreeze" then
        self:unfreezegsub()
    end
    
    local pattern = value[1] or value.pattern or value.p
    local repl = value[2] or value.repl or value.r
    local rec = value[3] or value.rec
    if type(pattern) == "string" and  type(repl) == "string" then
        self:addgsub(pattern,repl,nil,rec)
    end
end)




Invoke:registerKeyword("cancel",function  (self, value, rest, plr)
    if rest == "page" then
        self:cancelPage()
    else
        self:cancelEarly()
    end
end)

