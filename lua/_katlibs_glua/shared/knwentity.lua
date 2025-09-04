if kat_NWEntity then return end
kat_NWEntity = {}
AddCSLuaFile()

--[[ DOCS:
Purpose:
A static clientside entity table that is accessible even if the entity is not networked due to being out of PVS.
Contains hook methods that act as convenient callbacks on entity clientside initialization, clientside deinitialization, and serverside removal.

SERVER:
    Functions:
        void net.WriteKNWEntity(Entity ent)
        void kat_NWEntity.SendRemoveCall(Entity ent,Player ply)
        void kat_NWEntity.BroadcastRemoveCall(Entity ent)

CLIENT:
    Classes:
        KNWEntity {
            void OnInitialize(eid,ent)
            void OnDeinitialize(eid,ent)
            void OnRemove(eid)
            Entity GetEntity()
        }

    Functions:
        KNWEntity KNWEntity(int entIndex)
        KNWEntity net.ReadKNWEntity()
        KNWEntity Entity:GetKNWEntity()
]]

local ent_meta = FindMetaTable("Entity")
local e_EntIndex = ent_meta.EntIndex

local n_Start = net.Start
local n_WriteUInt = net.WriteUInt
local n_ReadUInt = net.ReadUInt
local n_Send = net.Send
local n_Broadcast = net.Broadcast
local IsValid = IsValid
local t_Simple = timer.Simple
local Entity = Entity

local NETSTRING_ENTREMOVED = "kat_EntityNetworking_er"

local activeEnts = {}
if SERVER then
    util.AddNetworkString(NETSTRING_ENTREMOVED)

    function net.WriteKNWEntity(ent)
        activeEnts[ent] = true
        n_WriteUInt(e_EntIndex(ent),13)
    end

    function kat_NWEntity.SendRemoveCall(ent,ply)
        n_Start(NETSTRING_ENTREMOVED)
        n_WriteUInt(e_EntIndex(ent),13)
        n_Send(ply)
    end

    function kat_NWEntity.BroadcastRemoveCall(ent)
        if not activeEnts[ent] then return end
        activeEnts[ent] = nil

        n_Start(NETSTRING_ENTREMOVED)
        n_WriteUInt(e_EntIndex(ent),13)
        n_Broadcast()
    end
    hook.Add("EntityRemoved","kat_NWEntity",kat_NWEntity.BroadcastRemoveCall)
elseif CLIENT then
    local initialized = {}
    function net.ReadKNWEntity()
        local eid = n_ReadUInt(13)

        local knwEnt = activeEnts[eid]
        if knwEnt then return knwEnt end
        knwEnt = {
            GetEntity = function() return Entity(eid) end,
            EntIndex = function() return eid end,
        }
        activeEnts[eid] = knwEnt

        t_Simple(0,function()
            local ent = Entity(eid)
            if not IsValid(ent) then return end

            if initialized[eid] then return end
            initialized[eid] = true

            local init = knwEnt.OnInitialize
            if not init then return end
            init(eid,ent)
        end)

        return knwEnt
    end

    function ent_meta:GetKNWEntity()
        return activeEnts[e_EntIndex(self)]
    end

    function KNWEntity(eid)
        return activeEnts[eid]
    end

    hook.Add("NetworkEntityCreated","kat_NWEntity",function(ent)
        if not IsValid(ent) then return end

        local eid = e_EntIndex(ent)
        local knwEnt = activeEnts[eid]
        if not knwEnt then return end

        if initialized[eid] then return end
        initialized[eid] = true

        local init = knwEnt.OnInitialize
        if not init then return end
        init(eid,ent)
    end)

    hook.Add("EntityRemoved","kat_NWEntity",function(ent)
        local eid = e_EntIndex(ent)
        local knwEnt = activeEnts[eid]
        if not knwEnt then return end

        initialized[eid] = nil

        local deinit = knwEnt.OnDeinitialize
        if not deinit then return end
        deinit(eid,ent)
    end)

    net.Receive(NETSTRING_ENTREMOVED, function()
        local eid = n_ReadUInt(13)
        local knwEnt = activeEnts[eid]
        if not knwEnt then return end

        local remove = knwEnt.OnRemove
        if not remove then return end
        remove(eid)
        activeEnts[eid] = nil
    end)
end

--solarembra 9/1/2025