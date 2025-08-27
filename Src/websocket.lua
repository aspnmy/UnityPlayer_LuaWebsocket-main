-- 原生Lua WebSocket模块入口
-- 不依赖任何外部库

-- 定义WebSocket帧类型常量
local FRAME = {
    CONTINUATION = 0,
    TEXT = 1,
    BINARY = 2,
    CLOSE = 8,
    PING = 9,
    PONG = 10
}

-- 设置模块元表，实现动态加载
local _M = setmetatable({}, {
    __index = function(self, key)
        -- 如果请求的是客户端
        if key == 'client' then
            local client = require('native_websocket.client_sync')
            self.client = client
            return client
        end
        
        -- 如果请求的是帧处理模块
        if key == 'frame' then
            local frame = require('native_websocket.frame')
            self.frame = frame
            return frame
        end
        
        -- 如果请求的是握手模块
        if key == 'handshake' then
            local handshake = require('native_websocket.handshake')
            self.handshake = handshake
            return handshake
        end
        
        -- 如果请求的是同步操作模块
        if key == 'sync' then
            local sync = require('native_websocket.sync')
            self.sync = sync
            return sync
        end
        
        -- 如果请求的是工具模块
        if key == 'tools' then
            local tools = require('native_websocket.tools')
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
    return require('native_websocket.client_sync')
end

-- 返回模块
return _M