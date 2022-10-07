FROM mirkobianco/delphimysql
RUN mkdir -p /app
COPY built/Linux64/Release/services/authentication/AuthenticationService /app/service
COPY artifacts/AuthenticationService.ini /app/service.ini
COPY source/services/authentication/DbMigrations /app/DbMigrations
WORKDIR /app
CMD ["./service"]