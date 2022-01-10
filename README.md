# phpipam-agent

phpIPAM is an open-source web IP address management application. Its goal is to provide light and simple IP address management application.

phpIPAM is developed and maintained by Miha Petkovsek, released under the GPL v3 license, project source is [here](https://github.com/phpipam/phpipam-agent)

Learn more on [phpIPAM homepage](http://phpipam.net)

This container can be used as a remote discovery scan agent.

## How to use this Docker image

### Setup PHPIPAM

* Configure a remote agent (Administration > scan agents), get the key.
![config_agent](https://user-images.githubusercontent.com/4225738/45190599-0b799000-b23f-11e8-9e41-fb993606264d.png)

* For each subnet, enable scan & configure the remote agent by selecting a remote.
![config_subnet](https://user-images.githubusercontent.com/4225738/45190619-2ba94f00-b23f-11e8-9e45-b5e721c63d70.png)

### Setup database

* Configure MySQL/MariaDB to [listen for incoming connections](https://mariadb.com/kb/en/configuring-mariadb-for-remote-client-access/) (not bind to loopback)

* Grant remote access to the database:
```
$ mysql -u root -p
> GRANT SELECT on `phpipam`.* TO 'username'@'192.168.1.%' identified by "securePasswordHere";
> GRANT INSERT on `phpipam`.* TO 'username'@'192.168.1.%' identified by "securePasswordHere";
> GRANT UPDATE on `phpipam`.* TO 'username'@'192.168.1.%' identified by "securePasswordHere";
> GRANT DELETE on `phpipam`.* TO 'username'@'192.168.1.%' identified by "securePasswordHere";
```
*Use `%` as a wildcard. `'phpipam'@'192.168.1.%'` would allow the user `phpipam` to access the database from any host on the `192.168.1.0/24` network. `'phpipam'@'%'` would let that user in from ANY host.*

### Run this container

```bash
version: '3'
services:
    phpipam-agent:
        container_name: phpipam-agent
        restart: unless-stopped
        image: jbowdre/phpipam-agent:latest
        environment:
          - IPAM_DATABASE_HOST=ipamhost.local
          - IPAM_DATABASE_NAME=phpipam
          - IPAM_DATABASE_USER=phpipam
          - IPAM_DATABASE_PASS=phpipamadmin
          - IPAM_DATABASE_PORT=3306
          - IPAM_AGENT_KEY=2RuQ0rt4Rir29vGN4_1ZOqShcUX7PSUb
          - IPAM_SCAN_INTERVAL=15m
          - IPAM_RESET_AUTODISCOVER=false
          - IPAM_REMOVE_DHCP_false
          - TZ=UTC
```

## Configuration Parameters
| Parameter | Description |
| --- | --- |
| `IPAM_DATABASE_HOST` | IP/FQDN where the phpIPAM database is running |
| `IPAM_DATABASE_NAME` | Name of the database on the host *(Optional; default: `phpipam`)* |
| `IPAM_DATABASE_USER` | Database user with required privileges *(Optional; default: `phpipam`)* |
| `IPAM_DATABASE_PASS` | Password for that user |
| `IPAM_DATABASE_PORT` | Port number for the database listener *(Optional; default: `3306`)* |
| `IPAM_AGENT_KEY` | Unique key generated by phpIPAM for each scan agent |
| `IPAM_SCAN_INTERVAL` | How frequently the Status and Discovery scans will run (Valid options: `5m`, `10m`, `15m`, `30m`, `1h`, `2h`, `4h`, `6h`, `12h`) *(Optional; default: `15m`)* |
| `IPAM_RESET_AUTODISCOVER` | Enable the agent to remove autodiscovered IPs which are offline *(Optional; default: `false`)* |
| `IPAM_REMOVE_DHCP` | Enable the agent to remove inactive DHCP addresses *(Optional; default: `false`)* |

## Logging
The logs are available on stdout/stderr (allowing to use `docker logs`).

## Acknowledgements

Based on [mc303/phpipam-agent](https://github.com/mc303/phpipam-agent) which is based on [pierrecdn/phpipam-agent](https://github.com/pierrecdn/phpipam-agent) and [published on docker hub](https://hub.docker.com/r/pierrecdn/phpipam-agent).

