--DO NOT EDIT OR REUPLOAD THIS FILE

simfphys = istable( simfphys ) and simfphys or {} -- lets check if the simfphys table exists. if not, create it!
simfphys.LFS = {} -- lets add another table for this project. We will be storing all our global functions and variables here. LFS means LunasFlightSchool

simfphys.LFS.VERSION = 43 -- note to self:  don't forget to update this

function simfphys.LFS.GetVersion()
	return simfphys.LFS.VERSION
end

local meta = FindMetaTable( "Player" )

function meta:lfsGetPlane()
	if not self:InVehicle() then return NULL end
	
	local Pod = self:GetVehicle()
	
	if not IsValid( Pod ) then return NULL end
	
	if Pod.LFSchecked == true then
		
		return Pod.LFSBaseEnt
		
	elseif Pod.LFSchecked == nil then
		
		local Parent = Pod:GetParent()
		
		if not IsValid( Parent ) then Pod.LFSchecked = false return NULL end
		
		if not Parent:GetClass():lower():StartWith( "lunasflightschool" ) or not Parent.LFS then Pod.LFSchecked = false return NULL end
		
		Pod.LFSchecked = true
		Pod.LFSBaseEnt = Parent
		
		return Parent
	else
		return NULL
	end
end

function meta:lfsGetAITeam()
	return self:GetNWInt( "lfsAITeam", 0 )
end

if SERVER then 
	function meta:lfsSetAITeam( nTeam )
		nTeam = nTeam or 0
		
		if self:lfsGetAITeam() ~= nTeam then
			self:PrintMessage( HUD_PRINTTALK, "[LFS] Your AI-Team has been updated to: Team "..nTeam )
		end
		
		self:SetNWInt( "lfsAITeam", nTeam )
	end
	
	util.AddNetworkString( "lfs_failstartnotify" )
	
	hook.Add( "PlayerLeaveVehicle", "!!LFS_Exit", function( ply, vehicle )
		local Pod = ply:GetVehicle()
		local Parent = ply:lfsGetPlane()
		
		if not IsValid( Pod ) or not IsValid( Parent ) then return end
		
		ply:lfsSetAITeam( Parent:GetAITEAM() )
		
		local ent = Pod
		local b_ent = Parent
		
		local Center = b_ent:LocalToWorld( b_ent:OBBCenter() )
		local vel = b_ent:GetVelocity()
		local radius = b_ent:BoundingRadius()
		local HullSize = Vector(18,18,0)
		local Filter1 = {ent,ply}
		local Filter2 = {ent,ply,b_ent}
		
		if vel:Length() > 250 then
			local pos = b_ent:GetPos()
			local dir = vel:GetNormalized()
			local targetpos = pos - dir *  (radius + 40)
			
			local tr = util.TraceHull( {
				start = Center,
				endpos = targetpos - Vector(0,0,10),
				maxs = HullSize,
				mins = -HullSize,
				filter = Filter2
			} )
			
			local exitpoint = tr.HitPos + Vector(0,0,10)
			
			if util.IsInWorld( exitpoint ) then
				ply:SetPos(exitpoint)
				ply:SetEyeAngles((pos - exitpoint):Angle())
			end
		else
			local pos = ent:GetPos()
			local targetpos = (pos + ent:GetRight() * 80)
			
			local tr1 = util.TraceLine( {
				start = targetpos,
				endpos = targetpos - Vector(0,0,100),
				filter = {}
			} )
			local tr2 = util.TraceHull( {
				start = targetpos,
				endpos = targetpos + Vector(0,0,80),
				maxs = HullSize,
				mins = -HullSize,
				filter = Filter1
			} )
			local traceto = util.TraceLine( {start = Center,endpos = targetpos,filter = Filter2} )
			
			local HitGround = tr1.Hit
			local HitWall = tr2.Hit or traceto.Hit
			
			local check0 = (HitWall == true or HitGround == false or util.IsInWorld( targetpos ) == false) and (pos - ent:GetRight() * 80) or targetpos
			local tr = util.TraceHull( {
				start = check0,
				endpos = check0 + Vector(0,0,80),
				maxs = HullSize,
				mins = -HullSize,
				filter = Filter1
			} )
			local traceto = util.TraceLine( {start = Center,endpos = check0,filter = Filter2} )
			local HitWall = tr.Hit or traceto.hit
			
			local check1 = (HitWall == true or HitGround == false or util.IsInWorld( check0 ) == false) and (pos + ent:GetUp() * 100) or check0
			
			local tr = util.TraceHull( {
				start = check1,
				endpos = check1 + Vector(0,0,80),
				maxs = HullSize,
				mins = -HullSize,
				filter = Filter1
			} )
			local traceto = util.TraceLine( {start = Center,endpos = check1,filter = Filter2} )
			local HitWall = tr.Hit or traceto.hit
			local check2 = (HitWall == true or util.IsInWorld( check1 ) == false) and (pos - ent:GetUp() * 100) or check1
			
			local tr = util.TraceHull( {
				start = check2,
				endpos = check2 + Vector(0,0,80),
				maxs = HullSize,
				mins = -HullSize,
				filter = Filter1
			} )
			local traceto = util.TraceLine( {start = Center,endpos = check2,filter = Filter2} )
			local HitWall = tr.Hit or traceto.hit
			local check3 = (HitWall == true or util.IsInWorld( check2 ) == false) and b_ent:LocalToWorld( Vector(0,radius,0) ) or check2
			
			local tr = util.TraceHull( {
				start = check3,
				endpos = check3 + Vector(0,0,80),
				maxs = HullSize,
				mins = -HullSize,
				filter = Filter1
			} )
			local traceto = util.TraceLine( {start = Center,endpos = check3,filter = Filter2} )
			local HitWall = tr.Hit or traceto.hit
			local check4 = (HitWall == true or util.IsInWorld( check3 ) == false) and b_ent:LocalToWorld( Vector(0,-radius,0) ) or check3
			
			local tr = util.TraceHull( {
				start = check4,
				endpos = check4 + Vector(0,0,80),
				maxs = HullSize,
				mins = -HullSize,
				filter = Filter1
			} )
			local traceto = util.TraceLine( {start = Center,endpos = check4,filter = Filter2} )
			local HitWall = tr.Hit or traceto.hit
			local exitpoint = (HitWall == true or util.IsInWorld( check4 ) == false) and b_ent:LocalToWorld( Vector(0,0,0) ) or check4
			
			if util.IsInWorld( exitpoint ) then
				ply:SetPos(exitpoint)
				ply:SetEyeAngles((pos - exitpoint):Angle())
			end
		end
	end )
end

http.Fetch("https://github.com/Blu-x92/LunasFlightSchool", function(contents,size) 
	local LatestVersion = tonumber( string.match( contents, "%s*(%d+)\n%s*</span>\n%s*commits" ) ) or 0  -- i took this from acf. I hope they don't mind
	
	if simfphys.LFS.GetVersion() >= LatestVersion then
		print("[LFS] is up to date, Version: "..simfphys.LFS.GetVersion())
	else
		print("[LFS] a newer version is available! Version: "..LatestVersion..", You have Version: "..simfphys.LFS.GetVersion())
		print("[LFS] get the latest version at https://github.com/Blu-x92/LunasFlightSchool")
		
		if CLIENT then 
			timer.Simple(10, function() 
				chat.AddText( Color( 255, 0, 0 ), "[LFS] a newer version is available!" )
				surface.PlaySound( "lfs/notification.ogg" ) 
			end)
		end
	end
end)

if CLIENT then
	local HintPlayerAboutHisFuckingIncompetence = true
	local smTran = 0

	 hook.Add( "CalcView", "LFS_calcview", function(ply, pos, angles, fov)
		HintPlayerAboutHisFuckingIncompetence = false
	 
		if ply:GetViewEntity() ~= ply then return end
		
		local Pod = ply:GetVehicle()
		local Parent = ply:lfsGetPlane()
		
		if not IsValid( Pod ) or not IsValid( Parent ) then return end
		
		smTran = smTran + ((ply:KeyDown( IN_WALK ) and 0 or 0.8) - smTran) * FrameTime() * 10
		
		local view = {}
		view.origin = pos
		view.fov = fov
		view.drawviewer = true
		view.angles = ((Parent:GetForward() * smTran + ply:EyeAngles():Forward()) * 0.5):Angle()
		view.angles.r = 0
		
		if Parent:GetDriverSeat() ~= Pod then
			view.angles = ply:EyeAngles()
		end
		
		if not Pod:GetThirdPersonMode() then
			
			view.drawviewer = false
			
			return view
		end
		
		--local mn, mx = Parent:GetRenderBounds()
		--local radius = ( mn - mx ):Length()
		local radius = 550
		radius = radius + radius * Pod:GetCameraDistance()
		
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

	local LFS_TIME_NOTIFY = 0
	net.Receive( "lfs_failstartnotify", function( len )
		surface.PlaySound( "common/wpn_hudon.wav" )
		LFS_TIME_NOTIFY = CurTime() + 2
	end )

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
		
		local startpos =  Parent:GetRotorPos()
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
		if Len > 34 then
			local FailStart = LFS_TIME_NOTIFY > CurTime()
			if FailStart then
				surface.SetDrawColor( 255, 0, 0, math.abs( math.cos( CurTime() * 10 ) ) * 255 )
			end
			
			if not ply:KeyDown( IN_WALK ) or FailStart then
				surface.DrawLine( HitPlane.x + Dir.x * 10, HitPlane.y + Dir.y * 10, HitPilot.x - Dir.x * 34, HitPilot.y- Dir.y * 34 )
			end
		end
		
		surface.SetDrawColor( 255, 255, 255, 255 )
		
		DrawCircle( HitPlane.x, HitPlane.y, 10 )
		surface.DrawLine( HitPlane.x + 10, HitPlane.y, HitPlane.x + 20, HitPlane.y ) 
		surface.DrawLine( HitPlane.x - 10, HitPlane.y, HitPlane.x - 20, HitPlane.y ) 
		surface.DrawLine( HitPlane.x, HitPlane.y + 10, HitPlane.x, HitPlane.y + 20 ) 
		surface.DrawLine( HitPlane.x, HitPlane.y - 10, HitPlane.x, HitPlane.y - 20 ) 
		
		DrawCircle( HitPilot.x, HitPilot.y, 34 )
		
		
	end )
end