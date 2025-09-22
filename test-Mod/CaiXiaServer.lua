-- 测试CaiXia WebSocket服务器完整功能
-- 这个脚本测试WebSocket服务器的创建、启动和基本功能

-- 在Windows环境下设置控制台编码为UTF-8
if package.config:sub(1,1) == '\\' then -- Windows系统
    os.execute('chcp 65001 >nul') -- 设置代码页为UTF-8，>nul表示不显示输出
end

-- 为了和lua官方组件区分，本原生组件中使用的WS业务一律用CaiXiaWS进行表述

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

-- 加载消息总线模块
local status, messageBus = pcall(require, 'caixia_messageBus')
if not status then
    print("  ✗ 加载消息总线模块失败: " .. messageBus)
    return
else
    -- 检查是否已经存在全局的Msg变量
    if not _G.Msg then
        -- 如果没有，创建一个新的
        _G.Msg = {}
        _G.Msg.init = function()
            _G.Msg.msgmap = {}
        end
        _G.Msg.Add = function(instance, msgId, func)
            local msgObj = {instance, func}
            if not _G.Msg.msgmap[msgId] then
                _G.Msg.msgmap[msgId] = {msgObj}
            else
                local list = _G.Msg.msgmap[msgId]
                for _, obj in pairs(list) do
                    if obj[1] == instance and obj[2] == func then
                        return
                    end
                end
                table.insert(_G.Msg.msgmap[msgId], msgObj)
            end
        end
        _G.Msg.Send = function(msgId, ...)
            local list = _G.Msg.msgmap[msgId]
            if list then
                for _, msgObj in pairs(list) do
                    if msgObj[2] then
                        msgObj[2](...)
                    end
                end
            end
        end
        _G.Msg.init()
    end
    print("  ✓ 消息总线已准备就绪")
end

-- 加载CaiXiaWS模块
local status, CaiXiaWS = pcall(require, 'caixia_websocket-init')
if not status then
    print("  ✗ 加载模块失败: " .. CaiXiaWS)
    return
else
    print("  ✓ 模块加载成功")
    print("  模块版本: " .. (CaiXiaWS.VERSION or "未知版本"))
end

-- 定义消息ID常量为全局变量
_G.MSG_IDS = {
    CLIENT_CONNECT = "CLIENT_CONNECT",
    CLIENT_DISCONNECT = "CLIENT_DISCONNECT",
    RECEIVE_MESSAGE = "RECEIVE_MESSAGE",
    SEND_MESSAGE = "SEND_MESSAGE"
}

local function caiXiaServer_OnInit()

	local caiXiaServer = caiXiaServer_StartRun()
	
	if not caiXiaServer then
    print("  ✗ 创建服务器失败")
    return
	else
		print("  ✓ 创建服务器成功")
		-- 检查服务器状态
		caiXiaServer_TestRun(caiXiaServer)
	end
end


local function caiXiaClient_OnInit()

	local CaiXiaClient = caiXiaClient_StartRun()
	local Host = "localhost"--"输入服务器IP或域名"
	local Port = "9559"--"输入服务器Tcp端口"
	local CaiXiaClientTo =  caiXiaClient_ConnectTo(Host,Port)
	if not CaiXiaClientTo then
    print("  ✗ 连接服务器失败")
    return
	else
		print("  ✓ 连接服务器成功")
	end


end

-- 日志记录函数
local function writeToServerLog(message, log_type)
    -- 确保logs目录在脚本同级目录
    local logs_dir = scriptDir .. 'logs'
    
    -- 确保logs目录存在
    local status, fs = pcall(require, 'lfs')
    if not status then
        print('无法加载lfs模块，请确保已安装LuaFileSystem')
        -- 尝试使用简单的方式检查目录是否存在
        local file = io.open(logs_dir .. '/.test', 'w')
        if not file then
            -- 尝试使用os.execute创建目录（Windows和Linux兼容）
            local cmd = ''
            if package.config:sub(1,1) == '\\' then -- Windows系统
                cmd = 'mkdir "' .. logs_dir .. '"'
            else -- 非Windows系统
                cmd = 'mkdir -p "' .. logs_dir .. '"'
            end
            print('尝试使用系统命令创建logs目录:', cmd)
            local ok = os.execute(cmd)
            if ok then
                print('使用系统命令创建logs目录成功')
            else
                print('使用系统命令创建logs目录失败')
                return false
            end
        else
            file:close()
            os.remove(logs_dir .. '/.test')
        end
    else
        if not fs.attributes(logs_dir) then
            print('logs目录不存在，正在创建...')
            local ok, err = fs.mkdir(logs_dir)
            if not ok then
                print('创建logs目录失败:', err)
                return false
            else
                print('logs目录创建成功')
            end
        else
            print('logs目录已存在')
        end
    end
    
    -- 创建带日期的日志文件名
    local date = os.date('%Y%m%d')
    local log_file_path = string.format('%s/server_%s.log', logs_dir, date)
    
    -- 打开文件进行追加写入
    print('尝试打开日志文件:', log_file_path)
    local file, err = io.open(log_file_path, 'a')
    if not file then
        print('无法打开日志文件:', err)
        return false
    end
    
    -- 写入数据和时间戳
    local timestamp = os.date('%Y-%m-%d %H:%M:%S')
    local log_entry = string.format('[%s] %s: %s\n', timestamp, log_type, message)
    file:write(log_entry)
    file:close()
    
    print('日志已写入:', log_file_path)
    return true
end

local function caiXiaServer_SetConfig(max_conn)
	print("调试：正在设置服务器配置")
	local server_config = {
    -- 可配置的最大连接数，默认为51200
    max_connections = max_conn or 51200, -- 如果没有提供则使用默认值51200
    
    on_connect = function(client)
        print("  [服务器] 客户端连接事件触发")
        print("  [服务器] 客户端ID: " .. (client.id or "未知"))
        
        -- 通过消息总线发送客户端连接事件
        _G.Msg.Send(_G.MSG_IDS.CLIENT_CONNECT, client)
        
        -- 记录连接日志
        local log_result = writeToServerLog("客户端连接: " .. (client.id or "未知"), "连接")
        print("  [服务器] 连接日志记录结果: " .. (log_result and "成功" or "失败"))
        -- 发送欢迎消息给客户端
        local send_result = client:send("欢迎连接到CaiXia WebSocket服务器！")
        print("  [服务器] 欢迎消息发送结果: " .. (send_result and "成功" or "失败"))
    end,
    
    on_message = function(client, message, opcode)
        print("  [服务器] 收到消息事件触发")
        print("  [服务器] 客户端ID: " .. (client.id or "未知"))
        print("  [服务器] 收到消息: " .. message)
        print("  [服务器] 消息类型: " .. (opcode or "未知"))
        
        -- 通过消息总线发送收到消息事件
        _G.Msg.Send(_G.MSG_IDS.RECEIVE_MESSAGE, client, message, opcode)
        
        -- 记录消息日志
        local log_result = writeToServerLog("来自客户端 " .. (client.id or "未知") .. " 的消息: " .. message, "消息")
        print("  [服务器] 消息日志记录结果: " .. (log_result and "成功" or "失败"))
        -- 回复消息
        local send_result = client:send("已收到你的消息: " .. message)
        print("  [服务器] 回复消息发送结果: " .. (send_result and "成功" or "失败"))
        
        -- 通过消息总线发送消息发送事件
        _G.Msg.Send(_G.MSG_IDS.SEND_MESSAGE, client, "已收到你的消息: " .. message, send_result)
    end,
    
    on_close = function(client)
        print("  [服务器] 客户端关闭事件触发")
        print("  [服务器] 客户端ID: " .. (client.id or "未知"))
        
        -- 通过消息总线发送客户端断开连接事件
        _G.Msg.Send(_G.MSG_IDS.CLIENT_DISCONNECT, client)
    end,
    
    on_error = function(client, err)
        print("  [服务器] 客户端错误事件触发")
        print("  [服务器] 客户端ID: " .. (client.id or "未知"))
        print("  [服务器] 错误信息: " .. err)
    end
}
	return  server_config
end

local function caiXiaServer_StartRun(host, port, max_conn)

	-- 初始化服务器配置 - 使用local关键字避免全局变量
	local server_config = caiXiaServer_SetConfig(max_conn)
	-- 设置默认值
	host = host or "0.0.0.0"
	port = port or 9559
	
	-- 启动服务器
	print("\n3. 启动WebSocket服务器...")
	print("  监听地址: " .. host)
	print("  监听端口: " .. port)
	print("  最大连接数: " .. (max_conn or 256))
	local server = CaiXiaWS.startServer(host, port, server_config)
	
	if not server then
    print("  ✗ 服务器启动失败")
    return
	else
		print("  ✓ 服务器启动成功")
		print("  服务器信息: " .. type(server))
	end
	return server
end



-- 修改为接受server参数
local function caiXiaServer_TestRun(server)
		-- 4. 检查服务器状态
		print("\n4. 检查服务器状态...")
		if server and server.is_running then
			print("  ✓ 服务器正在运行")
			print("  监听地址: " .. (server.host or "未知"))
			print("  监听端口: " .. (server.port or "未知"))
		else
			print("  ✗ 服务器未在运行")
		end
end

local function caiXiaClient_StartRun()
	-- 5. 创建WS客户端
	print("\n5. 创建WebSocket客户端...")
	local client = CaiXiaWS.createClient({
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
	-- 保存客户端到CaiXiaWS对象中以便后续使用
	CaiXiaWS.client = client
	return client
end

local function caiXiaClient_ConnectTo(Host,Port)
	--  本地Ws客户端连接服务器
	print("\n 本地Ws客户端连接服务器...")
	-- 修复URL构建，正确使用参数
	local ws_url = 'ws://' .. Host .. ':' .. Port
	-- 使用更新后的ws_connect方法
	local ok, protocol_or_err, headers = CaiXiaWS.client:ws_connect(ws_url)
	if not ok then
		print('连接失败:', protocol_or_err)
		return false
	else
		if protocol_or_err then
			print('  使用协议:', protocol_or_err)
		end
	end
	print('连接成功!')
	return true
end


local function caiXiaClient_SendText(Text)
	-- 发送文本数据
	if not CaiXiaWS.client then
		print('错误: 客户端未初始化')
		return
	end
	local Text = Text or 'Hello WebSocket!'
	local success, err = CaiXiaWS.client:send(Text)
	if not success then
		print('发送失败:', err)
	else
		print('发送成功:', Text)
	end
end

local function caiXiaClient_SendBinary_data(binary_data)
	-- 发送二进制数据
	if not CaiXiaWS.client then
		print('错误: 客户端未初始化')
		return
	end
	local binary_data = binary_data or '\x01\x02\x03\x04'
	local success, err = CaiXiaWS.client:send(binary_data, CaiXiaWS.BINARY)
	if not success then
		print('发送失败:', err)
	else
		print('发送二进制数据成功，长度:', #binary_data)
	end
end

local function caiXiaClient_Receive()
	-- 接收数据
	if not CaiXiaWS.client then
		print('错误: 客户端未初始化')
		return
	end
	local data, opcode = CaiXiaWS.client:receive()
	if data then
		if opcode == CaiXiaWS.TEXT then
			print('收到文本数据:', data)
		elseif opcode == CaiXiaWS.BINARY then
			print('收到二进制数据，长度:', #data)
		end
	else
		print('接收数据失败或超时')
	end
end

local function caiXiaClient_Close()
	-- 关闭连接
	if not CaiXiaWS.client then
		print('错误: 客户端未初始化')
		return
	end
	local was_clean, code, reason = CaiXiaWS.client:close(1000, '正常关闭')
	if was_clean then
		print('连接已干净关闭，代码:', code, '原因:', reason)
	else
		print('连接关闭异常，代码:', code, '原因:', reason)
	end
end

-- 示例：演示如何使用消息总线监听WebSocket事件
local function demoMessageBusHandlers()
    -- 监听客户端连接事件
    _G.Msg.Add(nil, _G.MSG_IDS.CLIENT_CONNECT, function(client)
        print("\n  [消息总线] 监听到客户端连接事件")
        print("  [消息总线] 客户端ID: " .. (client.id or "未知"))
        print("  [消息总线] 客户端IP: " .. (client.ip or "未知"))
        -- 这里可以添加自定义的连接处理逻辑
    end)
    
    -- 监听客户端断开连接事件
    _G.Msg.Add(nil, _G.MSG_IDS.CLIENT_DISCONNECT, function(client)
        print("\n  [消息总线] 监听到客户端断开连接事件")
        print("  [消息总线] 客户端ID: " .. (client.id or "未知"))
        -- 这里可以添加自定义的断开连接处理逻辑
    end)
    
    -- 监听收到消息事件
    _G.Msg.Add(nil, _G.MSG_IDS.RECEIVE_MESSAGE, function(client, message, opcode)
        print("\n  [消息总线] 监听到收到消息事件")
        print("  [消息总线] 客户端ID: " .. (client.id or "未知"))
        print("  [消息总线] 消息内容: " .. message)
        print("  [消息总线] 消息类型: " .. (opcode or "未知"))
        -- 这里可以添加自定义的消息处理逻辑
        -- 例如根据消息内容执行不同的业务逻辑
        if message:find("ping") then
            print("  [消息总线] 检测到ping消息，准备发送pong响应")
            client:send("pong")
        end
    end)
    
    -- 监听发送消息事件
    _G.Msg.Add(nil, _G.MSG_IDS.SEND_MESSAGE, function(client, message, result)
        print("\n  [消息总线] 监听到发送消息事件")
        print("  [消息总线] 客户端ID: " .. (client.id or "未知"))
        print("  [消息总线] 发送内容: " .. message)
        print("  [消息总线] 发送结果: " .. (result and "成功" or "失败"))
        -- 这里可以添加自定义的发送结果处理逻辑
    end)
    
    print("\n  ✓ 消息总线事件监听器已注册")
end

local function main()
	print("=== 开始测试CaiXia WebSocket通用服务器 ===")
	
	-- 解析命令行参数
	local host = "0.0.0.0" -- 默认监听地址
	local port = 9559      -- 默认端口
	local max_conn = 512000   -- 默认最大连接数
	
	-- 简单的命令行参数解析
	-- 格式：lua CaiXiaServer.lua [host] [port] [max_connections]
	if arg and #arg >= 1 then
		host = arg[1]
		if #arg >= 2 then
			port = tonumber(arg[2])
			if #arg >= 3 then
				max_conn = tonumber(arg[3])
			end
		end
	end
	
	-- 注册消息总线事件监听器
	demoMessageBusHandlers()
	
	-- 启动本地服务器
	print("\n 启动彩霞通用WebSocket服务器...")
	print("\n 了不起的修仙模拟器请访问：服务器地址--"  .. host)
	print("\n 了不起的修仙模拟器请访问：服务器端口--"  .. port)
	local server = caiXiaServer_StartRun(host, port, max_conn)
	
	-- 启动服务器后检查状态
	if server and server.is_running then
		-- 服务器状态检查
		caiXiaServer_TestRun(server)
		
		print("\n服务器已启动并将常驻后台运行。")
		print("按Ctrl+C可以停止服务器。\n")
		
		-- 添加事件循环，使服务器常驻后台
		-- 在实际应用中，这里应该是一个合适的事件循环实现
		-- 由于是演示，我们使用一个简单的循环
		print("\n服务器将持续运行，直到按Ctrl+C中断...\n")
		while server and server.is_running do
			-- 使用Lua内置的方式实现短暂延时，避免CPU占用过高
			-- 在Windows系统上使用ping命令实现延时
			if package.config:sub(1,1) == '\\' then -- Windows系统
				os.execute('ping -n 2 127.0.0.1 >nul') -- 约1秒延时
			else -- 非Windows系统
				os.execute('sleep 1') -- 1秒延时
			end
		end
	else
		print("\n服务器启动失败，无法进入常驻模式。")
	end
end
-- 执行主函数
main()