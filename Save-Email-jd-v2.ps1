<#
.SYNOPSIS
This script will save emails in the .msg format from the Outlook Inbox and place them in a folder of your choosing.

.DESCRIPTION
Using this script will save emails to the path specified in the DestinationFolder parameter.  If you use the UnreadOnly switch, only unread emails will be saved.  Otherwise, all emails will be saved. The MarkRead switch will mark unread email as read, but can only be used with the UnreadOnly parameter.  The emails will be saved as .msg files and can be opened with Outlook.

.PARAMETER DestinationPath
Specifies the path to the destination folder where the emails will be saved

.PARAMETER UnreadOnly
If used, only unread emails will be saved.  If not, all emails will be saved.

.PARAMETER MarkRead
If used, will mark unread emails as read.  Can only be used with the UnreadOnly parameter.

.INPUTS
System.IO.DirectoryInfo.  Will bind the property FullName from a directory object to the DestinationPath parameter in the pipeline.

.OUTPUTS
None.  Save-Email.ps1 does not generate any output.

.EXAMPLE
The following command will save all the emails in the Inbox to the C:\Saved Emails\ folder

PS C:\> .\Save-Email.ps1 -DestinationPath 'C:\Saved Emails'

.EXAMPLE
The following command will save only the unread emails in the Inbox to the C:\Saved Emails\ folder

PS C:\> .\Save-Email.ps1 -DestinationPath 'C:\Saved Emails' -UnreadOnly

.EXAMPLE
The following command will save only the unread emails in the Inbox to the C:\Saved Emails\ folder and mark them as read

PS C:\> .\Save-Email.ps1 -DestinationPath 'C:\Saved Emails' -UnreadOnly -MarkRead

.EXAMPLE
This example demonstrates using the pipeline to send a DirectoryInfo object to the script in the pipeline

PS C:\> Get-ChildItem 'C:\Users' -Recurse | Where-Object {$_.Name -eq "Saved Emails"} | .\Save-Email.ps1

.NOTES
If you do not enter a value for the DestinationPath parameter on the command line, you will be prompted to enter a value after pressing <Enter>.  At this point, do not enclose the value with quotation marks even if the path includes spaces. 

.LINK
http://msdn.microsoft.com/en-us/library/microsoft.office.interop.outlook.application.aspx
http://blogs.technet.com/b/heyscriptingguy/archive/2011/05/26/use-powershell-to-data-mine-your-outlook-inbox.aspx
#>

#Binding for Common Parameters
# jd - What I believe this is doing (with Param) is setting up the command line initiation 
[CmdletBinding(DefaultParameterSetName="All")]

Param(    
    [Parameter(ParameterSetName="All")]
    [Parameter(Mandatory=$true,ParameterSetName="Unread")]
    [Switch]$UnreadOnly,

    [Parameter(ParameterSetName="Unread")]
    [Switch]$MarkRead
)

#Add Interop Assembly
Add-type -AssemblyName "Microsoft.Office.Interop.Outlook" | Out-Null

#Type declaration for Outlook Enumerations, Thank you Hey, Scripting Guy! blog for this demonstration
$olFolders = "Microsoft.Office.Interop.Outlook.olDefaultFolders" -as [type]
$olSaveType = "Microsoft.Office.Interop.Outlook.OlSaveAsType" -as [type]
$olClass = "Microsoft.Office.Interop.Outlook.OlObjectClass" -as [type]

#Add Outlook Com Object, MAPI namespace, and set folder to the Inbox
$outlook = New-Object -ComObject Outlook.Application
$namespace = $outlook.GetNameSpace("MAPI")
$folder = $namespace.getDefaultFolder($olFolders::olFolderInBox)

# Dictionary of program contacts to their respective program areas 
$name_dict = @{
"Sonia Becerra" = "pst";

"Edward Minter" = "ihw";

"Johnny Bowers" = "nsr";

"Adam Bullock" = "airei";

"Hoyt Henry" = "tierii";

"Stacey Dunahoo" = "lpst";

"R04RO" = "r04";

"R02RO" = "r02";

"Stuart Beckley" = "enf";

"Katherine Mckenzie" = "ww";

"CR-STORM" = "sw";

"Calen Roome" = "p2";

"Keiandre Mcgruder" = "tires";

"Teresa Etheredge" = "WWOL";

"Heather Podlipny" = "ihwca";

"Tan Nguyen" = "airop";

"Kelly Mackenzie" = "tax";

"R01RO" = "r01";

"R03RO" = "r03";

"PWSINVEN" = "pws";

"Patrick Kading" = "pws";

"Carmen Portillo" = "pws";

"Hannah Evans" = "pws";
}


#Iterate through each object in the chosen folder
foreach ($email in $folder.Items) {
    
    #Get email's subject, date, and SenderName
    [string]$subject = $email.Subject
    [string]$sentOn = $email.SentOn
    [string]$senderName = $email.SenderName
    [string]$body = $email.Body
    
    # use regex to find responses to merges
    $subject -match '.*RN Merge \d+'
    $subj_check =  $subject -match '.*RN Merge \d+'   

    # 
    if ($subj_check -eq "True") {



    # save the subject line text to a variable 
    $subj_line = $matches[0]
 
    # Extract just the MMDB in the subject line and assign it to mmdb_id 
    $subj_line -match '\d+'
    $mmdb_id = $matches[0]

# this will be the name of the file, $name_dict.$senderName should acess the PGM CD value stored in the dictionary
    if (($body -match "not") -Or ($body -match "deny")) {
	$filename = "jd-" + $mmdb_id + "-" + $name_dict.$senderName + "-denied.msg"

       # the ? here after defers is a regex character, meaning the s is optional! :D 
     }elseif ($body -match "defers?") {
		$filename = "jd-" + $mmdb_id + "-" + $name_dict.$senderName + "-defer.msg" 
     }elseif ($body -match "switch") {
		$filename = "jd-" + $mmdb_id + "-" + $name_dict.$senderName + "-switch_request.msg"
     }else { $filename = "jd-" + $mmdb_id + "-" + $name_dict.$senderName + "-concur.msg" 
}


    # Set up the regex to find the folder name ( this could probably just be the $mmdb_id ) 
    $folderRegex = "jd-" + $mmdb_id + "-+"

    # put all of the complete paths of the folder names into $files
    $files = Get-ChildItem '' | select -expand fullname

    # checks each path to see if it has the folderRegex, if true, the path it returns is stored as $unique_path	
    $unique_path = $files -match $folderRegex | Out-String
    # get rid of new line that Out-String produces 
    $unique_pathYes = $unique_path.replace("`n","\").replace("`r","")


    if ($files -match $folderRegex) {
 			$DestinationPath = $unique_pathYes
    }else {
			Write-Output("No Match")
    }

    $DestinationPath	


    #Combine destination path with file name
    $dest = $DestinationPath+$fileName

    $destYes = $dest.replace("`n","\").replace("`r","") 
    
    #Test if object is a MailItem
    if ($email.Class -eq $olClass::olMail) {
        
        #Test if UnreadOnly switch was used
        if ($UnreadOnly) {
            
            #Test if email is unread and save if true
            if ($email.Unread) {
                
                #Test if MarkRead switch was used and mark read
                if ($MarkRead) {
                    $email.Unread = $false
                }
                # the $olSaveType::olMSG is accessing the message object of the $olSaveType variable
			
                $email.SaveAs($destYes, $olSaveType::olMSG)
            }
        }
        #UnreadOnly switch not used, save all
        else {
            $email.SaveAs($destYes, $olSaveType::olMSG)
        }
    }
    
}
}

#Quit Outlook and release the ComObject and references
#This does not seem to work correctly in a script versus the command line
#and does not shut the process down like expected after reading the 
#TechNet article here:  http://technet.microsoft.com/en-us/library/ff730962.aspx
#Any help with this would be appreciated
$outlook.Quit()
Remove-Variable folder
Remove-Variable namespace
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($outlook) | Out-Null
Remove-Variable outlook
