Language = {}

function _L(name, ...)
    if name then 
        local str = Language[Config.Language][name]
        if str then 
            return string.format(str, ...)
        else    
            return "ERR_TRANSLATE_"..(name).."_404"
        end
    else
        return "ERR_TRANSLATE_404"
    end
end

function lerp(a, b, t) return a + (b-a) * t end

function v3(coords) return vec3(coords.x, coords.y, coords.z), coords.w end

function GetRandomInt(min, max, exclude)
    for i=1, 1000 do 
        local int = math.random(min, max)
        if exclude == nil or exclude ~= int then 
            return int
        end
    end
end