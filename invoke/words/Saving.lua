
Invoke:registerByValue("save", function (self, rest, input)
    if self.plr == player then
        config:name("invoke_saved"):save(tostring(rest),input)
    end
end)

Invoke:registerByValue("load", function (self, rest, input)
    if self.plr == player then
        return config:name("invoke_saved"):load(tostring(rest))
    end
end)


Invoke:registerByValue("private", function (self, rest, input)
    return self.plr == client:getViewer()
end)