# Deploy Apache Guacamole in the Rapid Access Cloud
Guacamole is an HTML5-based clientless remote desktop gateway. It proxies connections between the guacamole server and any number of RDP, VPN or SSH connections. In the Rapid Access Cloud this is a way that one IPv4 address can be used amongst many different connections.
This document will detail how to deploy an instance in Cybera’s Rapid Access Cloud that will host guacamole and provide RDP access. There are example instructions on creating users and connections at the end of the document that detail how to use guacamole with RDP.

**Requirements:**
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

## Configuring guacamole users and connections
### User creation
1. Logged in as guacadmin, click the navigation menu in the top-right corner labelled with the current user (guacadmin) and select Settings.
2. Select the Users tab from along the top of the Settings panel then click the + New User button.
3. Fill out the username and password fields as needed. The Account Restrictions are optional.
4. For permissions, the following is recommended for users to be able to log in and create their own connections:
Administer system:			✕
Create new users:			✕
Create new connections:		✓
Create new connection groups:	✕
Create new sharing profiles:		✕
Change own password:		✓
5. Once the first user is created, each subsequent user can be created with the Clone button at the bottom of the page.

### Connection creation
1. Log in to the guacamole proxy with a user that has Administer system privileges (see User Creation), click the navigation menu in the top-right corner labelled with the current user and select Settings.
2. Select the Connections tab from along the top of the Settings panel then click the + New Connection button.
3. The following are the required values to get a Windows machine working via RDP. All other values in the Edit Connection screen are optional to this environment:

Note: This example assumes that the user, Alice, has access to an instance that has been created using the same ‘rdp’ security group created by the Terraform script. The IP address used in the Hostname field is the private 10.1.0.0/20 or 10.2.0.0/20 address automatically assigned to the default network interface when a Rapid Access Cloud instance is launched.
```
Name: “Alice’s Windows VM”
Protocol: RDP

Parameters
	Network
        Hostname:	<private-ip-address> (10.1.0.0/20 or 10.2.0.0/20)
        Port:		3389 (standard RDP port)
    Authentication
        Username:			alice
        Password: 			alicespassword
        Security mode:		Any
        Ignore server certificate:	✓
```

## Advanced Features
### user-mapping.xml
Guacamole's default authentication module is simple and consists of a mapping of usernames to configurations. This authentication module comes with Guacamole and simply reads usernames and passwords from an XML file. It is always enabled, but will only read from the XML file if it exists, and is always last in priority relative to any other authentication extensions. This is very little security in this, as the passwords are saved plaintext on the guacamole server; this means that the passwords are for access not security. It is possible to replace the default authentication, but that is beyond the scope of this implementation. See https://guacamole.incubator.apache.org/doc/gug/configuring-guacamole.html for more information.

If creating users and connections by hand sounds tedious, it is possible to build all the user and connections using the example below, and saving the file to `/etc/guacamole/user-mapping.xml`.
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
