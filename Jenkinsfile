String deduceDockerTag() {
    String dockerTag = env.BRANCH_NAME
    if (dockerTag.equals("main")) {
        echo "Building the 'main' branch so we'll publish a Docker tag starting with 'latest'"
        dockerTag = "latest"
    } else {
        dockerTag += env.BUILD_NUMBER
        echo "Building a branch other than 'main' so will publish a Docker tag starting with '$dockerTag', not 'latest'"
    }
    return dockerTag
}

pipeline {
    agent {
        label 'node20 && docker'
    }

    environment {
        GAR_BASE_URL = "us-east1-docker.pkg.dev"
        DOCKER_TAG = deduceDockerTag()
        FULL_IMAGE_NAME = "${GAR_BASE_URL}/teralivekubernetes/backstage/backstage:${DOCKER_TAG}"
    }

    stages {
        stage('Build') {
            steps {
                container('node') {
                    sh 'yarn install --network-timeout 900000' // TODO: Too long! Maybe mix of needing a local cache and an SSD capable agent?
                    sh 'yarn tsc'
                    sh 'yarn build:backend'
                }
            }
        }

        stage('Publish') {
            steps {
                // Publish a Docker image with GAR auth present
                withCredentials([file(credentialsId: 'jenkins-gar-sa', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh """
                        docker build -f packages/backend/Dockerfile -t backstage .
                        docker tag backstage ${FULL_IMAGE_NAME}
                        cat \${GOOGLE_APPLICATION_CREDENTIALS} | docker login -u _json_key --password-stdin https://${GAR_BASE_URL}
                        docker push ${FULL_IMAGE_NAME}
                    """
                }
            }
        }
    }
}
