TOOL.Category		= "Construction"
TOOL.Name			= "#Weight"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar["set"] = "1"

if CLIENT then
	language.Add( "Tool_weight_name", "Weight Tool" )
	language.Add( "Tool_weight_desc", "Sets objects weight" )
	language.Add( "Tool_weight_0", "Primary: Set   Secondary: Copy   Reload: Reset" )
	language.Add( "Tool_weight_set", "Weight:" )
	language.Add( "Tool_weight_set_desc", "Set the weight" )
	language.Add( "Tool_weight_zeromass", "Mass must be above 0!" )
end

if SERVER and not Weights then Weights = {} end

function IsReallyValid(trace)
	if (!trace.Hit) then return false end
	if (!trace.HitNonWorld) then return false end
	if (trace.Entity:IsPlayer()) then return false end
	if CLIENT then return true end
	if (!trace.Entity:GetPhysicsObject():IsValid()) then return false end
	return true
end

local function SetMass( Player, Entity, Data )

	if ( Data and Data.Mass ) then
		if (Data.Mass > 0) then
			Entity:GetPhysicsObject():SetMass(Data.Mass)
			duplicator.StoreEntityModifier( Entity, "MassMod", Data )
		else 
			self:GetOwner():ConCommand("weight_set 1");
			self:GetOwner():SendLua("ZMass()");
		end
		
		return true
	end
	
end
duplicator.RegisterEntityModifier( "MassMod", SetMass )


function TOOL:LeftClick( trace )
	if CLIENT and IsReallyValid(trace) then return true end
	if not IsReallyValid(trace) then return end
	
	if not Weights[trace.Entity:GetModel()] then 
		Weights[trace.Entity:GetModel()] = trace.Entity:GetPhysicsObject():GetMass() 
	end
	local mass = tonumber(self:GetClientInfo("set"))
	
	SetMass( Player, trace.Entity, {Mass = mass} )
	
	return true;
end

function TOOL:RightClick( trace )
	if CLIENT and IsReallyValid(trace) then return true end
	if not IsReallyValid(trace) then return end
	
	local mass = trace.Entity:GetPhysicsObject():GetMass()
	self:GetOwner():ConCommand("weight_set "..mass);
	return true;
end

function TOOL:Reload( trace )

end

function TOOL:Think()
	if CLIENT then return end;
	local pl = self:GetOwner()
	if not (pl:GetActiveWeapon():IsValid()) then return end
	if not (pl:GetActiveWeapon():GetClass() == "gmod_tool") then return end
	if not (pl:GetInfo("gmod_toolmode") == "weight") then return end
	local tr = util.GetPlayerTrace(pl, pl:GetCursorAimVector())
	local trace = util.TraceLine( tr )
	if not IsReallyValid(trace) then return end
	pl:SetNetworkedFloat("WeightMass", trace.Entity:GetPhysicsObject():GetMass())
	
	if pl:KeyPressed(IN_RELOAD) and Weights[trace.Entity:GetModel()] then
		trace.Entity:GetPhysicsObject():SetMass(Weights[trace.Entity:GetModel()])
		
			self.Weapon:EmitSound( Sound( "Airboat.FireGunRevDown" )	)
			self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
			
		local effectdata = EffectData()
			effectdata:SetOrigin( trace.HitPos )
			effectdata:SetNormal( trace.HitNormal )
			effectdata:SetEntity( trace.Entity )
			effectdata:SetAttachment( trace.PhysicsBone )
		util.Effect( "selection_indicator", effectdata )	
		
		local effectdata = EffectData()
			effectdata:SetOrigin( trace.HitPos )
			effectdata:SetStart( pl:GetShootPos() )
			effectdata:SetAttachment( 1 )
			effectdata:SetEntity( self.Weapon )
		util.Effect( "ToolTracer", effectdata )
	end
end

function TOOL.BuildCPanel( cp )
	cp:AddControl( "Header", { Text = "#Tool_weight_name", Description	= "#Tool_weight_desc" }  )

	local params = { Label = "#Presets", MenuButton = 1, Folder = "weight", Options = {}, CVars = {} }
	
	params.Options.default = { weight_set = 3 }
	table.insert( params.CVars, "weight_set" )
	
	cp:AddControl("ComboBox", params )
	cp:AddControl("Slider", { Label = "#Tool_weight_set", Type = "Numeric", Min = "1", Max = "50000", Command = "weight_set" } )
end


if CLIENT then
	
	local TipColor = Color( 250, 250, 200, 255 )

	surface.CreateFont( "coolvetica", 24, 500, true, false, "GModWorldtip" )

	local function DrawWeightTip()
		if not (LocalPlayer():GetActiveWeapon():IsValid()) then return end
		if not (LocalPlayer():GetActiveWeapon():GetClass() == "gmod_tool") then return end
		if not (LocalPlayer():GetInfo("gmod_toolmode") == "weight") then return end
		local tr = utilx.GetPlayerTrace( LocalPlayer(), LocalPlayer():GetCursorAimVector() )
		local trace = util.TraceLine( tr )
		if (!trace.Hit) then return end
		if (!trace.HitNonWorld) then return end
		if (trace.Entity:IsPlayer()) then return end
		
		local mass = LocalPlayer():GetNetworkedFloat("WeightMass") or 0
		local text = "Weight: "..mass
	
		local pos = (trace.Entity:GetPos()):ToScreen()
		
		local black = Color( 0, 0, 0, 255 )
		local tipcol = Color( TipColor.r, TipColor.g, TipColor.b, 255 )
		
		local x = 0
		local y = 0
		local padding = 10
		local offset = 50
		
		surface.SetFont( "GModWorldtip" )
		local w, h = surface.GetTextSize( text )
		
		x = pos.x - w 
		y = pos.y - h 
		
		x = x - offset
		y = y - offset

		draw.RoundedBox( 8, x-padding-2, y-padding-2, w+padding*2+4, h+padding*2+4, black )
		
		
		local verts = {}
		verts[1] = { x=x+w/1.5-2, y=y+h+2 }
		verts[2] = { x=x+w+2, y=y+h/2-1 }
		verts[3] = { x=pos.x-offset/2+2, y=pos.y-offset/2+2 }
		
		draw.NoTexture()
		surface.SetDrawColor( 0, 0, 0, tipcol.a )
		surface.DrawPoly( verts )
		
		
		draw.RoundedBox( 8, x-padding, y-padding, w+padding*2, h+padding*2, tipcol )
		
		local verts = {}
		verts[1] = { x=x+w/1.5, y=y+h }
		verts[2] = { x=x+w, y=y+h/2 }
		verts[3] = { x=pos.x-offset/2, y=pos.y-offset/2 }
		
		draw.NoTexture()
		surface.SetDrawColor( tipcol.r, tipcol.g, tipcol.b, tipcol.a )
		surface.DrawPoly( verts )
		
		
		draw.DrawText( text, "GModWorldtip", x + w/2, y, black, TEXT_ALIGN_CENTER )
	end
	
	hook.Add("HUDPaint", "WeightWorldTip", DrawWeightTip)
	
	function ZMass()
		GAMEMODE:AddNotify("#Tool_weight_zeromass", NOTIFY_ERROR, 6);
		surface.PlaySound( "buttons/button10.wav" )
	end
end






