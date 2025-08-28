-- WebSocket初始化模块
-- 统一化注册所有功能，方便外部进行统一调用

-- 导入所有必要的模块
local websocket = require('Src.caixia_websocket')
local client_sync = require('Src.caixia_client_sync')
local server = require('Src.caixia_server')
local frame = require('Src.caixia_frame')
local handshake = require('Src.caixia_handshake')
local sync = require('Src.caixia_sync')
local tools = require('Src.caixia_tools')

-- 创建WebSocket模块表
local WS = {}

-- 版本信息
WS.VERSION = "1.0.0"

-- 导出帧类型常量
WS.FRAME = {
    CONTINUATION = frame.CONTINUATION or 0,
    TEXT = frame.TEXT or 1,
    BINARY = frame.BINARY or 2,
    CLOSE = frame.CLOSE or 8,
    PING = frame.PING or 9,
    PONG = frame.PONG or 10
}

-- 导出所有帧类型常量
WS.CONTINUATION = WS.FRAME.CONTINUATION
WS.TEXT = WS.FRAME.TEXT
WS.BINARY = WS.FRAME.BINARY
WS.CLOSE = WS.FRAME.CLOSE
WS.PING = WS.FRAME.PING
WS.PONG = WS.FRAME.PONG

-- 创建WebSocket客户端
---@param options table 可选配置参数
---@return table WebSocket客户端实例
function WS.createClient(options)
    options = options or {}
    local client = client_sync:new()
    
    -- 设置可选回调函数
    if options.on_close then
        client.on_close = options.on_close
    end
    
    return client
end

-- 创建WebSocket服务器
---@param options table 可选配置参数
---@return table WebSocket服务器实例
function WS.createServer(options)
    options = options or {}
    local server = server:new()
    
    -- 设置可选回调函数
    if options.on_connect then
        server.on_connect = options.on_connect
    end
    if options.on_message then
        server.on_message = options.on_message
    end
    if options.on_close then
        server.on_close = options.on_close
    end
    if options.on_error then
        server.on_error = options.on_error
    end
    
    return server
end

-- 启动WebSocket服务器
---@param host string 主机地址
---@param port number 端口号
---@param options table 可选配置参数
---@return table|nil WebSocket服务器实例或nil（如果启动失败）
---@return string|nil 错误信息或nil（如果成功）
function WS.startServer(host, port, options)
    local server = WS.createServer(options)
    return server:listen(host, port)
end

-- 导入常用工具函数
WS.tools = {
    -- 位操作函数
    band = tools.band,
    bor = tools.bor,
    bxor = tools.bxor,
    rshift = tools.rshift,
    lshift = tools.lshift,
    
    -- 整数读写函数
    read_int8 = tools.read_int8,
    read_int16 = tools.read_int16,
    read_int32 = tools.read_int32,
    write_int8 = tools.write_int8,
    write_int16 = tools.write_int16,
    write_int32 = tools.write_int32,
    
    -- 哈希和编码函数
    sha1 = tools.sha1,
    base64_encode = tools.base64.encode,
    
    -- URL解析函数
    parse_url = tools.parse_url,
    generate_key = tools.generate_key
}

-- 直接导出常用工具函数以便快速访问
WS.band = tools.band
WS.bor = tools.bor
WS.bxor = tools.bxor
WS.rshift = tools.rshift
WS.lshift = tools.lshift
WS.sha1 = tools.sha1

-- 导出帧处理相关函数
WS.encodeFrame = frame.encode
WS.decodeFrame = frame.decode
WS.encodeClose = frame.encode_close
WS.decodeClose = frame.decode_close

-- 导出握手相关函数
WS.acceptUpgrade = handshake.accept_upgrade
WS.upgradeRequest = handshake.upgrade_request
WS.secWebSocketAccept = handshake.sec_websocket_accept
WS.httpHeaders = handshake.http_headers

-- 导出同步操作函数
WS.extend = sync.extend

-- 模块初始化函数
---@return table WS模块
function WS.init()
    -- 可以在这里添加初始化代码
    return WS
end

-- 设置模块元表，支持直接调用
setmetatable(WS, {
    __call = function(self)
        return self.init()
    end
})

return WS