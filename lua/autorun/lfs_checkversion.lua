simfphys = istable( simfphys ) and simfphys or {} -- lets check if the simfphys table exists. if not, create it!
simfphys.LFS = {} -- lets add another table for this project. We will be storing all our global functions and variables here. LFS means LunasFlightSchool

simfphys.LFS.VERSION = 3 -- don't forget to update this

function simfphys.LFS.GetVersion()
	return simfphys.LFS.VERSION
end

http.Fetch("https://github.com/Blu-x92/LunasFlightSchool", function(contents,size) 
	local LatestVersion = tonumber( string.match( contents, "%s*(%d+)\n%s*</span>\n%s*commits" ) ) or 0  -- i took this from acf. I hope they don't mind
	
	if simfphys.LFS.GetVersion() >= LatestVersion then
		print("[LFS][simfphys planes] is up to date, Version: "..simfphys.LFS.GetVersion())
	else
		print("[LFS][simfphys planes] a newer version is available! Version: "..LatestVersion..", You have Version: "..simfphys.LFS.GetVersion())
		print("[LFS][simfphys planes] get the latest version at https://github.com/Blu-x92/LunasFlightSchool")
		
		if CLIENT then chat.AddText( Color( 255, 0, 0 ), "[LFS][simfphys planes] a newer version is available!" ) end
	end
end)
