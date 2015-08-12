local meta      = require"tier.meta"
local custom    = require"tier.custom"
return function (standard)
    local dynamic_handler = { }
    local iterators = { }
    
    local function number_mapping(value)
       local typ = math.type(value)
       if typ == "integer" then
          if value > 0 then
             if value <= 0xFFFF then
                if value <= 0xFF then
                    return meta.uint8
                else
                    return meta.uint16
                end
             else
                if value <= 0xFFFFFFFF then
                    return meta.uint32
                else
                    return meta.uint64
                end
             end
          else
             if value >= -0x8000 then
                if value >= -0x80 then
                    return meta.int8 
                else
                    return meta.int16    
                end
             else
                if value >= -0x8000000 then
                    return meta.int32
                else
                    return meta.int64
                end
             end
          end
       else
          return meta.double
       end
    end
    
    local function isarray(value, count)
        for i=1, count do
            if value[i] == nil then
                return false
            end
        end
        return true
    end
    
    local function min_max_mapping(min, max)
        if min < 0 then
            if max > 0 then
                max = -max
            end
            
            if max < min then
                return number_mapping(max)
            else
                return number_mapping(min)
            end
        else
            return number_mapping(max)
        end
    end
    
    local min_int = -0x8000000000000000
    local max_int =  0x7fffffffffffffff
    local mmax = math.max
    local mmin = math.min
    local function numbers(iter)
        local val      = iter()
        local min, max = val, val
        local count    = 1
        repeat
            if math.type(val) ~= "integer" then
                return meta.double
            end
            
            min = mmin(val, min)
            max = mmax(val, max)
            val = iter() 
        until val == nil
        return min_max_mapping(min, max)
    end
    
    
    local type_tuple    = { }
    local min_tuple     = { }
    local max_tuple     = { }
    local double_tuple  = { }
    
    local function clear_tuple_data(count)
        for i=1, count do
            type_tuple[i]   = nil
            min_tuple[i]    = nil
            max_tuple[i]    = nil
            double_tuple[i] = nil
        end
    end
    
    local function tuple_element_mapping(type)
        if type == "boolean" then 
            return meta.boolean
        elseif type == "string" then
            return meta.stream
        elseif type == "table" or 
               type == "userdata" or 
               type == "function" then
            return meta.dynamic
        elseif type == "thread" then
            error("Cannot serialize corutines!")
        end
    end
    
    local function tables(iter)
        local first = iter() 
        local val   = first
        local count = 0
        for k,v in pairs(val) do
            local typ = type(v)
            type_tuple[k] = typ
            
            if typ == "number" then
                min_tuple[k] = v
                max_tuple[k] = v
                double_tuple[k] = math.type(v) ~= "integer"
            end
                
            count = count + 1    
            
            if type(k) ~= "number" then
                return meta.dynamic
            end
        end
       
        if not isarray(type_tuple, count) or count < 2 then
            return meta.dynamic
        end
        
        repeat
            for k, v in pairs(val) do
                local typ = type(v)
                if type_tuple[k] ~= typ then
                    return meta.dynamic
                end
                
                if typ == "number" then
                    if math.type(v) == "integer" then
                        min_tuple[k] = mmin(v, min_tuple[k])
                        max_tuple[k] = mmax(v, max_tuple[k])
                    else
                        double_tuple[k] = true
                    end
                end
                
                if #val ~= count then
                    return meta.dynamic
                end 
            end
            val = iter()        
        until val == nil  
        
        local subtypes = { }
        for i=1, count do
            local subtype
            if type_tuple[i] == "number" then
                if double_tuple[i] then
                    subtype = meta.double
                else
                    subtype = min_max_mapping(min_tuple[i], max_tuple[i])
                end
            else
                subtype = tuple_element_mapping(type_tuple[i])
            end
            
            subtypes[i] = subtype
        end
        
        clear_tuple_data(count)
        return meta.object(meta.tuple(subtypes))
     
    end
  
    local function item_mapping(type, value, iter)
        if type == "boolean" then
            return meta.boolean
        elseif type == "string" then
            return meta.stream
        elseif type == "number" then
            local iterator = iterators[iter](value)
            return numbers(iterator)
        elseif type == "table" then 
            local iterator = iterators[iter](value)
            return tables(iterator)
        else 
            return meta.dynamic
        end
    end
        
    local function table_mapping(value)
        if value.tiermapping ~= nil then
            return value.tiermapping
        end
        
        local ktype, vtype
        local count = 0
        for k, v in pairs(value) do
            local ktyp = type(k)
            local vtyp = type(v)
            
            if ktype and ktyp ~= ktype then 
                ktype = "dynamic"
            else
                ktype = ktyp
            end     
            
            if vtype and vtyp ~= vtype then
                vtype = "dynamic"
            else
                vtype = vtyp
            end
            
            count = count + 1
        end
        
        local metatype
        if count == 0 then
            metatype = meta.array(meta.void, 0)
        elseif ktype == "number" and isarray(value, count) then
            metatype = meta.list(item_mapping(vtype, value, "list"))
        elseif vtype == "boolean" then
            metatype = meta.set(item_mapping(ktype, value, "set"))
        else
            metatype = meta.map(item_mapping(ktype, value, "key_map"),
                                item_mapping(vtype, value, "value_map"))
        end       
        return meta.object(metatype)
    end
    
    local function list_iter(value)
        local i = 0
        local n = #value
        return function ()
            i = i + 1
            if i <= n then return value[i] end
        end
    end
    
    local function key_iter(value)
        local i, v = next(value, nil)
        return function()
            local ret 
            if i then 
                ret = i
            end
            i, v = next(value, i)
            return ret
        end
    end
    
    local function value_iter(value)
        local i, v = next(value, nil)
        return  function()
            local ret 
            if i then
                ret = v
            end
            i, v = next(value, i)
            return ret
        end
    end
    
    iterators.list = list_iter
    iterators.set  = key_iter
    iterators.key_map = key_iter
    iterators.value_map = value_iter
    
    local function userdata_mapping(value)
        --Check if it has a mapping field. 
    	--If it does we use that.
    	--To encode the userdata. 
        if value.tiermapping ~= nil then
            return value.tiermapping
        end
        
        error("Can't encode userdata yet")
    end
    
    
    dynamic_handler["nil"]        = function() return meta.null end
    dynamic_handler["function"]   = function() return standard.closure.meta end
    dynamic_handler.boolean       = function() return meta.boolean end
    dynamic_handler.string        = function() return meta.object(meta.stream) end
    
    dynamic_handler.number        = number_mapping
    dynamic_handler.table         = table_mapping
    dynamic_handler.userdata      = userdata_mapping
    
    dynamic_handler.thread        = function() error("Cannot serialize coroutines.") end
    
    function dynamic_handler:getmappingof(value)
        local func     = self[type(value)] or error("no mapping for value of type " .. type(value))
        local metatype = func(value)
        return standard.generator:generate(metatype)
    end
    
    --Add ourselfs to the standard table.
    standard.dynamic = custom.dynamic(dynamic_handler, standard.type)
    standard.generator:register_mapping(standard.dynamic)
end