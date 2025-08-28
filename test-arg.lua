-- 测试arg表结构
print("=== 测试arg表结构 ===")
if arg then
    print("arg表存在")
    
    -- 尝试直接访问已知的arg字段
    if arg[0] then
        print(string.format("arg[0] = %s", arg[0]))
    else
        print("arg[0] 不存在")
    end
    
    if arg[1] then
        print(string.format("arg[1] = %s", arg[1]))
    else
        print("arg[1] 不存在")
    end
    
    -- 尝试显示arg的长度
    print(string.format("#arg = %d", #arg))
    
    -- 使用pairs遍历所有键
    print("\n所有arg键值对：")
    for k, v in pairs(arg) do
        print(string.format("arg[%s] = %s", tostring(k), tostring(v)))
    end
    
    -- 检查是否存在progname字段
    if arg.progname then
        print(string.format("\narg.progname = %s", arg.progname))
    else
        print("\narg.progname 不存在")
    end
else
    print("arg表不存在")
end

print("=== 测试结束 ===")