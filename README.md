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

**Note:** It has been my experience that on some machines setting the `--listen-addr your.ip.address:2377` is necessary.

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
--name demo-alpine alpine /bin/sh -c "trap 'exit 0' INT TERM; while true; do echo Hello World; sleep 10; done"
```

**Note:** At this point we've created a container that doesn't really do anything but we'll be logging into it so we can explore interactively to see what is going on.


### find the node the demo-alpine service is running on

`docker service ps demo-alpine #this will report which node is running the container`

### SSH into the node that is running demo-alpine and attach to it's shell

```{bash}
docker ps #lists all the running containers on that node, find the container ID of demo-alpine

docker exec -i -t <container id> /bin/sh
```
### Once in the container, install Python, pip, and redis for Python:
```{bash}

apk update

apk add python

apk add py-pip

pip install redis
```
create a script to hit your redis service by container/service name vi test.py and paste something like this:
```{python}
import redis
import time

loopy = True

while loopy == True:
    # I'm creating the connection each time so we can see the change when we scale the Redis service
    # and the new service is brought online; connections should start rotating through the scaled Redis servers.
    # If one uses a Redis connection scoped outside of the loop then it would remain connected to the first Redis
    # service and we wouldn't see the new one come online.

    r = redis.StrictRedis(host='demo-redis', port=6379, db=0)
    r.incr('counter')
    print(r.get('counter'))
    time.sleep(3)
```
### run the script from within your demo-alpine container
```{bash}
python test.py
1
2
3
...
```

Notice that I've referenced the redis service by its container/service name not by IP, as it could be anywhere on the cluster. You should start seeing the incremented values print to screen.

For extra fun, if it is working for you, scale the redis service and you can see it occur because the already running Python script will start hitting the new scaled service and print some requests against the new service (starting at 1 again).

### ssh into the manager node from another terminal session so you don't stop your demo-alpine session
```{bash}
docker service scale demo-redis=3
```
You should start seeing new increment values printing to the screen from the newly scaled redis service and the cluster should round-robin requests to each newly created redis service. Synching that data is another story - but that wasn't the point of the quick demo!

