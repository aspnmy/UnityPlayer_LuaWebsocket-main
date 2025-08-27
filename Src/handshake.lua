-- 原生Lua WebSocket握手协议实现
-- 不依赖任何外部库

local tinsert = table.insert
local tconcat = table.concat

-- 导入工具函数
local tools = require('native_websocket.tools')
local sha1 = tools.sha1
local base64_encode = tools.base64.encode

-- WebSocket GUID常量
local guid = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

-- 计算Sec-WebSocket-Accept值
local function sec_websocket_accept(sec_websocket_key)
    local a = sec_websocket_key .. guid
    local sha1_hash = sha1(a)
    assert((#sha1_hash % 2) == 0, "SHA1 hash length must be even")
    return base64_encode(sha1_hash)
end

-- 解析HTTP头部
local function http_headers(request)
    local headers = {}
    
    -- 检查是否是HTTP/1.1请求
    if not request:match('.*HTTP/1%.1') then
        return headers
    end
    
    -- 提取头部部分
    request = request:match('[^\r\n]+\r\n(.*)')
    local empty_line
    
    -- 解析每一行头部
    for line in request:gmatch'([^\r\n]*)' do
        local name, val = line:match('([^%s]+)%s*:%s*([^\r\n]*)')
        if name and val then
            name = name:lower()
            -- 对于WebSocket特定头部，保持值的大小写
            if not name:match('sec%-websocket') then
                val = val:lower()
            end
            
            -- 处理同名头部（使用逗号连接）
            if not headers[name] then
                headers[name] = val
            else
                headers[name] = headers[name] .. ',' .. val
            end
        elseif line == '\r\n' then
            empty_line = true
        else
            assert(false, "Invalid header line: " .. line .. '(' .. #line .. ')')
        end
    end
    
    -- 返回解析后的头部和请求体
    return headers, request:match('(.*)')
end

-- 生成WebSocket升级请求
local function upgrade_request(req)
    local format = string.format
    local lines = {
        format('GET %s HTTP/1.1', req.uri or ''),
        format('Host: %s', req.host),
        'Upgrade: websocket',
        'Connection: Upgrade',
        format('Sec-WebSocket-Key: %s', req.key),
        format('Sec-WebSocket-Protocol: %s', table.concat(req.protocols, ', ')),
        'Sec-WebSocket-Version: 13',
    }
    
    -- 添加Origin头部（如果提供）
    if req.origin then
        tinsert(lines, string.format('Origin: %s', req.origin))
    end
    
    -- 处理非默认端口
    if req.port and req.port ~= 80 then
        lines[2] = format('Host: %s:%d', req.host, req.port)
    end
    
    -- 添加结尾空行
    tinsert(lines, '\r\n')
    
    return table.concat(lines, '\r\n')
end

-- 处理WebSocket升级请求并生成响应
local function accept_upgrade(request, protocols)
    local headers = http_headers(request)
    
    -- 验证必要的WebSocket头部
    if headers['upgrade'] ~= 'websocket' or
       not headers['connection'] or
       not headers['connection']:match('upgrade') or
       headers['sec-websocket-key'] == nil or
       headers['sec-websocket-version'] ~= '13' then
        return nil, 'HTTP/1.1 400 Bad Request\r\n\r\n'
    end
    
    -- 选择支持的协议
    local selected_protocol
    if headers['sec-websocket-protocol'] then
        for protocol in headers['sec-websocket-protocol']:gmatch('([^, ]+)%s*,?') do
            for _, supported in ipairs(protocols) do
                if supported == protocol then
                    selected_protocol = protocol
                    break
                end
            end
            if selected_protocol then
                break
            end
        end
    end
    
    -- 构建响应头部
    local response_lines = {
        'HTTP/1.1 101 Switching Protocols',
        'Upgrade: websocket',
        'Connection: ' .. headers['connection'],
        string.format('Sec-WebSocket-Accept: %s', sec_websocket_accept(headers['sec-websocket-key'])),
    }
    
    -- 如果有选择的协议，添加协议头部
    if selected_protocol then
        tinsert(response_lines, string.format('Sec-WebSocket-Protocol: %s', selected_protocol))
    end
    
    -- 添加结尾空行
    tinsert(response_lines, '\r\n')
    
    return table.concat(response_lines, '\r\n'), selected_protocol
end

return {
    sec_websocket_accept = sec_websocket_accept,
    http_headers = http_headers,
    accept_upgrade = accept_upgrade,
    upgrade_request = upgrade_request
}