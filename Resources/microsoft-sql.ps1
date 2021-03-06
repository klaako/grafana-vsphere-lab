#requires -Version 3

# Pull in vars
$vars = (Get-Item $PSScriptRoot).Parent.FullName + '\vars.ps1'
Invoke-Expression -Command ($vars)

# Pull SQL stats
[System.Collections.ArrayList]$counters = @()
$counters.Add("\\sql1.glacier.local\logicaldisk(c:)\avg. disk sec/transfer")
$counters.Add("\\sql1.glacier.local\logicaldisk(e:)\avg. disk sec/transfer")
$counters.Add("\\sql1.glacier.local\logicaldisk(f:)\avg. disk sec/transfer")
$counters.Add("\\sql1.glacier.local\logicaldisk(_total)\avg. disk sec/transfer")
$counters.Add("\\sql1.glacier.local\MSSQL`$PROD:Buffer Manager\buffer cache hit ratio")
$counters.Add("\\sql1.glacier.local\MSSQL`$PROD:Buffer Manager\page life expectancy")
$counters.Add("\\sql1.glacier.local\MSSQL`$PROD:General Statistics\User Connections")
$counters.Add("\\sql1.glacier.local\MSSQL`$PROD:SQL Statistics\Batch Requests/Sec")
$counters.Add("\\sql1.glacier.local\MSSQL`$PROD:Memory Manager\total server memory (kb)")
$countersall = (Get-Counter -Counter $Counters -SampleInterval 5).countersamples.CookedValue

[System.Collections.ArrayList]$nullarray = @()
$nullarray.Add($countersall)

# Build the post body
$body = @{}
$body.Add('name',"sql_stats.sql1.glacier.local")
$body.Add('columns',@('sys_transfer','db_transfer','log_transfer','all_transfer','buffer_cache_hit','page_life_exp','user_conns','batch_reqs','total_memory'))
$body.Add('points',$nullarray)

# Convert to json
$finalbody = $body | ConvertTo-Json

# Post to API
try 
{
    $r = Invoke-WebRequest -Uri $global:url -Body ('['+$finalbody+']') -ContentType 'application/json' -Method Post -ErrorAction:Stop
    Write-Host -Object "Data for SQL has been posted, status is $($r.StatusCode) $($r.StatusDescription)"        
}
catch 
{
    throw 'Could not POST to InfluxDB API endpoint'
}