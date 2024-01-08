pipeline {
    agent {
        label 'node20 && docker'
    }

    stages {
        stage('Build') {
            steps {
                sh 'yarn install --network-timeout 900000' // Too long! Maybe mix of needing a local cache and an SSD agent?
                sh 'yarn tsc'
                sh 'yarn build:backend'
                sh 'yarn build-image'
            }
        }

        stage('Publish') {
            steps {
                // Publish a Docker image using Jib with GCR auth present
                withCredentials([file(credentialsId: 'gcr-service-user-proto-client-ttf', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh 'docker tag backstage gcr.io/proto-client-ttf/backstage:latest'
                    sh 'docker login -u _json_key -p "$(cat $GOOGLE_APPLICATION_CREDENTIALS)" https://gcr.io'                    
                    sh 'docker push gcr.io/proto-client-ttf/backstage:latest'
                }
            }
        }
    }
}