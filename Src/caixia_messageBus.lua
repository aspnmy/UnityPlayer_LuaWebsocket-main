Msg = {}

Msg.init = function()
	--[[
		msgmap = {
			msgId = {
				{instance1, func1},
				{instance2, func2}
			}
		}
	]]
	Msg.msgmap = {}
end

--@desc 添加绑定事件
--@arg  ... msgId, instance, func
--@arg  msgId 消息Id
--@arg  func 消息执行函数
Msg.Add = function(instance, msgId, func)
	local msgObj = {instance, func}
	if not Msg.msgmap[msgId] then
		Msg.msgmap[msgId] = {msgObj}
	else
		local list = Msg.msgmap[msgId]
		for _, obj in pairs(list) do
			if obj[1] == instance and obj[2] == func then
				return
			end
		end
		table.insert(Msg.msgmap[msgId], msgObj)
	end
end

--@desc 移除绑定事件
--@arg  msgId 消息Id
--@arg  instance 监听实例
--@arg  func 消息执行函数
Msg.Remove = function(msgId, instance, func)
	if msgId then
		if not instance and not func then
			Msg.msgmap[msgId] = nil
		else
			local list = Msg.msgmap[msgId]
			Msg._remove(list, instance, func)
		end
	else
		for id, list in pairs(Msg.msgmap) do
			Msg._remove(list, instance, func)
		end
	end
end
Msg._remove = function(list, instance, func)
	if not list then
		return
	end
	for index, msgObj in pairs(list) do
		if instance and func then
			if msgObj[1] == instance and msgObj[2] == func then
				table.remove(list, index)
			end
		elseif instance and not func then
			if msgObj[1] == instance then
				table.remove(list, index)
			end
		elseif not instance and func then
			if msgObj[2] == func then
				table.remove(list, index)
			end
		end
	end
end

--@desc 发送事件
--@arg  msgId 消息Id息
Msg.Send = function(msgId, ...)
	local list = Msg.msgmap[msgId]
	if list then
		for _, msgObj in pairs(list) do
			if msgObj[2] then
				msgObj[2](...)
			end
		end
	end
end

local function main()
    Msg.init()
    return Msg
end

main()