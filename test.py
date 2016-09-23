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
