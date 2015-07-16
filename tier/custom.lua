local format = require"format"
local core   = require"tier.core"
local tags   = require"tier.tags"
local util   = require"tier.util"

local pack      = format.packvarint
local writemeta = core.writemeta

local custom = { }

do 
    local Int = { } Int.__index = Int
    function Int:encode(encoder, value)
        encoder.writer:int(self.meta.bits, value)
    end
    
    function Int:decode(decoder)
        return encoder.reader:int(self.meta.bits)
    end
    
    function custom.int(numbits)
        return setmetatable({ meta = meta.int(numbits) }, Int)
    end
end 

do 
    local Uint = { } Uint.__index = Uint
    function Uint:encode(encoder, value)
        encoder.writer:uint(self.meta.bits, value)
    end
    
    function Uint:decode(decoder)
        return encoder.reader:uint(self.meta.bits)
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
        local size = self.size
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
    
        local array = setmetatable({ }, Array)
        array.meta    = meta.array(mapping.meta, size)
        array.handler = handler
        array.mapping  = mapping
        return array    
    end
end 

local function writesize(writer, bits, size)
    if bits == 0 then
       writer:varint(size)
    else
       writer:uint(bits, size) 
    end
end

local function readsize(reader, bits)
    if bits == 0 then
        return reader:varint()
    else
        return reader:uint(bits)
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
            
        local list = setmetatable({ }, List)
        list.meta  = meta.list(mapping.meta, sizebits)
        list.handler = handler
        list.mapping = mapping
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
        set.meta    = meta.set(mapping.meta, sizebits)
        set.handler = handler
        set.mapping = mapping
        return set
    end
end 

do 
    --mapping for the MAP <K> <V> tag.
    local Map = { } Map.__index = Map
    function Map:encode(encoder, value)
        local size = self.handler:getsize(value)
        writesize(encoder.writer, self.meta.sizebits, size)
        for k, v in self.handler:getitems(value) do
            self.keymapping:encode(encoder, k)
            self.itemmapping:encode(encoder, v);
        end
    end
    
    function Map:decode(decoder)
        local size  = readsize(decoder.reader, self.meta.sizebits)
        local value = self.handler:create(size)
        decoder:setobject(value)
        for i=1, size, 1 do
            local key  = self.keymapping:decode(decoder)
            local item = self.itemmapping:decode(decoder)
            
            self.handler:putitem(value, key, item)
        end 
        
        return value;
    end
    
    function custom.map(handler, keymapping, itemmapping, sizebits)
        assert(util.ismapping(keymapping))
        assert(util.ismapping(itemmapping))
        
        assert(handler.getsize,  "Map handler missing function getsize")
        assert(handler.create,   "Map handler missing function create")
        assert(handler.putitem,  "Map handler missing function putitem")
        assert(handler.getitems, "Map handler missing function getitems")
          
        local map = setmetatable({}, Map)
        map.meta        = meta.map(keymapping.meta, itemmapping.meta, sizebits)
        map.handler     = handler
        map.keymapping  = keymapping
        map.itemmapping = itemmapping
        return map;
    end

end 

do 
    --mapping for the TUPLE N <T1> <T2> ... <TN> tag.
    local Tuple = { }
    Tuple.__index = Tuple
    function Tuple:encode(encoder, value)
        for i=1, #self.mappings, 1 do
            local mapping = self.mappings[i]
            local item   = self.handler:getitem(value, i)
            mapping:encode(encoder, item)
        end
    end
    
    function Tuple:decode(decoder)
        local value = self.handler:create();
        decoder:setobject(value)
        for i=1, #self.mappings, 1 do
            local mapping = self.mappings[i] 
            local item   = mapping:decode(decoder)
            self.handler:setitem(value, i, item)
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
    
        local types = { }
        for i=1, #mappings do 
            types[i] = mappings[i].meta
        end 
    
        local tuple = setmetatable({ }, Tuple)
        tuple.meta     = meta.tuple(types)
        tuple.mappings = mappings
        tuple.handler  = handler
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
    
        local types = { }
        for i=1, #mappings do 
            types[i] = mappings[i]
        end 
        
        local union = setmetatable({ }, Union)
        union.meta  = meta.union(types, sizebits)
        union.handler  = handler
        union.mappings  = mappings
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
        semantic.meta    = meta.semantic(id, mapping.meta)
        semantic.mapping = mapping
        return semantic
    end
end 

do 
    --mapping for the OBJECT <T> tag
    local Object = { } Object.__index = Object
    function Object:encode(encoder, value)
        local identity = self.handler:identify(value)
        local writer = encoder.writer
        local map = encoder:getobjectmap(self)
        local pos = map[identity]
        if pos == nil then 
            map[identity] = writer:getposition()
            writer:varint(0)
            self.mapping:encode(encoder, value)
        else 
            writer:varint(writer:getposition() - pos)
        end
    end
    
    function Object:decode(decoder)
        local reader = decoder.reader
        local pos = reader:getposition()
        local shift = reader:varint()
        local index = pos - shift
        local found, value = decoder:getobject(self, index)
        if not found then
            value = decoder:endobject(self, value, index, self.mapping:decode(decoder))
        end
        return value
    end 
    
    function custom.object(handler, mapping)
        assert(util.ismapping(mapping))
        
        local object = setmetatable({ }, Object)
        object.meta    = meta.object(mapping.meta)
        object.mapping = mapping
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
        
        local aligner = setmetatable({}, Align)
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
        local outstream = self.handler:getoutstream()
        local enco = newencoder(newwriter(outstream), false)
        self.mapping:encode(enco, value)
        enco:close()
        
        local data    = outstream:getdata()
        encoder.writer:stream(data)
        outstream:close()
    end
    
    local newreader  = format.reader 
    local newdecoder = core.decoder
    
    function Embedded:decode(decoder) 
        local data      = decoder.reader:stream() 
        local instream  = self.handler:getinstream(data)
        local deco      = newdecoder(newreader(instream), false)
        local value     = self.mapping:decode(deco) 
            
        deco:close()
        instream:close()
        return value
    end
    
    function custom.embedded(handler, mapping) 
        assert(util.ismapping(mapping))
        
        local embedded = setmetatable({}, Embedded)
        embedded.meta = meta.embedded(mapping.meta)
        embedded.handler = handler
        embedded.mapping = mapping
        return embedded
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
    
    function Typeref:setref(mapping)
        assert(self.mapping == nil, "canot reseed a typeref")
        self.mapping = mapping
        self.meta:setref(self.mapping.meta)
        self.meta = self.mapping.meta
                
        local mencode = mapping.encode
        function encode(tr, encoder, value)
            mencode(mapping, encoder, value)
        end
        
        local mdecode = mapping.decode
        function decode(tr, decoder)
           return mdecode(mapping, decoder)
        end
        
        self.encode = encode
        self.decode = decode    
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