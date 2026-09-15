require"invoke.Invoke"


Invoke:registerOld("gsub",function (self, value, rest)
    if rest == "freeze" then
        self:freezegsub()
    elseif rest == "unfreeze" then
        self:unfreezegsub()
    end
    
    local pattern = value[1] or value.pattern or value.p
    local repl = value[2] or value.repl or value.r
    local rec = value[3] or value.rec or (string.find(rest,"rec") ~= nil)
    if type(pattern) == "string" and  type(repl) == "string" then
        self:addgsub(pattern,repl,nil,rec)
    end
end)
:addAlternateNames("macro")
:addDoc{
    text =  "applies lua's string.gsub to any line that comes after.\n"..
            "applied after substitutions from earlier calls to this function.\n" ..
            "if rec is flagged, applies this repeatedly until nothing changes",
    value = "{pattern = <pattern>, repl = <repl>}",
    types ={
        pattern = "string",
        repl = "string",
        rec = "true|nil"
    },
    alts = {
        pattern = {"p",1},
        repl = {"r", 2},
    }
}
:addDoc{
    value = "{pattern = <pattern>, repl = <repl>, rec = true}",
}
:addDoc{
    rest = "rec",
    value = "{pattern = <pattern>, repl = <repl>}",
}




Invoke:registerOnlyRest("cancel",function  (self, rest)
    if rest == "page" then
        self:cancelPage()
    else
        self:cancelEarly()
    end
end)
:addAlternateNames("skip")
:addDoc{
    text =  "skips the execution of the rest of the clipboard.",
    rest = ""
}
:addDoc{
    text =  "skips the execution of the rest of the page.",
    rest = "page"
}

function Invoke:listWords()
    return Utils.table.getKeys(self.function_docs)
end


Invoke:registerOld("help",function  (self, value, rest)
    if type(value) == "string" then
        rest = value
    end
    if rest == "" then
        return self.function_docs["help"]:explain() .. "\n" .. toJson(self:listWords())
    end
    local doc = self.function_docs[rest]
    if doc then
        return doc:explain()
    else
        return "help: no such word as " .. tostring(rest)
    end
end)
:addDoc{
    text =  "returns documentation for <word>",
    rest = "<word>"
}
:addDoc{
    text =  "lists help.help as well as all words"
}
:addDoc{
    text =  "returns documentation for <word>",
    value = "<word>"
}

Invoke:registerByValue("error",function (self, rest,input)
    error("manual error: "..rest ..": "..toJson(input))
end)