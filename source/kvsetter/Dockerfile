FROM mirkobianco/delphibase
RUN mkdir -p /app
COPY built/Linux64/Release/kvsetter/KVSetter /app/service
COPY artifacts/KVSetter.ini /app/service.ini
COPY source/kvsetter/data /app/data
WORKDIR /app
CMD ["./service"]