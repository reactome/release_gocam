// This Jenkinsfile is used by Jenkins to run the 'DataExport' step of Reactome's release.
// It requires that the 'DiagramConverter' step has been run successfully before it can be run.

import org.reactome.release.jenkins.utilities.Utilities

// Shared library maintained at 'release-jenkins-utils' repository.
def utils = new Utilities()

pipeline{
    agent any

    environment {
        ECR_URL = 'public.ecr.aws/reactome/release-gocam'
        CONT_NAME = 'gocam_container'
        CONT_ROOT = '/opt/release-go-cam-generator'
        OUTPUT_DIR = "gocam_output"
    }

    stages{
        stage('Check Download Directory succeeded'){
            steps{
                script{
                    utils.checkUpstreamBuildsSucceeded("File-Generation/job/DownloadDirectory/")
                }
            }
        }

        stage('Setup: Pull and clean docker environment'){
            steps{
                sh "docker pull ${ECR_URL}:latest"
                sh """
                     if docker ps -a --format '{{.Names}}' | grep -Eq '${CONT_NAME}'; then
                         docker rm -f ${CONT_NAME}
                     fi
                   """
            }
        }

        stage('Main: Run GOCAM Generation'){
            steps{
                script{
                    def releaseVersion = utils.getReleaseVersion()
                    def downloadPath = "${env.ABS_DOWNLOAD_PATH}/${releaseVersion}"

                    sh "mkdir -p ${OUTPUT_DIR}"
                    sh "cp ${downloadPath}/biopax.zip ${OUTPUT_DIR}"
                    // This is a very memory-intensive step, and as such it is necessary to stop unused services to get it to run to completion.
                    sh "sudo service mysql stop"
                    sh "sudo service tomcat9 stop"
                    sh "docker run -v \$(pwd)/${OUTPUT_FOLDER}:/reactome_gen reactome-pathway2go:latest"
                    sh "mkdir -p ${downloadPath}/gocam"
                    sh "mv ${OUTPUT_DIR}/reacto-out/*.ttl ${downloadPath}/gocam/"
                    sh "cd ${downloadPath} && zip -r gocam.zip gocam/"
                    sh "rm -rf ${downloadPath}/gocam"
                    sh "sudo service mysql start"
                    sh "sudo service tomcat9 start"
                }
            }
        }

        // Archive everything on S3, and move the 'diagram' folder to the download/vXX folder.
        stage('Post: Archive Outputs'){
            steps{
                script{
                    def releaseVersion = utils.getReleaseVersion()
                    def dataFiles = ["${OUTPUT_DIR}/reacto_out/*"]
                    def logFiles = ["${OUTPUT_DIR}/reports/*"]
                    def foldersToDelete = []
                    utils.cleanUpAndArchiveBuildFiles("go_cams", dataFiles, logFiles, foldersToDelete)
                }
            }
        }
    }
}
