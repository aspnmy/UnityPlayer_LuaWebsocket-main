-- WebSocket初始化模块
-- 统一化注册所有功能，方便外部进行统一调用
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
-- 导入所有必要的模块
CaiXiaLuaServer = {}

CaiXiaLuaServer.websocket = require('caixia_websocket')
CaiXiaLuaServer.client_sync = require('caixia_client_sync')
CaiXiaLuaServer.server = require('caixia_server')
CaiXiaLuaServer.frame = require('caixia_frame')
CaiXiaLuaServer.handshake = require('caixia_handshake')
CaiXiaLuaServer.sync = require('caixia_sync')
CaiXiaLuaServer.tools = require('caixia_tools')

-- 导入Json模块
CaiXiaLuaServer.CaiXiaJson = require('caixia_json')



-- 创建WebSocket模块表
local WS = {}
CaiXiaLuaServer.WS = WS -- 将WS赋值给CaiXiaLuaServer的WS字段，使其可被访问

-- 版本信息
WS.VERSION = "1.0.0"

-- 导出帧类型常量
WS.FRAME = {
    CONTINUATION = CaiXiaLuaServer.frame.CONTINUATION or 0,
    TEXT = CaiXiaLuaServer.frame.TEXT or 1,
    BINARY = CaiXiaLuaServer.frame.BINARY or 2,
    CLOSE = CaiXiaLuaServer.frame.CLOSE or 8,
    PING = CaiXiaLuaServer.frame.PING or 9,
    PONG = CaiXiaLuaServer.frame.PONG or 10
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
function CaiXiaLuaServer.WS.createClient(options)
    options = options or {}
    local client = CaiXiaLuaServer.client_sync:new()
    
    -- 设置可选回调函数
    if options.on_close then
        client.on_close = options.on_close
    end
    
    return client
end

-- 创建WebSocket服务器
---@param options table 可选配置参数
---@return table WebSocket服务器实例
function CaiXiaLuaServer.WS.createServer(options)
    options = options or {}
    local server = CaiXiaLuaServer.server:new()
    
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
function CaiXiaLuaServer.WS.startServer(host, port, options)
    options = options or {}
    local server = CaiXiaLuaServer.WS.createServer(options)
    -- 从options中获取最大连接数，如果没有提供则使用默认值
    local max_connections = options.max_connections
    return server:listen(host, port, max_connections)
end

-- 导入常用工具函数
WS.tools = {
    -- 位操作函数
    band = CaiXiaLuaServer.tools.band,
    bor = CaiXiaLuaServer.tools.bor,
    bxor = CaiXiaLuaServer.tools.bxor,
    rshift = CaiXiaLuaServer.tools.rshift,
    lshift = CaiXiaLuaServer.tools.lshift,
    
    -- 整数读写函数
    read_int8 = CaiXiaLuaServer.tools.read_int8,
    read_int16 = CaiXiaLuaServer.tools.read_int16,
    read_int32 = CaiXiaLuaServer.tools.read_int32,
    write_int8 = CaiXiaLuaServer.tools.write_int8,
    write_int16 = CaiXiaLuaServer.tools.write_int16,
    write_int32 = CaiXiaLuaServer.tools.write_int32,
    
    -- 字符串编码函数
    utf8_encode = CaiXiaLuaServer.tools.utf8_encode,
    utf8_decode = CaiXiaLuaServer.tools.utf8_decode,
    
    -- 哈希和编码函数
    sha1 = CaiXiaLuaServer.tools.sha1,
    base64_encode = CaiXiaLuaServer.tools.base64.encode,
    
    -- URL解析函数
    parse_url = CaiXiaLuaServer.tools.parse_url,
    generate_key = CaiXiaLuaServer.tools.generate_key,

    -- Json编码和解析
    json_encode = CaiXiaLuaServer.CaiXiaJson.Json_encode,
    json_decode = CaiXiaLuaServer.CaiXiaJson.Json_decode,
}

-- 直接导出常用工具函数以便快速访问
WS.band = CaiXiaLuaServer.tools.band
WS.bor = CaiXiaLuaServer.tools.bor
WS.bxor = CaiXiaLuaServer.tools.bxor
WS.rshift = CaiXiaLuaServer.tools.rshift
WS.lshift = CaiXiaLuaServer.tools.lshift
WS.sha1 = CaiXiaLuaServer.tools.sha1
WS.base64_encode = CaiXiaLuaServer.tools.base64.encode
WS.base64_decode = CaiXiaLuaServer.tools.base64.decode
WS.json_encode = CaiXiaLuaServer.CaiXiaJson.Json_encode
WS.json_decode = CaiXiaLuaServer.CaiXiaJson.Json_decode
WS.parse_url = CaiXiaLuaServer.tools.parse_url
WS.generate_key = CaiXiaLuaServer.tools.generate_key

-- 导出帧处理相关函数
WS.encodeFrame = CaiXiaLuaServer.frame.encode
WS.decodeFrame = CaiXiaLuaServer.frame.decode
WS.encodeClose = CaiXiaLuaServer.frame.encode_close
WS.decodeClose = CaiXiaLuaServer.frame.decode_close

-- 导出握手相关函数
WS.acceptUpgrade = CaiXiaLuaServer.handshake.accept_upgrade
WS.upgradeRequest = CaiXiaLuaServer.handshake.upgrade_request
WS.secWebSocketAccept = CaiXiaLuaServer.handshake.sec_websocket_accept
WS.httpHeaders = CaiXiaLuaServer.handshake.http_headers

-- 导出同步操作函数
WS.extend = CaiXiaLuaServer.sync.extend

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