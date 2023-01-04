FROM mirkobianco/delphimysql
RUN mkdir -p /app
COPY built/Linux64/Release/services/users/UsersService /app/service
COPY artifacts/UsersService.ini /app/service.ini
COPY artifacts/libcrypto.so /app/libcrypto.so
COPY artifacts/libssl.so /app/libssl.so
COPY artifacts/libsagui.so.3.4.0 /app/libsagui.so.3
COPY source/services/users/DbMigrations /app/DbMigrations
RUN export PATH=$PATH:/app
WORKDIR /app
CMD ["./service"]