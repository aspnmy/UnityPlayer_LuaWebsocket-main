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

if not status then
    print("✗ 加载模块失败: " .. CaiXiaWS)
    -- 即使加载失败，也返回一个基础结构以便调用者能优雅处理错误
    return {
        CaiXiaWS = nil,
        loadStatus = false,
        loadError = CaiXiaWS
    }
end

-- 完整导出caixia_websocket-init.lua中的所有可使用函数和方法
local exports = {
    -- WebSocket主模块（完整引用）
    CaiXiaWS = CaiXiaWS,
    
    -- 加载状态信息
    loadStatus = true,
    version = CaiXiaWS.VERSION or "未知版本",
    
    -- 直接导出核心WebSocket函数
    createClient = CaiXiaWS.createClient,
    createServer = CaiXiaWS.createServer,
    startServer = CaiXiaWS.startServer,

    init = CaiXiaWS.init,
    
    -- 帧处理相关函数
    encodeFrame = CaiXiaWS.encodeFrame,
    decodeFrame = CaiXiaWS.decodeFrame,
    encodeClose = CaiXiaWS.encodeClose,
    decodeClose = CaiXiaWS.decodeClose,
    
    -- 握手相关函数
    acceptUpgrade = CaiXiaWS.acceptUpgrade,
    upgradeRequest = CaiXiaWS.upgradeRequest,
    secWebSocketAccept = CaiXiaWS.secWebSocketAccept,
    httpHeaders = CaiXiaWS.httpHeaders,
    
    -- 同步操作函数
    extend = CaiXiaWS.extend,
    
    -- 工具函数表（完整引用）
    tools = CaiXiaWS.tools,
    
    -- 直接导出常用工具函数
    band = CaiXiaWS.band,
    bor = CaiXiaWS.bor,
    bxor = CaiXiaWS.bxor,
    rshift = CaiXiaWS.rshift,
    lshift = CaiXiaWS.lshift,
    sha1 = CaiXiaWS.sha1,
    base64_encode = CaiXiaWS.base64_encode,
    base64_decode = CaiXiaWS.base64_decode,
    json_encode = CaiXiaWS.json_encode,
    json_decode = CaiXiaWS.json_decode,
    parse_url = CaiXiaWS.parse_url,
    generate_key = CaiXiaWS.generate_key,
    
    -- 整数读写函数
    read_int8 = CaiXiaWS.tools and CaiXiaWS.tools.read_int8 or nil,
    read_int16 = CaiXiaWS.tools and CaiXiaWS.tools.read_int16 or nil,
    read_int32 = CaiXiaWS.tools and CaiXiaWS.tools.read_int32 or nil,
    write_int8 = CaiXiaWS.tools and CaiXiaWS.tools.write_int8 or nil,
    write_int16 = CaiXiaWS.tools and CaiXiaWS.tools.write_int16 or nil,
    write_int32 = CaiXiaWS.tools and CaiXiaWS.tools.write_int32 or nil,
    
    -- 字符串编码函数
    utf8_encode = CaiXiaWS.tools and CaiXiaWS.tools.utf8_encode or nil,
    utf8_decode = CaiXiaWS.tools and CaiXiaWS.tools.utf8_decode or nil,
    
    -- 帧类型常量
    FRAME_TYPES = {
        CONTINUATION = CaiXiaWS.FRAME and CaiXiaWS.FRAME.CONTINUATION or 0,
        TEXT = CaiXiaWS.FRAME and CaiXiaWS.FRAME.TEXT or 1,
        BINARY = CaiXiaWS.FRAME and CaiXiaWS.FRAME.BINARY or 2,
        CLOSE = CaiXiaWS.FRAME and CaiXiaWS.FRAME.CLOSE or 8,
        PING = CaiXiaWS.FRAME and CaiXiaWS.FRAME.PING or 9,
        PONG = CaiXiaWS.FRAME and CaiXiaWS.FRAME.PONG or 10
    },
    

}

-- 复制帧类型常量到直接导出表
exports.CONTINUATION = exports.FRAME_TYPES.CONTINUATION
exports.TEXT = exports.FRAME_TYPES.TEXT
exports.BINARY = exports.FRAME_TYPES.BINARY
exports.CLOSE = exports.FRAME_TYPES.CLOSE
exports.PING = exports.FRAME_TYPES.PING
exports.PONG = exports.FRAME_TYPES.PONG

-- 测试函数
function exports.runTests()
    print("=== 开始测试caixia_websocket-init模块 ===")
    print("✓ 模块加载成功")
    print("模块版本: " .. exports.version)
    
    -- 测试核心WebSocket函数
    print("\n=== 测试核心WebSocket函数 ===")
    local coreFunctions = {
        {"createClient", exports.createClient},
        {"createServer", exports.createServer},
        {"startServer", exports.startServer},
        {"init", exports.init}
    }
    
    for _, funcInfo in ipairs(coreFunctions) do
        local funcName, func = funcInfo[1], funcInfo[2]
        if type(func) == "function" then
            print(string.format("✓ 函数 %s 存在", funcName))
        else
            print(string.format("✗ 函数 %s 不存在或不是函数类型", funcName))
        end
    end
    
    -- 测试帧处理函数
    print("\n=== 测试帧处理函数 ===")
    local frameFunctions = {
        {"encodeFrame", exports.encodeFrame},
        {"decodeFrame", exports.decodeFrame},
        {"encodeClose", exports.encodeClose},
        {"decodeClose", exports.decodeClose}
    }
    
    for _, funcInfo in ipairs(frameFunctions) do
        local funcName, func = funcInfo[1], funcInfo[2]
        if type(func) == "function" then
            print(string.format("✓ 函数 %s 存在", funcName))
        else
            print(string.format("✗ 函数 %s 不存在或不是函数类型", funcName))
        end
    end
    
    -- 测试握手相关函数
    print("\n=== 测试握手相关函数 ===")
    local handshakeFunctions = {
        {"acceptUpgrade", exports.acceptUpgrade},
        {"upgradeRequest", exports.upgradeRequest},
        {"secWebSocketAccept", exports.secWebSocketAccept},
        {"httpHeaders", exports.httpHeaders}
    }
    
    for _, funcInfo in ipairs(handshakeFunctions) do
        local funcName, func = funcInfo[1], funcInfo[2]
        if type(func) == "function" then
            print(string.format("✓ 函数 %s 存在", funcName))
        else
            print(string.format("✗ 函数 %s 不存在或不是函数类型", funcName))
        end
    end
    
    -- 测试工具函数
    print("\n=== 测试工具函数 ===")
    if exports.tools then
        local allToolFunctions = {
            -- 位操作函数
            {"band", exports.band},
            {"bor", exports.bor},
            {"bxor", exports.bxor},
            {"rshift", exports.rshift},
            {"lshift", exports.lshift},
            
            -- 整数读写函数
            {"read_int8", exports.read_int8},
            {"read_int16", exports.read_int16},
            {"read_int32", exports.read_int32},
            {"write_int8", exports.write_int8},
            {"write_int16", exports.write_int16},
            {"write_int32", exports.write_int32},
            
            -- 字符串编码函数
            {"utf8_encode", exports.utf8_encode},
            {"utf8_decode", exports.utf8_decode},
            
            -- 哈希和编码函数
            {"sha1", exports.sha1},
            {"base64_encode", exports.base64_encode},
            {"base64_decode", exports.base64_decode},
            
            -- URL解析和WebSocket密钥生成
            {"parse_url", exports.parse_url},
            {"generate_key", exports.generate_key},
            
            -- JSON处理函数
            {"json_encode", exports.json_encode},
            {"json_decode", exports.json_decode}
        }
        
        for _, toolInfo in ipairs(allToolFunctions) do
            local toolName, toolFunc = toolInfo[1], toolInfo[2]
            if type(toolFunc) == "function" then
                print(string.format("✓ 工具函数 %s 存在", toolName))
            else
                print(string.format("✗ 工具函数 %s 不存在或不是函数类型", toolName))
            end
        end
    else
        print("✗ 未找到tools表")
    end
    
    -- 测试帧类型常量
    print("\n=== 测试帧类型常量 ===")
    if exports.FRAME_TYPES then
        for typeName, typeValue in pairs(exports.FRAME_TYPES) do
            print(string.format("✓ 帧类型常量 %s = %d", typeName, typeValue))
        end
    else
        print("✗ 未找到帧类型常量")
    end
    
    -- 测试创建客户端
    print("\n=== 测试创建客户端 ===")
    if exports.createClient then
        local client = exports.createClient()
        if client then
            print("✓ 创建客户端成功")
            print(string.format("客户端类型: %s", type(client)))
        else
            print("✗ 创建客户端失败")
        end
    else
        print("✗ createClient函数不可用")
    end
    
    -- 测试URL解析函数
    print("\n=== 测试URL解析函数 ===")
    if exports.parse_url then
       -- 在Unity引擎环境中使用CS.UnityEngine.Time代替os.time
       local timestamp = 0
       if CS and CS.UnityEngine and CS.UnityEngine.Time then
           -- 使用Unity的Time.time获取时间戳
           timestamp = math.floor(CS.UnityEngine.Time.time)
       else
           -- 备用方案：使用os.time()或固定值
           local os_time_ok, os_time = pcall(function() return os.time() end)
           timestamp = os_time_ok and os_time or 1756382908
       end
       local apiUrl = "https://api.caixiagame.us.earth-oline.org/api?type=serverlist&time=" .. timestamp

        local url = "CaiXiaWS://s5.v100.vip:37667"
        local protocol, host, port, uri = exports.parse_url(url)
        
        if protocol and host then
            print(string.format("✓ URL解析成功: protocol=%s, host=%s, port=%s, uri=%s", 
                protocol or "nil", host or "nil", port or "nil", uri or "nil"))
        else
            print("✗ URL解析失败")
        end
    else
        print("✗ parse_url函数不可用")
    end
    
    print("\n=== 测试完成 ===")
end

-- 如果作为主程序运行，则执行测试
local function isMainScript()
    if arg and arg[0] then
        return arg[0]:find('test%-websocket%-init%.lua') ~= nil
    end
    return false
end

if isMainScript() then
    exports.runTests()
end

-- 返回完整的导出表
return exports