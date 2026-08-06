


-- test for what order things happen in

-- findings: for each part: 
-- rec(part) = pre(part); mid(part); for c in part.children do rec(c) end; post(part);

do return end

local debugKey = keybinds:newKeybind("debug order", "key.keyboard.j")

local function log2(title)
    return function (...)
        if debugKey:isPressed() then
            return log(title,...)
        end
    end
end
local function log3(part)
    return part
        :setPreRender( log2("pre") )
        :setMidRender( log2("mid") )
        :setPostRender( log2("post") )
end
local function log4(part,name)
    return log3(part:newPart(name))
end


local root = log4(models,"testSeq")
log4(root,"a")
local b = log4(root,"b")
local ba = log4(b,"ba")
log4(root,"c")