
function WireToolMakeWeight( self, trace, ply )
	
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_weight" && trace.Entity:GetTable().pl == ply ) then
		return true
	end

	local model = self:GetClientInfo( "model" )

	if !self:GetSWEP():CheckLimit( "wire_weights" ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_weight = MakeWireWeight( ply, trace.HitPos, Ang, model )

	local min = wire_weight:OBBMins()
	wire_weight:SetPos( trace.HitPos - trace.HitNormal * min.z )

	return wire_weight
end
