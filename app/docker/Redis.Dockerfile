FROM redis:alpine3.20
# The source file-path assumes that we are running docker build
# from the app/ directory.
COPY /docker/redis.conf /usr/local/etc/redis/redis.conf
EXPOSE 6379
CMD [ "redis-server", "/usr/local/etc/redis/redis.conf" ]
