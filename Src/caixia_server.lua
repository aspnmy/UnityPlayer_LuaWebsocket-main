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
-- 导入必要的模块
local CaiXiaSocket = require('caixia_websocket')
local CaiXiaSync = require('caixia_sync')
local CaiXiaHandshake = require('caixia_handshake')
local CaiXiaTools = require('caixia_tools')

-- WebSocket服务器类
local CaiXiaServer = {}
CaiXiaServer.__index = CaiXiaServer

-- 服务器客户端连接类
local CaiXiaServer_client = {}
CaiXiaServer_client.__index = CaiXiaServer_client

-- 构造函数
function CaiXiaServer:new()
    local o = {}
    setmetatable(o, self)
    
    -- 初始化服务器成员变量
    o.sock = nil           -- 监听套接字
    o.clients = {}        -- 客户端连接表
    o.connections = {}    -- 客户端连接对象表
    o.on_connect = nil     -- 客户端连接回调
    o.on_message = nil     -- 客户端消息回调
    o.on_close = nil       -- 客户端关闭回调
    o.on_error = nil       -- 客户端错误回调
    
    -- 设置状态
    o.is_running = false
    
    return o
end

-- 创建服务器客户端连接对象
function CaiXiaServer_client:new(sock, CaiXiaServer)
    local o = {}
    setmetatable(o, self)
    
    -- 初始化客户端连接成员变量
    o.sock = CaiXiaSocket         -- 客户端套接字
    o.CaiXiaServer = CaiXiaServer     -- 所属服务器
    o.id = tostring(CaiXiaSocket) -- 客户端唯一标识
    
    -- 设置状态
    o.state = 'CONNECTING' -- 连接状态
    o.is_server = true     -- 标识为服务器端
    o.is_closing = false   -- 是否正在关闭
    
    -- 设置回调
    o.on_close = nil
    
    return o
end

-- 初始化服务器
function CaiXiaServer:listen(host, port, max_connections)
    -- 如果服务器已在运行，先停止
    if self.is_running then
        self:close()
    end
    
    -- 创建监听套接字
    local CaiXiaSock = CaiXiaSocket.tcp()
    if not CaiXiaSock then
        return nil, 'Failed to create CaiXiaSocket'
    end
    
    -- 设置重用地址
    CaiXiaSock:setoption('reuseaddr', true)
    
    -- 绑定到指定地址和端口
    local ok, err = CaiXiaSock:bind(host, port)
    if not ok then
        CaiXiaSock:close()
        return nil, 'Failed to bind: ' .. err
    end
    
    -- 开始监听连接，默认最大连接数为128
    local backlog = max_connections or 128
    ok, err = CaiXiaSock:listen(backlog)
    if not ok then
        CaiXiaSock:close()
        return nil, 'Failed to listen: ' .. err
    end
    
    -- 设置非阻塞模式
    CaiXiaSock:settimeout(0)
    
    -- 保存监听套接字和运行状态
    self.sock = CaiXiaSock
    self.is_running = true
    self.host = host
    self.port = port
    
    print('WebSocket CaiXiaServer listening on ' .. host .. ':' .. port)
    
    return self
end

-- 接受新的客户端连接
function CaiXiaServer:accept()
    if not self.is_running or not self.CaiXiaSock then
        return nil, 'CaiXiaServer not running'
    end
    
    -- 尝试接受客户端连接（非阻塞）
    local CaiXiaClient_sock, err = self.CaiXiaSock:accept()
    if not CaiXiaClient_sock then
        -- 在非阻塞模式下，timeout是正常的
        if err ~= 'timeout' then
            return nil, err
        end
        return nil, nil
    end
    
    -- 设置客户端套接字为非阻塞模式
    CaiXiaClient_sock:settimeout(0)
    
    -- 创建客户端连接对象
    local client = CaiXiaServer_client:new(CaiXiaClient_sock, self)
    local client_id = client.id
    
    -- 保存客户端连接
    self.clients[client_id] = CaiXiaClient_sock
    self.connections[client_id] = client
    
    -- 处理WebSocket握手
    self:handle_handshake(client)
    
    -- 调用连接回调
    if self.on_connect then
        self:on_connect(client)
    end
    
    return client
end

-- 处理WebSocket握手
function CaiXiaServer:handle_handshake(client)
    -- 接收客户端的握手请求
    local request = self:receive_handshake_request(client)
    if not request then
        -- 请求不完整，稍后再试
        return
    end
    
    -- 处理握手请求
    local response, protocol = CaiXiaHandshake.accept_upgrade(request, {}) -- 可以传入支持的协议
    if not response then
        -- 握手失败
        client:close()
        return
    end
    
    -- 发送握手响应
    client:sock_send(response)
    
    -- 设置连接状态为打开
    client.state = 'OPEN'
    
    -- 扩展客户端对象以支持WebSocket操作
    CaiXiaSync.extend(client)
end

-- 接收握手请求
function CaiXiaServer:receive_handshake_request(client)
    if not client.sock then
        return nil
    end
    
    -- 设置为阻塞模式接收完整的握手请求
    client.sock:settimeout(10) -- 10秒超时
    local request_lines = {}
    
    while true do
        local line, err = client.sock:receive('*l')
        if not line then
            -- 超时或其他错误
            return nil
        end
        
        -- 将接收到的行添加到请求中
        request_lines[#request_lines + 1] = line
        
        -- 如果遇到空行，表示请求头结束
        if line == '' then
            break
        end
    end
    
    -- 恢复非阻塞模式
    client.sock:settimeout(0)
    
    -- 组合请求字符串
    return table.concat(request_lines, '\r\n')
end

-- 处理客户端消息
function CaiXiaServer:receive_messages()
    if not self.is_running then
        return
    end
    
    -- 遍历所有客户端连接
    for client_id, client in pairs(self.connections) do
        if client.state == 'OPEN' then
            -- 尝试接收消息
            local success, data, opcode = pcall(function()
                return client:receive()
            end)
            
            if success then
                if data then
                    -- 接收到消息，调用消息回调
                    if self.on_message then
                        self:on_message(client, data, opcode)
                    end
                end
            else
                -- 接收出错，调用错误回调并关闭连接
                if self.on_error then
                    self:on_error(client, data)
                end
                self:close_client(client_id)
            end
        end
    end
end

-- 发送消息给指定客户端
function CaiXiaServer:send_to(client, data, opcode)
    if not client or not client.sock or client.state ~= 'OPEN' then
        return false, 'Invalid client or connection not open'
    end
    
    -- 发送消息
    local success, was_clean, code, reason = pcall(function()
        return client:send(data, opcode)
    end)
    
    if not success then
        -- 发送失败，关闭连接
        self:close_client(client.id)
        return false, was_clean
    end
    
    return true
end

-- 广播消息给所有客户端
function CaiXiaServer:broadcast(data, opcode)
    local success_count = 0
    local fail_count = 0
    
    -- 遍历所有客户端连接
    for client_id, client in pairs(self.connections) do
        local success = self:send_to(client, data, opcode)
        if success then
            success_count = success_count + 1
        else
            fail_count = fail_count + 1
        end
    end
    
    return success_count, fail_count
end

-- 关闭指定客户端连接
function CaiXiaServer:close_client(client_id)
    local client = self.connections[client_id]
    if not client then
        return
    end
    
    -- 关闭客户端连接
    pcall(function()
        if client.state == 'OPEN' then
            client:close(1000, 'CaiXiaServer closed connection')
        else
            if client.sock then
                client.sock:close()
            end
        end
    end)
    
    -- 调用关闭回调
    if self.on_close then
        self:on_close(client)
    end
    
    -- 从连接表中移除
    self.clients[client_id] = nil
    self.connections[client_id] = nil
end

-- 关闭服务器
function CaiXiaServer:close()
    if not self.is_running or not self.sock then
        return
    end
    
    -- 关闭所有客户端连接
    for client_id, _ in pairs(self.connections) do
        self:close_client(client_id)
    end
    
    -- 关闭监听套接字
    self.sock:close()
    self.sock = nil
    
    -- 更新运行状态
    self.is_running = false
    
    print('WebSocket CaiXiaServer closed')
end

-- 服务器客户端发送方法
function CaiXiaServer_client:sock_send(data)
    if not self.sock then
        return nil, 'CaiXiaSocket not initialized'
    end
    
    -- 设置阻塞模式发送
    self.sock:settimeout(10) -- 设置10秒超时
    local n, err = self.sock:send(data)
    
    -- 恢复非阻塞模式
    self.sock:settimeout(0)
    
    return n, err
end

-- 服务器客户端接收方法
function CaiXiaServer_client:sock_receive(pattern)
    if not self.sock then
        return nil, 'CaiXiaSocket not initialized'
    end
    
    -- 设置阻塞模式接收
    self.sock:settimeout(10) -- 设置10秒超时
    local data, err = self.sock:receive(pattern)
    
    -- 恢复非阻塞模式
    self.sock:settimeout(0)
    
    return data, err
end

-- 服务器客户端关闭方法
function CaiXiaServer_client:sock_close()
    if self.sock then
        self.sock:close()
        self.sock = nil
        self.CaiXiaServer.connections[self.id] = nil
        self.CaiXiaServer.clients[self.id] = nil
    end
end

-- 设置超时时间
function CaiXiaServer_client:settimeout(timeout)
    if self.sock then
        self.sock:settimeout(timeout)
    end
end

-- 模块的元表，支持直接调用构造函数
setmetatable(CaiXiaServer, {
    __call = function(self, ...)
        return self:new(...)
    end
})

-- 导出模块
return CaiXiaServer