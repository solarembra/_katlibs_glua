if kat_EnumNetMsg then return end
kat_EnumNetMsg = {} --the only moral action is the minimization of NW slots - sun tzu
AddCSLuaFile()

--[[ DOCS:
Purpose:
Trades network efficiency for less NWString usage. Probably good for organizing net messages in use cases where net efficiency isn't a priority.

SHARED:
    Functions:
        function, function kat_EnumNetMsg:New(string netstring,table enums)
            Returns the netstart and the netreceive functions to use.
]]--

local n_Start = net.Start
local n_WriteUInt = net.WriteUInt
local n_ReadUInt = net.ReadUInt
function kat_EnumNetMsg:New(netstring,enums)
    if SERVER then util.AddNetworkString(netstring) end
    local highestEnum = enums[table.getWinningKey(enums)]
    local enum_bitcount = math.floor(math.log(highestEnum,2)) + 1
    local receivers = {}

    local function netMsgStart(messageEnum)
        n_Start(netstring)
        n_WriteUInt(messageEnum,enum_bitcount)
    end

    local function netMsgReceiver(messageEnum,func)
        receivers[messageEnum] = func
    end

    net.Receive(netstring,function(_,ply)
        local receiver = receivers[n_ReadUInt(enum_bitcount)]
        if receiver then receiver(ply) end
    end)

    return netMsgStart,netMsgReceiver
end

--solarembra 9/1/2025