-- 原生Lua WebSocket客户端同步实现
-- 不依赖任何外部库

-- 导入必要的模块
local socket = require('socket')
local sync = require('native_websocket.sync')

-- WebSocket客户端类
local client = {}
client.__index = client

-- 构造函数
function client:new()
    local o = {} 
    setmetatable(o, self)
    
    -- 初始化成员变量
    o.sock = nil
    o.is_server = false
    
    -- 设置回调函数
    o.on_close = nil
    
    -- 设置状态
    o.state = 'CLOSED'
    o.is_closing = false
    
    return o
end

-- 连接到WebSocket服务器
function client:connect(ws_url, ws_protocol, ssl_params)
    -- 确保套接字已创建
    if not self.sock then
        self.sock = socket.tcp()
        if not self.sock then
            return nil, 'Failed to create socket', nil
        end
        
        -- 设置非阻塞模式
        self.sock:settimeout(0)
    end
    
    -- 使用sync模块进行连接
    return sync.extend(self):connect(ws_url, ws_protocol, ssl_params)
end

-- 发送数据
function client:send(data, opcode)
    return sync.extend(self):send(data, opcode)
end

-- 接收数据
function client:receive()
    return sync.extend(self):receive()
end

-- 关闭连接
function client:close(code, reason)
    return sync.extend(self):close(code, reason)
end

-- 底层套接字连接方法
function client:sock_connect(host, port)
    if not self.sock then
        self.sock = socket.tcp()
        if not self.sock then
            return nil, 'Failed to create socket'
        end
        self.sock:settimeout(0)
    end
    
    -- 连接到主机
    local _, err = self.sock:connect(host, port)
    
    -- 处理非阻塞连接的情况
    if err == 'timeout' or err == 'Operation already in progress' then
        -- 尝试设置阻塞模式来等待连接完成
        self.sock:settimeout(10) -- 设置10秒超时
        local _, err_connect = self.sock:connect(host, port)
        
        -- 恢复非阻塞模式
        self.sock:settimeout(0)
        
        if err_connect and err_connect ~= 'already connected' then
            return nil, err_connect
        end
        return 1
    end
    
    if err then
        return nil, err
    end
    
    return 1
end

-- 底层套接字发送方法
function client:sock_send(data)
    if not self.sock then
        return nil, 'Socket not initialized'
    end
    
    -- 设置阻塞模式发送
    self.sock:settimeout(10) -- 设置10秒超时
    local n, err = self.sock:send(data)
    
    -- 恢复非阻塞模式
    self.sock:settimeout(0)
    
    return n, err
end

-- 底层套接字接收方法
function client:sock_receive(pattern)
    if not self.sock then
        return nil, 'Socket not initialized'
    end
    
    -- 设置阻塞模式接收
    self.sock:settimeout(10) -- 设置10秒超时
    local data, err = self.sock:receive(pattern)
    
    -- 恢复非阻塞模式
    self.sock:settimeout(0)
    
    return data, err
end

-- 底层套接字关闭方法
function client:sock_close()
    if self.sock then
        self.sock:close()
        self.sock = nil
    end
end

-- 设置超时时间
function client:settimeout(timeout)
    if self.sock then
        self.sock:settimeout(timeout)
    end
end

-- 模块的元表，支持直接调用构造函数
setmetatable(client, {
    __call = function(self, ...)
        return self:new(...)
    end
})

return client