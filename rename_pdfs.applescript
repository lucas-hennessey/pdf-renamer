set tool to (POSIX path of (path to me)) & "Contents/Resources/rename_pdfs"

try
	set srcFolder to choose folder with prompt "Step 1 of 2: Choose the folder that holds the PDFs to rename"
	set dstFolder to choose folder with prompt "Step 2 of 2: Choose the folder to move the renamed PDFs into"
on error number -128
	return
end try

set srcPath to POSIX path of srcFolder
set dstPath to POSIX path of dstFolder

if srcPath is dstPath then
	display dialog "The source and destination folders are the same. Please run again and pick two different folders." buttons {"OK"} default button "OK" with icon caution
	return
end if

try
	set report to do shell script quoted form of tool & " " & quoted form of srcPath & " " & quoted form of dstPath & " 2>/dev/null"
on error errMsg
	display dialog "Something went wrong:" & return & errMsg buttons {"OK"} default button "OK" with icon stop
	return
end try

set choice to button returned of (display dialog report buttons {"Open Destination", "OK"} default button "OK")
if choice is "Open Destination" then tell application "Finder" to open dstFolder
