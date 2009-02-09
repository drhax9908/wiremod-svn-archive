AddCSLuaFile('serverinfo.lua')

/******************************************************************************\
  Server Information
\******************************************************************************/

registerFunction("map", "", "s", function(self, args)
	return string.Replace(GetConVarString("host_map"),".bsp","")
end)

registerFunction("hostname", "", "s", function(self, args)
	if(SinglePlayer()) then return "" end
	return GetConVarString("hostname")
end)

registerFunction("isLan", "", "n", function(self, args)
	if(GetConVar("sv_lan"):GetBool()) then return 1 else return 0 end
end)

registerFunction("gamemode", "", "s", function(self, args)
	return gmod.GetGamemode().Name
end)

registerFunction("isSinglePlayer", "", "n", function(self, args)
	if(SinglePlayer()) then return 1 else return 0 end
end)

registerFunction("isDedicated", "", "n", function(self, args)
	if(SinglePlayer()) then return 0 end
	if(isDedicatedServer()) then return 1 else return 0 end
end)

registerFunction("numPlayers", "", "n", function(self, args)
	return table.Count(player.GetAll())
end)

registerFunction("maxPlayers", "", "n", function(self, args)
	return MaxPlayers()
end)

registerFunction("gravity", "", "n", function(self, args)
	return GetConVarNumber("sv_gravity")
end)
