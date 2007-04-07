include( "shared.lua" );

// mats
local matbeam = Material( "tripmine_laser" );
local matpoint = Material( "sprites/gmdm_pickups/light" );

// init
function ENT:Initialize( )
	// point list
	self.PointList = {};
	
	// active point
	self.ActivePoint = Vector( 0, 0, 0 );
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
	
	// did the point differ from active point?
	if( point != self.ActivePoint && self.Entity:GetNetworkedBool( "Display" ) ) then
		// fetch color.
		local _, _, _, a = self.Entity:GetColor();
	
		// store this point inside the point list
		table.insert( self.PointList, { pos = self.ActivePoint, alpha = a, faderate = self.Entity:GetNetworkedFloat( "Lifetime" ) } );
		
		// store new active point
		self.ActivePoint = point;
	end
	
	// Reset?
	local shouldreset = self.Entity:GetNetworkedBool( "Reset" )

	// fade the points away
	local i;
	for i = 1, table.getn( self.PointList ) do
		// easy access
		local pt = self.PointList[i];
		if( pt ) then
			// fade away
			pt.alpha = pt.alpha - pt.faderate * FrameTime();
			
			// die? (changed to add Reset input)
			if( (pt.alpha <= 0) || shouldreset ) then
				table.remove( self.PointList, i );
			end
			
		end
	end
end

// draw
function ENT:Draw( )
	// render model
	self.Entity:DrawModel();
	
	// are we rendering?
	if( !self.Entity:GetNetworkedBool( "Display" ) ) then return; end
	
	// read emitter.
	local emitter = self.Entity:GetNetworkedEntity( "grid" );
	if( !emitter || !emitter:IsValid() ) then return; end
	
	// calculate emitter position.
	local fwd 	= emitter:GetForward();
	local right 	= emitter:GetRight();
	local up 	= emitter:GetUp();
	local pos = emitter:GetPos() + up * 64;
	
	// read color
	local r, g, b, a = self.Entity:GetColor();
	local color = Color( r, g, b, a );
	
	// calculate pixel point.
	local pixelpos = self:CalculatePixelPoint( self.ActivePoint, pos, fwd, right, up );
	
	// draw active point - beam
	render.SetMaterial( matbeam );
	render.DrawBeam(
		self.Entity:GetPos(),
		pixelpos,
		1,
		0, 1,
		color
	);
	
	// draw active point - sprite
	render.SetMaterial( matpoint );
	render.DrawSprite(
		pixelpos,
		4, 4,
		color
	);
	
	
	// draw fading points.
	local point, lastpos = nil, pixelpos;
	for _, point in pairs( self.PointList ) do
		// calculate pixel point.
		local pixelpos = self:CalculatePixelPoint( point.pos, pos, fwd, right, up );
		
		// draw active point - beam
		render.SetMaterial( matbeam );
		render.DrawBeam(
			self.Entity:GetPos(),
			pixelpos,
			1,
			0, 1,
			Color( r, g, b, point.alpha )
		);
		render.DrawBeam(
			lastpos,
			pixelpos,
			2,
			0, 1,
			Color( r, g, b, point.alpha )
		);
		lastpos = pixelpos;
		
		// draw active point - sprite
		render.SetMaterial( matpoint );
		render.DrawSprite(
			pixelpos,
			4, 4,
			Color( r, g, b, point.alpha )
		);
		
	end
end

