local RT_CACHE_SIZE = 3

//
// Create rendertarget cache
//
if (!RenderTargetCache) then
	RenderTarget_NextID = 4

	RenderTargetCache = {}
	for i=1,RT_CACHE_SIZE do
		RenderTargetCache[i] = GetRenderTarget("WireGPU_RT_"..i, 512, 512)
	end
	RenderTargetCacheSize = RT_CACHE_SIZE
end

//
// Create basic vital fonts
//
surface.CreateFont("lucida console", 20, 800, true, false, "WireGPU_ConsoleFont")

//
// Create screen textures and materials
//
WireGPU_matScreen 	= Material("models\duckeh\buttons\0")
WireGPU_texScreen	= surface.GetTextureID("models\duckeh\buttons\0")

//
// Rendertarget cache management
//
function WireGPU_NeedRenderTarget()
	if (RenderTargetCache[RenderTargetCacheSize]) then
		print("Render target cache = taken from "..RenderTargetCacheSize)

		RenderTargetCacheSize = RenderTargetCacheSize - 1
		return RenderTargetCache[RenderTargetCacheSize+1]
	else
		RenderTargetCacheSize = RenderTargetCacheSize + 1
		RenderTargetCache[RenderTargetCacheSize] = GetRenderTarget("WireGPU_RT_"..RenderTarget_NextID, 512, 512)
		RenderTarget_NextID = RenderTarget_NextID + 1

		print("Render target cache = created new into "..RenderTargetCacheSize)
		return RenderTargetCache[RenderTargetCacheSize]
	end
end

function WireGPU_ReturnRenderTarget(rt)
 	RenderTargetCacheSize = RenderTargetCacheSize + 1
	RenderTargetCache[RenderTargetCacheSize] = rt
	print("Render target cache = restored into "..RenderTargetCacheSize)
end

//
// Misc helper functions
//
function WireGPU_DrawScreen(x,y,w,h,rotation,scale)
	vertex = {}

	//Generate vertex data
	vertex[1] = {}
	vertex[1]["x"] = x
	vertex[1]["y"] = y
	vertex[1]["u"] = 0-scale
	vertex[1]["v"] = 0-scale

	vertex[2] = {}
	vertex[2]["x"] = x+w
	vertex[2]["y"] = y
	vertex[2]["u"] = 1+scale
	vertex[2]["v"] = 0-scale

	vertex[3] = {}
	vertex[3]["x"] = x+w
	vertex[3]["y"] = y+h
	vertex[3]["u"] = 1+scale
	vertex[3]["v"] = 1+scale

	vertex[4] = {}
	vertex[4]["x"] = x
	vertex[4]["y"] = y+h
	vertex[4]["u"] = 0-scale
	vertex[4]["v"] = 1+scale

	//Rotation
	if (rotation == 1) then
		vertex[2]["u"] = 0-scale
		vertex[2]["v"] = 0-scale
		vertex[3]["u"] = 1+scale
		vertex[3]["v"] = 0-scale
		vertex[4]["u"] = 1+scale
		vertex[4]["v"] = 1+scale
		vertex[1]["u"] = 0-scale
		vertex[1]["v"] = 1+scale
	end

	if (rotation == 2) then
		vertex[3]["u"] = 0-scale
		vertex[3]["v"] = 0-scale
		vertex[4]["u"] = 1+scale
		vertex[4]["v"] = 0-scale
		vertex[1]["u"] = 1+scale
		vertex[1]["v"] = 1+scale
		vertex[2]["u"] = 0-scale
		vertex[2]["v"] = 1+scale
	end

	if (rotation == 3) then
		vertex[4]["u"] = 0-scale
		vertex[4]["v"] = 0-scale
		vertex[1]["u"] = 1+scale
		vertex[1]["v"] = 0-scale
		vertex[2]["u"] = 1+scale
		vertex[2]["v"] = 1+scale
		vertex[3]["u"] = 0-scale
		vertex[3]["v"] = 1+scale
	end

	surface.DrawPoly(vertex)
end

