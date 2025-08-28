-- 测试CaiXia WebSocket服务器完整功能
-- 这个脚本测试WebSocket服务器的创建、启动和基本功能

-- 在Windows环境下设置控制台编码为UTF-8
if package.config:sub(1,1) == '\\' then -- Windows系统
    os.execute('chcp 65001 >nul') -- 设置代码页为UTF-8，>nul表示不显示输出
end

-- 设置package.path以确保能找到模块
package.path = package.path .. ';./Src/?.lua'

print("=== 开始测试CaiXia WebSocket服务器 ===")

-- 1. 加载WebSocket初始化模块
print("\n1. 加载WebSocket初始化模块...")
local status, WS = pcall(require, 'Src/caixia_websocket-init')

if not status then
    print("  ✗ 加载模块失败: " .. WS)
    return
else
    print("  ✓ 模块加载成功")
    print("  模块版本: " .. (WS.VERSION or "未知版本"))
end

-- 2. 初始化服务器配置
print("\n2. 初始化服务器配置...")
local server_config = {
    on_connect = function(client)
        print("  [服务器] 客户端连接: " .. (client.id or "未知"))
    end,
    
    on_message = function(client, message, opcode)
        print("  [服务器] 收到消息: " .. message)
        print("  [服务器] 消息类型: " .. (opcode or "未知"))
        -- 回复消息
        client:send("已收到你的消息: " .. message)
    end,
    
    on_close = function(client)
        print("  [服务器] 客户端关闭: " .. (client.id or "未知"))
    end,
    
    on_error = function(client, err)
        print("  [服务器] 客户端错误: " .. (client.id or "未知") .. " - " .. err)
    end
}
print("  ✓ 服务器配置完成")

-- 3. 启动服务器
print("\n3. 启动WebSocket服务器...")
local server = WS.startServer("127.0.0.1", 8080, server_config)

if not server then
    print("  ✗ 服务器启动失败")
    return
else
    print("  ✓ 服务器启动成功")
    print("  服务器信息: " .. type(server))
end

-- 4. 检查服务器状态
print("\n4. 检查服务器状态...")
if server and server.is_running then
    print("  ✓ 服务器正在运行")
    print("  监听地址: " .. (server.host or "未知"))
    print("  监听端口: " .. (server.port or "未知"))
else
    print("  ✗ 服务器未在运行")
end

-- 5. 创建客户端
print("\n5. 创建WebSocket客户端...")
local client = WS.createClient({
    on_close = function()
        print("  [客户端] 连接已关闭")
    end
})

if not client then
    print("  ✗ 客户端创建失败")
else
    print("  ✓ 客户端创建成功")
    print("  客户端信息: " .. type(client))
end

-- 6. 测试工具函数
print("\n6. 测试WebSocket工具函数...")

-- 位操作函数
local a, b = 10, 5
print("  位操作测试: " .. a .. " & " .. b .. " = " .. WS.band(a, b))
print("  位操作测试: " .. a .. " | " .. b .. " = " .. WS.bor(a, b))

-- 编码解码
local text = "Hello CaiXia WebSocket"
local encoded = WS.tools.base64_encode(text)
print("  Base64编码测试: " .. text .. " -> " .. encoded)

-- 帧操作测试
local frame = WS.encodeFrame(text, WS.TEXT, true)
print("  编码帧测试: 长度 = " .. #frame .. " 字节")

-- 7. 关闭服务器
print("\n7. 关闭WebSocket服务器...")
if server then
    server:close()
    print("  ✓ 服务器已关闭")
else
    print("  ✗ 无法关闭服务器")
end

-- 8. 测试完成
print("\n=== CaiXia WebSocket服务器测试完成 ===")
print("\n注意事项：")
print("1. 这是一个模拟实现，在实际游戏中需要使用游戏提供的网络API替换模拟的Socket方法")
print("2. 完整的功能测试需要在实际游戏环境中进行，包括真实的网络连接测试")
print("3. 目前的实现提供了所有必要的接口，但实际的网络通信需要游戏引擎的支持")