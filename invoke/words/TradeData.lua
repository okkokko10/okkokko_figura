require"invoke.Invoke"
local Writing = require "invoke.Writing"


---@class DB<N,K,H>
---@field keyname `N`
---@field data {[H] : {[`N`] : K, [any] : any}}
---@field keyhash fun(key:K):H
---@field indexes table
---@field i_indexes any[]
---@field indexing_hashes table
local DB = {}


function Utils.functions.id(...)
    return ...
end

---@generic N,K,H
---@param keyname `N`
---@param keyhash? fun(key:K):H
---@return DB<N,K,H>
function DB.create(keyname,keyhash)
    return setmetatable(
    {
        data = {},indexes={},i_indexes={},indexing_hashes={},
        keyname=keyname or "key",
        keyhash = keyhash or Utils.functions.id
        
    },DB)
end


---@return DB<N,K,H>
function DB:setup_index(name,hash,type)
    self.i_indexes[#self.i_indexes+1] = name
    self.indexes[name] = {}
    self.indexing_hashes[name] = hash or Utils.functions.id
    return self
end

---doesn't do anything
---@return DB<N,K,H>
function DB:inform_field(name,type)
    return self
end


function DB:gethash(tbl)
    return self.keyhash(tbl[self.keyname])
end

function Utils.table.getDefaultEmptyInit(tbl,key)
    local out = tbl[key]
    if out == nil then
        out = {}
        tbl[key] = out
    end
    return out
end


---@package
function DB:init_indexes(record,hash)
    for key, indexing in pairs(self.indexes) do
        local q = record[key]
        local hk = self.indexing_hashes[key](q)
        if hk ~= nil then
            local bucket = Utils.table.getDefaultEmptyInit(indexing,hk)
            bucket[hash] = record
        end
    end
end

---@package
function DB:update_indexing(record,hash,field,old,new)
    local indexing = self.indexes[field]
    if not indexing then
        return
    end
    old = self.indexing_hashes[field](old)
    if old ~= nil then
        local bucket = Utils.table.getDefaultEmptyInit(indexing,old)
        bucket[hash] = nil
    end
    new = self.indexing_hashes[field](new)
    if new ~= nil then
        local bucket = Utils.table.getDefaultEmptyInit(indexing,new)
        bucket[hash] = record
    end
end



---adds a data item only if it did not exist beforehand 
---@return boolean
function DB:add_first(record)
    if self:get(record) then
        return false
    end
    self:add(record)
    return true
end


---@param key K
function DB:get(key)
    return self.data[self.keyhash(key)]
end

function DB:getField(key,field)
    local q = self:get(key)
    return q and q[field]
end
function DB:add(record)
    local hash = self:gethash(record)
    local t = Utils.table.getDefaultEmptyInit(self.data,hash)
    for key, value in pairs(record) do
        local old = t[key]
        self:update_indexing(t,hash,key,old,value)
        t[key] = value
    end
    return t
end


function DB:update(record,field,value)
    return self:add{
        [self.keyname]=record[self.keyname],
        [field] = value
    }
end

---returns a set 
---@param field any
---@param value any
---@return table
function DB:index(field,value)
    local k = self.indexing_hashes[field](value)
    return k and self.indexes[field][k] or {}
end

---
---@param field any
---@return table
function DB:index_table(field)
    return self.indexes[field]
end



function Utils.world.vectorToChunk(vector)
    local x,y,z = vector:unpack()
    local x1 = math.floor(x/16)
    local z1 = math.floor(z/16)
    return ("%d|%d"):format(x1,z1)
end

function Utils.world.chunkToVector(chunkString)
    local x1,y1 = string.match(chunkString,"^(.-)%|(.*)$")
    return vec(tonumber(x1)*16,0,tonumber(y1)*16)
end



function Utils.world.isChunkLoaded(chunkString)
    return world.isChunkLoaded(Utils.world.chunkToVector(chunkString))
end

local TradeData = {}

TradeData.database = DB.create("pos",Utils.vectorHash):setup_index("updated_or_chunk",nil,"string|true")
:setup_index("sells",nil,"Item string")
:setup_index("buys",nil,"Item string")
:inform_field("price","number")
:inform_field("amount","number")
:inform_field("stock","number")
:inform_field("coins","number") -- coin inventory. relevant for buying.
:inform_field("desc","string") -- would be used to store extra info about the item.
:setup_index("owner",nil,"uuid string") -- uses the shop network uuid if necessary.
:setup_index("section",nil,"string concatenated")
:setup_index("shop",nil,"string")



local LoadedChunks = {}



---call this on a coordinate read from a list.
---@param vector Vector
function TradeData.registerCoord(vector,desc,shop,section)
    TradeData.database:add_first{
        pos = vector,
        desc = desc,
        updated_or_chunk = Utils.world.vectorToChunk(vector),
        shop = shop,
        section = section,

    }
end

--- call when a chunk becomes loaded
function TradeData.onNewChunk(chunkString)
    local ind = TradeData.database:index("updated_or_chunk",chunkString)
    for key, record in pairs(ind) do
        TradeData.scanRecord(record)
    end
end


TradeData.reads = {}


--- call with data read from a vendor/table_cloth to add onto a record.
function TradeData.vendor_node(item_id,amount,price,stock,coins,owner)
    
end

function TradeData.reads.vendor(block)
    local BED = block:getEntityData()
    --- todo
end

function TradeData.reads.table_cloth(block)
    local BED = block:getEntityData()
    --- todo
end

--- todo: hm, should I store x,y,z as separate fields instead of a vec, and have the hash function take the whole record as input?
--- that way I can also do non-coordinates?

--- where do I store a general shop description? the coord of the clipboard?

--- parses " x   y,z,   description   "
---@param line string
function TradeData.parseCoords(line)
    local x,y,z,desc = (line):match("^%s*(%S-)%,?%s*(%S-)%,?%s*(%S-)%,?%s*(.-)%s*$")
    local x1 = tonumber(x)
    local y1 = tonumber(y)
    local z1 = tonumber(z)
    if x1 and y1 and z1 then
        if desc == "" then
            desc = nil
        end
        return vec(math.floor(x1),math.floor(y1),math.floor(z1)), desc
    end
end

--- incomplete
--- "shop <name>" -- should be the first line? what if it's just a routing clipboard?
--- "section <name>"
--- "<x>, <y>, <z>, [<description>]", the commas are optional.
function TradeData.reads.clipboard(block)
    local item = block:asItem()-- todo: check whether this works correctly
    local writing = Writing.extract(item)
    local shop
    local section
    for line in writing:iter() do
        local shop1 = line:match("^%s*shop%s*(.-)%s*$")
        if shop1 then
            shop = shop1
            section = nil
        else
            local section1 = line:match("^%s*section%s*(.-)%s*$")
            if section1 then
                section = (shop or "") .. "|".. section1
            else
                local v,d = TradeData.parseCoords(line)
                if v then
                    TradeData.registerCoord(v,d,shop,section)
                end
            end
        end
    end
end


--- reads the block at the coordinates, and updates the database to add discovered nodes.
---@param vector Vector
function TradeData.scan(vector)
    local block = world.getBlockState(vector)
    
    local strip_id = string.match(block.id,"[^%:]$")-- id after the colon.
    local cloth = string.match(block.id,"table%_cloth")
    if cloth then
        TradeData.reads.table_cloth(block)
    elseif TradeData.reads[strip_id] then
        TradeData.reads[strip_id](block)
    end


end



---@param record table
function TradeData.scanRecord(record)
    local data = TradeData.scan(record.pos)
    TradeData.database:update(record,"data",data)
    TradeData.database:update(record,"updated_or_chunk",true)
end

function Utils.table.any(tbl)
    for key, value in pairs(tbl) do
        return value,key
    end
end

function TradeData.tryChunks()
    local q = TradeData.database:index_table("updated_or_chunk")
    for chunk, value in pairs(q) do -- hm, this might add to the table during iteration.
        if chunk ~= true then
            if Utils.world.isChunkLoaded(chunk) then
                TradeData.onNewChunk(chunk)
                if not Utils.table.any(value) then
                    q[chunk] = nil
                else
                    log("error TradeData.tryChunks")
                end -- clears
            end
        
        end

    end
end