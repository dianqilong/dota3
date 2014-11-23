--
-- Author: yjun
-- Date: 2014-11-19 21:20:24
--
cc.utils = require("framework.cc.utils.init")
cc.net = require("framework.cc.net.init")

local json = require("framework.json")

local NetManager = class("NetManager")

function NetManager:ctor()
	self._buf = ""
	self.listeners = {}
end

function NetManager:onStatus(__event)
	printInfo("socket status: %s", __event.name)
end

-- 根据首部四个字节（int）判断数据是否接收完毕
function NetManager:check(buffer)
    -- 已经收到的长度（字节）
    local recv_length = string.len(self._buf)
    -- 接收到的数据长度不够？
    if recv_length < 4 then
        return 4 - recv_length
    end
    -- 读取首部4个字节，网络字节序int
    local next, total_length = string.unpack(string.sub(self._buf, 1, 4), '>I')
    -- 得到这次数据的整体长度（字节）
    if total_length > recv_length then
        -- 还有这么多字节要接收
        return total_length - recv_length
    end
    -- 接收完毕
    return 0
end

-- 打包
function NetManager:encode(data)    
    -- 选用json格式化数据
    local buffer = json.encode(data)
    -- 包的整体长度为json长度加首部四个字节(首部数据包长度存储占用空间)
    local total_length = 4 + string.len(buffer)
    return string.pack('>I', total_length) .. buffer
end

-- 解包
function NetManager:decode()
    -- 得到这次数据的整体长度（字节）
    local _, total_length = string.unpack(string.sub(self._buf, 1, 4), '>I')
    -- json的数据
    local json_string = string.sub(self._buf, 5, total_length)
    if string.len(self._buf) > total_length then
    	self._buf = string.sub(self._buf, total_length+1)
    else
    	self._buf = ""
    end
    return json.decode(json_string, true);
end

function NetManager:Send(msg)
	if not self._socket then
		print("socket not connect")
		return
	end

	self._socket:send(self:encode(msg))
end

function NetManager:onData(__event)
	self._buf = self._buf..__event.data

	while self:check() == 0 do
		self:dispatchMsg(self:decode())	
	end
end

function NetManager:Connect()
	if not self._socket then
		self._socket = cc.net.SocketTCP.new("127.0.0.1", 8480, false)
		self._socket:addEventListener(cc.net.SocketTCP.EVENT_CONNECTED, handler(self, self.onStatus))
		self._socket:addEventListener(cc.net.SocketTCP.EVENT_CLOSE, handler(self,self.onStatus))
		self._socket:addEventListener(cc.net.SocketTCP.EVENT_CLOSED, handler(self,self.onStatus))
		self._socket:addEventListener(cc.net.SocketTCP.EVENT_CONNECT_FAILURE, handler(self,self.onStatus))
		self._socket:addEventListener(cc.net.SocketTCP.EVENT_DATA, handler(self,self.onData))
	end
	self._socket:connect()
end

-- 添加消息监听者
function NetManager:AddMsgListener(msgid, func)
	-- 转成字符串
	msgid = tostring(msgid)
	if not self.listeners[msgid] then
		self.listeners[msgid] = {}
	end
	
	self.listeners[msgid][#self.listeners[msgid]+1] = func
end

-- 分发消息
function NetManager:dispatchMsg(msg)
	local list = self.listeners[tostring(msg[1])]
	if list then
		for i = 1, #list do
			-- 截断消息
			if list[i](msg) == 0 then
				break
			end
		end
	end
end

return NetManager