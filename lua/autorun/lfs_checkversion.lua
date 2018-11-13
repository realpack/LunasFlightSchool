local CurrentVersion = 2

http.Fetch("https://github.com/Blu-x92/LunasFlightSchool", function(contents,size) 
	local LatestVersion = tonumber(string.match( contents, "%s*(%d+)\n%s*</span>\n%s*commits" )) or 0 
	
	if CurrentVersion >= LatestVersion then
		print("[LFS][simfphys planes] is up to date, Version: "..CurrentVersion)
	else
		print("[LFS][simfphys planes] a newer version is available! Version: "..LatestVersion..", You have Version: "..CurrentVersion)
		print("[LFS][simfphys planes] get the latest version at https://github.com/Blu-x92/LunasFlightSchool")
		
		if CLIENT then chat.AddText( Color( 255, 0, 0 ), "[LFS][simfphys planes] a newer version is available!" ) end
	end
end)
