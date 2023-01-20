docker build . -f source\services\authentication\Dockerfile -t mirkobianco/authentication:latest
docker build . -f source\services\authorization\Dockerfile -t mirkobianco/authorization:latest
docker build . -f source\services\users\Dockerfile -t mirkobianco/users:latest
