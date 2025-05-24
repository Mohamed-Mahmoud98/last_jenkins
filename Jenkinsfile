pipeline {
    agent any

    environment {
        TF_DIR = 'terraform'
        ANSIBLE_DIR = 'ansible'
        HOSTS_FILE = 'hosts.ini'
        LOCAL_SSH_KEY = 'ec2_key.pem'
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Verify Tools') {
            steps {
                sh '''
                    terraform --version
                    ansible --version
                '''
            }
        }

        stage('Terraform Init & Apply') {
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY

                        cd ${TF_DIR}
                        terraform init -input=false
                        terraform plan -out=tfplan -input=false
                        terraform apply -auto-approve -input=false tfplan
                    '''
                }
            }
        }

        stage('Extract Terraform Outputs') {
            steps {
                script {
                    env.WP_A_PUBLIC_IP = sh(script: "cd ${TF_DIR} && terraform output -raw wordpress_instance_a_public_ip", returnStdout: true).trim()
                    env.WP_B_PUBLIC_IP = sh(script: "cd ${TF_DIR} && terraform output -raw wordpress_instance_b_public_ip", returnStdout: true).trim()
                    env.MARIADB_PRIVATE_IP = sh(script: "cd ${TF_DIR} && terraform output -raw mariadb_instance_private_ip", returnStdout: true).trim()

                    echo "Extracted Terraform Outputs:"
                    echo "WP_A_PUBLIC_IP = ${env.WP_A_PUBLIC_IP}"
                    echo "WP_B_PUBLIC_IP = ${env.WP_B_PUBLIC_IP}"
                    echo "MARIADB_PRIVATE_IP = ${env.MARIADB_PRIVATE_IP}"
                }
            }
        }

        stage('Wait for EC2 to Boot') {
            steps {
                echo 'Waiting for EC2 instances to initialize...'
                sleep time: 60, unit: 'SECONDS'  // Increased wait time
            }
        }

        stage('Generate Ansible Files') {
            steps {
                withCredentials([file(credentialsId: 'EC2_SSH_KEY', variable: 'SSH_KEY')]) {
                    script {
                        // Prepare SSH key
                        sh """
                            cp \$SSH_KEY ${LOCAL_SSH_KEY}
                            chmod 600 ${LOCAL_SSH_KEY}
                        """

                        // Create Ansible directory structure if not exists
                        sh """
                            mkdir -p ${ANSIBLE_DIR}/roles/php_wordpress/templates
                        """

                        // Write hosts file
                        writeFile file: "${HOSTS_FILE}", text: """
[wordpress]
${env.WP_A_PUBLIC_IP} ansible_user=ubuntu ansible_ssh_private_key_file=${LOCAL_SSH_KEY}
${env.WP_B_PUBLIC_IP} ansible_user=ubuntu ansible_ssh_private_key_file=${LOCAL_SSH_KEY}

[database]
${env.MARIADB_PRIVATE_IP} ansible_user=ubuntu ansible_ssh_private_key_file=${LOCAL_SSH_KEY} ansible_ssh_common_args='-o ProxyCommand="ssh -i ${LOCAL_SSH_KEY} -W %h:%p -o StrictHostKeyChecking=no ubuntu@${env.WP_A_PUBLIC_IP}"'

[all:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
"""

                        // Write playbook
                        writeFile file: "${ANSIBLE_DIR}/playbook.yml", text: """
---
- hosts: wordpress
  become: yes
  vars:
    db_name: wordpress
    db_user: zozz
    db_password: 12341234
    db_host: ${env.MARIADB_PRIVATE_IP}
  roles:
    - apache
    - php_wordpress

- hosts: database
  become: yes
  vars:
    db_name: wordpress
    db_user: zozz
    db_password: 12341234
  roles:
    - mariadb
"""
                        
                        // Write wp-config template
                        writeFile file: "${ANSIBLE_DIR}/roles/php_wordpress/templates/wp-config.php.j2", text: """
<?php
define('DB_NAME', '{{ db_name }}');
define('DB_USER', '{{ db_user }}');
define('DB_PASSWORD', '{{ db_password }}');
define('DB_HOST', '{{ db_host }}');
// Rest of your config...
"""
                    }
                }
            }
        }

        stage('Run Ansible Playbook') {
            steps {
                sh """
                    cd ${ANSIBLE_DIR}
                    ansible-playbook -i ../${HOSTS_FILE} playbook.yml -vvv
                """
            }
        }
    }

    post {
        always {
            echo 'Cleaning up...'
            sh "rm -f ${LOCAL_SSH_KEY}"
            cleanWs()
        }
    }
}
