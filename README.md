# UnityPlayer_LuaWebsocket-main 原生Lua WebSocket组件
这是一个不依赖任何外部库的Lua 5.4原生WebSocket组件，专门为《了不起的修仙模拟器》（Amazing Cultivation Simulator）游戏Mod开发提供Lua-Websocket原生支持，作为多人游戏基础业务支撑。同时支持WebSocket客户端和服务器功能。

## 如何让Mod支持联网

- 查看本项目 test-Mod 文件夹，里面有一个简单的Mod示例，展示了如何使用本组件实现联网功能。



## 功能特点

- 完全基于Lua 5.4原生实现，不依赖任何外部库或组件
- 支持完整的WebSocket协议，包括握手、帧处理、消息发送和接收
- 提供与原UnityPlayer_LuaWebsocket-main库相同的API接口，便于集成到现有项目
- 包含完整的SHA1哈希和Base64编码实现，用于WebSocket握手过程
- 支持文本和二进制数据传输，以及关闭帧处理
- 实现非阻塞套接字操作，提高应用程序的响应性能
- **新增服务器功能**：支持创建本地WebSocket服务器，实现客户端连接管理、消息收发和广播
- 服务器支持事件回调机制，可自定义连接、消息、关闭和错误处理逻辑

## 文件结构

- `Src/caixia_websocket-init.lua` - 模块入口文件，统一化模块初始化和导出
- `Src/caixia_websocket.lua` - 实现WebSocket帧类型常量并实现动态加载机制，同时支持客户端和服务器模块，包含本地Socket实现
- `Src/caixia_tools.lua` - 实现位操作、字节读写、SHA1哈希、Base64编码、URL解析和随机密钥生成等基础工具函数
- `Src/caixia_frame.lua` - 实现WebSocket帧处理功能，包括帧编码/解码、掩码处理、长度编码和关闭帧处理
- `Src/caixia_handshake.lua` - 实现WebSocket握手协议，包含Sec-WebSocket-Accept计算、HTTP头解析、升级请求构建和升级响应处理
- `Src/caixia_sync.lua` - 实现WebSocket的同步操作功能，包括连接、发送、接收和关闭等操作
- `Src/caixia_client_sync.lua` - 实现WebSocket客户端的具体功能，包括建立TCP连接和封装底层套接字操作
- `Src/caixia_server.lua` - 实现WebSocket服务器功能，包括监听连接、处理客户端握手、管理连接对象、收发消息和广播消息
- `Src/caixia_json.lua` - 实现JSON编码和解码功能，用于消息序列化和反序列化



## 全部工具函数
=== 开始测试caixia_websocket-init模块 ===
✓ 模块加载成功
模块版本: 1.0.0

=== 测试核心WebSocket函数 ===
✓ 函数 createClient 存在
✓ 函数 createServer 存在
✓ 函数 startServer 存在
✓ 函数 init 存在

=== 测试帧处理函数 ===
✓ 函数 encodeFrame 存在
✓ 函数 decodeFrame 存在
✓ 函数 encodeClose 存在
✓ 函数 decodeClose 存在

=== 测试握手相关函数 ===
✓ 函数 acceptUpgrade 存在
✓ 函数 upgradeRequest 存在
✓ 函数 secWebSocketAccept 存在
✓ 函数 httpHeaders 存在

=== 测试工具函数 ===
✓ 工具函数 band 存在
✓ 工具函数 bor 存在
✓ 工具函数 bxor 存在
✓ 工具函数 rshift 存在
✓ 工具函数 lshift 存在
✓ 工具函数 read_int8 存在
✓ 工具函数 read_int16 存在
✓ 工具函数 read_int32 存在
✓ 工具函数 write_int8 存在
✓ 工具函数 write_int16 存在
✓ 工具函数 write_int32 存在
✓ 工具函数 utf8_encode 存在
✓ 工具函数 utf8_decode 存在
✓ 工具函数 sha1 存在
✓ 工具函数 base64_encode 存在
✓ 工具函数 base64_decode 存在
✓ 工具函数 parse_url 存在
✓ 工具函数 json_encode 存在
✓ 工具函数 json_decode 存在

=== 测试帧类型常量 ===
✓ 帧类型常量 CONTINUATION = 0
✓ 帧类型常量 TEXT = 1
✓ 帧类型常量 CLOSE = 8
✓ 帧类型常量 BINARY = 2
✓ 帧类型常量 PING = 9
✓ 帧类型常量 PONG = 10




## 使用方法

### WebSocket客户端使用方法

#### 1. 导入模块

```lua
-- WebSocket初始化模块测试文件
-- 重构版本：完整导出caixia_websocket-init.lua中的所有可使用函数和方法
-- 在WindoCaiXiaWS环境下设置控制台编码为UTF-8
if package.config:sub(1,1) == '\\' then -- WindoCaiXiaWS系统
    os.execute('chcp 65001 >nul') -- 设置代码页为UTF-8，>nul表示不显示输出
end

-- 设置package.path以便正确加载模块
local function getCurrentScriptDir()
    local info = debug.getinfo(1, 'S')
    local scriptPath = info.source:sub(2) -- 去掉前面的@符号
    local scriptDir = scriptPath:match('(.*[/\\])')
    return scriptDir or ''
end

-- 获取当前脚本目录
local scriptDir = getCurrentScriptDir()

-- 添加Src目录到package.path，确保能正确加载模块
package.path = scriptDir .. 'Src/?.lua;' .. package.path
-- 加载WebSocket初始化模块
local status, CaiXiaWS = pcall(function() 
    return require('caixia_websocket-init')
end);
```

#### 2. 创建客户端实例

```lua
local client = CaiXiaWS.client()
```

#### 3. 连接到WebSocket服务器

```lua
local ok, err_or_protocol, headers = client:connect('ws://echo.websocket.org', nil, nil)
if not ok then
    print('连接失败:', err_or_protocol)
    return
end
print('连接成功!')
```

#### 4. 发送数据

```lua
-- 发送文本数据
local success, was_clean, code, reason = client:send('Hello WebSocket!')
if not success then
    print('发送失败:', reason)
end

-- 发送二进制数据
local binary_data = '\x01\x02\x03\x04'
local success, was_clean, code, reason = client:send(binary_data, CaiXiaWS.BINARY)
if not success then
    print('发送失败:', reason)
end
```

#### 5. 接收数据

```lua
-- 接收数据
local data, opcode = client:receive()
if data then
    if opcode == CaiXiaWS.TEXT then
        print('收到文本数据:', data)
    elseif opcode == CaiXiaWS.BINARY then
        print('收到二进制数据，长度:', #data)
    end
else
    print('接收数据失败')
end
```

#### 6. 关闭连接

```lua
local was_clean, code, reason = client:close(1000, '正常关闭')
if was_clean then
    print('连接已干净关闭，代码:', code, '原因:', reason)
else
    print('连接关闭异常，代码:', code, '原因:', reason)
end
```

### WebSocket服务器使用方法

#### 1. 导入模块

```lua
-- WebSocket初始化模块测试文件
-- 重构版本：完整导出caixia_websocket-init.lua中的所有可使用函数和方法
-- 在WindoCaiXiaWS环境下设置控制台编码为UTF-8
if package.config:sub(1,1) == '\\' then -- WindoCaiXiaWS系统
    os.execute('chcp 65001 >nul') -- 设置代码页为UTF-8，>nul表示不显示输出
end

-- 设置package.path以便正确加载模块
local function getCurrentScriptDir()
    local info = debug.getinfo(1, 'S')
    local scriptPath = info.source:sub(2) -- 去掉前面的@符号
    local scriptDir = scriptPath:match('(.*[/\\])')
    return scriptDir or ''
end

-- 获取当前脚本目录
local scriptDir = getCurrentScriptDir()

-- 添加Src目录到package.path，确保能正确加载模块
package.path = scriptDir .. 'Src/?.lua;' .. package.path
-- 加载WebSocket初始化模块
local status, CaiXiaWS = pcall(function() 
    return require('caixia_websocket-init')
end);
```

#### 2. 创建服务器实例

```lua
local server = CaiXiaWS.server()
```

#### 3. 设置事件回调

```lua
-- 设置客户端连接回调
server.on_connect = function(client_conn)
    print('客户端已连接:', client_conn.id)
end

-- 设置消息接收回调
server.on_message = function(client_conn, message, opcode)
    print('收到来自客户端', client_conn.id, '的消息:', message)
    
    -- 回显消息给客户端
    server:send(client_conn.id, message, opcode)
end

-- 设置客户端断开连接回调
server.on_close = function(client_conn, was_clean, code, reason)
    print('客户端断开连接:', client_conn.id, '干净关闭:', was_clean, '代码:', code, '原因:', reason)
end

-- 设置错误处理回调
server.on_error = function(client_conn, err)
    print('发生错误:', err)
end
```

#### 4. 启动服务器

```lua
local ok, err = server:listen('127.0.0.1', 8080)
if not ok then
    print('服务器启动失败:', err)
    return
end
print('服务器已启动，监听端口:', 8080)
```

#### 5. 处理客户端连接和消息

```lua
-- 服务器主循环（根据实际应用场景调整）
while true do
    -- 接受新连接并处理消息
    server:update()
    
    -- 这里可以添加其他服务器逻辑
    
    -- 让出一些CPU时间
    socket.sleep(0.01)
end
```

#### 6. 发送消息给特定客户端

```lua
-- 发送文本消息给特定客户端
server:send(client_id, 'Hello from server!', CaiXiaWS.TEXT)

-- 发送二进制消息给特定客户端
local binary_data = '\x01\x02\x03\x04'
server:send(client_id, binary_data, CaiXiaWS.BINARY)
```

#### 7. 广播消息给所有客户端

```lua
-- 广播文本消息给所有客户端
server:broadcast('Server broadcast message!', CaiXiaWS.TEXT)

-- 广播二进制消息给所有客户端
local binary_data = '\x01\x02\x03\x04'
server:broadcast(binary_data, CaiXiaWS.BINARY)
```

#### 8. 关闭服务器

```lua
-- 关闭服务器，断开所有客户端连接
server:close()
print('服务器已关闭')
```

## 注意事项

1. 本组件完全基于Lua原生实现，无需任何外部依赖，适合《了不起的修仙模拟器》Mod开发
2. 当前版本为模拟实现，在实际游戏环境中需要将Socket相关功能替换为游戏提供的网络API
3. 支持完整的WebSocket协议，包括握手、帧处理、消息发送和接收
4. 提供与原UnityPlayer_LuaWebsocket-main库兼容的API接口
5. 包含完整的SHA1哈希和Base64编码实现，用于WebSocket握手过程
6. 如需使用SSL/TLS加密连接(wss://)，需要确保运行环境支持SSL
7. 测试脚本(`test-caixia-server.lua`和`test-local-socket.lua`)可用于验证组件功能在当前环境下的可用性

## 测试脚本使用

### 测试本地Socket实现

```bash
lua test-local-socket.lua
```

### 测试WebSocket服务器功能

```bash
lua test-caixia-server.lua
```



## 兼容性

该组件已在Lua 5.4环境下测试通过，可以在任何支持Lua 5.4的环境中使用。对于其他版本的Lua，可能需要进行适当的调整。