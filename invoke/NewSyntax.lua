




--[[

functions, finally?
pattern matching?

or maybe use old functions?
fun.F (x,y,z) {[var.x][call.getItem 1]}

lambda calculus?

no, inputs. what about optional arguments?

display(target{} text{})


maybe have pure and nil-return functions marked?



chain[e1][e2]...[en]
    _ := e1(_)
    _ := e2(_)
    ...
    _ := en(_)
    return _

it(a){b}
    return if a(_) then b(_) else nil
ite(a){b}{c}
    return if a(_) then b(_) else c(_)
oelim(f){g}{d}
    -- from Option.elim
    local temp = f(_)
    return if temp then g(temp) else d(_)
side(e)
#e
    local temp = _
    e(_)
    return temp

M{f}




]]
--- ite(cond){then}
Invoke:registerByValue("ite",function (self, rest, input)
    
    local cond,the, e = string.match(rest,"^(%b())%s*(%b{})(.*)$")
    if not cond then
        error("cannot parse ite: " .. rest)
    end
    local els = string.match(e,"^%s*(.-)%s*$")
    
    local a = self:call(string.sub(cond,2,-2),input)
    if a then
        return self:call(string.sub(the,2,-2),input)
    elseif els then
        return self:call(els,input)
    end
end)

--- IT(c) a
Invoke:registerByValue("IT",function (self, rest, input)
    
    local cond,the = string.match(rest,"^(%b())%s*(.*)$")
    if not cond then
        error("cannot parse IT: " .. rest)
    end
    
    local a = self:call(string.sub(cond,2,-2),input)
    if a then
        return self:call(the,input)
    end
end):addAlternateNames("I")


Invoke:registerByValue("oelim",function (self, rest, input)
    
    local cond,the, e = string.match(rest,"^(%b())%s*(%b{})%s*(.*)$")
    if not cond then
        error("cannot parse oelim: " .. rest)
    end
    local els = string.match(e,"^%s*{(.*)}%s*$")
    
    local a = self:call(string.sub(cond,2,-2),input)
    if a then
        return self:call(string.sub(the,2,-2),a)
    elseif els then
        return self:call(els,input)
    end
end):addAlternateNames("Od")

--- Option.map?
--- I now realize that 
Invoke:registerByValue("O",function (self, rest, input)
    
    local cond,the = string.match(rest,"^(%b())%s*(.*)$")
    if not cond then
        error("cannot parse O: " .. rest)
    end
    
    local a = self:call(string.sub(cond,2,-2),input)
    if a then
        return self:call(the,a)
    end
end):addAlternateNames("OM")


Invoke:registerByValue("side",function (self, rest, input)
    local rs = string.match(rest,"^%s*(.*)$")
    if rs then
        self:call(rs,input)
    else
        error("weird in side: " ..rest)
    end
    return input
end):addAlternateNames("E")


--- incomplete
function Invoke:parseWord(word)

    local start,rest = string.match(word,"^(%a*)%.?(.*)$")
end


--- incomplete
function Invoke:callNew(word, input)
    
    if not word then return end
    if type(word) == "table" then
        return self:runTable_(word)
    end
    if type(word) ~= "string" then
        log(word)
        error("not table or string")
    end
    local start,rest = string.match(word,"^(%a*)%.?(.*)$")
    -- local _,_,start,rest = string.find(word,"^([^%.]*)%.?(.*)$")
    if self.functions[start] then
        -- log(start,rest)
        return self:run(start,tbl,rest)
    else
        error("unknown word:\n"..word .. "\nstart: " .. (start or "nil") .. "\nrest: " .. (rest or "nil"))
        return word
    end
    
end
