local HintPlayerAboutHisFuckingIncompetence = true
local smTran = 0

 hook.Add( "CalcView", "LFS_calcview", function(ply, pos, angles, fov)
	HintPlayerAboutHisFuckingIncompetence = false
 
	if ply:GetViewEntity() ~= ply then return end
	
	local Pod = ply:GetVehicle()
	local Parent = ply:lfsGetPlane()
	
	if not IsValid( Pod ) or not IsValid( Parent ) then return end
	
	if Parent:GetDriverSeat() ~= Pod then return end
	
	smTran = smTran + ((ply:KeyDown( IN_WALK ) and 0 or 0.8) - smTran) * FrameTime() * 10
	
	local view = {}
	view.origin = pos
	view.fov = fov
	view.drawviewer = true
	view.angles = ((Parent:GetForward() * smTran + ply:EyeAngles():Forward()) * 0.5):Angle()
	view.angles.r = 0
	
	if not Pod:GetThirdPersonMode() then
		
		view.drawviewer = false
		
		return view
	end
	
	local mn, mx = Parent:GetRenderBounds()
	local radius = ( mn - mx ):Length()
	local radius = radius + radius * Pod:GetCameraDistance()
	
	local TargetOrigin = view.origin - view.angles:Forward() * radius  + view.angles:Up() * radius * 0.2
	local WallOffset = 4

	local tr = util.TraceHull( {
		start = view.origin,
		endpos = TargetOrigin,
		filter = function( e )
			local c = e:GetClass()
			local collide = not c:StartWith( "prop_physics" ) and not c:StartWith( "prop_dynamic" ) and not c:StartWith( "prop_ragdoll" ) and not e:IsVehicle() and not c:StartWith( "gmod_" ) and not c:StartWith( "player" ) and not c:lower():StartWith( "lunasflightschool" )
			
			return collide
		end,
		mins = Vector( -WallOffset, -WallOffset, -WallOffset ),
		maxs = Vector( WallOffset, WallOffset, WallOffset ),
	} )
	
	view.origin = tr.HitPos
	
	if tr.Hit and not tr.StartSolid then
		view.origin = view.origin + tr.HitNormal * WallOffset
	end

	return view
end )

local function DrawCircle( X, Y, radius )
	local segmentdist = 360 / ( 2 * math.pi * radius / 2 )
	
	for a = 0, 360 - segmentdist, segmentdist do
		surface.DrawLine( X + math.cos( math.rad( a ) ) * radius, Y - math.sin( math.rad( a ) ) * radius, X + math.cos( math.rad( a + segmentdist ) ) * radius, Y - math.sin( math.rad( a + segmentdist ) ) * radius )
		
		surface.DrawLine( X + math.cos( math.rad( a ) ) * radius, Y - math.sin( math.rad( a ) ) * radius, X + math.cos( math.rad( a + segmentdist ) ) * radius, Y - math.sin( math.rad( a + segmentdist ) ) * radius )
	end
end

surface.CreateFont( "LFS_FONT", {
	font = "Verdana",
	extended = false,
	size = 20,
	weight = 2000,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = true,
	additive = false,
	outline = false,
} )

local MinZ = 0
local function PaintPlaneHud( ent )

	if not IsValid( ent ) then return end
	
	local X = ScrW()
	local Y = ScrH()
	
	local vel = ent:GetVelocity():Length()
	
	local Throttle = math.max( math.Round( ((ent:GetRPM() - ent:GetIdleRPM()) / (ent:GetMaxRPM() - ent:GetIdleRPM())) * 100, 0) ,0)
	local Col = Throttle <= 100 and Color(255,255,255,255) or Color(255,0,0,255)
	draw.SimpleText( "THR", "LFS_FONT", 10, 10, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
	draw.SimpleText( Throttle.."%" , "LFS_FONT", 120, 10, Col, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
	
	local speed = math.Round(vel * 0.09144,0)
	draw.SimpleText( "IAS", "LFS_FONT", 10, 35, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
	draw.SimpleText( speed.."km/h" , "LFS_FONT", 120, 35, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
	
	local ZPos = math.Round( ent:GetPos().z,0)
	if (ZPos + MinZ)< 0 then MinZ = math.abs(ZPos) end
	draw.SimpleText( "ALT", "LFS_FONT", 10, 60, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
	draw.SimpleText( math.Round( (ent:GetPos().z + MinZ) * 0.0254,0).."m" , "LFS_FONT", 120, 60, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
	
	if ent:GetMaxAmmoPrimary() > -1 then
		draw.SimpleText( "PRI", "LFS_FONT", 10, 85, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
		draw.SimpleText( ent:GetAmmoPrimary(), "LFS_FONT", 120, 85, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
	end
	
	if ent:GetMaxAmmoSecondary() > -1 then
		draw.SimpleText( "SEC", "LFS_FONT", 10, 110, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
		draw.SimpleText( ent:GetAmmoSecondary(), "LFS_FONT", 120, 110, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
	end
end

local NextFind = 0
local AllPlanes = {}

local function PaintPlaneIdentifier( ent )
	if NextFind < CurTime() then
		NextFind = CurTime() + 3
		AllPlanes = ents.FindByClass( "lunasflightschool_*" )
	end
	
	local MyPos = ent:GetPos()
	local MyTeam = ent:GetAITEAM()
	
	for _, v in pairs( AllPlanes ) do
		if IsValid( v ) then
			if v ~= ent then
				if isvector( v.SeatPos ) then
					local rPos = v:LocalToWorld( v.SeatPos )
					local Pos = rPos:ToScreen()
					local Size = 60
					local Dist = (MyPos - rPos):Length()
					
					if Dist < 13000 then
						local Alpha = math.max(255 - Dist * 0.015,0)
						local Team = v:GetAITEAM()
						if Team ~= MyTeam or Team == 0 then
							surface.SetDrawColor( 255, 0, 0, Alpha )
						else
							surface.SetDrawColor( 0, 127, 255, Alpha )
						end
						
						surface.DrawLine( Pos.x - Size, Pos.y + Size, Pos.x + Size, Pos.y + Size )
						
						surface.DrawLine( Pos.x - Size, Pos.y - Size, Pos.x - Size, Pos.y + Size )
						
						surface.DrawLine( Pos.x + Size, Pos.y - Size, Pos.x + Size, Pos.y + Size )
						surface.DrawLine( Pos.x - Size, Pos.y - Size, Pos.x + Size, Pos.y - Size )
					end
				end
			end
		end
	end
end

hook.Add( "HUDPaint", "LFS_crosshair", function()
	local ply = LocalPlayer()
	
	if ply:GetViewEntity() ~= ply then return end
	
	local Pod = ply:GetVehicle()
	local Parent = ply:lfsGetPlane()
	
	if not IsValid( Pod ) or not IsValid( Parent ) then return end
	
	if Parent:GetDriverSeat() ~= Pod then return end
	
	if HintPlayerAboutHisFuckingIncompetence then
		if not Parent.ERRORSOUND then
			surface.PlaySound( "error.wav" )
			Parent.ERRORSOUND = true
		end
		
		local X = ScrW()
		local Y = ScrH()
		local HintCol = Color(255,0,0, 255 )
		
		surface.SetDrawColor( 0, 0, 0, 255 )
		surface.DrawRect( 0, 0, X, Y ) 
		surface.SetDrawColor( 255, 255, 255, 255 )
		
		draw.SimpleText( "OOPS! SOMETHING WENT WRONG :( ", "LFS_FONT", X * 0.5, Y * 0.5 - 40, HintCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		draw.SimpleText( "ONE OF YOUR ADDONS IS BREAKING THE CALCVIEW HOOK. PLANES WILL NOT BE USEABLE", "LFS_FONT", X * 0.5, Y * 0.5 - 20, HintCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		draw.SimpleText( "HOW TO FIX?", "LFS_FONT", X * 0.5, Y * 0.5 + 20, HintCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		draw.SimpleText( "DISABLE ALL ADDONS THAT COULD POSSIBLY MESS WITH THE CAMERA-VIEW", "LFS_FONT", X * 0.5, Y * 0.5 + 40, HintCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		draw.SimpleText( "(THIRDPERSON ADDONS OR SIMILAR)", "LFS_FONT", X * 0.5, Y * 0.5 + 60, HintCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		
		draw.SimpleText( ">>PRESS YOUR USE-KEY TO LEAVE THE VEHICLE & HIDE THIS MESSAGE<<", "LFS_FONT", X * 0.5, Y * 0.5 + 120, Color(255,0,0, math.abs( math.cos( CurTime() ) * 255) ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		
		return
	end
	
	PaintPlaneHud(Parent)
	PaintPlaneIdentifier(Parent)
	
	local startpos =  Parent:LocalToWorld( Vector(170,0,75) ) 
	local TracePlane = util.TraceLine( {
		start = startpos,
		endpos = (startpos + Parent:GetForward() * 50000),
		filter = function( e )
			local collide = e ~= Parent
			
			return collide
		end
	} )
	
	local TracePilot = util.TraceLine( {
		start = startpos,
		endpos = (startpos + ply:EyeAngles():Forward() * 50000),
		filter = function( e )
			local collide = e ~= Parent
			
			return false
		end
	} )
	
	local HitPlane = TracePlane.HitPos:ToScreen()
	local HitPilot = TracePilot.HitPos:ToScreen()

	local Sub = Vector(HitPilot.x,HitPilot.y,0) - Vector(HitPlane.x,HitPlane.y,0)
	local Len = Sub:Length()
	local Dir = Sub:GetNormalized()
	surface.SetDrawColor( 255, 255, 255, 100 )
	if Len > 34 and not ply:KeyDown( IN_WALK ) then
		surface.DrawLine( HitPlane.x + Dir.x * 10, HitPlane.y + Dir.y * 10, HitPilot.x - Dir.x * 34, HitPilot.y- Dir.y * 34 )
	end
	
	surface.SetDrawColor( 255, 255, 255, 255 )
	
	DrawCircle( HitPlane.x, HitPlane.y, 10 )
	surface.DrawLine( HitPlane.x + 10, HitPlane.y, HitPlane.x + 20, HitPlane.y ) 
	surface.DrawLine( HitPlane.x - 10, HitPlane.y, HitPlane.x - 20, HitPlane.y ) 
	surface.DrawLine( HitPlane.x, HitPlane.y + 10, HitPlane.x, HitPlane.y + 20 ) 
	surface.DrawLine( HitPlane.x, HitPlane.y - 10, HitPlane.x, HitPlane.y - 20 ) 
	
	DrawCircle( HitPilot.x, HitPilot.y, 34 )
	
	
end )
