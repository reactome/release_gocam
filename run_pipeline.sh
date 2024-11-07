set -e

docker pull maven:3.8.7-openjdk-18-slim
mkdir -p reactome_gen
#cp /usr/local/reactomes/Reactome/production/Website/static/download/90/biopax.zip reactome_gen -f

sudo service tomcat9 stop
sudo service neo4j stop
docker build -t reactome-pathway2go:latest .;
docker run -v $(pwd)/reactome_gen:/reactome_gen reactome-pathway2go:latest
sudo service neo4j start
sudo service tomcat9 start
