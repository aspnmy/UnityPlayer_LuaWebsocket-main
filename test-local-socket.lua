-- 测试本地Socket实现
-- 这个脚本用于验证caixia_websocket.lua中的本地socket实现是否正常工作

-- 在Windows环境下设置控制台编码为UTF-8
if package.config:sub(1,1) == '\\' then -- Windows系统
    os.execute('chcp 65001 >nul') -- 设置代码页为UTF-8，>nul表示不显示输出
end

-- 设置package.path以确保能找到模块
package.path = package.path .. ';./Src/?.lua'

-- 尝试加载caixia_websocket模块
print("开始测试本地Socket实现...")
local status, CaiXiaSocket = pcall(require, 'Src.caixia_websocket')

if not status then
    print("加载模块失败: " .. CaiXiaSocket)
    return
end

print("模块加载成功！")

-- 测试tcp方法
print("\n测试tcp方法...")
local sock = CaiXiaSocket.tcp()
if sock then
    print("✓ 创建tcp套接字成功")
    print("  套接字类型: " .. type(sock))
else
    print("✗ 创建tcp套接字失败")
end

-- 测试setoption方法
print("\n测试setoption方法...")
local ok = sock:setoption('reuseaddr', true)
if ok then
    print("✓ 设置选项成功")
else
    print("✗ 设置选项失败")
end

-- 测试bind方法
print("\n测试bind方法...")
local ok, err = sock:bind('127.0.0.1', 8080)
if ok then
    print("✓ 绑定地址成功")
else
    print("✗ 绑定地址失败: " .. (err or "未知错误"))
end

-- 测试listen方法
print("\n测试listen方法...")
local ok, err = sock:listen(128)
if ok then
    print("✓ 开始监听成功")
else
    print("✗ 开始监听失败: " .. (err or "未知错误"))
end

-- 测试settimeout方法
print("\n测试settimeout方法...")
local ok = sock:settimeout(0)
if ok then
    print("✓ 设置超时成功")
else
    print("✗ 设置超时失败")
end

-- 测试accept方法（非阻塞模式下应该返回timeout）
print("\n测试accept方法...")
local client, err = sock:accept()
if err == 'timeout' then
    print("✓ accept方法按预期返回timeout")
else
    print("✗ accept方法行为不符合预期: " .. (err or "未知结果"))
end

-- 测试close方法
print("\n测试close方法...")
local ok = sock:close()
if ok then
    print("✓ 关闭套接字成功")
else
    print("✗ 关闭套接字失败")
end

print("\n=== 本地Socket实现测试完成 ===")
print("注意：这只是模拟实现，在实际游戏中需要使用游戏提供的网络API替换这些模拟方法。")