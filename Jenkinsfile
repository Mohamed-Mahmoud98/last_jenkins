pipeline {
    agent any

    environment {
        TF_DIR = 'terraform'
        ANSIBLE_DIR = 'ansible'
        HOSTS_FILE = 'hosts.ini'
        LOCAL_SSH_KEY = 'ec2_key.pem'  // Local filename for the SSH key
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
                    env.WP_A_PUBLIC_IP = sh(script: "cd ${TF_DIR} && terraform output -raw wordpress_instance_a_public_ip", returnStdout: true).trim()
                    env.WP_B_PUBLIC_IP = sh(script: "cd ${TF_DIR} && terraform output -raw wordpress_instance_b_public_ip", returnStdout: true).trim()
                    env.MARIADB_PRIVATE_IP = sh(script: "cd ${TF_DIR} && terraform output -raw mariadb_instance_private_ip", returnStdout: true).trim()

                    // Print outputs to verify correctness
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
                sleep time: 150, unit: 'SECONDS'
            }
        }

        stage('Generate Ansible Files') {
            steps {
                withCredentials([file(credentialsId: 'EC2_SSH_KEY', variable: 'SSH_KEY')]) {
                    script {
                        // Copy SSH private key from Jenkins credentials to local workspace file
                        sh """
                            echo "Preparing SSH key..."
                            cp \$SSH_KEY ${LOCAL_SSH_KEY}
                            chmod 400 ${LOCAL_SSH_KEY}
                        """

                        // Write the Ansible hosts file with dynamic IPs and local SSH key path
                        writeFile file: "${HOSTS_FILE}", text: """
[jump_host]
${env.WP_A_PUBLIC_IP} ansible_user=ubuntu ansible_ssh_private_key_file=${LOCAL_SSH_KEY}

[wordpress]
${env.WP_A_PUBLIC_IP} ansible_user=ubuntu ansible_ssh_private_key_file=${LOCAL_SSH_KEY}
${env.WP_B_PUBLIC_IP} ansible_user=ubuntu ansible_ssh_private_key_file=${LOCAL_SSH_KEY}

[database]
${env.MARIADB_PRIVATE_IP} ansible_user=ubuntu ansible_ssh_private_key_file=${LOCAL_SSH_KEY} ansible_ssh_common_args='-o ProxyCommand="ssh -i ${LOCAL_SSH_KEY} -W %h:%p ubuntu@${env.WP_A_PUBLIC_IP}"'

[all:vars]
ansible_ssh_common_args='-o IdentitiesOnly=yes'
"""

                        // Write Ansible playbook.yml
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

                        // Write wp-config.php.j2 template
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
        }

        stage('Run Ansible Playbook') {
            steps {
                sh """
                    echo "Running Ansible playbook..."
                    ansible-playbook -i ${HOSTS_FILE} ${ANSIBLE_DIR}/playbook.yml
                """
            }
        }
    }

    post {
        always {
            echo 'Cleaning up workspace and SSH key...'
            sh "rm -f ${LOCAL_SSH_KEY}"
            cleanWs()
        }
    }
}
