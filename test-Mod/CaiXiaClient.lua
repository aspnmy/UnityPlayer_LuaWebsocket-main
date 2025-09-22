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

-- 加载CaiXiaWS模块
local status, CaiXiaWS = pcall(require, 'caixia_websocket-init')
if not status then
    print("  ✗ 加载模块失败: " .. CaiXiaWS)
    return
else
    print("  ✓ 模块加载成功")
    print("  模块版本: " .. (CaiXiaWS.VERSION or "未知版本"))
end

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

local function caiXiaServer_SetConfig()
	local server_config = {
    on_connect = function(client)
        print("  [服务器] 客户端连接: " .. (client.id or "未知"))
    end,
    
    on_message = function(client, message, opcode)
        print("  [服务器] 收到消息: " .. message)
        print("  [服务器] 消息类型: " .. (opcode or "未知"))
        -- 回复消息 - 修复API调用
        client:send("已收到你的消息: " .. message)
    end,
    
    on_close = function(client)
        print("  [服务器] 客户端关闭: " .. (client.id or "未知"))
    end,
    
    on_error = function(client, err)
        print("  [服务器] 客户端错误: " .. (client.id or "未知") .. " - " .. err)
    end
}
	return  server_config
end

local function caiXiaServer_StartRun()

	-- 初始化服务器配置 - 使用local关键字避免全局变量
	local server_config = caiXiaServer_SetConfig()
	-- 启动服务器
	print("\n3. 启动WebSocket服务器...")
	local server = CaiXiaWS.startServer("0.0.0.0", 9559, server_config)
	
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
		end,
		on_message = function(data, opcode)
			print("  [客户端] 收到服务器消息")
			if opcode == CaiXiaWS.TEXT then
				print('收到文本数据:', data)
				-- 保存文本数据到日志文件
				writeToLogFile(data, '文本')
			elseif opcode == CaiXiaWS.BINARY then
				print('收到二进制数据，长度:', #data)
				-- 对于二进制数据，我们只记录长度和时间戳
				writeToLogFile(string.format('二进制数据，长度: %d', #data), '二进制')
			end
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

-- 创建logs目录的函数
local function createLogsDir()
    print('调试：尝试创建logs目录')
    -- 在脚本同级目录下创建logs目录
    local logs_dir = scriptDir .. 'logs'
    -- 首先检查是否可以加载lfs模块
    local status, fs = pcall(require, 'lfs')
    if not status then
        print('错误: 无法加载lfs模块，请确保已安装LuaFileSystem')
        -- 尝试使用简单的方式检查目录是否存在
        local file = io.open(logs_dir .. '/.test', 'w')
        if file then
            file:close()
            os.remove(logs_dir .. '/.test')
            return true
        else
            print('创建logs目录失败: 无法创建目录或打开文件')
            -- 尝试使用os.execute创建目录（Windows和Linux兼容）
            local cmd = ''
            if package.config:sub(1,1) == '\\' then -- Windows系统
                cmd = 'mkdir ' .. logs_dir
            else -- 非Windows系统
                cmd = 'mkdir -p ' .. logs_dir
            end
            local ok = os.execute(cmd)
            if ok then
                print('使用系统命令创建logs目录成功')
                return true
            else
                print('使用系统命令创建logs目录也失败')
                return false
            end
        end
    end
    
    -- 如果lfs模块加载成功
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
    return true
end

-- 将数据写入日志文件的函数
local function writeToLogFile(data, data_type)
    -- 确保logs目录存在
    if not createLogsDir() then
        return
    end
    
    -- 创建带日期的日志文件名
    local date = os.date('%Y%m%d')
    local log_file_path = string.format('%s/client_received_%s.log', scriptDir .. 'logs', date)
    
    -- 打开文件进行追加写入
    local file, err = io.open(log_file_path, 'a')
    if not file then
        print('无法打开日志文件:', err)
        return
    end
    
    -- 写入数据和时间戳
    local timestamp = os.date('%Y-%m-%d %H:%M:%S')
    file:write(string.format('[%s] %s数据: %s\n', timestamp, data_type, data))
    file:close()
    
    print(string.format('数据已保存到日志文件: %s', log_file_path))
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
			-- 保存文本数据到日志文件
			writeToLogFile(data, '文本')
		elseif opcode == CaiXiaWS.BINARY then
			print('收到二进制数据，长度:', #data)
			-- 对于二进制数据，我们只记录长度和时间戳
			writeToLogFile(string.format('二进制数据，长度: %d', #data), '二进制')
		end
	else
		-- print('接收数据失败或超时') -- 为了不干扰事件循环，不再打印超时信息
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

local function main()

	print("=== 开始测试CaiXia WebSocket客户端 ===")
	
	-- 预创建logs目录，确保日志功能可用
	print("\n1. 初始化日志系统...")
	local logs_ready = createLogsDir()
	if logs_ready then
		print("  ✓ 日志系统初始化成功")
	else
		print("  ✗ 日志系统初始化失败，但仍继续运行")
	end
	
	-- 连接本地服务器：localhost:9559
	print("\n2. 启动WebSocket客户端...")
	local client = caiXiaClient_StartRun()
	
	if client then
		print("\n3. 客户端连接服务器...")
		local connected = caiXiaClient_ConnectTo("localhost", "9559")
		
		if connected then
			print("\n4. 客户端发送测试消息...")
			caiXiaClient_SendText("Hello from CaiXia WebSocket Client!")
			
			-- 客户端常驻后台运行
			print("\n客户端已连接服务器并将常驻后台运行...")
			print("按Ctrl+C可以停止客户端。\n")
			
			-- 事件循环，使客户端常驻后台
			while true do
				-- 尝试接收服务器消息
				print('调试：尝试接收服务器消息...')
				caiXiaClient_Receive()
				
				-- 短暂延时，避免CPU占用过高
				-- 在Windows系统上使用ping命令实现延时
				if package.config:sub(1,1) == '\\' then -- Windows系统
					os.execute('ping -n 2 127.0.0.1 >nul') -- 大约1秒延时
				else -- 非Windows系统
					os.execute('sleep 1') -- 1秒延时
				end
			end
		else
			print("\n客户端连接服务器失败，跳过后续测试")
		end
	else
		print("\n创建客户端失败，跳过后续测试")
	end

end
	

-- 执行主函数
main()