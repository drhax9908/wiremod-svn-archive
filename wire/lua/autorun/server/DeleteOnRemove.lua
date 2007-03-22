// Entity.DeleteOnRemove override by TheApathetic
//Modified to use entity indexes for DORInfo instead by TAD2020

local meta = FindMetaTable("Entity")
if (!meta) then return end

/*not need any more
if (!oldDORFunction) then
oldDORFunction = meta.DeleteOnRemove

	function meta:NewDORFunction( fRealFunc, fNewFunc )
		// Create a dummy function to forward stuff on
		local function fDummyFunc( ... )
			fNewFunc( unpack( arg ) )
			aRealFuncResults = fRealFunc( unpack( arg ) )
			return aRealFuncResults
		end

		// Return the original function intact
		return fDummyFunc
	end

	function meta:DORInfoAdd( attachedent )
		if (!self.DeleteOnRemoveInfo) then
			self.DeleteOnRemoveInfo = {}
		end

		if (!attachedent || !attachedent:IsValid() || attachedent:EntIndex() == 0) then return end
			// Add the entity
			table.insert(self.DeleteOnRemoveInfo,attachedent)
	end

	// Overwrite the exiting DeleteOnRemove with our own new version
	meta.DeleteOnRemove = meta:NewDORFunction( meta.DeleteOnRemove, meta.DORInfoAdd )
end

// Get DeleteOnRemoveInfo
function meta:GetDeleteOnRemoveInfo()
	if (!self.DeleteOnRemoveInfo) then return end

	local DORInfo = {}

	for _,ent in pairs(self.DeleteOnRemoveInfo) do
		if (ent && ent:IsValid() && ent:EntIndex() > 0) then
			table.insert(DORInfo,ent:EntIndex())
		end
	end

	return DORInfo
end*/

//Set DeleteOnRemoveInfo
function meta:SetDeleteOnRemoveInfo(DORInfo, GetEntID)
	if (!DORInfo) then return end

	if (!self.DeleteOnRemoveInfo) then
		self.DeleteOnRemoveInfo = {}
	end

	for _,entindex in pairs(DORInfo) do
		local ent = GetEntID( entindex )
		if (ent && ent:IsValid() && ent:EntIndex() > 0) then
			// Add the entity
			
			table.insert(self.DeleteOnRemoveInfo,ent)
		end
	end
end

// Console Command to print EntIndex() of all attached ents
/*local function PrintDOREntities(player,command,arguments)
	local trace = player:GetEyeTrace()
	if (!trace.HitPos || !trace.Entity || !trace.Entity:IsValid() || trace.Entity:IsPlayer()) then return end
	if (!trace.Entity.DeleteOnRemoveInfo) then return end

	// Get info first
	local DORInfo = trace.Entity:GetDeleteOnRemoveInfo()

	// Now print it
	for index,ent in pairs(DORInfo) do
		Msg(index..": "..ent:EntIndex().."\n")
	end
end
concommand.Add("dor_entities",PrintDOREntities)*/
