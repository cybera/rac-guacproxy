# Deploy Apache Guacamole in the Rapid Access Cloud

Guacamole is an HTML5-based clientless remote desktop gateway. It proxies connections between the guacamole server and any number of RDP, VPN or SSH connections. In the Rapid Access Cloud this is a way that one IPv4 address can be used amongst many different connections.

This document will detail how to deploy an instance in Cybera’s Rapid Access Cloud that will host guacamole and provide RDP access. There are example instructions on creating users and connections at the end of the document that detail how to use guacamole with RDP.

Requirements:
 - a Cybera Rapid Access Cloud account
 - terraform v0.9.7 or higher
 - wget

## Deploying guacamole instance

Note: the examples below assume a Unix-type environment like Linux or macOS.

1. From a command-line, create a working directory (this example creates the working directory in your home directory). This is the directory you will run terraform from to build the guacamole server.
```
# mkdir ~/guacproxy
```

2. Change to the working directory created in 1) and download the following files from Cybera’s GitHub-hosted repository:
```
# cd guacproxy/
# wget https://raw.githubusercontent.com/cybera/rac-guacproxy/master/deploy.tf
# wget https://raw.githubusercontent.com/cybera/rac-guacproxy/master/provider.tf
# wget https://raw.githubusercontent.com/cybera/rac-guacproxy/master/terraform.tfvars
```
3. Modify ~/guacproxy/terraform.tfvars and include your Rapid Access Cloud username and password, and the project that this instance should be associated with (see examples at the end of the document).

4. Run terraform to provision the instance: # terraform plan # terraform apply

5. Once terraform is completed you will see an output message:
```
ssh to guacproxy using 'ssh -i /path/to/id_rsa ubuntu@<floating_ip_address>’,
run /home/ubuntu/guac-install.sh as root 'sudo ./guac-install.sh',
You will be prompted during the script to create passwords for the MySQL database and guacdb.
```

6. Once guac-install.sh has been run, reboot the machine:
```
# sudo reboot now
```
The machine should reboot fairly quickly. Test the installation by navigating to the guacamole dashboard with your browser and logging in with the default user-name/password:
User: guacadmin
Password: guacadmin
Address: http://<floating_ip_address>:8080/guacamole

7. Change the default password and address quirks of the system:
  a) In the top-right corner click the user navigation button, labelled with the current ‘guacadmin’ user and then click Settings.
  b) Select the Preferences tab from along the top of the Settings panel and update your password.
  c) Create two “dummy” connections. Guacamole will auto-login with the only connection, and by default will associate that one connection with all users, and if there is a problem with that connection, it is possible to get trapped in a login-loop in which accessing the dashboard can be difficult. See Creating a connection below, and instead of filling out any of the values, just give the connection a name, such as null0 or null1, and save the connection.


```
<user-mapping>

    <!-- Per-user authentication and config information -->
    <authorize username="USERNAME" password="PASSWORD">
        <protocol>vnc</protocol>
        <param name="hostname">localhost</param>
        <param name="port">5900</param>
        <param name="password">VNCPASS</param>
    </authorize>

    <!-- Another user, but using md5 to hash the password
         (example below uses the md5 hash of "PASSWORD") -->
    <authorize
            username="USERNAME2"
            password="319f4d26e3c536b5dd871bb2c52e3178"
            encoding="md5">

        <!-- First authorized connection -->
        <connection name="localhost">
            <protocol>vnc</protocol>
            <param name="hostname">localhost</param>
            <param name="port">5901</param>
            <param name="password">VNCPASS</param>
        </connection>

        <!-- Second authorized connection -->
        <connection name="otherhost">
            <protocol>vnc</protocol>
            <param name="hostname">otherhost</param>
            <param name="port">5900</param>
            <param name="password">VNCPASS</param>
        </connection>

    </authorize>

</user-mapping>
```
