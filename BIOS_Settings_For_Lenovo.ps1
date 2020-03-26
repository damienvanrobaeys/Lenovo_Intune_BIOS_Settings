Param
(
	[string]$MyPassword,	
	[string]$Language		
)				

$SystemRoot = $env:SystemRoot
$Log_File = "$SystemRoot\Debug\Lenovo_BIOS_Settings.log" 
If(test-path $Log_File)
	{
		remove-item $Log_File -force
	}
new-item $Log_File -type file -force

Function Write_Log
	{
	param(
	$Message_Type, 
	$Message
	)
		$MyDate = "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)  
		Add-Content $Log_File  "$MyDate - $Message_Type : $Message"  
	} 
  
Write_Log -Message_Type "INFO" -Message "The 'Set BIOS settings for Lenovo' process starts"  

$Exported_CSV = ".\BIOS_Settings.csv"																																			
$Get_CSV_Content = Import-CSV $Exported_CSV  -Delimiter ";"				

$Script:IsPasswordSet = (gwmi -Class Lenovo_BiosPasswordSettings -Namespace root\wmi).PasswordState					
If (($IsPasswordSet -eq 1) -or ($IsPasswordSet -eq 2) -or ($IsPasswordSet -eq 3))
	{
		Write_Log -Message_Type "INFO" -Message "A password is configured"  
		If($MyPassword -eq "")
			{
				Write_Log -Message_Type "WARNING" -Message "No password has been sent to the script"  	
				Break
			}
		ElseIf($Language -eq "")
			{
				Write_Log -Message_Type "WARNING" -Message "No language has been sent to the script"  	
				Write_Log -Message_Type "WARNING" -Message "The default language will be US" 
				$Script:Language = 'US'
			}			
	}	
	
	
$bios = gwmi -class Lenovo_SetBiosSetting -namespace root\wmi 
ForEach($Settings in $Get_CSV_Content)
	{
		$MySetting = $Settings.Setting
		$NewValue = $Settings.Value		
		
		Write_Log -Message_Type "INFO" -Message "Change to do: $MySetting - $NewValue"  
	
		If (($IsPasswordSet -eq 1) -or ($IsPasswordSet -eq 2) -or ($IsPasswordSet -eq 3))
			{					
				$Execute_Change_Action = $bios.SetBiosSetting("$MySetting,$NewValue,$MyPassword,ascii,$Language")								
				$Change_Return_Code = $Execute_Change_Action.return				
				If(($Change_Return_Code) -eq "Success")        				
					{
						Write_Log -Message_Type "INFO" -Message "New value for $MySetting is $NewValue"  
						Write_Log -Message_Type "SUCCESS" -Message "The setting has been setted"  						
					}
				Else
					{
						Write_Log -Message_Type "ERROR" -Message "Can not change setting $MySetting (Return code $Change_Return_Code)"  						
					}
			}
		Else
			{
				$Execute_Change_Action = $BIOS.SetBiosSetting("$MySetting,$NewValue") 			
				$Change_Return_Code = $Execute_Change_Action.return			
				If(($Change_Return_Code) -eq "Success")        								
					{
						Write_Log -Message_Type "INFO" -Message "New value for $MySetting is $NewValue"  	
						Write_Log -Message_Type "SUCCESS" -Message "The setting has been setted"  												
					}
				Else
					{
						Write_Log -Message_Type "ERROR" -Message "Can not change setting $MySetting (Return code $Change_Return_Code)"  											
					}								
			}
	}	
	

$Save_BIOS = (gwmi -class Lenovo_SaveBiosSettings -namespace root\wmi)
If (($IsPasswordSet -eq 1) -or ($IsPasswordSet -eq 2) -or ($IsPasswordSet -eq 3))
	{	
		$Execute_Save_Change_Action = $SAVE_BIOS.SaveBiosSettings("$MyPassword,ascii,$Language")	
		$Save_Change_Return_Code = $Execute_Save_Change_Action.return			
		If(($Save_Change_Return_Code) -eq "Success")
			{
				Write_Log -Message_Type "SUCCESS" -Message "BIOS settings have been saved"  																	
			}
		Else
			{
				Write_Log -Message_Type "ERROR" -Message "An issue occured while saving changes - $Save_Change_Return_Code"  																				
			}
	}
Else
	{
		$Execute_Save_Change_Action = $SAVE_BIOS.SaveBiosSettings()	
		$Save_Change_Return_Code = $Execute_Save_Change_Action.return			
		If(($Save_Change_Return_Code) -eq "Success")
			{
				Write_Log -Message_Type "SUCCESS" -Message "BIOS settings have been saved"  																	
			}
		Else
			{
				Write_Log -Message_Type "ERROR" -Message "An issue occured while saving changes - $Save_Change_Return_Code"  																				
			}		
	}