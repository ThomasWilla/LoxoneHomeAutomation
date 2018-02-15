 
<#
    .SYNOPSIS
	   This ist a Claas for Managed the Loxone Miniserver over REST
	   
	   Use the Class 
 	  $LxHomeAutomation = New-Object LxHomeAutomation -ArgumentList "Username","Plain Password"

     .DESCRIPTION
    
  
    .NOTES
       The Class is running explicit on Powershell 5.x

    .COMPONENT
        No Component are requierd

    .LINK
        Useful Link to ressources or others.

    .Parameter ParameterName
		 $Server = Address from the Miniserver
		 $cred =  Miniserver Credentinal mit Secure Sting Password
		 $LastResult = Last Raw Response Result from the Miniserver
		 $object = Object for the REST Call	
		 $enumout  = dynamic Variable with all Loxone Outputs
		 $enumin = dynamic Variable with all Loxone Inputs
		 
#>



 class LxHomeAutomation   {
	
	#Properties
	
	[bool] $ConStatus
	static [int] $ErrorCode

	[System.Object]$cred
	[string]$server = ""
	[string]$Object
	[xml]$lastResult



	# Constructor
 	LxHomeAutomation ([String]$User, [String] $PlainPW)
	{
		#Bind Credentials
		$secpasswd = ConvertTo-SecureString $PlainPW -AsPlainText -Force
		$this.cred = New-Object System.Management.Automation.PSCredential ($user, $secpasswd)
		
		
		#Test Connection
		
		if (! (Test-Connection -Server $this.server -Count 1 -ea SilentlyContinue))
		{
			$this.ConStatus = $false
			[LXHomeAutomation]::ErrorCode = "400"
		}
		else
		{
			$this.ConStatus = $true
            #Add all Outputs to Class
            $this.RESTRequestSps("enumout")
            #Add all Inputs to Class
            $this.RESTRequestSps("enumin")
		}
		
	}
	
	static [xml]ErrorHandling ()
	{
		if ([LxHomeAutomation]::conStatus -eq $false)
		{
			[LxHomeAutomation]::ErrorCode = "400"
			[xml]$SendOnError = "<error_code>"+ [LxHomeAutomation]::ErrorCode+"</error_code>"
			return $SendOnError
			
		}
		else
		{
			[xml]$SendOnError = "<error_code>" + [LxHomeAutomation]::ErrorCode + "</error_code>"
			return $SendOnError
		}

		
	}
	
	[object] RESTRequestLANStatus ($Object) 
	{
		#Possible Value:
		# txp 	Retrieve number of LAN packets sent
		# txe 	Retrieve number of LAN packets sent with errors
		# txc 	Retrieve number of LAN packets sent with collisions
		# exh 	Retrieve number of LAN buffer errors
		# txu 	Retrieve number of LAN under-run errors
		# rxp 	Retrieve number of LAN packets recieved
		# eof 	Retrieve number of LAN EOF errors
		# rxo 	Retrieve number of LAN receive overflow errors
		# nob 	Retrieve number of LAN 'No receive buffer' errors
		
		$srv=$this.Server

			try
			{
			$this.lastResult = Invoke-WebRequest -Uri "http://$srv/dev/lan/$Object" -Credential $this.cred
            return $this.lastResult.ll
		
			}		
			catch [exception]
		{
			
			[LxHomeAutomation]::ErrorCode = "404"
			return [LxHomeAutomation]::ErrorHandling()
			}
	}
	
	
	[object] RESTRequestSysStatus ($Object)
	{
		#Possible Value:
		# cpu 				Retrieve CPU load
		# contextswitches 	Retrieve number of switchings between tasks
		# contextswitchesi 	Retrieve number of switchings between tasks that were triggered interrupts
		# heap 				Retrieve memory size
		# ints 				Retrieve number of system interrupts
		# comints 			Retrieve number of communication interrupts
		# lanints 			Retrieve number of LAN interrupts
		# watchdog 			Retrieve watchdog bits
		# date 				Returns the local date
		# time 				Returns the local time
		# setdatetime 		Set system date and time. Format: 2013-06-18 16:58:00 or 18/06/2013 
		# spscycle 			Retrieve number of PLC cycles
		# ntp 				Force NTP request
		# reboot 			Boot Miniserver
		# check 			Displays active connections in Loxone Config
		# logoff 			Ends any existing connections in Loxone Config
		# sdtest 			Tests the SD card
		# lastcpu		 	Shows the last value of the CPU utilisation and the number of PLC cycles
		# search 			Performs a search for connected extensions
		# searchdata 		Lists the search results
		# 05000001 			Retrieve the statistics of a 1-Wire Extension (replace 05000001 with the actual serial number)
		# updateext			Start an update of extensions
		
		$srv = $this.Server
		
		try
		{
		    $this.lastResult = Invoke-WebRequest -Uri "http://$srv/dev/sys/$Object" -Credential $this.cred
            return $this.lastResult.ll
            			
		}
		catch [exception]
		{
			
			[LxHomeAutomation]::ErrorCode = "404"
			return [LxHomeAutomation]::ErrorHandling()
		}
	}


	
	[object] RESTRequestSps ($Object)
	{
		<# 
        Possible Value:
        status     aktuelle SPS Frequenz abfragen
        restart    SPS neu starten
        stop       SPS anhalten
        run        SPS fortsetzen
        log        SPS globales Logging erlauben
        enumdev    alle Geräte der SPS auflisten (Miniserver,Extensions,…)
        enumin     alle Eingänge der SPS auflisten
        enumout    alle Ausgänge der SPS auflisten
        identify   Miniserver identifizieren Für Erweiterungen muss die Seriennumer als Parameter mitgegeben werden.
        #>


		
		$srv = $this.Server
		
		try
		{
		    $this.lastResult = Invoke-WebRequest -Uri "http://$srv/dev/sps/$Object" -Credential $this.cred
            $this | Add-Member -NotePropertyName $Object -NotePropertyValue $NULL
            
            switch($Object){
             
            "enumout" { $this.$Object = (($this.lastResult.ll.value).Replace(", ","-")).split("-"); break }
            "enumin"  { $this.$Object = (($this.lastResult.ll.value).Replace(", ","-")).split("-"); break }
            
            default   {$this.$object = $this.lastResult.ll.value}
            
            }


       

            return $this.lastResult.ll
            			
		}
		catch [exception]
		{
			
			[LxHomeAutomation]::ErrorCode = "404"
			return [LxHomeAutomation]::ErrorHandling()
		}
	}


	[object] RESTControllIO ($verb, $Object)
	{
		<# 
        Possible Value:
        status     aktuelle SPS Frequenz abfragen
        restart    SPS neu starten
        stop       SPS anhalten
        run        SPS fortsetzen
        log        SPS globales Logging erlauben
        enumdev    alle Geräte der SPS auflisten (Miniserver,Extensions,…)
        enumin     alle Eingänge der SPS auflisten
        enumout    alle Ausgänge der SPS auflisten
        identify   Miniserver identifizieren Für Erweiterungen muss die Seriennumer als Parameter mitgegeben werden.
        #>


		
		$srv = $this.Server
		
		try
		{
        
        switch ($verb){
        
        "get" {$verb = "state";break}
        "impuls" {$verb = "impuls";break}

        default{
        $verb = "state"
        }
        
        }
            
            $IO = ($Object.Substring(0, $Object.Length -39))    
                        
		    $this.lastResult = Invoke-WebRequest -Uri "http://$srv/dev/sps/io/$IO/$verb" -Credential $this.cred
                          

            return $this.lastResult.ll
            			
		}
		catch [exception]
		{
			
			[LxHomeAutomation]::ErrorCode = "404"
			return [LxHomeAutomation]::ErrorHandling()
		}
	}




	
}


