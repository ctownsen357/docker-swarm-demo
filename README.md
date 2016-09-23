# docker-swarm-demo
This assumes you have several machines or VMs with Docker 1.12.x or greater installed.  It is very important that each machines time is synchronized via NTP or manually. For a quick and dirty test you can sync them manually with the following command:

```{bash}
$ sudo date --set="$(ssh you@your-computer date)"
```

### Initialize at least one Manager node
```{bash}
$ sudo docker swarm init 
```
This command will return the command you need to use in order to join the cluster; the command to be executed on your worker nodes.

* Note: * It has been my experience that on some machines setting the `--listen-addr your.ip.address:2377` is necessary.
* 

### Initialize one or more workers
```{bash}
$ docker swarm join \
>     --token SOME----LONG-----TOKEN \
>     manager.ip.address:2377
```


### Create a network overlay from a manager node
This allows the services to reference one another by container/service name just like one would do in a Docker Compose file:

```{bash}
$ docker network create --driver overlay my-app-network
```

### Create a service to run on the cluster (within the network overlay):
```{bash}
$ docker service create --replicas 1 --network my-app-network \
>   --name demo-redis redis
```

### Create a service to call Redis
I'm going to create a service that I can attach to, to run a simple Python script to interact with Redis.

```{bash}
docker service create --replicas 1 --network my-app-network \
--name demo-alpine alpine /bin/sh -c "trap 'exit 0' INT TERM; while true; do echo Hello World; sleep 1; done"
```

#### To do:
- Show how to list machines services are running on
- Explain how to attach to shell of Alpine container
- apk add --update py-pip
- test call to Redis service
- Scale Redis
- Demo that new service was brought online*
- Clean up README
