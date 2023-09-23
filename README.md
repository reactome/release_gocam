# reactome_go-cams_pipline
This pipeline generates go-cam ttl files from Biopax and validates them

The pipeline Biopax3 file was added to the root of this repo before running the pipeline. 

To build the environment container:

```bash
docker build -t reactome-pathway2go:latest .
```

and to run the pipeline run:

```bash
docker run -v $(pwd)/reactome_gen:/reactome_gen reactome-pathway2go:latest
```

This will create TTL GO-CAM files reactome_gen/reacto-out and reports in reactome_gen/reports 
