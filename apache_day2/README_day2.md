# andrei_nikitsenka_homework


## Task 1 

### MPM worker module
Configure hybrid multi-process multi-threaded httpd server (i.e., worker):  
![img 1](./apache_day2_1.png)

Set server fqdn to worker.name.surname:  
![img 2](./apache_day2_2.png)
![img 3](./apache_day2_3.png)

Set MaxRequestWorkers to 50. If necessary, change other module settings accordingly and start httpd server:  
![img 4](./apache_day2_4.png)

Show that httpd is using worker module:  
![img 5](./apache_day2_5.png)

Using ab benchmarking tool prove that server can process only 50 simultaneous requests:  
![img 6](./apache_day2_6.png)

Show process tree, which includes workers and threads:  
![img 7](./apache_day2_7.png)


### MPM prefork module

Stop httpd server and configure non-threaded httpd server (i.e., prefork). Set server fqdn to prefork.name.surname:  
![img 8](./apache_day2_8.png)

Set MaxRequestWorkers to 25. If necessary, change other module settings accordingly and start httpd server:  
![img 9](./apache_day2_9.png)

Show that httpd is using prefork module:  
![img 10](./apache_day2_10.png)

Using ab benchmarking tool prove that server can process only 25 simultaneous requests.
Show process tree, which includes workers:  
![img 11](./apache_day2_11.png)


## Task 2

### Proxy

Review proxying. Review mod_proxy configuration.
Configure httpd as a forward proxy with authentication. Set proxy fqdn to forward.name.surname:  
![img 12](./apache_day2_12.png)
![img 13](./apache_day2_13.png)
![img 14](./apache_day2_14.png)

Grant access to internet via proxy only for user Name_Surname:  
![img 15](./apache_day2_15.png)
![img 16](./apache_day2_16.png)
![img 17](./apache_day2_17.png)

Configure httpd as a reverse proxy to any url of your choice. Set proxy fqdn to reverse.name.surname:  
![img 18](./apache_day2_18.png)
![img 19](./apache_day2_19.png)
![img 20](./apache_day2_20.png)


