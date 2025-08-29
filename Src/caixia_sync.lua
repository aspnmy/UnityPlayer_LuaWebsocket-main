-- 原生Lua WebSocket同步操作实现
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
local tinsert = table.insert
local tconcat = table.concat

-- 导入必要的模块
local frame = require('caixia_frame')
local handshake = require('caixia_handshake')
local tools = require('caixia_tools')

-- 接收WebSocket数据
local function receive(self)
    -- 检查连接状态
    if self.state ~= 'OPEN' and not self.is_closing then
        return nil, nil, false, 1006, 'wrong state'
    end
    
    local first_opcode
    local frames
    local bytes = 3
    local encoded = ''
    
    -- 清理连接的函数
    local clean = function(was_clean, code, reason)
        self.state = 'CLOSED'
        self:sock_close()
        if self.on_close then
            self:on_close()
        end
        return nil, nil, was_clean, code, reason or 'closed'
    end
    
    while true do
        -- 接收数据块
        local chunk, err = self:sock_receive(bytes)
        if err then
            return clean(false, 1006, err)
        end
        
        encoded = encoded .. chunk
        
        -- 尝试解码帧
        local decoded, fin, opcode, remaining, masked = frame.decode(encoded)
        
        -- 客户端必须接收未掩码的数据
        if not self.is_server and masked then
            return clean(false, 1006, 'Websocket receive failed: frame was not masked')
        end
        
        if decoded then
            -- 处理关闭帧
            if opcode == frame.CLOSE then
                if not self.is_closing then
                    local code, reason = frame.decode_close(decoded)
                    -- 回显关闭码
                    local msg = frame.encode_close(code)
                    local encoded_close = frame.encode(msg, frame.CLOSE, not self.is_server)
                    local n, err = self:sock_send(encoded_close)
                    if n == #encoded_close then
                        return clean(true, code, reason)
                    else
                        return clean(false, code, err)
                    end
                else
                    return decoded, opcode
                end
            end
            
            -- 记录第一个操作码
            if not first_opcode then
                first_opcode = opcode
            end
            
            -- 处理非结束帧
            if not fin then
                if not frames then
                    frames = {}
                elseif opcode ~= frame.CONTINUATION then
                    return clean(false, 1002, 'protocol error')
                end
                bytes = 3
                encoded = ''
                tinsert(frames, decoded)
            -- 处理单个完整帧
            elseif not frames then
                return decoded, first_opcode
            -- 处理多个帧的组合
            else
                tinsert(frames, decoded)
                return tconcat(frames), first_opcode
            end
        else
            -- 解码不完整，需要更多数据
            assert(type(fin) == 'number' and fin > 0)
            bytes = fin
        end
    end
    
    -- 永远不会到达这里
    assert(false, 'never reach here')
end

-- 发送WebSocket数据
local function send(self, data, opcode)
    -- 检查连接状态
    if self.state ~= 'OPEN' then
        return nil, false, 1006, 'wrong state'
    end
    
    -- 编码数据
    local encoded = frame.encode(data, opcode or frame.TEXT, not self.is_server)
    
    -- 发送数据
    local n, err = self:sock_send(encoded)
    if n ~= #encoded then
        return nil, self:close(1006, err)
    end
    
    return true
end

-- 关闭WebSocket连接
local function close(self, code, reason)
    -- 检查连接状态
    if self.state ~= 'OPEN' then
        return false, 1006, 'wrong state'
    end
    if self.state == 'CLOSED' then
        return false, 1006, 'wrong state'
    end
    
    -- 发送关闭帧
    local msg = frame.encode_close(code or 1000, reason)
    local encoded = frame.encode(msg, frame.CLOSE, not self.is_server)
    local n, err = self:sock_send(encoded)
    
    local was_clean = false
    local close_code = 1005
    local close_reason = ''
    
    if n == #encoded then
        self.is_closing = true
        -- 等待对方的关闭确认
        local rmsg, opcode = self:receive()
        if rmsg and opcode == frame.CLOSE then
            close_code, close_reason = frame.decode_close(rmsg)
            was_clean = true
        end
    else
        close_reason = err
    end
    
    -- 关闭底层套接字
    self:sock_close()
    
    -- 调用关闭回调
    if self.on_close then
        self:on_close()
    end
    
    self.state = 'CLOSED'
    return was_clean, close_code, close_reason or ''
end

-- 连接到WebSocket服务器
local function connect(self, ws_url, ws_protocol, ssl_params)
    -- 检查连接状态
    if self.state ~= 'CLOSED' then
        return nil, 'wrong state', nil
    end
    
    -- 解析URL
    local protocol, host, port, uri = tools.parse_url(ws_url)
    
    -- 建立TCP连接
    local _, err = self:sock_connect(host, port)
    if err then
        return nil, err, nil
    end
    
    -- 处理SSL（注意：这里不实现真正的SSL，需要外部提供SSL支持）
    if protocol == 'wss' then
        if ssl_params and self.sock and self.sock.wrap then
            self.sock = self.sock:wrap(ssl_params)
            if self.sock.dohandshake then
                self.sock:dohandshake()
            else
                return nil, 'SSL not supported', nil
            end
        else
            return nil, 'SSL not supported', nil
        end
    elseif protocol ~= "ws" then
        return nil, 'bad protocol', nil
    end
    
    -- 处理协议参数
    local ws_protocols_tbl = {''}
    if type(ws_protocol) == 'string' then
        ws_protocols_tbl = {ws_protocol}
    elseif type(ws_protocol) == 'table' then
        ws_protocols_tbl = ws_protocol
    end
    
    -- 生成密钥并创建握手请求
    local key = tools.generate_key()
    local req = handshake.upgrade_request {
        key = key,
        host = host,
        port = port,
        protocols = ws_protocols_tbl,
        uri = uri
    }
    
    -- 发送握手请求
    local n, err = self:sock_send(req)
    if n ~= #req then
        return nil, err, nil
    end
    
    -- 接收握手响应
    local resp = {}
    repeat
        local line, err = self:sock_receive('*l')
        resp[#resp + 1] = line
        if err then
            return nil, err, nil
        end
    until line == ''
    
    -- 解析响应
    local response = table.concat(resp, '\r\n')
    local headers = handshake.http_headers(response)
    
    -- 验证握手
    local expected_accept = handshake.sec_websocket_accept(key)
    if headers['sec-websocket-accept'] ~= expected_accept then
        local msg = 'Websocket Handshake failed: Invalid Sec-Websocket-Accept (expected %s got %s)'
        return nil, msg:format(expected_accept, headers['sec-websocket-accept'] or 'nil'), headers
    end
    
    -- 设置连接状态为打开
    self.state = 'OPEN'
    
    return true, headers['sec-websocket-protocol'], headers
end

-- 扩展对象以添加WebSocket功能
local function extend(obj)
    -- 验证必要的方法
    assert(obj.sock_send, "obj must have sock_send method")
    assert(obj.sock_receive, "obj must have sock_receive method")
    assert(obj.sock_close, "obj must have sock_close method")
    
    -- 确保没有覆盖现有方法
    assert(obj.is_closing == nil)
    assert(obj.receive == nil)
    assert(obj.send == nil)
    assert(obj.close == nil)
    assert(obj.connect == nil)
    
    -- 客户端需要连接方法
    if not obj.is_server then
        assert(obj.sock_connect, "client obj must have sock_connect method")
    end
    
    -- 初始化状态
    if not obj.state then
        obj.state = 'CLOSED'
    end
    
    -- 添加WebSocket方法
    obj.receive = receive
    obj.send = send
    obj.close = close
    obj.connect = connect
    
    return obj
end

return {
    extend = extend
}