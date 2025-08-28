-- 原生Lua WebSocket模块入口

-- 定义WebSocket帧类型常量
local FRAME = {
    CONTINUATION = 0,
    TEXT = 1,
    BINARY = 2,
    CLOSE = 8,
    PING = 9,
    PONG = 10
}

-- 本地Socket实现类
local CaiXiaSocketImpl = {}
CaiXiaSocketImpl.__index = CaiXiaSocketImpl

-- 创建新的Socket实例
function CaiXiaSocketImpl:new()
    local o = {}
    setmetatable(o, self)
    
    -- 模拟Socket属性
    o.is_server = false
    o.is_client = false
    o.is_connected = false
    o.timeout = 0
    o.host = nil
    o.port = nil
    
    -- 缓冲区
    o.buffer = ''
    
    -- 连接选项
    o.options = {}
    
    -- 模拟客户端连接表（用于服务器）
    o.clients = {}
    
    return o
end

-- 创建TCP套接字
function CaiXiaSocketImpl:tcp()
    local sock = CaiXiaSocketImpl:new()
    return sock
end

-- 设置套接字选项
function CaiXiaSocketImpl:setoption(option, value)
    self.options[option] = value
    return true
end

-- 绑定地址和端口
function CaiXiaSocketImpl:bind(host, port)
    self.is_server = true
    self.host = host
    self.port = port
    
    -- 模拟绑定成功
    print('Socket绑定到 ' .. host .. ':' .. port)
    return true
end

-- 开始监听连接
function CaiXiaSocketImpl:listen(backlog)
    if not self.is_server then
        return false, 'Not a server socket'
    end
    
    -- 模拟监听成功
    print('Socket开始监听，最大连接数: ' .. backlog)
    return true
end

-- 设置超时时间
function CaiXiaSocketImpl:settimeout(timeout)
    self.timeout = timeout
    return true
end

-- 接受新连接
function CaiXiaSocketImpl:accept()
    if not self.is_server then
        return false, 'Not a server socket'
    end
    
    -- 模拟接受连接（在实际游戏中应使用游戏提供的网络API）
    -- 这里仅返回一个模拟的客户端socket
    if next(self.clients) then
        -- 返回第一个客户端
        for id, client in pairs(self.clients) do
            self.clients[id] = nil
            return client
        end
    end
    
    -- 非阻塞模式下没有连接时返回超时
    if self.timeout == 0 then
        return nil, 'timeout'
    end
    
    return nil, 'No connections available'
end

-- 发送数据
function CaiXiaSocketImpl:send(data)
    if not self.is_connected then
        return false, 'Not connected'
    end
    
    -- 模拟发送数据
    print('发送数据，长度: ' .. #data)
    return #data
end

-- 接收数据
function CaiXiaSocketImpl:receive(pattern)
    if not self.is_connected then
        return false, 'Not connected'
    end
    
    -- 模拟接收数据
    if pattern == '*l' then
        -- 接收一行
        local pos = string.find(self.buffer, '\n')
        if pos then
            local line = string.sub(self.buffer, 1, pos - 1)
            self.buffer = string.sub(self.buffer, pos + 1)
            return line
        else
            return nil, 'timeout'
        end
    else
        -- 其他模式
        if #self.buffer > 0 then
            local data = self.buffer
            self.buffer = ''
            return data
        else
            return nil, 'timeout'
        end
    end
end

-- 关闭连接
function CaiXiaSocketImpl:close()
    -- 模拟关闭连接
    self.is_connected = false
    self.buffer = ''
    print('Socket已关闭')
    return true
end

-- HTTP请求功能实现
local function http_request(url, method, headers, body)
    -- 检查luasocket是否可用
    if not socket_available then
        return nil, "luasocket库不可用，无法执行HTTP请求"
    end
    
    method = method or "GET"
    headers = headers or {}
    
    -- 设置默认User-Agent
    if not headers["User-Agent"] then
        headers["User-Agent"] = "CaiXiaWebSocket/1.0"
    end
    
    -- 如果是POST请求且有body，设置Content-Length
    if method == "POST" and body then
        headers["Content-Length"] = tostring(#body)
    end
    
    -- 准备请求选项
    local request_options = {
        url = url,
        method = method,
        headers = headers,
    }
    
    -- 设置请求体接收器
    local response_body = {}
    request_options.sink = ltn12.sink.table(response_body)
    
    -- 如果有请求体，设置源
    if method == "POST" and body then
        request_options.source = ltn12.source.string(body)
    end
    
    -- 发送请求
    local result, status_code, response_headers, response_status = http.request(request_options)
    
    -- 处理响应
    if result then
        return {
            status_code = status_code,
            headers = response_headers,
            body = table.concat(response_body),
            status = response_status
        }
    else
        return nil, status_code -- status_code 包含错误信息
    end
end

-- 设置模块元表，实现动态加载
local _M = setmetatable({}, {
    __index = function(self, key)
        -- Socket方法
        if key == 'tcp' then
            return function()
                return CaiXiaSocketImpl:new()
            end
        end
        
        -- 如果请求的是客户端
        if key == 'client' then
            local client = require('Src.caixia_client_sync')
            self.client = client
            return client
        end
        
        -- 如果请求的是服务器
        if key == 'server' then
            local server = require('Src.caixia_server')
            self.server = server
            return server
        end
        
        -- 如果请求的是帧处理模块
        if key == 'frame' then
            local frame = require('Src.caixia_frame')
            self.frame = frame
            return frame
        end
        
        -- 如果请求的是握手模块
        if key == 'handshake' then
            local handshake = require('Src.caixia_handshake')
            self.handshake = handshake
            return handshake
        end
        
        -- 如果请求的是同步操作模块
        if key == 'sync' then
            local sync = require('Src.caixia_sync')
            self.sync = sync
            return sync
        end
        
        -- 如果请求的是工具模块
        if key == 'tools' then
            local tools = require('Src.caixia_tools')
            self.tools = tools
            return tools
        end
        
        -- 尝试返回帧类型常量
        return FRAME[key]
    end
})

-- 导出帧类型常量
_M.FRAME = FRAME
_M.CONTINUATION = FRAME.CONTINUATION
_M.TEXT = FRAME.TEXT
_M.BINARY = FRAME.BINARY
_M.CLOSE = FRAME.CLOSE
_M.PING = FRAME.PING
_M.PONG = FRAME.PONG

-- 创建WebSocket客户端的工厂方法
function _M.client()
    return require('Src.caixia_client_sync')
end

-- 导出HTTP请求方法
function _M.http_get(url, headers)
    return http_request(url, "GET", headers)
end

function _M.http_post(url, body, headers)
    return http_request(url, "POST", headers, body)
end

-- 返回模块
return _M