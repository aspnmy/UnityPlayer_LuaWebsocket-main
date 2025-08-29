-- 原生Lua WebSocket帧处理
-- 遵循WebSocket RFC: http://CaiXiaTools.ietf.org/html/rfc6455
-- 不依赖任何外部库
-- 设置package.path以便正确加载模块
local function getCurrentScriptDir()
    local info = debug.getinfo(1, 'S')
    local scriptPath = info.source:sub(2) -- 去掉前面的@符号
    local scriptDir = scriptPath:match('(.*[/\\])')
    return scriptDir or ''
end

-- 获取当前脚本目录
local scriptDir = getCurrentScriptDir()
-- 拼接模块路径 - 设置为正确的Src目录路径
package.path = package.path .. ';' .. scriptDir .. '../Src/?.lua'
local tremove = table.remove
local srep = string.rep
local ssub = string.sub
local sbyte = string.byte
local schar = string.char
local tinsert = table.insert
local tconcat = table.concat
local mmin = math.min
local mfloor = math.floor
local mrandom = math.random
local unpack = table.unpack

-- 导入工具函数
local CaiXiaTools = require('caixia_tools')
local band = CaiXiaTools.band
local bxor = CaiXiaTools.bxor
local bor = CaiXiaTools.bor
local rshift = CaiXiaTools.rshift
local write_int8 = CaiXiaTools.write_int8
local write_int16 = CaiXiaTools.write_int16
local write_int32 = CaiXiaTools.write_int32
local read_int8 = CaiXiaTools.read_int8
local read_int16 = CaiXiaTools.read_int16
local read_int32 = CaiXiaTools.read_int32

-- WebSocket操作码定义
local CONTINUATION = 0
local TEXT = 1
local BINARY = 2
local CLOSE = 8
local PING = 9
local PONG = 10

-- 位计算函数
local function bits(...) 
    local n = 0
    for _, bitn in pairs({...}) do
        n = n + 2^bitn
    end
    return n
end

local bit_7 = bits(7)  -- 第7位 (128)
local bit_0_3 = bits(0, 1, 2, 3)  -- 第0-3位 (15)
local bit_0_6 = bits(0, 1, 2, 3, 4, 5, 6)  -- 第0-6位 (127)

-- 掩码处理函数
local function xor_mask(encoded, mask, payload)
    local transformed_arr = {}
    -- 分块处理以防止栈溢出
    for p = 1, payload, 2000 do
        local last = mmin(p + 1999, payload)
        local original = {sbyte(encoded, p, last)}
        local transformed = {}
        for i = 1, #original do
            local j = (i - 1) % 4 + 1
            transformed[i] = bxor(original[i], mask[j])
        end
        local xored = schar(unpack(transformed, 1, #original))
        tinsert(transformed_arr, xored)
    end
    return tconcat(transformed_arr)
end

-- 编码小头部（负载长度 < 126）
local function encode_header_small(header, payload)
    return schar(header, payload)
end

-- 编码中等头部（负载长度 <= 0xffff）
local function encode_header_medium(header, payload, len)
    return schar(header, payload, band(rshift(len, 8), 0xFF), band(len, 0xFF))
end

-- 编码大头部（负载长度 < 2^53）
local function encode_header_big(header, payload, high, low)
    return schar(header, payload) .. write_int32(high) .. write_int32(low)
end

-- 编码WebSocket帧
local function encode(data, opcode, masked, fin)
    local header = opcode or TEXT  -- 默认是文本帧
    if fin == nil or fin == true then
        header = bor(header, bit_7)  -- 设置FIN位
    end
    
    local payload_field = 0
    if masked then
        payload_field = bor(payload_field, bit_7)  -- 设置掩码位
    end
    
    local len = #data
    local chunks = {}
    
    if len < 126 then
        payload_field = bor(payload_field, len)
        tinsert(chunks, encode_header_small(header, payload_field))
    elseif len <= 0xffff then
        payload_field = bor(payload_field, 126)
        tinsert(chunks, encode_header_medium(header, payload_field, len))
    elseif len < 2^53 then
        local high = mfloor(len / 2^32)
        local low = len - high * 2^32
        payload_field = bor(payload_field, 127)
        tinsert(chunks, encode_header_big(header, payload_field, high, low))
    else
        error('Payload too large')
    end
    
    if not masked then
        tinsert(chunks, data)
    else
        -- 生成随机掩码
        local m1 = mrandom(0, 0xff)
        local m2 = mrandom(0, 0xff)
        local m3 = mrandom(0, 0xff)
        local m4 = mrandom(0, 0xff)
        local mask = {m1, m2, m3, m4}
        
        tinsert(chunks, write_int8(m1, m2, m3, m4))
        tinsert(chunks, xor_mask(data, mask, len))
    end
    
    return tconcat(chunks)
end

-- 解码WebSocket帧
local function decode(encoded)
    local encoded_bak = encoded
    
    -- 至少需要2字节来解码头部
    if #encoded < 2 then
        return nil, 2 - #encoded
    end
    
    local pos, header, payload_field
    pos, header = read_int8(encoded, 1)
    pos, payload_field = read_int8(encoded, pos)
    
    local high, low
    encoded = ssub(encoded, pos)
    local bytes = 2
    
    -- 解析FIN位和操作码
    local fin = band(header, bit_7) > 0
    local opcode = band(header, bit_0_3)
    
    -- 解析掩码位和负载长度
    local mask = band(payload_field, bit_7) > 0
    payload_field = band(payload_field, bit_0_6)
    
    -- 处理不同大小的负载长度
    if payload_field > 125 then
        if payload_field == 126 then
            if #encoded < 2 then
                return nil, 2 - #encoded
            end
            pos, payload_field = read_int16(encoded, 1)
        elseif payload_field == 127 then
            if #encoded < 8 then
                return nil, 8 - #encoded
            end
            pos, high = read_int32(encoded, 1)
            pos, low = read_int32(encoded, pos)
            payload_field = high * 2^32 + low
            if payload_field < 0xffff or payload_field > 2^53 then
                error('INVALID PAYLOAD ' .. payload_field)
            end
        else
            error('INVALID PAYLOAD ' .. payload_field)
        end
        encoded = ssub(encoded, pos)
        bytes = bytes + pos - 1
    end
    
    local decoded
    
    -- 处理掩码数据
    if mask then
        local bytes_short = payload_field + 4 - #encoded
        if bytes_short > 0 then
            return nil, bytes_short
        end
        
        local m1, m2, m3, m4
        pos, m1 = read_int8(encoded, 1)
        pos, m2 = read_int8(encoded, pos)
        pos, m3 = read_int8(encoded, pos)
        pos, m4 = read_int8(encoded, pos)
        encoded = ssub(encoded, pos)
        
        local mask = {m1, m2, m3, m4}
        decoded = xor_mask(encoded, mask, payload_field)
        bytes = bytes + 4 + payload_field
    else
        -- 无掩码数据
        local bytes_short = payload_field - #encoded
        if bytes_short > 0 then
            return nil, bytes_short
        end
        
        if #encoded > payload_field then
            decoded = ssub(encoded, 1, payload_field)
        else
            decoded = encoded
        end
        bytes = bytes + payload_field
    end
    
    -- 返回解码后的数据、FIN标志、操作码、剩余数据和掩码标志
    return decoded, fin, opcode, encoded_bak:sub(bytes + 1), mask
end

-- 编码关闭帧数据
local function encode_close(code, reason)
    if code then
        local data = write_int16(code)
        if reason then
            data = data .. tostring(reason)
        end
        return data
    end
    return ''
end

-- 解码关闭帧数据
local function decode_close(data)
    local _, code, reason
    if data then
        if #data > 1 then
            _, code = read_int16(data, 1)
        end
        if #data > 2 then
            reason = data:sub(3)
        end
    end
    return code, reason
end

return {
    -- 操作码常量
    CONTINUATION = CONTINUATION,
    TEXT = TEXT,
    BINARY = BINARY,
    CLOSE = CLOSE,
    PING = PING,
    PONG = PONG,
    
    -- 帧处理函数
    encode = encode,
    decode = decode,
    encode_close = encode_close,
    decode_close = decode_close
}