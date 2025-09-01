if kat_ClientInit then return end
kat_ClientInit = {}
AddCSLuaFile()

local NETSTRING = "kat_clientinit"

local h_Run = hook.Run
local n_Start = net.Start
local n_WriteString = net.WriteString
local n_ReadString = net.ReadString
local n_Send = net.Send
local n_SendToServer = net.SendToServer
local pairs = pairs

local receivers = {}

if SERVER then
	local alreadyLoaded = {}
	hook.Add("PlayerDisconnected","kat_clientinit",function(ply)
		alreadyLoaded[ply] = nil
	end)

	net.Receive("kat_clientinit", function(_,ply)
		if alreadyLoaded[ply] then return end
		alreadyLoaded[ply] = true

		h_Run("kat_OnClientInit",ply)

		for key,func in pairs(receivers) do
			n_Start(NETSTRING)
			n_WriteString(key)
			func()
			n_Send(ply)
		end
	end)

	function kat_ClientInit.SendClientData(key,func)
		receivers[key] = func
	end
elseif CLIENT then
	hook.Add("InitPostEntity","kat_ClientInit",function()
		n_Start(NETSTRING)
		n_SendToServer()
	end)

	function kat_ClientInit.ReceiveServerData(key,func)
		receivers[key] = func
	end

	net.Receive("kat_clientinit",function()
		local func = receivers[n_ReadString()]
		if func then func() end
	end)
end

--solarembra 9/1/2025