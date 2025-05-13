
# Output CSV file path
$outputFile = "sql_databases.csv"

# Write CSV header
"ResourceGroup,ServerOrInstance,DatabaseName,Size,Status,RedundancyType,Type" | Out-File -FilePath $outputFile -Encoding utf8

# --- SQL Databases (PaaS) ---
$databases = az resource list --resource-type "Microsoft.Sql/servers/databases" --query "[].{Id:id, ResourceGroup:resourceGroup}" --output json | ConvertFrom-Json

$uniquePairs = $databases | ForEach-Object {
$serverName = ($_.Id -split "/")[8]
"$($serverName) $($_.ResourceGroup)"
} | Sort-Object -Unique

foreach ($pair in $uniquePairs) {
$parts = $pair -split " "
$server = $parts[0]
$resourceGroup = $parts[1]

Write-Host "Fetching SQL DBs for Resource Group: $resourceGroup, Server: $server"

$dbs = az sql db list --resource-group $resourceGroup --server $server --query "[].{Name:name, Size:currentServiceObjectiveName, Status:status}" --output json | ConvertFrom-Json

foreach ($db in $dbs) {
    # Get detailed info for each database, focusing directly on properties we need
    $dbDetails = az sql db show --name $($db.Name) --resource-group $resourceGroup --server $server --output json | ConvertFrom-Json
    
    # Determine redundancy type based on the available properties
    $redundancyType = "None"
    
    # First check zone redundancy (most specific)
    if ($dbDetails.zoneRedundant -eq $true) {
        $redundancyType = "Zone Redundant"
    }
    
    # Check backup storage redundancy which can indicate geo redundancy
    if ($dbDetails.requestedBackupStorageRedundancy) {
        switch ($dbDetails.requestedBackupStorageRedundancy) {
            "Geo" { 
                if ($redundancyType -eq "Zone Redundant") {
                    $redundancyType = "Zone and Geo Redundant"
                } else {
                    $redundancyType = "Geo Redundant" 
                }
            }
            "Zone" { 
                if ($redundancyType -ne "Zone Redundant") {
                    $redundancyType = "Zone Redundant Storage" 
                }
            }
            "Local" { 
                if ($redundancyType -eq "None") {
                    $redundancyType = "Local Redundant" 
                }
            }
            "GeoZone" { $redundancyType = "Geo-Zone Redundant" }
        }
    }
    
    # Check for failover groups (indicates geo redundancy)
    try {
        $failoverGroups = az sql failover-group list --resource-group $resourceGroup --server $server --query "[?contains(databases[].id, '$($dbDetails.id)')]" --output json | ConvertFrom-Json
        if ($failoverGroups -and $failoverGroups.Count -gt 0) {
            if ($redundancyType -eq "Zone Redundant") {
                $redundancyType = "Zone Redundant with Geo Failover"
            } else {
                $redundancyType = "Geo Redundant (Failover Group)"
            }
        }
    } catch {
        # Ignore errors when checking failover groups
    }
    
    # For premium and business critical tiers, they have local redundancy by default
    if ($redundancyType -eq "None" -and ($db.Size -like "*Premium*" -or $db.Size -like "*Business*" -or $db.Size -like "*Critical*")) {
        $redundancyType = "Local Redundancy (Premium/Business Critical)"
    }

    "$resourceGroup,$server,$($db.Name),$($db.Size),$($db.Status),$redundancyType,SQLDatabase" | Out-File -FilePath $outputFile -Append -Encoding utf8
}
}

# --- Managed Instances ---
$instances = az sql mi list --query "[].{Name:name, ResourceGroup:resourceGroup}" --output json | ConvertFrom-Json

foreach ($instance in $instances) {
$miName = $instance.Name
$resourceGroup = $instance.ResourceGroup

Write-Host "Fetching Managed DBs for Resource Group: $resourceGroup, Instance: $miName"

# Get detailed instance info
$miDetails = az sql mi show --name $miName --resource-group $resourceGroup --output json | ConvertFrom-Json

# Determine redundancy type for managed instance
$redundancyType = "None"

# Check zone redundancy (most specific property)
if ($miDetails.zoneRedundant -eq $true) {
    $redundancyType = "Zone Redundant"
}

# Check availability zones
if ($miDetails.availabilityZone) {
    $redundancyType = "Availability Zone: $($miDetails.availabilityZone)"
}

# Check backup storage redundancy which can indicate geo redundancy
if ($miDetails.requestedBackupStorageRedundancy) {
    switch ($miDetails.requestedBackupStorageRedundancy) {
        "Geo" { 
            if ($redundancyType -eq "Zone Redundant") {
                $redundancyType = "Zone and Geo Redundant"
            } else {
                $redundancyType = "Geo Redundant" 
            }
        }
        "Zone" { 
            if ($redundancyType -ne "Zone Redundant") {
                $redundancyType = "Zone Redundant Storage" 
            }
        }
        "Local" { 
            if ($redundancyType -eq "None") {
                $redundancyType = "Local Redundant" 
            }
        }
        "GeoZone" { $redundancyType = "Geo-Zone Redundant" }
    }
}

# Check high availability configuration
if ($miDetails.haMode) {
    if ($redundancyType -ne "None") {
        $redundancyType = "$redundancyType with $($miDetails.haMode) HA"
    } else {
        $redundancyType = "$($miDetails.haMode) HA"
    }
}

# Check if it's Business Critical tier (which has local redundancy by default)
if ($redundancyType -eq "None" -and $miDetails.sku.tier -eq "BusinessCritical") {
    $redundancyType = "Local Redundancy (Business Critical)"
}

# Try to find failover groups for the managed instance
try {
    # For managed instances, we need to check if it's part of a failover group
    $miGroups = az sql instance-failover-group list --resource-group $resourceGroup --output json 2>$null | ConvertFrom-Json
    $matchingGroups = $miGroups | Where-Object { $_.primaryManagedInstanceName -eq $miName -or $_.secondaryManagedInstanceName -eq $miName }
    
    if ($matchingGroups -and $matchingGroups.Count -gt 0) {
        if ($redundancyType -eq "Zone Redundant") {
            $redundancyType = "Zone Redundant with Geo Failover"
        } else {
            $redundancyType = "Geo Redundant (Failover Group)"
        }
    }
} catch {
    # Ignore errors when checking failover groups
}

$managedDbs = az sql midb list --managed-instance $miName --resource-group $resourceGroup --query "[].{Name:name, Status:status}" --output json | ConvertFrom-Json

foreach ($db in $managedDbs) {
    "$resourceGroup,$miName,$($db.Name),N/A,$($db.Status),$redundancyType,ManagedInstance" | Out-File -FilePath $outputFile -Append -Encoding utf8
}
}

Write-Host "`n✅ Output saved to $outputFile"
