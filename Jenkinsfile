node {
		stage('init') {
    		 	checkout([$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], userRemoteConfigs: [[credentialsId: 'ed737560-5157-45fa-a1de-17becf0802d9', url: 'https://github.com/avinash514/antproject.git']]])
		}
		stage('SrcBuild') {
			echo 'Pulling...' + env.BRANCH_NAME
			def ant_version = 'Ant1.9.13'
				withEnv( ["PATH+MAVEN=${tool ant_version}/bin"] ) {
					bat "ant clean compile"
				}
      			
		}
		stage('SonarQube analysis') {
		// requires SonarQube Scanner 2.8+
		env.JAVA_HOME = 'C:\\Program Files\\Java\\jdk1.8.0_101'
		def scannerHome = tool 'SonarScanner 2.8';
			withSonarQubeEnv('Sonar') {
				bat "${scannerHome}\\bin\\sonar-scanner -Dsonar.projectKey=antproject -Dsonar.language=java -Dsonar.sources=./src"
			}
		powershell '''$sonarProps = convertfrom-stringdata (Get-Content ".\\.sonar\\report-task.txt" -raw)
							$ceTaskUrl = $sonarProps.ceTaskUrl
							$serverUrl = $sonarProps.serverUrl
							DO {
							$sonarScanner = Invoke-RestMethod -Uri "$ceTaskUrl"
							$sonarTaskStatus = $sonarScanner.task.status
							start-sleep 10
							} while ($sonarTaskStatus -ne \'SUCCESS\')
							$sonarAnalysisID = $sonarScanner.task.analysisId
							$sonarQG = Invoke-RestMethod -Uri $serverUrl"/api/qualitygates/project_status?analysisId="$sonarAnalysisID
							$sonarQGstatus = $sonarQG.projectstatus.status
							if ($sonarQGstatus -eq \'ERROR\'){
							echo "Creating JIRA"
							$user = [System.Text.Encoding]::UTF8.GetBytes("avinash:avinash9")
							$headers = @{Authorization = "Basic " + [System.Convert]::ToBase64String($user)}
							$body = Get-Content ".\\data.txt"
							Invoke-RestMethod -URI "http://localhost:8085/rest/api/2/issue/" -Method Post -Headers $headers  -ContentType "application/json" -Body $body
						}'''
  }
}