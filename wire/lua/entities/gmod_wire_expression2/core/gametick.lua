AddCSLuaFile('gametick.lua')

/******************************************************************************\
  Game tick callback support
\******************************************************************************/

local wire_exp2_id = 0
local wire_exp2_tickclk = {}
local wire_exp2_tickrun = 0

registerFunction("runOnTick", "n", "", function(self,args)
    local op1 = args[2]
    local rv1 = op1[1](self, op1)
	
    if rv1 != 0 then
        wire_exp2_tickclk["_" .. tostring(self.data['tickid'])] = self.entity
    else
		wire_exp2_tickclk["_" .. tostring(self.data['tickid'])] = self.entity
    end
end)

registerCallback("construct", function(self)
	self.data['tickid'] = wire_exp2_id
	wire_exp2_id = wire_exp2_id + 1
end)

registerCallback("destruct",function(self)
	wire_exp2_tickclk["_" .. tostring(self.data['tickid'])] = nil
end)

registerFunction("tickClk", "", "n", function(self,args)
	return wire_exp2_tickrun
end)


local function Expression2Tick()
	wire_exp2_tickrun = 1
	for _,entity in pairs(wire_exp2_tickclk) do
		entity:Execute()
	end
	wire_exp2_tickrun = 0
end

hook.Add("Think", "Expression2TickClock", Expression2Tick)