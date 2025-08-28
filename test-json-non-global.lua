-- 测试脚本：验证非全局变量方式获取CaiXiaJson
-- 在Windows环境下设置控制台编码为UTF-8
if package.config:sub(1,1) == '\\' then -- Windows系统
    os.execute('chcp 65001 >nul') -- 设置代码页为UTF-8，>nul表示不显示输出
end

print("=== 开始测试非全局变量方式获取CaiXiaJson ===")

-- 加载修改后的test-websocket-init模块
local status, ws_module = pcall(function() 
    return require('test-websocket-init')
end);

if not status then
    print("✗ 加载test-websocket-init模块失败: " .. ws_module)
else
    print("✓ 加载test-websocket-init模块成功")
    
    -- 检查CaiXiaJson是否成功获取（非全局变量方式）
    if ws_module.CaiXiaJson then
        print("✓ 成功通过非全局变量方式获取CaiXiaJson模块")
        print(string.format("  CaiXiaJson类型: %s", type(ws_module.CaiXiaJson)))
    else
        print("✗ 未能通过非全局变量方式获取CaiXiaJson模块")
    end
    
    -- 检查JSON函数是否可用
    if ws_module.json_encode and type(ws_module.json_encode) == "function" then
        print("✓ json_encode函数可用")
    else
        print("✗ json_encode函数不可用")
    end
    
    if ws_module.json_decode and type(ws_module.json_decode) == "function" then
        print("✓ json_decode函数可用")
    else
        print("✗ json_decode函数不可用")
    end
    
    -- 运行完整测试
    print("\n=== 运行完整模块测试 ===")
    if ws_module.runTests and type(ws_module.runTests) == "function" then
        ws_module.runTests()
    else
        print("✗ runTests函数不可用")
    end
end

print("\n=== 测试结束 ===")