FROM mirkobianco/delphimysql
RUN mkdir -p /app
COPY built/Linux64/Release/services/authorization/AuthorizationService /app/service
COPY artifacts/AuthorizationService.ini /app/service.ini
COPY artifacts/libcrypto.so /app/libcrypto.so
COPY artifacts/libssl.so /app/libssl.so
COPY artifacts/libsagui.so.3.4.0 /app/libsagui.so.3
COPY source/services/authorization/DbMigrations /app/DbMigrations
WORKDIR /app
CMD ["./service"]
