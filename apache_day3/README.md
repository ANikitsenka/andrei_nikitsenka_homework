## Task 1 
### List of all commands in script.sh (current branch).
1. Setup apache2 web server VM with mod_jk module.
2. Setup 3 VMs with tomcat server and configure them. Tomcat instances surname-tomcat1, surname-tomcat2,
surname-tomcat3:  
![img 4](./4.png)
#To add a new user who will be able to access the tomcat web interface (manager-gui and admin-gui) we need to define the user in tomcat-users.xml file as shown below.
![img 2](./2.png)
#Open access to web-interface from everywhere (forbidden for most cases).
![img 3](./3.png)
#Add to /etc/hosts of client.
![img 1](./1.png)

3. Add test.jsp from presentation to all tomcat servers.
![img 5](./5.png)
![img 6](./6.png)
![img 7](./7.png)
![img 8](./8.png)
![img 9](./9.png)
![img 10](./10.png)

4. Deploy clusterjsp.war on each tomcat:
#Autodeploy from webapps on nikitsenka-tomcat1
![img 11](./11.png)
#Deploy via browrer on nikitsenka-tomcat2
![img 12](./12.png)
#Deploy via ContextPath on nikitsenka-tomcat3
![img 13](./13.png)
![img 14](./14.png)

## Task 2

1.Using mod_jk configure Tomcat Cluster with session persistence (replication):
a. Configure 4 separate Virtual hosts for nikitsenka-tomcat1.lab, nikitsenka-tomcat2.lab, nikitsenka-tomcat3.lab
and Tomcat Cluster (Apache cluster) – nikitsenka-cluster.lab.

![img 15](./15.png)

b. Configure mod_jk – worker.properties

![img 17](./17.png)

c. Setup cluster and check that you can reach clusterjsp app via sfirewall-cmd --reload.
d. Check session persistence by stopping active tomcat server.

![img 18](./18.png)
#Sessions attributes without changes.
![img 19](./19.png)
#Sticky_session set to 1, but session ID changes with any request.

## Task 3

1. Configure Log4j2 logging for one of the tomcat servers.
#Unpack archive to /opt/tomcat/lib
![img 20](./20.png)
#Create script setenv.sh
![img 21](./21.png)
#Create a file called log4j2.xml into /opt/tomcat/conf
![img 22](./22.png)
#Run startup.sh
![img 23](./23.png)
#log
![img 24](./24.png)

![img 25](./25.png)

Thanks for your attention. File 'script.sh' contain commands.
