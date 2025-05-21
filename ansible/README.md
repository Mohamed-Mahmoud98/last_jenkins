
# WordPress Deployment with Ansible

This project automates the deployment of a WordPress website using Ansible. It installs and configures Apache, PHP, and MariaDB for a WordPress instance on EC2 instances. The configuration is defined in roles and tasks, making it highly modular and reusable.

## Project Structure

```
ansible-config/
├── ansible.cfg             # Ansible configuration file
├── hosts.ini               # Inventory file with host details
├── playbook.yaml           # Main playbook for executing tasks
└── roles/
    ├── apache/
    │   └── main.yaml       # Apache installation and configuration
    ├── mariadb/
    │   └── main.yaml       # MariaDB installation and configuration
    └── php_wordpress/
        ├── tasks/
        │   └── main.yaml   # PHP and WordPress installation and configuration
        └── templates/
            └── wp-config.php.j2  # WordPress configuration template
```

## Requirements

Before running the playbook, ensure you have the following:

- Ansible 2.x or later
- EC2 instances with SSH access
- A private SSH key to connect to your EC2 instances (`ec2-ansible.pem`)
- WordPress EC2 instance and Database EC2 instance
- Ansible installed on the local machine

## Configuration

### `hosts.ini`

This file defines the host groups for the WordPress server and MariaDB database server. Replace the placeholders with the actual public IPs of your EC2 instances.

```ini
[wordpress]
wordpress_server ansible_host=<"WORDPRESS PUBLIC IP"> ansible_ssh_private_key_file=~/.ssh/ec2-ansible.pem

[database]
db_server ansible_host=<"Public DB IP"> ansible_ssh_private_key_file=~/.ssh/ec2-ansible.pem
```

### `ansible.cfg`

The Ansible configuration file that specifies the inventory file, remote user, and other settings.

```ini
[defaults]
inventory = {{ inventory }}
remote_user = {{ remote_user }}
private_key_file = {{ private_key_file }}
host_key_checking = False
```

### `playbook.yaml`

The main playbook that applies the roles to the `wordpress` and `database` servers.

```yaml
- hosts: wordpress 
  become: yes
  vars:
    db_name: <"DB Name">
    db_user: <"DB User Name">
    db_password: <"DB Password">
    db_host: <"Public DB IP">
  roles:
    - apache
    - php_wordpress

- hosts: database
  become: yes
  vars:
    db_name: <"DB Name">
    db_user: <"DB User Name">
    db_password: <"DB Password">
    db_host: <"Public DB IP">
  roles:
    - mariadb
```

## Roles

### Apache Role

The `apache` role installs Apache, configures it to serve WordPress, and enables mod_rewrite.

Tasks:

- Updates apt cache
- Installs Apache
- Configures Apache DocumentRoot to `/var/www/wordpress`
- Restarts Apache to apply the changes

### MariaDB Role

The `mariadb` role installs MariaDB, sets up the WordPress database and user, and configures the server for remote connections.

Tasks:

- Installs MariaDB server
- Creates WordPress database and user
- Grants privileges to the WordPress user
- Configures MariaDB to allow connections from any IP
- Restarts MariaDB to apply changes

### PHP WordPress Role

The `php_wordpress` role installs PHP and required extensions, downloads and extracts WordPress, and configures `wp-config.php`.

Tasks:

- Installs PHP and necessary modules
- Downloads and extracts WordPress
- Sets permissions for the WordPress directory
- Configures `wp-config.php` for WordPress to connect to MariaDB

### `wp-config.php.j2`

This is a Jinja2 template that configures WordPress to use the MariaDB database and user credentials.

```php
<?php
define('DB_NAME', 'wordpress');
define('DB_USER', 'zozz');
define('DB_PASSWORD', '12341234');
define('DB_HOST', '<"Public DB IP">');  // MariaDB EC2 IP
define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');

$table_prefix = 'wp_';
define('WP_DEBUG', false);

if ( !defined('ABSPATH') )
    define('ABSPATH', dirname(__FILE__) . '/');

require_once(ABSPATH . 'wp-settings.php');
```

## How to Run

1. Clone the repository:

   ```bash
   git clone <repository_url>
   cd ansible-config
   ```

2. Update `hosts.ini` with the public IPs of your WordPress and MariaDB EC2 instances.

3. Ensure your private SSH key file (`ec2-ansible.pem`) is in the correct location and is readable.

4. Run the playbook to deploy WordPress:

   ```bash
   ansible-playbook playbook.yaml
   ```

This will configure your WordPress server and MariaDB server, install all dependencies, and set up the WordPress instance.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
