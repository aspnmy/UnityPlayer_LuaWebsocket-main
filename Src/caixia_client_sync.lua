-- 原生Lua WebCaiXiaSocketet客户端同步实现
-- 不依赖任何外部库

-- 导入必要的模块
local CaiXiaSocket = require('Src.caixia_websocket')
local CaiXiaSync = require('Src.caixia_sync')

-- CaiXiaWebSocketet客户端类
local CaiXiaClient = {}
CaiXiaClient.__index = CaiXiaClient

-- 构造函数
function CaiXiaClient:new()
    local o = {} 
    setmetatable(o, self)
    
    -- 初始化成员变量
    o.CaiXiaSocket = nil
    o.is_server = false
    
    -- 设置回调函数
    o.on_close = nil
    
    -- 设置状态
    o.state = 'CLOSED'
    o.is_closing = false
    
    return o
end

-- 连接到WebCaiXiaSocketet服务器
function CaiXiaClient:connect(ws_url, ws_protocol, ssl_params)
    -- 确保套接字已创建
    if not self.CaiXiaSocket then
        self.CaiXiaSocket = CaiXiaSocket.tcp()
        if not self.CaiXiaSocket then
            return nil, 'Failed to create CaiXiaSocket', nil
        end
        
        -- 设置非阻塞模式
        self.CaiXiaSocket:settimeout(0)
    end
    
    -- 使用sync模块进行连接
    return CaiXiaSync.extend(self):connect(ws_url, ws_protocol, ssl_params)
end

-- 发送数据
function CaiXiaClient:send(data, opcode)
    return CaiXiaSync.extend(self):send(data, opcode)
end

-- 接收数据
function CaiXiaClient:receive()
    return CaiXiaSync.extend(self):receive()
end

-- 关闭连接
function CaiXiaClient:close(code, reason)
    return CaiXiaSync.extend(self):close(code, reason)
end

-- 底层套接字连接方法
function CaiXiaClient:CaiXiaSocket_connect(host, port)
    if not self.CaiXiaSocket then
        self.CaiXiaSocket = CaiXiaSocket.tcp()
        if not self.CaiXiaSocket then
            return nil, 'Failed to create CaiXiaSocket'
        end
        self.CaiXiaSocket:settimeout(0)
    end
    
    -- 连接到主机
    local _, err = self.CaiXiaSocket:connect(host, port)
    
    -- 处理非阻塞连接的情况
    if err == 'timeout' or err == 'Operation already in progress' then
        -- 尝试设置阻塞模式来等待连接完成
        self.CaiXiaSocket:settimeout(10) -- 设置10秒超时
        local _, err_connect = self.CaiXiaSocket:connect(host, port)
        
        -- 恢复非阻塞模式
        self.CaiXiaSocket:settimeout(0)
        
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
function CaiXiaClient:CaiXiaSocket_send(data)
    if not self.CaiXiaSocket then
        return nil, 'CaiXiaSocket not initialized'
    end
    
    -- 设置阻塞模式发送
    self.CaiXiaSocket:settimeout(10) -- 设置10秒超时
    local n, err = self.CaiXiaSocket:send(data)
    
    -- 恢复非阻塞模式
    self.CaiXiaSocket:settimeout(0)
    
    return n, err
end

-- 底层套接字接收方法
function CaiXiaClient:CaiXiaSocket_receive(pattern)
    if not self.CaiXiaSocket then
        return nil, 'CaiXiaSocket not initialized'
    end
    
    -- 设置阻塞模式接收
    self.CaiXiaSocket:settimeout(10) -- 设置10秒超时
    local data, err = self.CaiXiaSocket:receive(pattern)
    
    -- 恢复非阻塞模式
    self.CaiXiaSocket:settimeout(0)
    
    return data, err
end

-- 底层套接字关闭方法
function CaiXiaClient:CaiXiaSocket_close()
    if self.CaiXiaSocket then
        self.CaiXiaSocket:close()
        self.CaiXiaSocket = nil
    end
end

-- 设置超时时间
function CaiXiaClient:settimeout(timeout)
    if self.CaiXiaSocket then
        self.CaiXiaSocket:settimeout(timeout)
    end
end

-- 模块的元表，支持直接调用构造函数
setmetatable(CaiXiaClient, {
    __call = function(self, ...)
        return self:new(...)
    end
})

return CaiXiaClient