require"invoke.Invoke"
local Writing = require "invoke.Writing"


---@class DB<N,K,H,F>
---@field keyname `N`
---@field data {[H] : {[`N`] : K, [F] : any}}
---@field keyhash fun(key:K):H
---@field indexes table
---@field i_indexes any[]
---@field indexing_hashes table
local DB = {}
DB.__index = DB


function Utils.functions.id(...)
    return ...
end

---@generic N,K,H
---@param keyname `N`
---@param keyhash? fun(key:K):H
---@return DB<N,K,H,N>
function DB.create(keyname,keyhash)
    return setmetatable(
    {
        data = {},indexes={},i_indexes={},indexing_hashes={},
        keyname=keyname or "key",
        keyhash = keyhash or Utils.functions.id
        
    },DB)
end



---@generic N,K,H,F,Q
---@param self DB<N,K,H,F>
---@param name `Q`
---@param hash unknown
---@param type any
---@return DB<N,K,H,F|`Q`>
function DB:setup_index(name,hash,type)
    self.i_indexes[#self.i_indexes+1] = name
    self.indexes[name] = {}
    self.indexing_hashes[name] = hash or Utils.functions.id
    return self
end

---doesn't do anything


---@generic N,K,H,F,Q
---@param self DB<N,K,H,F>
---@param name `Q`
---@param type any
---@return DB<N,K,H,F|`Q`>
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
    if self:get(record[self.keyname]) then
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

---@generic N,K,H,F,Q
---@param self DB<N,K,H,F>
---@param record {[F]: any}
function DB:add(record)
    logTable(record)
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

TradeData.database = DB.create("pos",Utils.vectorHash)
:setup_index("updated_or_chunk",nil,"string|true")
:setup_index("sells",nil,"Item string")
:setup_index("buys",nil,"Item string")
:inform_field("price","number")
:inform_field("price_per","number")
:inform_field("amount","number")
:inform_field("stock","number")
:inform_field("coins","number") -- coin inventory. relevant for buying.
:inform_field("desc","string") -- would be used to store extra info about the item.
:setup_index("owner",nil,"uuid string")
-- :setup_index("owner",function (t)
--     return client.intUUIDToString(table.unpack(t))
-- end,"uuid string")
:setup_index("section",nil,"string concatenated")
:setup_index("shop",nil,"string")
:setup_index("currency",nil,"Item string")  -- nil means spurs
:inform_field("error","string")
:inform_field("block","string")



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

TradeData.one_at_a_time = avatar:getPermissionLevel() ~= "MAX"

--- call when a chunk becomes loaded
--- 
function TradeData.onNewChunk(chunkString,indexing)
    local ind = indexing or TradeData.database:index("updated_or_chunk",chunkString)
    for key, record in pairs(ind) do
        local success = TradeData.scanRecord(record)
        if success and TradeData.one_at_a_time then
            return true
        end
    end
    return false
end


TradeData.reads = {}


--- call with data read from a vendor/table_cloth to add onto a record.
function TradeData.add_vendor_node(block,item_id,amount,price,owner,stock,is_buying,currency,note)
    local sells
    local buys
    if is_buying then
        buys = item_id
    else
        sells = item_id
    end
    local price_per = price and amount and price/amount
    TradeData.database:add{
        pos=block:getPos(),
        block = block.id,
        sells = sells,
        buys = buys,
        price = price,
        amount = amount,
        stock = stock,
        owner = owner,
        price_per = price_per,
        currency = currency,
        note = note,
        updated_or_chunk = true
    }

end

function TradeData.ownerUUID(intarray)
    return intarray and client.intUUIDToString(table.unpack(intarray))
    
end

TradeData.reads["numismatics:vendor"] = function(block)
    local BED = block:getEntityData()
    if not BED then
        return
    end
    -- local CoinInventory = BED.CoinInventory and Utils.currency.pricestring_upper(BED.CoinInventory)
    local stock = 0
    for index, value in ipairs((BED.Inventory or {}).Items or {}) do
        stock = stock + (value.count or 0)
    end
    local is_buying = BED.Mode == 1
    local Owner = TradeData.ownerUUID(BED.Owner)
    local price = BED.Prices and Utils.currency.price(BED.Prices)
    local count = BED.Selling.count
    local item_id = BED.Selling.id

    TradeData.add_vendor_node(block,item_id,count,price,Owner,stock,is_buying)

end

function TradeData.reads.table_cloth(block)
    local BED = block:getEntityData()
    if not BED then
        return
    end
    local Owner = TradeData.ownerUUID(BED.OwnerUUID)
    local price, currency = Utils.currency.fromItemCount(assert(BED.Filter.id,"invalid: no price set"),BED.FilterAmount)
    local entries1 = BED.RequestData.encoded_request.ordered_stacks.entries[1]
    local count = entries1.count
    local item_id = entries1.item_stack.id
    TradeData.add_vendor_node(block,item_id,count,price,Owner,nil,nil,currency)
end

--- todo: hm, should I store x,y,z as separate fields instead of a vec, and have the hash function take the whole record as input?
--- that way I can also do non-coordinates?

--- where do I store a general shop description? the coord of the clipboard?

--- parses " x   y,z,   description   "
---@param line string
function TradeData.parseCoords(line)
    local x,y,z,desc = (line):match("^%s*(%S*)%s*(%S*)%s*(%S*)%s*(.-)%s*$")
    local x1 = tonumber(x)
    local y1 = tonumber(y)
    local z1 = tonumber(z)
    -- log("parsing:",line,x,x1,y,y1,z,z1,"desc:",desc)

    if x1 and y1 and z1 then
        if desc == "" then
            desc = nil
        end
        return vec(math.floor(x1),math.floor(y1),math.floor(z1)), desc
    end
end


--- "shop <name>" -- should be the first line? what if it's just a routing clipboard?
--- "section <name>"
--- "<x>, <y>, <z>, [<description>]", the commas are optional.
TradeData.reads["create:clipboard"] = function (block)
    -- local item = block:asItem()-- todo: check whether this works correctly
    local item = {
        tag = {["create:clipboard_content"] = block:getEntityData().components["create:clipboard_content"]},
        id = block.id
    }
    -- print()
    -- print(item.tag.display)
    local writing = Writing.extract(item)
    local shop
    local section
    for line in writing:iter() do
        -- print("  ",line)
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
    TradeData.database:add{
            pos=block:getPos(),
            updated_or_chunk = true,
            block = block.id,
            -- shop = shop,
            -- section = section,
        }
    
end


--- reads the block at the coordinates, and updates the database to add discovered nodes.
---@param vector Vector
---@return boolean success
function TradeData.scan(vector)
    local block = world.getBlockState(vector)
    
    -- local strip_id = string.match(block.id,"[^%:]$")-- id after the colon.
    local cloth = string.match(block.id,"table%_cloth")
    local s, r
    if cloth then
        s,r = pcall(TradeData.reads.table_cloth,block)
    elseif TradeData.reads[block.id] then
        s,r = pcall(TradeData.reads[block.id],block)
    else
        TradeData.database:add{
                pos=vector,
                updated_or_chunk = true,
                block = block.id,
                note = "incompatible block"
            }
        return false
    end
    if not s then
        if avatar:getPermissionLevel() ~= "MAX" then
            r = tostring(r):sub(1,50)
        end
        TradeData.database:add{
                pos=vector,
                error = r,
                updated_or_chunk = true,
                block = block.id,
            }
    end
    return true


end



---@param record table
---@return boolean success
function TradeData.scanRecord(record)
    return TradeData.scan(record.pos)
    -- TradeData.database:update(record,"data",data)
    -- TradeData.database:update(record,"updated_or_chunk",true)
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

                TradeData.onNewChunk(chunk,value)

                if not Utils.table.any(value) then -- clears empty indexing groups
                    q[chunk] = nil
                else
                end 
            end
        
        end

    end
end


function events.skull_render(delta, block, item, entity, mode)
    -- if Utils.tick.first_frame() then
    -- if player:isLoaded() and player:isSneaking() then
    --     log(delta,block,item,entity,mode)
    --     if block then
    --         log(block:toStateString())
    --         log(block.properties)
    --     end
    -- end
    if block then
        TradeData.tryChunks()
        local pos = block:getPos()
        TradeData.registerCoord(pos + vec(0,1,0))
    end

    -- end
end