# EC2 Tunnel (Port Forwarding)

## Server setup (public network)

- Create ec2 instance (im using ubuntu image)
- configure GatewayPorts yes or nginx (if you want to expose to the internet)
- sudo service sshd restart

## Client setup (private network)

- Create ec2 instance (im using ubuntu image)
- add remote pem key
- tunnel local port: ssh -N -i "key.pem" ubuntu@remote-ip -R 8080:localhost:80 -C

curl remote-ip:8080 => localhost:80
