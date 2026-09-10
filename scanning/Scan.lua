
-- require"utils"

local Scan = {}

Scan.queued_scans = {}
Scan.queued_scans_index_current = 1
Scan.queued_scans_top = 0


---@class ScanGroup
---@field last integer?
---@field onError? fun(block:BlockState?,err:any)
---@field onFinish? fun(block:BlockState?,ret:any)

---@alias ScanFunction fun(block:BlockState,num:integer,out_of:integer):any

---enqueue a scan
--- if a function returns truthy, the rest is skipped
---@param pos1 Vector
---@param pos2 Vector
---@param func ScanFunction
---@param onFinish any
---@param group { last: integer? }?
---@return integer
function Scan.order_scan1(pos1,pos2,func,onFinish,group)
    Scan.queued_scans_top = Scan.queued_scans_top + 1
    ---@class ScanQueueElement
    local sc = {pos1=pos1,pos2=pos2,func=func,onFinish=onFinish,group=group}
    Scan.queued_scans[Scan.queued_scans_top] = sc
    if group then
        group.last = Scan.queued_scans_top
    end
    return Scan.queued_scans_top
end
-- function Scan.order_function(func)
--     local ind = #Scan.queued_scans+1
--     Scan.queued_scans[ind] = {only_func=func}
--     return ind
-- end



Scan.visual = models:newPart("ScanVisual")
Scan.visual_item = Scan.visual:newBlock("red_stained_glass"):setBlock("red_stained_glass"):setLight(15,15)

---comment
---@param sc ScanQueueElement
function Scan.setVisual(sc)
    Utils.Sublevel.SublevelPositionPart(sc.pos1,nil,Scan.visual)
    local s = (sc.pos2-sc.pos1 + 1)
    Scan.visual:setScale(s):setVisible(true)

    -- Rect.fromEndpoints(vec(0,0,0),s)


end
function Scan.resetVisual(sc)
    Scan.visual:setVisible(false)
end




function Scan.advance_queue()
    if Scan.queued_scans_top < Scan.queued_scans_index_current then 
        Scan.resetVisual()
        return
    end
    local sc = Scan.queued_scans[Scan.queued_scans_index_current]
    if not sc then
        error("no queued scan found")
    end
    Scan.queued_scans[Scan.queued_scans_index_current] = nil
    Scan.setVisual(sc)
    local blocks = world.getBlocks(sc.pos1,sc.pos2)
    for index, value in ipairs(blocks) do
        if sc.group then
            sc.group.current = (sc.group.current or 0) + 1
        end
        local succ, b = pcall(sc.func,value,sc.group and sc.group.current or index, sc.group and sc.group.size or #blocks)
        if ((not succ) or b) then
            if not succ then
                if sc.group and sc.group.onError then
                    if type(sc.group.onError) == "function" then
                        local s2,r = pcall(sc.group.onError,value,b)
                        if not s2 then
                            log(r)
                        end
                    end
                else
                    log(b)
                end
            end
            if sc.group then
                for i = Scan.queued_scans_index_current, sc.group.last do
                    Scan.queued_scans[i] = nil
                end
                Scan.queued_scans_index_current = sc.group.last+1
                if sc.group.onFinish then
                    local s2,r = pcall(sc.group.onFinish,value,b)
                    if not s2 then
                        log(r)
                    end
                end
                return
            end
            
        end
    end
    
    if sc.group and sc.group.last == Scan.queued_scans_index_current then
        if sc.group.onFinish then
            local s2,r = pcall(sc.group.onFinish)
            if not s2 then
                log(r)
            end
        end
    end
    Scan.queued_scans_index_current = Scan.queued_scans_index_current + 1
    
end

function Scan.cancel(group)
    if not (group and group.last) then return end
    if Scan.queued_scans_index_current <= group.last then
        for i = Scan.queued_scans_index_current, group.last do
            Scan.queued_scans[i] = nil
        end
        Scan.queued_scans_index_current = group.last+1
        if group.onError then
            group.onError(nil,"canceled")
        end
    end
    
end

events.TICK:register(Scan.advance_queue)



---deprecated
---@param rect Rect
---@param func fun(block:BlockState)
function Scan.foreachOld(rect,func)
    if not rect then return end
    local pos1 = rect.min
    local pos2 = rect.max
    local size = rect.size
    for x = 0, size.x, 8 do
        for y = 0, size.y,8 do
            for z = 0, size.z,8 do
                local lpos = pos1+vec(x,y,z)
                local lsize = vec(8,8,8)
                local tbl = world.getBlocks(lpos,Utils.math.vectorMin(pos2,lpos+lsize))
                for key, value in pairs(tbl) do
                    func(value)
                end
            end
        end
    end
end

Scan.stepSize = vec(9,9,9)

---enqueues scans
---@generic X
---@param rect Rect
---@param func fun(block:BlockState,num:integer,out_of:integer):X?
---@param onFinish? fun(block:BlockState?,ret:X?)
function Scan.foreach(rect,func,onFinish)
    if not rect then return end
    
    local group = {onFinish=onFinish}

    local pos1 = rect.min
    local pos2 = rect.max
    local size = rect.size
    group.size = (size.x + 1) * (size.y + 1) * (size.z + 1)

    for x = pos1.x, pos2.x, Scan.stepSize.x do
        for y = pos1.y, pos2.y, Scan.stepSize.y do
            for z = pos1.z, pos2.z, Scan.stepSize.z do
                local l1 = vec(x,y,z)
                local l2 = Utils.math.vectorMin(l1 + Scan.stepSize - 1,pos2)
                if l1 <= l2 then
                    Scan.order_scan1(l1,l2,func,nil,group)
                end
            end
        end
    end
end

return Scan