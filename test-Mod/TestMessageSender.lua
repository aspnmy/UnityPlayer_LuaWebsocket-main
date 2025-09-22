-- 测试消息发送脚本
-- 在Windows环境下设置控制台编码为UTF-8
if package.config:sub(1,1) == '\\' then -- Windows系统
    os.execute('chcp 65001 >nul') -- 设置代码页为UTF-8，>nul表示不显示输出
end

-- 获取当前脚本目录
local function getCurrentScriptDir()
    local info = debug.getinfo(1, 'S')
    local scriptPath = info.source:sub(2) -- 去掉前面的@符号
    local scriptDir = scriptPath:match('(.*[/\\])')
    return scriptDir or ''
end

-- 设置package.path以便正确加载模块
local scriptDir = getCurrentScriptDir()
package.path = package.path .. ';' .. scriptDir .. '../Src/?.lua'

-- 加载CaiXiaWS模块
local status, CaiXiaWS = pcall(require, 'caixia_websocket-init')
if not status then
    print("  ✗ 加载模块失败: " .. CaiXiaWS)
    return
else
    print("  ✓ 模块加载成功")
    print("  模块版本: " .. (CaiXiaWS.VERSION or "未知版本"))
end

-- 创建客户端
local client = CaiXiaWS.createClient({
    on_close = function()
        print("  [客户端] 连接已关闭")
    end,
    on_message = function(data, opcode)
        print("  [客户端] 收到消息:")
        if opcode == CaiXiaWS.TEXT then
            print("  文本数据: " .. data)
        else
            print("  二进制数据，长度: " .. #data)
        end
        
        -- 将收到的消息写入临时日志文件进行测试
        local file, err = io.open('test_message.log', 'a')
        if file then
            file:write(string.format('[%s] 收到消息: %s\n', os.date('%Y-%m-%d %H:%M:%S'), data))
            file:close()
            print("  消息已保存到test_message.log")
        else
            print("  无法保存消息到日志文件: " .. err)
        end
    end
})

if not client then
    print("  ✗ 客户端创建失败")
    return
else
    print("  ✓ 客户端创建成功")
end

-- 连接服务器
print("\n连接到服务器 localhost:9559...")
local ws_url = 'ws://localhost:9559'
local ok, protocol_or_err, headers = client:ws_connect(ws_url)
if not ok then
    print('连接失败:', protocol_or_err)
    return
else
    print('连接成功!')
    if protocol_or_err then
        print('  使用协议:', protocol_or_err)
    end
end

-- 发送测试消息
print("\n发送测试消息...")
local test_message = "这是一条测试消息 - " .. os.date('%Y-%m-%d %H:%M:%S')
local success, err = client:send(test_message)
if not success then
    print('发送失败:', err)
else
    print('发送成功:', test_message)
end

-- 等待接收消息
print("\n等待接收服务器回复...")
for i = 1, 10 do
    local data, opcode = client:receive()
    if data then
        print("  收到回复:")
        if opcode == CaiXiaWS.TEXT then
            print("  文本数据: " .. data)
            
            -- 将收到的回复写入日志文件
            local file, err = io.open('test_message.log', 'a')
            if file then
                file:write(string.format('[%s] 收到回复: %s\n', os.date('%Y-%m-%d %H:%M:%S'), data))
                file:close()
                print("  回复已保存到test_message.log")
            else
                print("  无法保存回复到日志文件: " .. err)
            end
        else
            print("  二进制数据，长度: " .. #data)
        end
        break
    else
        print("  等待中... (" .. i .. "/10)")
        -- 短暂延时
        if package.config:sub(1,1) == '\\' then -- Windows系统
            os.execute('ping -n 2 127.0.0.1 >nul')
        else
            os.execute('sleep 1')
        end
    end
end

-- 关闭连接
print("\n关闭连接...")
client:close(1000, '测试完成')
print("\n测试完成")