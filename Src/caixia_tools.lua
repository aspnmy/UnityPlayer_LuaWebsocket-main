-- 原生Lua WebSocket工具函数
-- 不依赖任何外部库

local tremove = table.remove
local tinsert = table.insert
local tconcat = table.concat
local srep = string.rep
local ssub = string.sub
local sbyte = string.byte
local schar = string.char
local mrandom = math.random
local mfloor = math.floor
local mceil = math.ceil
local abs = math.abs

-- 位操作函数（纯Lua实现，兼容Lua 5.1）
local function band(a, b) -- 按位与
    local result = 0
    local bit = 1
    while a > 0 or b > 0 do
        if (a % 2 == 1) and (b % 2 == 1) then
            result = result + bit
        end
        bit = bit * 2
        a = mfloor(a / 2)
        b = mfloor(b / 2)
    end
    return result
end

local function bor(a, b) -- 按位或
    local result = 0
    local bit = 1
    while a > 0 or b > 0 do
        if (a % 2 == 1) or (b % 2 == 1) then
            result = result + bit
        end
        bit = bit * 2
        a = mfloor(a / 2)
        b = mfloor(b / 2)
    end
    return result
end

local function bxor(a, b) -- 按位异或
    local result = 0
    local bit = 1
    while a > 0 or b > 0 do
        if (a % 2 == 1) ~= (b % 2 == 1) then
            result = result + bit
        end
        bit = bit * 2
        a = mfloor(a / 2)
        b = mfloor(b / 2)
    end
    return result
end

local function bnot(a) -- 按位非（这里简单实现为取反）
    return -a - 1
end

local function lshift(a, b) -- 左移
    return a * (2 ^ b)
end

local function rshift(a, b) -- 右移
    return mfloor(a / (2 ^ b))
end

local function rol(a, b) -- 循环左移（简化版）
    local bits = 32 -- 假设32位整数
    b = b % bits
    return bor(lshift(a, b), rshift(a, bits - b))
end

-- 读取n个字节
local function read_n_bytes(str, pos, n)
    pos = pos or 1
    return pos + n, {sbyte(str, pos, pos + n - 1)}
end

-- 读取8位整数
local function read_int8(str, pos)
    local new_pos, bytes = read_n_bytes(str, pos, 1)
    return new_pos, bytes[1]
end

-- 读取16位整数（大端序）
local function read_int16(str, pos)
    local new_pos, bytes = read_n_bytes(str, pos, 2)
    return new_pos, lshift(bytes[1], 8) + bytes[2]
end

-- 读取32位整数（大端序）
local function read_int32(str, pos)
    local new_pos, bytes = read_n_bytes(str, pos, 4)
    return new_pos,
           lshift(bytes[1], 24) +
           lshift(bytes[2], 16) +
           lshift(bytes[3], 8) +
           bytes[4]
end

-- 写入8位整数
local function write_int8(...) -- 可以接受多个参数
    local args = {...}
    local chars = {}
    for i = 1, #args do
        chars[i] = schar(args[i])
    end
    return tconcat(chars)
end

-- 写入16位整数（大端序）
local function write_int16(v)
    return schar(band(rshift(v, 8), 0xFF), band(v, 0xFF))
end

-- 写入32位整数（大端序）
local function write_int32(v)
    return schar(
        band(rshift(v, 24), 0xFF),
        band(rshift(v, 16), 0xFF),
        band(rshift(v, 8), 0xFF),
        band(v, 0xFF)
    )
end

-- SHA1 哈希函数（纯Lua实现）
local function sha1(msg)
    local h0 = 0x67452301
    local h1 = 0xEFCDAB89
    local h2 = 0x98BADCFE
    local h3 = 0x10325476
    local h4 = 0xC3D2E1F0

    local bits = #msg * 8
    -- 追加 b10000000
    msg = msg .. schar(0x80)

    -- 64位长度将被追加
    local bytes = #msg + 8

    -- 512位填充
    local fill_bytes = 64 - (bytes % 64)
    if fill_bytes ~= 64 then
        msg = msg .. srep(schar(0), fill_bytes)
    end

    -- 追加64位大端序长度
    local high = mfloor(bits / 2^32)
    local low = bits - high * 2^32
    msg = msg .. write_int32(high) .. write_int32(low)

    for j = 1, #msg, 64 do
        local chunk = ssub(msg, j, j + 63)
        local words = {}
        local next = 1
        local word
        repeat
            next, word = read_int32(chunk, next)
            tinsert(words, word)
        until next > 64

        for i = 17, 80 do
            words[i] = bxor(words[i-3], words[i-8], words[i-14], words[i-16])
            words[i] = rol(words[i], 1)
        end

        local a = h0
        local b = h1
        local c = h2
        local d = h3
        local e = h4

        for i = 1, 80 do
            local k, f
            if i > 0 and i < 21 then
                f = bor(band(b, c), band(bnot(b), d))
                k = 0x5A827999
            elseif i > 20 and i < 41 then
                f = bxor(b, c, d)
                k = 0x6ED9EBA1
            elseif i > 40 and i < 61 then
                f = bor(band(b, c), band(b, d), band(c, d))
                k = 0x8F1BBCDC
            elseif i > 60 and i < 81 then
                f = bxor(b, c, d)
                k = 0xCA62C1D6
            end

            local temp = rol(a, 5) + f + e + k + words[i]
            e = d
            d = c
            c = rol(b, 30)
            b = a
            a = temp
        end

        h0 = band(h0 + a, 0xffffffff)
        h1 = band(h1 + b, 0xffffffff)
        h2 = band(h2 + c, 0xffffffff)
        h3 = band(h3 + d, 0xffffffff)
        h4 = band(h4 + e, 0xffffffff)
    end

    return write_int32(h0) .. write_int32(h1) .. write_int32(h2) .. write_int32(h3) .. write_int32(h4)
end

-- Base64 编码（纯Lua实现）
local function base64_encode(data)
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local result = {}
    local i = 1
    while i <= #data do
        local a, b, c = sbyte(data, i, i+2)
        local nil_count = 0
        if not b then b, nil_count = 0, 2 end
        if not c then c, nil_count = 0, 1 end
        
        local triple = lshift(a or 0, 16) + lshift(b or 0, 8) + (c or 0)
        
        for j = 1, 4 - nil_count do
            local index = band(rshift(triple, 6 * (4 - j)), 0x3F)
            tinsert(result, ssub(chars, index + 1, index + 1))
        end
        
        for j = 1, nil_count do
            tinsert(result, '=')
        end
        
        i = i + 3
    end
    return tconcat(result)
end

-- 默认端口
local DEFAULT_PORTS = {ws = 80, wss = 443}

-- URL解析
local function parse_url(url)
    local protocol, address, uri = url:match('^(%w+)://([^/]+)(.*)$')
    if not protocol then error('Invalid URL:'..url) end
    protocol = protocol:lower()
    local host, port = address:match('^(.+):(%d+)$')
    if not host then
        host = address
        port = DEFAULT_PORTS[protocol]
    end
    if not uri or uri == '' then uri = '/' end
    return protocol, host, tonumber(port), uri
end

-- 生成随机密钥
local function generate_key()
    math.randomseed(os.time() + math.abs(tonumber(tostring({}):sub(8)))) -- 简单的随机种子
    local r1 = mrandom(0, 0xfffffff)
    local r2 = mrandom(0, 0xfffffff)
    local r3 = mrandom(0, 0xfffffff)
    local r4 = mrandom(0, 0xfffffff)
    local key = write_int32(r1) .. write_int32(r2) .. write_int32(r3) .. write_int32(r4)
    return base64_encode(key)
end

return {
    -- 位操作函数
    band = band,
    bor = bor,
    bxor = bxor,
    bnot = bnot,
    lshift = lshift,
    rshift = rshift,
    rol = rol,
    
    -- 字节操作函数
    read_n_bytes = read_n_bytes,
    read_int8 = read_int8,
    read_int16 = read_int16,
    read_int32 = read_int32,
    write_int8 = write_int8,
    write_int16 = write_int16,
    write_int32 = write_int32,
    
    -- 加密函数
    sha1 = sha1,
    base64 = {
        encode = base64_encode
    },
    
    -- 其他工具函数
    parse_url = parse_url,
    generate_key = generate_key
}