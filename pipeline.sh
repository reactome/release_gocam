set -e

mkdir -p $BIOPAX_PATH $REACTO_OUT $REPORTS_PATH
rm $BIOPAX_PATH $REACTO_OUT $REPORTS_PATH -r
mkdir -p $BIOPAX_PATH $REACTO_OUT $REPORTS_PATH

unzip $TARGET_PATH/biopax.zip -d $BIOPAX_PATH/

if [ -f "$TARGET_PATH/go-lego.owl" ]; then
    echo "GO Lego file already exists. Skipping download."
else
    wget -P $TARGET_PATH http://current.geneontology.org/ontology/extensions/go-lego.owl
fi

if [ -f "$TARGET_PATH/chebi.owl" ]; then
    echo "ChEBI OWL file already exists. Skipping download."
else
    wget -P $TARGET_PATH https://ftp.ebi.ac.uk/pub/databases/chebi/ontology/chebi.owl
fi

java -jar -Xmx24G pathways2GO/exchange/bin/biopax2go.jar -b $BIOPAX_PATH/Homo_sapiens.owl -bg $REACTO_OUT/blazegraph.jnl -o $REACTO_OUT/ -e REACTO -dc GOC:reactome_curators -dp https://reactome.org -lego $TARGET_PATH/go-lego.owl > $REPORTS_PATH/biopax2go.log
grep DELETING_NON_SMALL_MOL_REGULATOR $REPORTS_PATH/biopax2go.log | cut -f2- > $REPORTS_PATH/deleted_regulators.tsv
java -jar -Xmx24G pathways2GO/exchange/bin/biopax2go.jar -b $BIOPAX_PATH/Homo_sapiens.owl -reacto $TARGET_PATH/reacto -chebi $TARGET_PATH/chebi.owl -lego $TARGET_PATH/go-lego.owl
robot export --input $TARGET_PATH/reacto.ttl --header "IRI|LABEL" --format tsv --export $TARGET_PATH/reacto_labels.tsv
join -t "	" -a 1 -j 1 -o 1.1,2.2,1.3,1.4 <(sort $REPORTS_PATH/deleted_regulators.tsv) <(sort -n $TARGET_PATH/reacto_labels.tsv) > $REPORTS_PATH/deleted_regulators_labels.tsv

cp $REACTO_OUT/blazegraph.jnl $REACTO_OUT/reacto-models-bg.jnl

if [ -f "$TARGET_PATH/go-lego-reacto.owl" ]; then
    echo "GO Lego Reacto file already exists. Skipping download."
else
    wget -P $TARGET_PATH http://current.geneontology.org/ontology/extensions/go-lego-reacto.owl
fi

/workdir/bin/blazegraph-runner-${BLAZEGRAPH_RUNNER_VERSION}/bin/blazegraph-runner load --journal=$REACTO_OUT/reacto-models-bg.jnl --use-ontology-graph=true --informat=rdfxml $TARGET_PATH/go-lego-reacto.owl
/workdir/bin/blazegraph-runner-${BLAZEGRAPH_RUNNER_VERSION}/bin/blazegraph-runner reason --journal=$REACTO_OUT/reacto-models-bg.jnl --ontology="http://purl.obolibrary.org/obo/go/extensions/go-lego-reacto.owl" --source-graphs-query="/workdir/pathways2GO/exchange/src/main/resources/org/geneontology/gocam/exchange/manuscript-graphs.rq" --target-graph=”http://model.geneontology.org/inferences” --merge-sources=false --parallelism=8 --reasoner=arachne
java -Xmx24G -cp pathways2GO/exchange/bin/biopax2go.jar org.geneontology.garage.Manuscript -b $BIOPAX_PATH/Homo_sapiens.owl -j $REACTO_OUT/reacto-models-bg.jnl -g $REACTO_OUT/ -r $REPORTS_PATH/

java -jar -Xmx12G bin/minerva-cli.jar --validate-go-cams --shex -i $REACTO_OUT/blazegraph.jnl -r $REPORTS_PATH/ -ontojournal $TARGET_PATH/blazegraph-lego.jnl
