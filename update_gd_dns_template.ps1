
Function Start-CountDownTimer {
    
    Param (
    
        [CmdletBinding()]
        [Parameter(Position=0)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern("[0-9]*")]
        [int]$Seconds,

        [Parameter(Position=1)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern("[0-9]*")]
        [int]$Minutes,

        [Parameter(Position=2)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern("[0-9]*")]
        [int]$Hours
        
    )

    $Timer = 0
    $i = 1

    if (!$Seconds  -and !$Minutes -and !$Hours) {
        Write-Warning "No parameters were supplied, default is 1 minute"
        $Timer = New-TimeSpan -Minutes 1
        #Write-Error  -Message "At least one parameter is required" -RecommendedAction "Usage: Start-CountDownTimer -seconds 35" -Category NotSpecified -Exception "Missing one of the following parameters -Seconds, -Minutes, -Hours" -TargetObject "Missing Parameters"
        
    }

 
    
    

    Write-Verbose "Following values were supplied"
    Write-Verbose "`nSeconds: $Seconds`nMinutes: $Minutes `nHours: $Hours"

    if ($Seconds) {
        Write-Verbose "Adding $Seconds seconds to Timer"
        $Timer = New-TimeSpan -Seconds $Seconds
        
    }

    if ($Minutes) {
        Write-Verbose "Adding $Minutes Mintues to Timer"
        $Timer += New-TimeSpan -Minutes $Minutes
        
    }

    if ($Hours) {
        Write-Verbose "Adding $Hours Hours to Timer"
        $Timer += New-TimeSpan -Hours $Hours
        
    }
    
    Write-Verbose "Total Timer Value: $Timer"
    

    Write-Verbose "Starting the progress bar"

    while ( $i -ne $Timer.TotalSeconds) {
        
        Write-Verbose "Calculating the percentage"
        $Percentage = [math]::Round($i/$Timer.TotalSeconds*100)

        Write-Verbose "Percentage: $Percentage"

        Write-Verbose "Calculating total time remaining"
        $TimeDifference = $Timer - (New-TimeSpan -Seconds $i)

        Write-Verbose "Time remaining $TimeDifference"
       
        Write-Progress -Activity "Time Remaining: $TimeDifference" -Status "Timer Progress $Percentage%" -PercentComplete $Percentage
        
        Write-Verbose "Incrementing `$i($i) variable"
        $i++

        Write-Verbose "Adding 1 second sleep"
        sleep 1
    }

    Write-Verbose "Marking progress bar done"
    Write-Progress -Activity "Time Remaining: $TimeDifference" -Status "Done" -Completed 
    
}

<#

This script was originally forked from https://github.com/markafox/GoDaddy_Powershell_DDNS and heavily modified for 
my own internal use. This works great for me. Your mileage may vary.

#>
<#
This script is used to check and update your GoDaddy DNS server to the IP address of your current internet connection.

First go to GoDaddy developer site to create a developer account and get your key and secret

https://developer.godaddy.com/getstarted
 
Update the first 4 varriables with your information
 
#>

#This data is now in the include file
$domain="xxx.com"                           # your domain
$type="A"                                    # Record type A, CNAME, MX, etc.
$name="@"                                   # name of record to update. Store number.
$ttl=600                                   # Time to Live min value 600
$port=1                                    # Required port, Min value 1
$weight=1                                  # Required weight, Min value 1
$key="xxxxxxxxxxxx"       # key for godaddy developer API - prod
$secret="xxxxxxxxxxxx"             # secret for godaddy developer API - prod

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$headers = @{}
$headers["Authorization"] = 'sso-key ' + $key + ':' + $secret

$period = [timespan]::FromSeconds(45)
$lastRunTime = [DateTime]::MinValue
echo "Start to check..." 
while (1)
{


    $result = Invoke-WebRequest https://api.godaddy.com/v1/domains/$domain/records/$type/$name -method get -headers $headers -UseBasicParsing
    $content = ConvertFrom-Json $result.content
    $dnsIp = $content.data
    # Get public ip address there are several websites that can do this.
    # $currentIp = Invoke-RestMethod http://ipinfo.io/json | Select-Object -ExpandProperty ip
    # $currentIp = (Invoke-WebRequest "https://www.cip.cc/").content
    $body = Invoke-WebRequest -Uri "https://www.cip.cc/"
    $str=$null
    if ($body.StatusCode -eq 200)
    {
	    [string]$str = $body.ParsedHtml.body.innerHTML
	    $StartIndex = $str.IndexOf("IP	: ") + 4
	    $EndIndex = $str.IndexOf("µÿ÷∑	: ") - 2
	    $length = $EndIndex - $StartIndex - 1
	    $currentIp = $str.Substring($StartIndex + 1, $length)
        echo "CurrentIP: $currentIp"
        if ( $currentIp -ne $dnsIp ) {
            $Request = @(@{data=$currentIp;port=$port;priority=0;protocol="string";service="string";ttl=$ttl;weight=$weight })
            $JSON = Convertto-Json $request
            $result = Invoke-WebRequest https://api.godaddy.com/v1/domains/$domain/records/$type/$name -method put -headers $headers -Body $json -ContentType "application/json" -UseBasicParsing
        }
        if ( $currentIp -eq $dnsIp ) {
            echo "IP's are equal, no update required"
        }
        echo "Wait for another check..."
    }
    else
    {
	    Write-Warning "Bad Request to get current ip."
    }
<#    
    $lastRunTime = Get-Date
    # If the next period isn't here yet, sleep so we don't consume CPU
    while ((Get-Date) - $lastRunTime -lt $period) { 
        Start-Sleep -Seconds 600
    }
#>
    Start-CountDownTimer -Minutes 10
}

#EOF