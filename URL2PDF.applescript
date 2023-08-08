######################################################################
# URL2PDF
#
# Applet (Double-click): Retrieve the frontmost Safari tabs URL & page title
# 	¥ On OS X 10.9 or higher, Notification Center is used for status messages, else standard display dialogs
#	¥ Uses the Safari download folder as default target; fallback: current users Desktop
#	
# 
#
# 2015-04-25
# Timo Kahle
#
# Changes
#
# v1.0 (2015-04-22)
# o Initial version
#
#
# v1.0.1 (2015-04-25)
# + Added Check if wkhtmltopdf is installed
# + Added option to open wkhtmltopdf homepage in Safari to download it, if it is not installed
# + Added dialog texts
# + Unified constant names with all capital characters
# + Extended IsValidMinOS() for more flexibility
# + Added check if Safari is running
#
#
# v1.1.0 (2015-04-25)
# o Updated identification string to net.tk.URL2PDF
# + Refactored functions
# 	+ Added AskForUpdateDownload()
# 	+ Added OpenURLInBrowser()
# 	+ Added GetURLDetailsFromSafari()
#		+ Added IsInstalledComponent()
# + 
#
#
# ToDo
#
# + Add option to enter a URL manually
# + Add option to Convert supported files (URL, webarchive, HTM, HTML) when used as a Droplet
# + Use browser set as default in Safari preferences as default for URL parsing and downloading
#   wkhtmltopdf if missing
# o Componentarize functions for enhanced flexibility and maintainability
# 
#
######################################################################

# Environment
property APP_ICON : "applet.icns"
property APP_NAME : "URL2PDF"
property APP_VERSION : "1.1.0"
property TIMEOUT_SEC : 3600 -- 60 minutes

# Environment
property CMD_DOWNLOADEFAULT : "cd ~/Desktop/ && "
property CMD_DOWNLOADFOLDER : "defaults read com.apple.Safari DownloadsPath"
property CMD_GETPDF : "/usr/local/bin/wkhtmltopdf"
property MIN_OS_VERSION : "10.9"
property URL_WKHTMLTOPDF_DOWNLOAD : "http://wkhtmltopdf.org"
property DEFAULT_BROWSER : "Safari"

# UI texts
property APP_DETAILS : APP_NAME & " " & APP_VERSION
property DLG_TITLE_ERROR : "ERROR"
property DLG_MSG_ERROR : "An error occurred."
property DLG_MSG_SUCCESS : "Finished downloading."
property DLG_MSG_OS_UNSUPPORTED : "Your OS X version is not supported. You need at least OS X 10.9 to use this app."
property DLG_MSG_WKHTMLTOPDF_MISSING : "The required external component wkhtmltopdf is not found. Probably it is not installed. Click 'DOWNLOAD' to open wkhtmltopdf's homepage for download or 'QUIT' to quit the application."
property DLG_MSG_DEF_BROWSER_NOT_RUNNING : "Your default browser is not running. Start your browser and try again."
property DLG_MSG_ENTER_TITLE : "Enter the PDF title"


# Applet
on run
	set dlgIcon to (path to resource APP_ICON)
	
	
	# Check if wkhtmltopdf is installed
	if IsInstalledComponent(CMD_GETPDF) is false then
		if AskForUpdateDownload(URL_WKHTMLTOPDF_DOWNLOAD, dlgIcon) is false then
			# User cancelled and we cannot continue
			return
		end if
	end if
	
	
	# Check minimum supported OS X version
	if IsValidMinOS(MIN_OS_VERSION) is false then
		# Handle non-supported OS
		display dialog DLG_MSG_OS_UNSUPPORTED with title DLG_TITLE_ERROR buttons {"OK"} default button {"OK"} with icon dlgIcon
		return
	end if
	
	
	# Get and set the Download folder location
	set theDownloadFolder to GetCommandResults(CMD_DOWNLOADFOLDER)
	set theDownloadTarget to "cd " & theDownloadFolder & " && "
	
	
	# Check if Safari is running
	if isRunningProcess(DEFAULT_BROWSER) is false then
		display dialog DLG_MSG_DEF_BROWSER_NOT_RUNNING with title APP_DETAILS with icon dlgIcon buttons {"OK"} default button {"OK"} cancel button {"OK"}
		return
	end if
	
	set myURLError to aError of GetURLDetailsFromSafari()
	if myURLError is "0" then
		set myURL to aURL of GetURLDetailsFromSafari()
		set myURLTitle to aTitle of GetURLDetailsFromSafari()
	end if
	
	# Exchange invalid characters in theTitle
	set theName to the text returned of (display dialog DLG_MSG_ENTER_TITLE default answer myURLTitle buttons {"CANCEL", "OK"} default button {"OK"} with icon dlgIcon cancel button {"CANCEL"})
	
	# Check if pdf extension is already given and avoid duplicating it
	if theName contains ".pdf" then
		set theCMD to CMD_GETPDF & " " & (quoted form of myURL) & " " & (quoted form of (theDownloadFolder & "/" & myURLTitle))
	else
		set theCMD to CMD_GETPDF & " " & (quoted form of myURL) & " " & (quoted form of (theDownloadFolder & "/" & myURLTitle)) & ".pdf"
	end if
	#display alert "myURLTitle: " & myURLTitle & return & return & "DEBUG: theCMD: " & theCMD
	
	# Call Download functionality
	set theResult to ExecCommand(theCMD)
	
	# Inform about success or failure of command execution
	if theResult is not "" then
		if SupportsNotificationCenter() is true then
			# Message in Notification Center
			display notification theResult with title DLG_TITLE_ERROR
		else
			display dialog theResult & return & return & theResult with title DLG_TITLE_ERROR buttons {"OK"} default button {"OK"} with icon dlgIcon
		end if
	else
		if SupportsNotificationCenter() is true then
			# Message in Notification Center
			display notification DLG_MSG_SUCCESS with title APP_DETAILS
		else
			display dialog DLG_MSG_SUCCESS & return & return with title APP_DETAILS buttons {"OK"} default button {"OK"}
		end if
	end if
	
end run

######################################################################
######################################################################


# Run a command without admin privileges
on ExecCommand(theCMD)
	set theError to ""
	#display alert "ExecCommand: Would now do: " & theCMD & " " & theFile & return & return with title APP_DETAILS
	try
		set returnValue to do shell script (theCMD)
	on error errMsg
		return errMsg
	end try
end ExecCommand


# Run a single command without admin privileges
on GetCommandResults(theCMD)
	set theError to ""
	#display alert "ExecCommand: Would now do: " & theCMD & " " & theFile & return & return with title APP_DETAILS
	try
		set returnValue to do shell script (theCMD)
	on error errMsg
		return errMsg
	end try
end GetCommandResults


# Check if minimum required OS X version is running
on IsValidMinOS(minVersion)
	set strOSXVersion to system version of (system info)
	considering numeric strings
		#set IsMavericks to strOSXVersion ³ "10.9"
		set IsSupportedMinOS to strOSXVersion is greater than or equal to minVersion
	end considering
	
	return IsSupportedMinOS
end IsValidMinOS


# Check if minimum required OS X version is running
on IsMinOS109()
	set strOSXVersion to system version of (system info)
	considering numeric strings
		#set IsMavericks to strOSXVersion ³ "10.9"
		set IsSupportedMinOS to strOSXVersion is greater than or equal to "10.9"
	end considering
	
	return IsSupportedMinOS
end IsMinOS109


# Check if a process is running
on isRunningProcess(theProcess)
	tell application "System Events"
		set processList to name of every process
		if theProcess is in processList then
			return true
		else
			return false
		end if
	end tell
end isRunningProcess


# Check if native AppleScript Progress is supported (min. Yosemite, 10.10)
on SupportsNativeProgress()
	set strOSXVersion to system version of (system info)
	considering numeric strings
		#set IsMavericks to strOSXVersion ³ "10.10"
		set IsSupportedMinOS to strOSXVersion is greater than or equal to "10.10"
	end considering
	
	return IsSupportedMinOS
end SupportsNativeProgress


# Check if Notification Center is supported (min. Mavericks 10.9)
on SupportsNotificationCenter()
	set strOSXVersion to system version of (system info)
	considering numeric strings
		#set IsMavericks to strOSXVersion ³ "10.9"
		set IsSupportedMinOS to strOSXVersion is greater than or equal to "10.9"
	end considering
	
	return IsSupportedMinOS
end SupportsNotificationCenter



# Retrieve the OS X version
on GetOSXVersion()
	set os_version to do shell script "sw_vers -productVersion"
	return os_version as text
end GetOSXVersion


# Ask for update download
on AskForUpdateDownload(aComponent, aIcon)
	set downloadComponent to the button returned of (display dialog DLG_MSG_REQUIRED_COMPONENT_MISSING with title DLG_TITLE_ERROR buttons {BTN_TEXT_QUIT, BTN_TEXT_DOWNLOAD} default button {BTN_TEXT_DOWNLOAD} cancel button {BTN_TEXT_QUIT} with icon aIcon)
	if downloadComponent as text is BTN_TEXT_DOWNLOAD then
		OpenURLInBrowser(aComponent, DEFAULT_BROWSER)
	end if
	return
end AskForUpdateDownload



# Open a URL
on OpenURLInBrowser(aURL, aBrowser)
	tell application aBrowser
		activate
		open location aURL
	end tell
end OpenURLInBrowser



# Get URL from the browser
on GetURLDetailsFromSafari()
	try
		tell application "Safari"
			set theTitle to name of window 1
			set theURL to URL of document 1
		end tell
	on error
		return {aError:"No URL"}
	end try
	return {aError:"0", aTitle:theTitle, aURL:theURL}
end GetURLDetailsFromSafari


# Check if a specified component is installed
on IsInstalledComponent(aComponent)
	tell application "Finder"
		if not (exists aComponent as POSIX file) then
			return false
		else
			return true
		end if
	end tell
end IsInstalledComponent