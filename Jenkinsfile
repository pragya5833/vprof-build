pipeline{
    agent any
    environment {
        NEXUS_VERSION = "nexus3"
        NEXUS_PROTOCOL = "http"
        NEXUS_URL = "172.31.3.83:8081"
        NEXUS_REPOSITORY = "vprof-maven-release"
	    NEXUS_REPOGRP_ID    = "vprof-maven-central"
        NEXUS_CREDENTIAL_ID = "nexus"
        ARTVERSION = "${env.BUILD_ID}"
    }
    stages{
        stage('checkout'){
            steps{
                git branch: 'master', url:'https://github.com/pragya5833/vprof-build.git'
            }
        }
        stage('Build'){
            steps{
                sh 'mvn clean install -DskipTests'
            }
            post{
                success{
                    archiveArtifacts artifacts: '**/target/*.war'
                }
            }
        }
        stage('Unit Test'){
            steps{
                sh 'mvn test'
            }
        }
        stage('Integration Test'){
            steps{
                sh 'mvn verify -DskipUnitTests'
            }
        }
        stage('CODE ANALYSIS with SONARQUBE'){
            environment{
                    scannerHome= tool 'SonarQubeScanner4.7.0.2747'
                }
            steps{
             withSonarQubeEnv('Sqserver'){
                 sh '''${scannerHome}/bin/sonar-scanner -Dsonar.projectKey=vprofile \
                   -Dsonar.projectName=vprofile-repo \
                   -Dsonar.projectVersion=1.0 \
                   -Dsonar.sources=src/ \
                   -Dsonar.java.binaries=target/test-classes/com/visualpathit/account/controllerTest/ \
                   -Dsonar.junit.reportsPath=target/surefire-reports/ \
                   -Dsonar.jacoco.reportsPath=target/jacoco.exec \
                   -Dsonar.java.checkstyle.reportPaths=target/checkstyle-result.xml'''
             }  
             timeout(time: 10, unit: 'MINUTES') {
               waitForQualityGate abortPipeline: true
            } 
            }
        }
        stage('Publish to nexus'){
            steps{
                script {
                    pom = readMavenPom file: "pom.xml";
                    filesByGlob = findFiles(glob: "target/*.${pom.packaging}");
                    echo "${filesByGlob[0].name} ${filesByGlob[0].path} ${filesByGlob[0].directory} ${filesByGlob[0].length} ${filesByGlob[0].lastModified}"
                    artifactPath = filesByGlob[0].path;
                    artifactExists = fileExists artifactPath;
                    if(artifactExists) {
                        echo "*** File: ${artifactPath}, group: ${pom.groupId}, packaging: ${pom.packaging}, version ${pom.version} ARTVERSION";
                        nexusArtifactUploader(
                            nexusVersion: NEXUS_VERSION,
                            protocol: NEXUS_PROTOCOL,
                            nexusUrl: NEXUS_URL,
                            groupId: NEXUS_REPOGRP_ID,
                            version: ARTVERSION,
                            repository: NEXUS_REPOSITORY,
                            credentialsId: NEXUS_CREDENTIAL_ID,
                            artifacts: [
                                [artifactId: pom.artifactId,
                                classifier: '',
                                file: artifactPath,
                                type: pom.packaging],
                                [artifactId: pom.artifactId,
                                classifier: '',
                                file: "pom.xml",
                                type: "pom"]
                            ]
                        );
                    } 
		    else {
                        error "*** File: ${artifactPath}, could not be found";
                    }
            }
        }
    }
}
}