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

local function main()
	print("=== 开始测试CaiXia WebSocket服务器和客户端 ===")
	
	-- 启动本地服务器：0.0.0.0:9559
	print("\n1. 启动WebSocket服务器...")
	local server = caiXiaServer_StartRun()
	
	-- 启动服务器后检查状态
	if server and server.is_running then
		-- 服务器状态检查
		caiXiaServer_TestRun(server)
			
		-- 连接本地服务器：localhost:9559
		print("\n2. 启动WebSocket客户端...")
		local client = caiXiaClient_StartRun()
		
		if client then
			print("\n3. 客户端连接服务器...")
			local connected = caiXiaClient_ConnectTo("localhost", "9559")
			
			if connected then
				print("\n4. 客户端发送测试消息...")
				caiXiaClient_SendText("Hello from CaiXia WebSocket Client!")
				
				-- 接收服务器回复
				print("\n5. 客户端等待接收服务器回复...")
				caiXiaClient_Receive()
				
				-- 发送二进制数据
				print("\n6. 客户端发送二进制数据...")
				caiXiaClient_SendBinary_data()
				
				-- 关闭连接
				print("\n7. 客户端关闭连接...")
				caiXiaClient_Close()
			else
				print("\n客户端连接服务器失败，跳过后续测试")
			end
		else
			print("\n创建客户端失败，跳过后续测试")
		end
	else
		print("\n服务器启动失败，跳过客户端测试")
	end
	
	print("\n=== CaiXia WebSocket测试完成 ===")
end

-- 执行主函数
main()