set -e

sudo service tomcat9 stop
sudo service neo4j stop
docker build -t reactome-pathway2go:latest .;
docker run -v $(pwd)/reactome_gen:/reactome_gen reactome-pathway2go:latest
sudo service neo4j start
sudo service tomcat9 start
