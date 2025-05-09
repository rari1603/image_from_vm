def BOOT_VOLUME_ID = "04327bac-1181-42ec-93c6-469924440f82"

pipeline {
    agent any

    environment {
        OPENRC_FILE = "/tmp/openstack-creds/.B2Bmgmt_openrc"
        VENV_PATH = "/var/lib/jenkins/openstack-venv/bin/activate"
        INSTANCE_ID = "d4a0c74f-5d63-4f95-8ccb-808fcb84167b"
        FLAVOR = "m1.small"
        VENV_ACTIVATE = "source /var/lib/jenkins/openstack-venv/bin/activate"
    }

    stages {
        stage('Initialize') {
            steps {
                script {
                    def timeSuffix = new Date().format("yyyyMMdd-HHmmss", TimeZone.getTimeZone("UTC"))
                    env.SNAPSHOT_NAME = "snapshot-from-${env.INSTANCE_ID}-${timeSuffix}"
                    env.VOLUME_NAME   = "volume-from-${env.INSTANCE_ID}-${timeSuffix}"
                    env.IMAGE_NAME    = "image-from-${env.INSTANCE_ID}-${timeSuffix}"
                    echo "Generated names:"
                    echo "SNAPSHOT_NAME = ${env.SNAPSHOT_NAME}"
                    echo "VOLUME_NAME   = ${env.VOLUME_NAME}"
                    echo "IMAGE_NAME    = ${env.IMAGE_NAME}"
                }
            }
        }

        stage('Setup OpenStack Virtualenv') {
            steps {
                script {
                    sh '''
                        python3 -m venv /var/lib/jenkins/openstack-venv
                        source /var/lib/jenkins/openstack-venv/bin/activate
                        pip install --upgrade pip
                        pip install python-openstackclient
                        deactivate
                    '''
                }
            }
        }

        stage('Checkout OpenRC') {
            steps {
                script {
                    sh 'rm -rf /tmp/openstack-creds'
                    sh 'git clone https://github.com/rari1603/image_from_vm.git /tmp/openstack-creds'

                    if (!fileExists(env.OPENRC_FILE)) {
                        error "OpenRC file ${env.OPENRC_FILE} not found."
                    }
                    echo "OpenRC file found."
                }
            }
        }

        stage('Stop Instance') {
            steps {
                script {
                    echo "Stopping instance ${env.INSTANCE_ID}..."
                    sh """
                        ${env.VENV_ACTIVATE}
                        source ${env.OPENRC_FILE}
                        openstack server stop ${env.INSTANCE_ID}
                    """
                }
            }
        }

        stage('Create Snapshot') {
            steps {
                script {
                    echo "Creating snapshot from hardcoded volume ID: ${BOOT_VOLUME_ID}"
                    sh """
                        ${env.VENV_ACTIVATE}
                        source ${env.OPENRC_FILE}
                        openstack volume snapshot create --volume ${BOOT_VOLUME_ID} ${env.SNAPSHOT_NAME} --force
                    """

                    echo "Waiting for snapshot to become available..."
                    waitForSnapshot(env.SNAPSHOT_NAME)
                }
            }
        }

        stage('Create Volume from Snapshot') {
            steps {
                script {
                    echo "Creating volume from snapshot: ${env.SNAPSHOT_NAME}"
                    sh """
                        ${env.VENV_ACTIVATE}
                        source ${env.OPENRC_FILE}
                        openstack volume create --snapshot ${env.SNAPSHOT_NAME} --size 100 ${env.VOLUME_NAME}
                    """

                    echo "Waiting for volume to become available..."
                    waitForVolume(env.VOLUME_NAME)
                }
            }
        }

        stage('Upload Volume to Glance') {
            steps {
                script {
                    echo "Uploading volume ${env.VOLUME_NAME} to Glance as image ${env.IMAGE_NAME}..."
                    sh """
                        ${env.VENV_ACTIVATE}
                        source ${env.OPENRC_FILE}
                        openstack image create --os-volume-api-version 3.1 --disk-format qcow2 --container-format bare --volume ${env.VOLUME_NAME} ${env.IMAGE_NAME}
                    """

                    echo "✅ Pipeline complete: Snapshot → Volume → Glance Image"
                }
            }
        }
         stage('Upload Image to Another OpenStack Environment') {
            steps {
                script {
                    def uploadScript = "${WORKSPACE}/upload-to-other-glance.sh"
                    def glanceImageName = "${env.IMAGE_NAME}-${env.IMAGE_TIMESTAMP}"

                    sh """
                        if [ ! -f "${uploadScript}" ]; then
                            echo "Upload script not found: ${uploadScript}"
                            exit 1
                        fi

                        chmod +x "${uploadScript}"
                        ${uploadScript} "${env.IMAGE_FILE_PATH}" "${glanceImageName}"
                    """
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline execution finished."
        }
        failure {
            echo "Pipeline failed. Please check the logs."
        }
    }
}

// Utility function: wait until snapshot status is 'available'
def waitForSnapshot(snapshotName) {
    timeout(time: 5, unit: 'MINUTES') {
        waitUntil {
            def status = sh(script: """
                ${env.VENV_ACTIVATE}
                source ${env.OPENRC_FILE}
                openstack volume snapshot show ${snapshotName} -f value -c status
            """, returnStdout: true).trim()
            echo "Snapshot status: '${status}'"
            if (status == "error") {
                error "Snapshot creation failed."
            }
            return (status == "available")
        }
    }
}

// Utility function: wait until volume status is 'available'
def waitForVolume(volumeName) {
    timeout(time: 5, unit: 'MINUTES') {
        waitUntil {
            def status = sh(script: """
                ${env.VENV_ACTIVATE}
                source ${env.OPENRC_FILE}
                openstack volume show ${volumeName} -f value -c status
            """, returnStdout: true).trim()
            echo "Volume status: '${status}'"
            if (status == "error") {
                error "Volume creation failed."
            }
            return (status == "available")
        }
    }
}
