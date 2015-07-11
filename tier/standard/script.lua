local custom    = require"tier.custom"
local primitive = require"tier.primitive"
local Script = { identifier = "script-" .. _VERSION }
local dump = string.dump

--There is no convinent place to put the state since 
--transformers do not have access to the encoder and decoder objects. 
--So we use a table with weak values instead. This is all needed 
--so that we get unique tables to preserve the object property of 
--functions with cycles. 
local encoded_functions = setmetatable({ }, { __mode = "v" })
function Script:to(value)
    assert(type(value) == "function", "expected function")
    
    --This is nessesary incase of cyclic references
    if encoded_functions[value] then 
        return encoded_functions[value]
    end
  
    local i = 1
    local code     = dump(value)
    local upname, upval = debug.getupvalue(value, i)
    local upvalues = { }

    while upval do 
        table.insert(upvalues, upval)
      
        i = i + 1
        upval = debug.getupvalue(value, i)
    end

    local func_table = { upvalues, [2] = code}
    encoded_functions[value] = func_table
    return func_table
end

function Script:from(value)
    --Fun problem. Not trivial to solve really...
    if #value == 0 then return value end

    local upvalues = value[1]
    local code     = value[2]
    local func = assert(load(code))
    for i=1, #upvalues do
        local upval = upvalues[i]   
        if upval == value then
            upval = func
        end 
        debug.setupvalue(func, i, upval)
    end
    
    return func
end

return function(standard)
	local mapping =  
    custom.transform(Script,
          standard.semantic(Script.identifier, 
                standard.object(standard.tuple
                {
                    { mapping = standard.list(standard.dynamic) },
                    { mapping = primitive.stream }
                })))
                
                
    --Have to add it to the generator so that we can dynamically decode it.
    standard.generator:idmapping(mapping)
    
	--SEMANTIC "script-Lua 5.3" OBJECT TUPLE 02 LIST 0x00 DYNAMIC STREAM
    --It's important to have object incase of cyclic references.
	standard.script = mapping
end


--Need to fix recursive functions...
--And proboably mutualy recursive functions aswell...