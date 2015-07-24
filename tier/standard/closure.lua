local custom    = require"tier.custom"
local primitive = require"tier.primitive"
local meta      = require"tier.meta"
local dump = string.dump

local inf = 0x7FFFFFFFFFFFFFFF
local Closure = { } 
function Closure:encode(encoder, value)
    local t = type(value)
    if t ~= "function" then 
        error("expected function got " .. t)
    end 

    if not encoder.upvalues then 
        encoder.upvalues = { }
        encoder.upvaluecount = 0
    end 
    
    local code = dump(value)
    encoder:writef("s", code)

    local count = 0
    for i=1, inf do 
        local _, upval = debug.getupvalue(value, i)
        if not upval then break end 
        count = count + 1
    end
    
    encoder:writef("V", count)
    
    local upvals  = encoder.upvalues
    local upcount = encoder.upvaluecount    
    for i=1, count do 
        local upname, upval = debug.getupvalue(value, i)
        if upname == "_ENV" then 
            upval = "_ENV"            
        end 
        
        local upid          = debug.upvalueid (value, i)
        
        local numberid      = upvals[upid]
        if not numberid then 
            upcount      = upcount + 1
            upvals[upid] = upcount
            numberid     = upcount
        end
        
        self.upmapping:encode(encoder, { numberid, upval})
    end
        
     encoder.upvaluecount = upcount                                                                                      
end

function Closure:decode(decoder)
    if not decoder.upvalues then 
        decoder.upvalues = { }
    end 
    
    local code = decoder:readf("s")
    local func    = load(code)
    decoder:setobject(func)
    
    local upcount = decoder:readf("V")

    for i=1, upcount do 
        local upval = self.upmapping:decode(decoder)
        if upval[2] == "_ENV" then 
            --Do nothing i guess. 
        else 
            local fup     = decoder.upvalues[upval[1]]
            if fup then 
                local f, idx = fup.f, fup.idx
                debug.upvaluejoin(func, i, f, idx)
            else 
                decoder.upvalues[upval[1]] = { f = func, idx = i }
                debug.setupvalue(func, i, upval[2])            
            end 
        end     
    end
    return func      
end

local UpvalHandler = { }
function UpvalHandler:identify(value)
    return value[1]
end 

return function(standard)
    local upvalue = custom.object(UpvalHandler, 
                           standard.tuple{ 
                               { mapping = primitive.varint }, 
                               { mapping = standard.dynamic } })
                               
    Closure.upmapping    = upvalue
    Closure.meta         = meta.semantic("closure", meta.tuple(meta.stream, meta.list(upvalue.meta)))    
    standard.closure     = standard.object(Closure)
    
    standard.generator:register_mapping(standard.closure)
end 