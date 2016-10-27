NAME = docker-swarm-demo
VERSION = 0.0.1

all: build_alpine

build_alpine:
	docker build ./alpine-swarm-demo/ -t "ctownsend/alpine-swarm-demo"

install: build_alpine
	docker swarm init --advertise-addr 192.168.122.1
	docker network create --driver overlay my-app-network
	docker service create --replicas 1 --network my-app-network \
	--name demo-redis redis

	docker service create --replicas 1 --network my-app-network \
	--name alpine-swarm-demo ctownsend/alpine-swarm-demo /bin/sh -c "trap 'exit 0' INT TERM; while true; do echo Hello World; sleep 10; done"
	docker service ls
	echo "You'll want to perform a docker service ls until you see the instances are up and running.  Then you may connect and test."

clean:
	docker swarm leave --force
	docker rmi ctownsend/alpine-swarm-demo
