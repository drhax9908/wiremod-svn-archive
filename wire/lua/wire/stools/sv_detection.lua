
function WireToolMakeSpeedometer( self, trace, ply )
	
	local xyz_mode = (self:GetClientNumber("xyz_mode") ~= 0)
	local AngVel = (self:GetClientNumber( "angvel" ) == 1)

	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_speedometer" && trace.Entity.pl == ply ) then
		trace.Entity:Setup(xyz_mode, AngVel)
		return true
	end

	if ( !self:GetSWEP():CheckLimit( "wire_speedometers" ) ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_speedometer = MakeWireSpeedometer( ply, Ang, trace.HitPos, xyz_mode, AngVel )

	local min = wire_speedometer:OBBMins()
	wire_speedometer:SetPos( trace.HitPos - trace.HitNormal * min.z )
	
	return wire_speedometer
end
