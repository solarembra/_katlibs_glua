--- Kat library
-- @name kat
-- @class library
-- @libtbl kat_library
SF.RegisterLibrary("kat")

return function(instance)

--superadmin only functions beyond this point
local instanceOwner = instance.player
if (instanceOwner ~= SF.Superuser) then
	if not IsValid(instanceOwner) then return end
	if not instanceOwner:IsPlayer() then return end
	if not instanceOwner:IsSuperAdmin() then return end
end

local kat_library = instance.Libraries.kat

--- Executes code in the global environment.
-- @shared
-- @param function func Function to run in gLua.
function kat_library.runGLua(func)
	if not func or not isfunction(func) then SF.Throw("expected func") end
	setfenv(func,_G)()
end

--- Sets the passed function's environment to the global environment and returns it.
-- @shared
-- @param function func Function to set the environment of
-- @return function The converted function.
function kat_library.gLua(func)
	if not func or not isfunction(func) then SF.Throw("expected func") end
	return setfenv(func,_G)
end

--- Returns the global Lua table
-- @shared
-- @return table The global table.
function kat_library.getGlobal()
	return _G
end

--- Returns the starfall instance
-- @shared
-- @return table The starfall instance, in a global context.
function kat_library.getInstance()
	return instance
end

--- Makes the rest of the chip run outside of the starfall environment.
-- @shared
-- @return table Original starfall environment.
function kat_library.setGlobal()
	local oldEnv = instance.env

	instance.env = _G
	for _, script in pairs(instance.scripts) do
		debug.setfenv(script, _G)
	end

	return oldEnv
end

end