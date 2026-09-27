




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


--- to use with load. a line that changes the value of `input` and may call `call`
function Invoke:compileCall(word)
    local start,rest = self:splitWordRest(word)

    if self.function_compiles[start] then
        return self.function_compiles[start](self,rest)
    else
        return string.format('input = call(%q,input);\n',word) -- %q should make code injection impossible
        -- return string.format('input = call',word)
    end

end


function Invoke:callCompileFunc(word)
    local compiled = self:compileCall(word)
    local s = ("local input,call = ...; %s; return input"):format(compiled)
    -- log("callCompile",s)
    local f,p = load(s,word .. "\n|||compiles to|||\n"..s,"t",{})
    if not f then
        error(p)
    end
    return f
end
function Invoke:callCompileRun(f,input)
    
    local function call(...)
        -- log("call",...)
        return self:call(...)
    end

    local out = f(input,call)
    return out
end

function Invoke:callCompile(word,input)
    return self:callCompileRun(Invoke:callCompileFunc(word),input)

    
end




--- ite(cond){then}
Invoke:registerByValue("ite",function (self, rest, input)
    
    local cond,the, e = string.match(rest,"^(%b())%s*(%b{})%s*(.*)$")
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

:compilation(function (self,rest)
    local cond,the, e = string.match(rest,"^(%b())%s*(%b{})%s*(.*)$")
    if not cond then
        error("cannot parse ite: " .. rest)
    end
    local els = string.match(e,"^%s*(.-)%s*$")
    
    
    local st = "do local temp = input; %s; local tempA = input; input = temp; if (tempA) then %s else %s end end"

    return st:format(self:compileCall(string.sub(cond,2,-2)),self:compileCall(string.sub(the,2,-2)),self:compileCall(els))
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


:compilation(function (self,rest)
    local cond,the = string.match(rest,"^(%b())%s*(.*)$")
    if not cond then
        error("cannot parse IT: " .. rest)
    end
    
    local st = "do local temp = input; %s; local tempA = input; input = temp; if (tempA) then %s else input = nil end end"

    return st:format(self:compileCall(string.sub(cond,2,-2)) ,self:compileCall(the))
end)


--- Od(a){b}c
--- stands for Option default
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


:compilation(function (self,rest)
    local cond,the, e = string.match(rest,"^(%b())%s*(%b{})%s*(.*)$")
    if not cond then
        error("cannot parse oelim: " .. rest)
    end
    local els = string.match(e,"^%s*{(.*)}%s*$")
    
    local st = "do local temp = input; %s; if (input ~= nil) then %s else input = temp;%s end end"

    return st:format(self:compileCall(string.sub(cond,2,-2)),self:compileCall(string.sub(the,2,-2)),els and self:compileCall(els) or "input = nil")
end)



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


:compilation(function (self,rest)

    local cond,the = string.match(rest,"^(%b())%s*(.*)$")
    if not cond then
        error("cannot parse O: " .. rest)
    end

    
    local st = "%s; if (input ~= nil) then %s end"

    return st:format(self:compileCall(string.sub(cond,2,-2)),self:compileCall(the))
end)


--- basically adds the current value to a stack and returns to that once the inner call is over.
Invoke:registerByValue("side",function (self, rest, input)
    local rs = string.match(rest,"^%s*(.*)$")
    if rs then
        self:call(rs,input)
    else
        error("weird in side: " ..rest)
    end
    return input
end):addAlternateNames("E")


:compilation(function (self,rest)

    local rs = string.match(rest,"^%s*(.*)$")
    if not rs then
        error("weird in side: " ..rest)
    end

    
    local st = "do local temp = input; %s; input = temp end"

    return st:format(self:compileCall(rs))
end)



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


--- idea: compiling. parse chain as [a]b, where b can itself be [c]d, for [a][c]d. 
--- if the last part is empty, parse it as nop. perform compiling so that this doesn't add a layer of recursion each time.
--- Array[][][][] 

-- c[AB] BC
Invoke:registerByValue("chained",function (self, rest, input)
    local cond,the = string.match(rest,"^%s*(%b[])%s*(.*)$")
    if not cond then
        if string.match(rest,"^%s*$") then
            return input
        end
        error("cannot parse chained: " .. rest)
    end
    local a = self:callCompile(string.sub(cond,2,-2),input)
    if the == "" then
        return a
    end
    -- log("chained",rest,input,a)
    return self:callCompile(the,a)
end)
:addDoc{
    text = "[a]b passes the input to a, then passes its output to b"
}:addAlternateNames("")

:compilation(function (self,rest)

    local cond,the = string.match(rest,"^%s*(%b[])%s*(.*)$")
    if not cond then
        if string.match(rest,"^%s*$") then
            return ""
        end
        error("cannot parse chained: " .. rest)
    end

    local a = self:compileCall(string.sub(cond,2,-2))
    local b = self:compileCall(the) -- here I don't check for the == "" because above it generates an equivalent value
    local st = "%s; %s"
    return st:format(a,b)
end)