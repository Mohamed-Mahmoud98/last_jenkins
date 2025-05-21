pipeline {
    agent any

    environment {
        TF_DIR = 'terraform'
        ANSIBLE_DIR = 'ansible'
        HOSTS_FILE = 'hosts.ini'
        SSH_KEY_PATH = '/home/jenkins/.ssh/ec2_key.pem'  // Adjust if needed
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
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
                        terraform init
                        terraform plan -out=tfplan
                        terraform apply -auto-approve tfplan
                    '''
                }
            }
        }

        stage('Extract Terraform Outputs') {
            steps {
                script {
                    def tfOutput = sh(script: "cd ${TF_DIR} && terraform output -json", returnStdout: true).trim()
                    def outputs = readJSON text: tfOutput

                    // Save IPs to environment variables
                    env.WP_A_PUBLIC_IP = outputs.wordpress_server_a_public_ip.value
                    env.WP_B_PUBLIC_IP = outputs.wordpress_server_b_public_ip.value
                    env.MARIADB_PRIVATE_IP = outputs.mariadb_private_ip.value
                }
            }
        }

        stage('Wait for EC2 to Boot') {
            steps {
                echo 'Waiting for EC2 instances to initialize...'
                sleep time: 150, unit: 'SECONDS'
            }
        }

        stage('Generate Ansible Files') {
            steps {
                script {
                    writeFile file: "${HOSTS_FILE}", text: """
[jump_host]
jump_host ansible_host=${env.WP_A_PUBLIC_IP} ansible_user=ubuntu ansible_ssh_private_key_file=${SSH_KEY_PATH}

[wordpress]
wordpress_server_a ansible_host=${env.WP_A_PUBLIC_IP} ansible_user=ubuntu ansible_ssh_private_key_file=${SSH_KEY_PATH}
wordpress_server_b ansible_host=${env.WP_B_PUBLIC_IP} ansible_user=ubuntu ansible_ssh_private_key_file=${SSH_KEY_PATH}

[database]
db_server ansible_host=${env.MARIADB_PRIVATE_IP} ansible_user=ubuntu ansible_ssh_private_key_file=${SSH_KEY_PATH} ansible_ssh_common_args='-o ProxyCommand="ssh -i ${SSH_KEY_PATH} -W %h:%p ubuntu@${env.WP_A_PUBLIC_IP}"'

[all:vars]
ansible_ssh_common_args='-o IdentitiesOnly=yes'
"""

                    writeFile file: "${ANSIBLE_DIR}/playbook.yml", text: """
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
    db_host: ${env.MARIADB_PRIVATE_IP}
  roles:
    - mariadb
"""

                    writeFile file: "${ANSIBLE_DIR}/roles/php_wordpress/templates/wp-config.php.j2", text: """
<?php
define('DB_NAME', 'wordpress');
define('DB_USER', 'zozz');
define('DB_PASSWORD', '12341234');
define('DB_HOST', '${env.MARIADB_PRIVATE_IP}');
define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');

\$table_prefix = 'wp_';
define('WP_DEBUG', false);

if ( !defined('ABSPATH') )
    define('ABSPATH', dirname(__FILE__) . '/');

require_once(ABSPATH . 'wp-settings.php');
"""
                }
            }
        }

        stage('Run Ansible Playbook') {
            steps {
                sh """
                    ansible-playbook -i ${HOSTS_FILE} ${ANSIBLE_DIR}/playbook.yml
                """
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
