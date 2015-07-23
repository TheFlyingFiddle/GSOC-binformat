local format = require"format"
local meta   = require"tier.meta"
local core   = require"tier.core"
local util   = require"tier.util"

local pack      = format.packvarint
local writemeta = core.writemeta

local custom = { }

do 
    local Int = { } Int.__index = Int
    function Int:encode(encoder, value)
        encoder:writef("p", self.meta.bits, value)
    end
    
    function Int:decode(decoder)
        return decoder:readf("p", self.meta.bits)
    end
    
    function custom.int(numbits)
        return setmetatable({ meta = meta.int(numbits) }, Int)
    end
end 

do 
    local Uint = { } Uint.__index = Uint
    function Uint:encode(encoder, value)
        encoder:writef("P", self.meta.bits, value)
    end
    
    function Uint:decode(decoder)
        return decoder:readf("P", self.meta.bits)
    end
    
    function custom.uint(numbits)
        return setmetatable( { meta = meta.uint(numbits) }, Uint)
    end
end 

do 
    --mapping for the ARRAY <T> tag.
    local Array = { } Array.__index = Array
    function Array:encode(encoder, value)
        local size = self.meta.size
        assert(self.handler:getsize(value) >= size, "array to small")
        
        local mapping = self.mapping
        local encode  = mapping.encode
        local handler = self.handler
        local getitem = handler.getitem
            
        for i=1, size do
            encode(mapping, encoder, getitem(handler, value, i))
        end
    end
    
    function Array:decode(decoder)
        local size = self.meta.size
        local value = self.handler:create()
        decoder:setobject(value)
        
        local mapping = self.mapping
        local decode  = mapping.decode
        local handler = self.handler
        local setitem = handler.setitem
        
        for i=1, size, 1 do
            setitem(handler, value, i, decode(mapping, decoder))
        end
        return value
    end
    
    function custom.array(handler, mapping, size)
        assert(util.ismapping(mapping))
        assert(handler.getsize, "Array handler missing function getsize")
        assert(handler.create,  "Array handler missing function create")
        assert(handler.setitem, "Array handler missing function setitem")
        assert(handler.getitem, "Array handler missing function getitem")
    
        local array   = setmetatable({ }, Array)
        array.mapping = mapping
        array.meta    = meta.array(mapping.meta, size)
        array.handler = handler
        return array    
    end
end 

local function writesize(writer, bits, size)
    if bits == 0 then
       writer:writef("V", size)
    else
       writer:writef("P", bits, size) 
    end
end

local function readsize(reader, bits)
    if bits == 0 then
        return reader:readf("V")
    else
        return reader:readf("P", bits)
    end
end

do 
    --mapping for the LIST <T> tag.
    local List = {  } List.__index = List;
    function List:encode(encoder, value)
        local size = self.handler:getsize(value)
        writesize(encoder.writer, self.meta.sizebits, size)
        
        local mapping = self.mapping
        local encode  = mapping.encode
        local handler = self.handler
        local getitem = handler.getitem
        
        for i=1, size do
            encode(mapping, encoder, getitem(handler, value, i))
        end 
    end
    
    function List:decode(decoder)
        local size   = readsize(decoder.reader, self.meta.sizebits)
        local value  = self.handler:create(size)
        decoder:setobject(value)
    
        local mapping = self.mapping
        local decode  = mapping.decode
        local handler = self.handler
        local setitem = handler.setitem
            
        for i=1,size, 1 do
            setitem(handler, value, i, decode(mapping, decoder))
        end
        return value;
    end
    
    function custom.list(handler, mapping, sizebits)
        assert(util.ismapping(mapping))
        assert(handler.getsize, "List handler missing function getsize")
        assert(handler.create,  "List handler missing function create")
        assert(handler.setitem, "List handler missing function setitem")
        assert(handler.getitem, "List handler missing function getitem")
            
        local list   = setmetatable({ }, List)
        list.mapping = mapping
        list.meta    = meta.list(mapping.meta, sizebits)
        list.handler = handler
        return list
    end
end 

do 
    --mapping for the SET <T> tag.
    local Set = {  } Set.__index = Set;
    function Set:encode(encoder, value)
        local size = self.handler:getsize(value)
        writesize(encoder.writer, self.meta.sizebits, size)
        
        local mapping = self.mapping
        local encode  = mapping.encode
        local handler = self.handler
        local getitem = handler.getitem
        
        for i=1,size, 1 do
            encode(mapping, encoder, getitem(handler, value, i))
        end 
    end
    
    function Set:decode(decoder)
        local size  = readsize(decoder.reader, self.meta.sizebits)
        local value  = self.handler:create(size)
        decoder:setobject(value)
    
        local mapping = self.mapping
        local decode  = mapping.decode
        local handler = self.handler
        local putitem = handler.putitem
    
        for i=1,size, 1 do
            putitem(handler, value, decode(mapping, decoder))
        end
            
        return value
    end
    
    function custom.set(handler, mapping, sizebits)
        assert(util.ismapping(mapping))
        assert(handler.getsize, "Set handler missing function getsize")
        assert(handler.create,  "Set handler missing function create")
        assert(handler.putitem, "Set handler missing function setitem")
        assert(handler.getitem, "Set handler missing function getitem")
    
        local set   = setmetatable({ }, Set)
        set.mapping = mapping
        set.meta    = meta.set(mapping.meta, sizebits)
        set.handler = handler
        return set
    end
end 

do 
    --mapping for the MAP <K> <V> tag.
    local Map = { } Map.__index = Map
    function Map:encode(encoder, value)
        local keys   = self.keymapping
        local values = self.valuemapping
    
        local kencode = keys.encode
        local vencode = values.encode 
    
        local size = self.handler:getsize(value)
        writesize(encoder.writer, self.meta.sizebits, size)
        for k, v in self.handler:getitems(value) do
            kencode(keys, encoder, k)
            vencode(values, encoder, v)
        end
    end
    
    function Map:decode(decoder)
        local keys   = self.keymapping
        local values = self.valuemapping
        
        local kdecode = keys.decode 
        local vdecode = values.decode
        
        local handler = self.handler
        local putitem = handler.putitem

        local size  = readsize(decoder.reader, self.meta.sizebits)
        local value = self.handler:create(size)
        decoder:setobject(value)
        for i=1, size, 1 do
            local key  = kdecode(keys, decoder)
            local item = vdecode(values, decoder)
            putitem(handler, value, key, item)
        end 
        
        return value
    end
    
    function custom.map(handler, keymapping, valuemapping, sizebits)
        assert(util.ismapping(keymapping))
        assert(util.ismapping(valuemapping))
        
        assert(handler.getsize,  "Map handler missing function getsize")
        assert(handler.create,   "Map handler missing function create")
        assert(handler.putitem,  "Map handler missing function putitem")
        assert(handler.getitems, "Map handler missing function getitems")
          
        local map = setmetatable({}, Map)
        map.keymapping    = keymapping
        map.valuemapping  = valuemapping
        map.meta        = meta.map(keymapping.meta, valuemapping.meta, sizebits)
        map.handler     = handler
        return map;
    end

end 

do 
    --mapping for the TUPLE N <T1> <T2> ... <TN> tag.
    local Tuple = { }
    Tuple.__index = Tuple
    function Tuple:encode(encoder, value)
        local handler  = self.handler
        local getitem  = handler.getitem
    
        for i=1, #self.mappings do
            local mapping = self.mappings[i]
            local item    = getitem(handler, value, i)
            mapping:encode(encoder, item)
        end
    end
    
    function Tuple:decode(decoder)
        local handler = self.handler
        local setitem = handler.setitem
    
        local value = self.handler:create();
        decoder:setobject(value)
        for i=1, #self.mappings do
            local mapping = self.mappings[i] 
            local item   = mapping:decode(decoder)
            setitem(handler, value, i, item)
        end
        return value;   
    end
    
    function custom.tuple(handler, mappings)
        for i=1, #mappings do
            assert(util.ismapping(mappings[i]))
        end
        
        assert(handler.create,  "Tuple handler missing function create")
        assert(handler.getitem, "Tuple handler missing function getitem")
        assert(handler.setitem, "Tuple handler missing function setitem")
    
        local tuple = setmetatable({ }, Tuple)
        
        local types = { }
        for i=1, #mappings do 
            types[i] = mappings[i].meta
        end 
        
        tuple.meta     = meta.tuple(types)
        tuple.handler  = handler
        tuple.mappings = mappings
        return tuple
    end
end 

do 
    --mapping for the UNION N <T1> <T2> ... <TN>
    local Union = { }
    Union.__index = Union
    function Union:encode(encoder, value)
        local kind, encodable = self.handler:select(value)
        local mapping = self.mappings[kind]
        writesize(encoder.writer, self.meta.sizebits, kind)
        mapping:encode(encoder, value)    
    end
    
    function Union:decode(decoder)
        local kind = readsize(decoder.reader, self.meta.sizebits)
        return self.mappings[kind]:decode(decoder)
    end
    
    function custom.union(handler, mappings, sizebits)
        assert(handler.select, "Union handler missing function select")

        for i=1, #mappings do
            assert(util.ismapping(mappings[i]))
        end

        local union = setmetatable({ }, Union)
        local types = { }
        for i=1, #mappings do 
            types[i] = mappings[i].meta
        end 
        
        union.mappings = mappings
        union.meta  = meta.union(types, sizebits)
        union.handler  = handler
        return union
    end
end 

do 
    --mapping for the SEMANTING "ID" <T> tag
    local Semantic = { } Semantic.__index = Semantic
    function Semantic:encode(encoder, value)
        self.mapping:encode(encoder, value)
    end
    
    function Semantic:decode(decoder)
        return self.mapping:decode(decoder)
    end
    
    function custom.semantic(id, mapping)
        assert(util.ismapping(mapping))
    
        local semantic = setmetatable({ }, Semantic)
        semantic.mapping = mapping
        semantic.meta    = meta.semantic(id, mapping.meta)
        return semantic
    end
end 

do 
    --mapping for the OBJECT <T> tag
    local Object = { } Object.__index = Object
    function Object:encode(encoder, value)
        local identity = self.handler:identify(value)
        local writer = encoder.writer
        local mapping = self.mapping
        local map = encoder:getobjectmap(self)
        local pos = map[identity]
        if pos == nil then 
            map[identity] = writer:getposition()
            writer:writef("V", 0)
            mapping:encode(encoder, value)
        else 
            writer:writef("V", writer:getposition() - pos)
        end
    end
    
    function Object:decode(decoder)
        local reader  = decoder.reader
        local mapping = self.mapping
        local pos = reader:getposition()
        local shift = reader:readf("V")
        local index = pos - shift
        local found, value = decoder:getobject(self, index)
        if not found then
            value = decoder:endobject(self, index, mapping:decode(decoder))
        end
        return value
    end 
    
    function custom.object(handler, mapping)
        assert(util.ismapping(mapping))
        
        local object   = setmetatable({ }, Object)
        object.mapping = mapping
        object.meta    = meta.object(mapping.meta)
        object.handler = handler
        return object    
    end
end 

do 
    local Align = { }
    Align.__index = Align
    
    function Align:encode(encoder, value)
        encoder.writer:align(self.meta.alignof)
        self.mapping:encode(encoder, value)
    end
    
    function Align:decode(decoder)
        decoder.reader:align(self.meta.alignof)
        return self.mapping:decode(decoder)
    end
    
    function custom.align(size, mapping)
        util.ismapping(mapping)
        
        local aligner = setmetatable({ }, Align)
        aligner.meta    = meta.align(mapping.meta, size)
        aligner.mapping = mapping
        return aligner                
    end
end 

do 
    local newwriter  = format.writer
    local newencoder = core.encoder

    local Embedded = { } Embedded.__index = Embedded;
    function Embedded:encode(encoder, value)
        local mapping = self.mapping
        local outstream = self.handler:getoutstream()
        local enco = newencoder(newwriter(outstream), false)
        mapping:encode(enco, value)
        enco:close()
        
        local data    = outstream:getdata()
        encoder:writef("s", data)
        outstream:close()
    end
    
    function Embedded:decode(decoder) 
        local mapping   = self.mapping
        local reader    = decoder.reader
        
        local length    = reader:readf("V")
        local spos      = reader:getposition()
        local value     = mapping:decode(decoder)
        local epos      = reader:getposition()
        assert(epos - spos == length, "did not read the embedded stream correctly!")        
        return value
    end
    
    function custom.embedded(handler, mapping) 
        assert(util.ismapping(mapping))
        
        local embedded = setmetatable({ }, Embedded)
        embedded.mapping = mapping
        embedded.meta = meta.embedded(mapping.meta)
        embedded.handler = handler
        return embedded
    end
    
    local Opaque = { } Opaque.__index = Opaque
    function Opaque:encode(encoder, value)
        assert(value.opaque == self)
        encoder:writef("s", data)
    end 
    
    function Opaque:decode(decoder)
        local data = decoder:readf("s")
        return { data = data, opaque = self }
    end
    
    function custom.opaque()
        local opaque = setmetatable({}, Opaque)
        opaque.meta  = meta.embedded(meta.void)
        return opaque
    end      
end 

do 
    local Typeref = { } Typeref.__index = Typeref
    function Typeref:encode(encoder, value)
        error("typeref not yet initialized")
    end
    
    function Typeref:decode(decoder)
        error("typeref not yet initialized")
    end
    
    local tofix = { }
    local insert = table.insert
    local function findrefs(table, ref)
        if table.is_fixing_typerefs then return end

        --Avoid cyclic reference problems 
        table.is_fixing_typerefs = true
        
        --Placing items in a temprorary tofix array 
        --to avoid mutating during iteration
        for k, v in pairs(table) do 
            if k == ref or v == ref then 
                insert(tofix, table)
                insert(tofix, k)
            end
            
            if type(k) == "table" then 
                findrefs(k, ref, value)
            end
            
            if type(v) == "table" then
                findrefs(v, ref, value) 
            end 
        end
        
        table.is_fixing_typerefs = nil
    end 
    
    local function fixrefs(mapping, ref, value)
        findrefs(mapping, ref)
        local size = #tofix
        for i=1, size, 2 do
            local table = tofix[i+0] ; tofix[i+0] = nil
            local key   = tofix[i+1] ; tofix[i+1] = nil
            if key == ref then  
                local val    = table[key]
                if val == ref then 
                    val = value 
                end                
                table[value] = val
                table[key]   = nil   
            else 
                table[key] = value
            end 
        end 
    end 
    
        
    function Typeref:setref(mapping)
        assert(self.mapping == nil, "canot reseed a typeref")
        self.mapping = mapping
        
        --We really don't want to have typerefs in the final mapping 
        --chaing when we have initialized the value. Instead 
        --we want to replace any occurance of a typeref with the 
        --actual mapping. 
        fixrefs(mapping, self, mapping)
        mapping.meta = self.meta:setref(mapping.meta)
    end
    
    function custom.typeref()
        local typeref = setmetatable({ }, Typeref)
        typeref.meta  = meta.typeref()
        return typeref
    end
end 

do
    local Type = { } Type.__index = Type
    function Type:encode(encoder, value) --Value would be a tag here.
        assert(util.ismapping(value))
        meta.encodetype(encoder, value.meta)
    end
     
    function Type:decode(decoder)
        local meta = meta.decodetype(decoder)
        return self.handler:getmapping(meta)     
    end
    
    function custom.type(handler)
        assert(handler, "expected a type handler")
        assert(handler.getmapping, "Type handler missing function getmapping")
        return setmetatable({ meta = meta.type, handler = handler}, Type)
    end
end 

do 
    local Dynamic = { } Dynamic.__index = Dynamic
    function Dynamic:encode(encoder, value)
    	local mapping   = self.handler:getmappingof(value)
    	self.mapping:encode(encoder, mapping)
        mapping:encode(encoder, value)
    end
   
    function Dynamic:decode(decoder)
    	local mapping  = self.mapping:decode(decoder)
        return mapping:decode(decoder)
    end
    
    function custom.dynamic(handler, type_mapping)
        assert(type_mapping.meta == meta.type)
        assert(handler.getmappingof, "Dynamic handler missing function getmappingof")
    
        local dynamic = setmetatable({ }, Dynamic)
        dynamic.meta        = meta.dynamic 
        dynamic.handler     = handler
        dynamic.mapping     = type_mapping
        return dynamic
    end
end 

do 
    --Should this be here?
    local Transform = { }
    Transform.__index = Transform
    function Transform:encode(encoder, value)
        local val = self.handler:to(value)
        self.mapping:encode(encoder, val)
    end
    
    function Transform:decode(decoder)
        local val = self.mapping:decode(decoder)
        return self.handler:from(val)
    end
    
    function custom.transform(handler, mapping)
        assert(handler, "expected transform handler")
        assert(util.ismapping(mapping))
        
        assert(handler.to, "Transform handler missing function to")
        assert(handler.from, "Transform handler missing function from")
        
        local transform = setmetatable({ }, Transform)
        transform.meta    = mapping.meta
        transform.handler = handler
        transform.mapping = mapping
        return transform
    end
end 

return custom