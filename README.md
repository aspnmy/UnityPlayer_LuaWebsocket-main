# UnityPlayer_LuaWebsocket 原生Lua WebSocket组件
这是一个不依赖任何外部库的Lua 5.4原生WebSocket组件，,专门为UnityPlayer游戏提供Lua-Websocket原生支持，作为多人游戏基础业务支撑



## 功能特点

- 完全基于Lua 5.4原生实现，不依赖任何外部库或组件
- 支持完整的WebSocket协议，包括握手、帧处理、消息发送和接收
- 提供与原UnityPlayer_LuaWebsocket-main库相同的API接口，便于集成到现有项目
- 包含完整的SHA1哈希和Base64编码实现，用于WebSocket握手过程
- 支持文本和二进制数据传输，以及关闭帧处理
- 实现非阻塞套接字操作，提高应用程序的响应性能

## 文件结构

- `Src/websocket.lua` - 模块入口文件，定义WebSocket帧类型常量并实现动态加载机制
- `Src/tools.lua` - 实现位操作、字节读写、SHA1哈希、Base64编码、URL解析和随机密钥生成等基础工具函数
- `Src/frame.lua` - 实现WebSocket帧处理功能，包括帧编码/解码、掩码处理、长度编码和关闭帧处理
- `Src/handshake.lua` - 实现WebSocket握手协议，包含Sec-WebSocket-Accept计算、HTTP头解析、升级请求构建和升级响应处理
- `Src/sync.lua` - 实现WebSocket的同步操作功能，包括连接、发送、接收和关闭等操作
- `Src/client_sync.lua` - 实现WebSocket客户端的具体功能，包括建立TCP连接和封装底层套接字操作

## 使用方法

### 1. 导入模块

```lua
local websocket = require('UnityPlayer_LuaWebsocket.websocket')
```

### 2. 创建客户端实例

```lua
local client = websocket.client()
```

### 3. 连接到WebSocket服务器

```lua
local ok, err_or_protocol, headers = client:connect('ws://echo.websocket.org', nil, nil)
if not ok then
    print('连接失败:', err_or_protocol)
    return
end
print('连接成功!')
```

### 4. 发送数据

```lua
-- 发送文本数据
local success, was_clean, code, reason = client:send('Hello WebSocket!')
if not success then
    print('发送失败:', reason)
end

-- 发送二进制数据
local binary_data = '\x01\x02\x03\x04'
local success, was_clean, code, reason = client:send(binary_data, websocket.BINARY)
if not success then
    print('发送失败:', reason)
end
```

### 5. 接收数据

```lua
-- 接收数据
local data, opcode = client:receive()
if data then
    if opcode == websocket.TEXT then
        print('收到文本数据:', data)
    elseif opcode == websocket.BINARY then
        print('收到二进制数据，长度:', #data)
    end
else
    print('接收数据失败')
end
```

### 6. 关闭连接

```lua
local was_clean, code, reason = client:close(1000, '正常关闭')
if was_clean then
    print('连接已干净关闭，代码:', code, '原因:', reason)
else
    print('连接关闭异常，代码:', code, '原因:', reason)
end
```

## 注意事项

1. 本组件完全基于Lua原生实现，无需任何外部依赖
2. 支持的WebSocket协议版本与原UnityPlayer_LuaWebsocket-main库兼容
3. 如需使用SSL/TLS加密连接(wss://)，需要确保运行环境支持SSL
4. 在使用过程中，建议设置合理的超时时间，避免阻塞应用程序
5. 发送和接收大量数据时，请注意内存使用情况

## 示例代码

```lua
local websocket = require('UnityPlayer_LuaWebsocket.websocket')

-- 创建客户端
local client = websocket.client()

-- 设置超时
client:settimeout(10)

-- 连接服务器
local ok, err = client:connect('ws://echo.websocket.org')
if not ok then
    print('连接失败:', err)
    return
end

print('连接成功，发送测试消息...')

-- 发送消息
client:send('Hello from Native Lua WebSocket!')

-- 接收响应
local data, opcode = client:receive()
if data then
    print('收到响应:', data)
else
    print('未收到响应')
end

-- 关闭连接
client:close()
print('连接已关闭')
```

## 兼容性

该组件已在Lua 5.4环境下测试通过，可以在任何支持Lua 5.4的环境中使用。对于其他版本的Lua，可能需要进行适当的调整。