FROM oraclelinux:7-slim

# install needed tools for installation
#RUN yum -y install coreutils gcc cc make kernel-headers tar gzip wget

RUN groupadd redis && adduser -g redis redis

ENV REDIS_VERSION 4.0.2
ENV REDIS_DOWNLOAD_URL http://download.redis.io/releases/redis-4.0.2.tar.gz
ENV REDIS_DOWNLOAD_SHA b1a0915dbc91b979d06df1977fe594c3fa9b189f1f3d38743a2948c9f7634813

# Main RUN for building the Redis server within the container
RUN set -ex; \
	\
	yum -y install coreutils gcc cc make kernel-headers tar gzip wget; \
	\
	wget -O redis.tar.gz "$REDIS_DOWNLOAD_URL"; \
	echo "$REDIS_DOWNLOAD_SHA *redis.tar.gz" | sha256sum -c -; \
	mkdir -p /usr/src/redis; \
	tar -xzf redis.tar.gz -C /usr/src/redis --strip-components=1; \
	rm redis.tar.gz; \
	\
# disable Redis protected mode [1] as it is unnecessary in context of Docker
# (ports are not automatically exposed when running inside Docker, but rather explicitly by specifying -p / -P)
# [1]: https://github.com/antirez/redis/commit/edd4d555df57dc84265fdfb4ef59a4678832f6da
	grep -q '^#define CONFIG_DEFAULT_PROTECTED_MODE 1$' /usr/src/redis/src/server.h; \
	sed -ri 's!^(#define CONFIG_DEFAULT_PROTECTED_MODE) 1$!\1 0!' /usr/src/redis/src/server.h; \
	grep -q '^#define CONFIG_DEFAULT_PROTECTED_MODE 0$' /usr/src/redis/src/server.h; \
# for future reference, we modify this directly in the source instead of just supplying a default configuration flag because apparently "if you specify any argument to redis-server, [it assumes] you are going to specify everything"
# see also https://github.com/docker-library/redis/issues/4#issuecomment-50780840
# (more exactly, this makes sure the default behavior of "save on SIGTERM" stays functional by default)
	\
	make -C /usr/src/redis -j "$(nproc)"; \
	make -C /usr/src/redis install; \
	\
# Ensure we have the right config files in place and split the files so
# we have a config file per role (master, slave or sentinel)
	mkdir -p /etc/redis && \
	cp /usr/src/redis/redis.conf /etc/redis/redis_master.conf &&\
	cp /usr/src/redis/redis.conf /etc/redis/redis_slave.conf &&\
	cp /usr/src/redis/sentinel.conf /etc/redis/redis_sentinel.conf &&\
	\
# change redis_master.conf file
	sed -i 's/^\(bind .*\)$/# \1/' /etc/redis/redis_master.conf && \
	sed -i 's/^\(daemonize .*\)$/# \1/' /etc/redis/redis_master.conf && \
	sed -i 's/^\(dir .*\)$/# \1\ndir \/data/' /etc/redis/redis_master.conf && \
	sed -i 's/^\(logfile .*\)$/# \1/' /etc/redis/redis_master.conf && \
	\
# change redis_slave.conf file
# -- no changes at this moment

# change the redis_sentinel.conf file
# -- no changes at this moment

# remove redis sources used for compilation
	rm -r /usr/src/redis; \
	\
# remove rpm's to ensure we leave a clean system
        yum -y erase gcc cc tar gzip; \
	\
#         yum -y erase coreutils gcc cc make kernel-headers tar gzip wget; \
# clean the YUM cache.	
	yum clean all


# Create a /data location to be used by Redis. 
RUN mkdir /data 
VOLUME /data
WORKDIR /data


# ensure we have an entrypoint available which will take the needed input parameters
# to start the container in the right manner. We have to make sure that the file is 
# an executable file so we have an additional chmod command to prevent possible issues
# when trying to start the file. 
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]


# make sure we expose the redis port as port 6479 outside of the container.
EXPOSE 6379


# Define a default CMD to be used in combination with the entrypoint to het Redis
# started within the container. 
CMD ["redis-server"]
