$sonrReport = "$args[0]"
$sonarProps = convertfrom-stringdata (Get-Content "$sonarReport" -raw)
$ceTaskUrl = "$sonarProps.ceTaskUrl"
$serverUrl = "$sonarProps.serverUrl"
$sonarProject = "$sonarProps.projectKey"
DO {
	$sonarScanner = Invoke-RestMethod -Uri "$ceTaskUrl"
	$sonarTaskStatus = "$sonarScanner.task.status"
	start-sleep 10
} while ("$sonarTaskStatus" -ne \'SUCCESS\')

$sonarAnalysisID = "$sonarScanner.task.analysisId"
$sonarQG = Invoke-RestMethod -Uri $serverUrl"/api/qualitygates/project_status?analysisId="$sonarAnalysisID
$sonarQGstatus = "$sonarQG.projectstatus.status"
if ("$sonarQGstatus" -eq \'ERROR\'){
	$types = @("BUG","VULNERABILITY","CODE_SMELL")
	$severities = @("CRITICAL","MAJOR","BLOCKER")
	foreach ("$type" in "$types"){
		foreach ("$severity" in "$severities"){
			$issuesUrl = "$serverUrl/api/issues/search?componentRoots=$sonarProject&types=$type&severities=$severity&resolved=false&statuses=OPEN"
			$totalIssues = (Invoke-RestMethod -Uri "$issuesUrl" | ConvertFrom-Json) | %{$_.total}
			$totalIssuesUrl = "$issuesUrl&p=1$ps=$totalIssues"
			$totalIssues = (Invoke-RestMethod -Uri "$totalIssuesUrl" | ConvertFrom-Json)
				foreach ("$issue" in "$totalIssues.issues"){
					$issueKey = "$issue.key"
					$issueMsg = "$issue.message"
					$issueSeverity = "$issue.severity"
					$issuePermLink = "$serverUrl/project/issues?id=$sonarProject&issues=$issueKey&open=$issueKey"
					#$issueType = "$issue.type"
					if ("$issueType" -eq "CODE_SMELL" -Or "$issueType" -eq "VULNERABILITY"){
						$issueType = "Task"
					}
					echo "Creating JIRA with below Arguments"
					echo "JIRA Priority : $issueSeverity"
					echo "JIRA Summary : $issueMsg"
					echo "JIRA Type : $issueType"
					echo "JIRA Description : $issuePermLink"
					$user = [System.Text.Encoding]::UTF8.GetBytes("avinash:avinash9")
					$headers = @{Authorization = "Basic " + [System.Convert]::ToBase64String($user)}
					$body = Get-Content ".\\CreateJiraIssue.json" | %{$_ -replace '\$projectkey',"PROJKEY" | %{$_ -replace '\$Summary',"$issueMsg"} | %{$_ -replace '\$description',"$issuePermLink"} | %{$_ -replace '\$priority',"$issueSeverity"} | %{$_ -replace '\$issuetype',"$issueType"}
					#$body = Get-Content ".\\data.txt"
					Invoke-RestMethod -URI "http://localhost:8085/rest/api/2/issue/" -Method Post -Headers $headers  -ContentType "application/json" -Body $body
				}
	
}
