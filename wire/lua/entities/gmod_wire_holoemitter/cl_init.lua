include( "shared.lua" );

// mats
local matbeam = Material( "tripmine_laser" );
local matpoint = Material( "sprites/gmdm_pickups/light" );

// init
function ENT:Initialize( )
	// point list
	self.PointList = {};
	self.LastClear = self.Entity:GetNetworkedBool("Clear");
	
	// active point
	self.ActivePoint = Vector( 0, 0, 0 );
	
	// boundry.
	self.Boundry = 64;
end

// calculate point
function ENT:CalculatePixelPoint( pos, emitterPos, fwd, right, up )
	// calculate point
	return emitterPos + ( up * pos.z ) + ( fwd * pos.x ) + ( right * pos.y );
end

// think
function ENT:Think( )
	// read point.
	local point = Vector(
		self.Entity:GetNetworkedFloat( "X" ),
		self.Entity:GetNetworkedFloat( "Y" ),
		self.Entity:GetNetworkedFloat( "Z" )
	);

	lastclear = self.Entity:GetNetworkedInt("Clear")
	if(lastclear != self.LastClear) then
		self.PointList = {}
		self.LastClear = lastclear
	end
	
	// did the point differ from active point?
	if( point != self.ActivePoint && self.Entity:GetNetworkedBool( "Active" ) ) then
		// fetch color.
		local _, _, _, a = self.Entity:GetColor();
	
		// store this point inside the point list
		local tempfaderate
		if (SinglePlayer()) then
			tempfaderate = math.Clamp( self.Entity:GetNetworkedFloat( "FadeRate" ), 0.1, 255 )
		else
			tempfaderate = math.Clamp( self.Entity:GetNetworkedFloat( "FadeRate" ), 10, 255 )
		end
		table.insert( self.PointList, { pos = self.ActivePoint, alpha = a, faderate = tempfaderate } );
		
		// store new active point
		self.ActivePoint = point;
		
	end
	
end

// draw
function ENT:Draw( )
	// render model
	self.Entity:DrawModel();
	
	// are we rendering?
	if( !self.Entity:GetNetworkedBool( "Active" ) ) then return; end
	
	// read emitter.
	local emitter = self.Entity:GetNetworkedEntity( "grid" );
	if( !emitter || !emitter:IsValid() ) then return; end
	
	// calculate emitter position.
	local fwd 	= emitter:GetForward();
	local right 	= emitter:GetRight();
	local up 	= emitter:GetUp();
	local pos 	= emitter:GetPos() + up * 64;
	local usegps = emitter:GetNetworkedBool( "UseGPS" )

	// draw beam?
	local drawbeam	= self.Entity:GetNetworkedBool( "ShowBeam" );
	
	// read point size
	local size	= self.Entity:GetNetworkedFloat( "PointSize" );
	local beamsize	= size * 0.25;
	
	// read color
	local r, g, b, a = self.Entity:GetColor();
	local color = Color( r, g, b, a );
	
	self.Entity:SetRenderBounds( Vector()*-8192, Vector()*8192 )	
	// calculate pixel point.
	local pixelpos
	if (usegps == true) then
		pixelpos = self.ActivePoint;
	else
		pixelpos = self:CalculatePixelPoint( self.ActivePoint, pos, fwd, right, up );
	end
	
	// draw active point - beam
	if( drawbeam ) then
		render.SetMaterial( matbeam );
		render.DrawBeam(
			self.Entity:GetPos(),
			pixelpos,
			beamsize,
			0, 1,
			color
		);
		
	end
	
	// draw active point - sprite
	render.SetMaterial( matpoint );
	render.DrawSprite(
		pixelpos,
		size,  size,
		color
	);
	
	
	// draw fading points.
	local point, lastpos, i = nil, pixelpos;
	for i = table.getn( self.PointList ), 1, -1 do
		// easy access
		local point = self.PointList[i];

		
		// I'm doing this here, to remove that extra loop in ENT:Think.
		// fade away
		point.alpha = point.alpha - point.faderate * FrameTime();
		
		// die?
		if( point.alpha <= 0 ) then
			table.remove( self.PointList, i );
			
			
		// WHY CAN'T LUA SUPPORT CONTINUE!?!?!!?
		else
			// calculate pixel point.
			local pixelpos
			if (usegps == true) then
				pixelpos = point.pos
			else
				pixelpos = self:CalculatePixelPoint( point.pos, pos, fwd, right, up );
			end
			
			// calculate color.
			local color = Color( r, g, b, point.alpha );
			
			// draw active point - beam
			if( drawbeam ) then
				render.SetMaterial( matbeam );
				render.DrawBeam(
					self.Entity:GetPos(),
					pixelpos,
					beamsize,
					0, 1,
					color
				);
				render.DrawBeam(
					lastpos,
					pixelpos,
					beamsize * 2,
					0, 1,
					color
				);
				lastpos = pixelpos;
				
			end
			
			// draw active point - sprite
			render.SetMaterial( matpoint );
			render.DrawSprite(
				pixelpos,
				size, size,
				color
			);
			
		end
		
	end
end

