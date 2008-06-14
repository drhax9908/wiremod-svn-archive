AddCSLuaFile( "physics.lua" )
WireToolSetup.setCategory( "Physics" )

--wire_weight
WireToolSetup.open( "weight", "Weight", "gmod_wire_weight", WireToolMakeWeight )

if CLIENT then
    language.Add( "Tool_wire_weight_name", "Weight Tool (Wire)" )
    language.Add( "Tool_wire_weight_desc", "Spawns a weight." )
    language.Add( "Tool_wire_weight_0", "Primary: Create/Update weight" )
    language.Add( "WireDataWeightTool_weight", "Weight:" )
	language.Add( "sboxlimit_wire_weights", "You've hit weights limit!" )
end
WireToolHelpers.BaseLang("Weights")

if SERVER then
	CreateConVar('sbox_maxwire_weights', 20)
	ModelPlug_Register("weight")
end
 
TOOL.ClientConVar = {model	= "models/props_interiors/pot01a.mdl"}

function TOOL.BuildCPanel(panel)
	WireToolHelpers.MakeModelSel(panel, "wire_weight")
end




--wire_simple_explosive
WireToolSetup.open( "simple_explosive", "Explosives (Simple)", "gmod_wire_simple_explosive", WireToolMakeExplosivesSimple )
TOOL.ConfigName = nil

if CLIENT then
    language.Add( "Tool_wire_simple_explosive_name", "Simple Wired Explosives Tool" )
    language.Add( "Tool_wire_simple_explosive_desc", "Creates a simple explosives for wire system." )
    language.Add( "Tool_wire_simple_explosive_0", "Left click to place the bomb. Right click update." )
	language.Add( "WireSimpleExplosiveTool_Model", "Model:" )
	language.Add( "WireSimpleExplosiveTool_modelman", "Manual model selection:" )
	language.Add( "WireSimpleExplosiveTool_usemodelman", "Use manual model selection:" )
	language.Add( "WireSimpleExplosiveTool_tirgger", "Trigger value:" )
	language.Add( "WireSimpleExplosiveTool_damage", "Dammage:" )
	language.Add( "WireSimpleExplosiveTool_remove", "Remove on explosion:" )
	language.Add( "WireSimpleExplosiveTool_doblastdamage", "Do blast damage:" )
	language.Add( "WireSimpleExplosiveTool_radius", "Blast radius:" )
	language.Add( "WireSimpleExplosiveTool_freeze", "Freeze:" )
	language.Add( "WireSimpleExplosiveTool_weld", "Weld:" )
	language.Add( "WireSimpleExplosiveTool_noparentremove", "Don't remove on parent remove:" )
	language.Add( "WireSimpleExplosiveTool_nocollide", "No collide all but world:" )
	language.Add( "WireSimpleExplosiveTool_weight", "Weight:" )
	language.Add( "sboxlimit_wire_simple_explosive", "You've hit wired explosives limit!" )
end
WireToolHelpers.BaseLang("SimpleExplosives")

if SERVER then
    CreateConVar('sbox_maxwire_simple_explosive', 30)
end 

TOOL.ClientConVar = {
	model = "models/props_c17/oildrum001_explosive.mdl",
	modelman = "",
	tirgger = 1,		// Current tirgger
	damage = 200,		// Damage to inflict
	doblastdamage = 1,
	radius = 300,
	removeafter = 0,
	freeze = 0,
	weld = 1,
	weight = 400,
	nocollide = 0,
	noparentremove = 0,
}

function TOOL:GetSelModel( showerr )
	local model = self:GetClientInfo( "model" )
	
	if (model == "usemanmodel") then
		local _modelman = self:GetClientInfo( "modelman" )
		if (_modelman && string.len(_modelman) > 0) then
			model = _modelman
		else
			local message = "You need to define a model."
			if (showerr) then
				self:GetOwner():PrintMessage(3, message)
				self:GetOwner():PrintMessage(2, message)
			end
			return false
		end
	elseif (model == "usereloadmodel") then
		if (self.reloadmodel && string.len(self.reloadmodel) > 0) then
			model = self.reloadmodel
		else
			local message = "You need to select a model model."
			if (showerr) then
				self:GetOwner():PrintMessage(3, message)
				self:GetOwner():PrintMessage(2, message)
			end
			return false
		end
	end
	
	if (not util.IsValidModel(model)) then
		//something fucked up, notify user of that
		local message = "This is not a valid model."..model
		if (showerr) then
			self:GetOwner():PrintMessage(3, message)
			self:GetOwner():PrintMessage(2, message)
		end
		return false
	end
	if (not util.IsValidProp(model)) then return false end
	
	return model
end

function TOOL:RightClick( trace )
	local ply = self:GetOwner()
	//shot an explosive, update it instead
	if ( trace.Entity:IsValid() && trace.Entity:GetClass() == "gmod_wire_simple_explosive" && trace.Entity:GetTable().pl == ply ) then
		local _tirgger			= self:GetClientNumber( "tirgger" ) 
		local _damage 			= math.Clamp( self:GetClientNumber( "damage" ), 0, 1500 )
		local _removeafter		= self:GetClientNumber( "removeafter" ) == 1
		local _doblastdamage	= self:GetClientNumber( "doblastdamage" ) == 1
		local _radius			= math.Clamp( self:GetClientNumber( "radius" ), 0, 10000 )
		local _weld				= self:GetClientNumber( "weld" ) == 1
		local _nocollide		= self:GetClientNumber( "nocollide" ) == 1
		local _weight			= math.Max(self:GetClientNumber( "weight" ), 1)
		
		trace.Entity:Setup( _damage, _delaytime, _removeafter, _doblastdamage, _radius, _nocollide )
		
		local ttable = {
			nocollide = _nocollide,
			key = _tirgger, 
			damage = _damage, 
			removeafter = _removeafter, 
			doblastdamage = _doblastdamage, 
			radius = _radius
		}
		table.Merge( trace.Entity:GetTable(), ttable )
		
		trace.Entity:GetPhysicsObject():SetMass(_weight)
		duplicator.StoreEntityModifier( trace.Entity, "MassMod", {Mass = _weight} )
		
		return true
	end
	
end

function TOOL:Reload( trace )
	//get the model of what was shot and set our reloadmodel to that
	//model info getting code mostly copied from OverloadUT's What Is That? STool
	if !trace.Entity then return false end
	local ent = trace.Entity
	local ply = self:GetOwner()
	local class = ent:GetClass()
	if class == "worldspawn" then
		return false
	else
		local model = ent:GetModel()
		local message = "Model selected: "..model
		self.reloadmodel = model
		ply:PrintMessage(3, message)
		ply:PrintMessage(2, message)
	end
	return true
end


