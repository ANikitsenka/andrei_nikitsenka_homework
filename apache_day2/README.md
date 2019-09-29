# andrei_nikitsenka_homework

##Apache_day2


## Task 1 
### Installing httpd
Start httpd, check httpd syntax with “httpd -S”, open test page in browser, stop httpd service:  
![img 1](./apache_day1/1.png)
![img 2](./apache_day1/2.png)

### Installing apache2
Start apache2, check apache syntax with “apachectl -S”, open test page in browser, stop apache service:  
![img 3](./apache_day1/3.png)
![img 4](./apache_day1/4.png)
![img 5](./apache_day1/5.png)


What is apache graceful restart?
A graceful restart tells the web sever to finish any active connections before restarting. This means that active visitors to your site will be able to finish downloading anything already in progress before the server restarts.

It mean we should add “graceful” for restarting command for live-servers.


## Task 2
### Using vhosts and redirection
I use httpd server:  
![img 6](./apache_day1/6.png)


Configure client machine so it can resolve virtual host server name and alias:  
![img 7](./apache_day1/7.png)


Create test html page named ping.html in virtual host root directory:  
![img 8](./apache_day1/8.png)


Check web server syntax with -S flag:  
![img 9](./apache_day1/9.png)

Start\restart web server. Open test page in browser:  
![img 10](./apache_day1/10.png)
![img 11](./apache_day1/11.png)


Configure mod rewrite for Virtual host and check it with debug console:  
![img 12](./apache_day1/12.png)
![img 13](./apache_day1/13.png)


## Task 3
### using cronolog
Screenshot of virtual host with cronolog configuration, output of tree command showing layout of log files created by cronolog:  
![img 14](./apache_day1/14.png)
![img 15](./apache_day1/15.png)

Screenshot of virtual host configuration with logging to syslog. Screenshots of syslog entries related to access/error web server logging:  
![img 16](./apache_day1/16.png)
![img 17](./apache_day1/17.png)
