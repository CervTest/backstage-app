pipeline {
    agent {
        label 'node20 && docker'
    }

    stages {
        stage('Build') {
            steps {
                sh 'yarn install --network-timeout 900000' // TODO: Too long! Maybe mix of needing a local cache and an SSD capable agent?
                sh 'yarn tsc'
                sh 'yarn build:backend'
                sh 'yarn build-image'
            }
        }

        stage('Publish') {
            steps {
                // Publish a Docker image with GCR auth present
                withCredentials([file(credentialsId: 'gcr-service-user-proto-client-ttf', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh """
                        docker tag backstage gcr.io/proto-client-ttf-832500/backstage:latest
                        cat \${GOOGLE_APPLICATION_CREDENTIALS} | docker login -u _json_key --password-stdin https://gcr.io
                        docker push gcr.io/proto-client-ttf-832500/backstage:latest
                    """
                }
            }
        }
    }
}
