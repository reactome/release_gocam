FROM openjdk:11.0.15-jdk

RUN apt update;
RUN apt install wget git unzip maven tree -y

ENV BIOPAX_VERSION v1.1.4
ENV BLAZEGRAPH_RUNNER_VERSION 1.6
ENV OWLAPI_VERSION 4.5.26

ENV TARGET_PATH=/reactome_gen
ENV BIOPAX_PATH=$TARGET_PATH/biopax
ENV REACTO_OUT=$TARGET_PATH/reacto-out
ENV REPORTS_PATH=$TARGET_PATH/reports

WORKDIR /workdir

RUN git clone https://github.com/ontodev/robot.git && \
    cd robot && \
    mvn package -DskipTests

ENV PATH=/workdir/robot/bin:$PATH

RUN wget https://github.com/geneontology/pathways2GO/releases/download/v1.1.5/biopax2go.jar

RUN git clone https://github.com/geneontology/pathways2GO.git && \
    cd pathways2GO/exchange/ && \
    git checkout v1.1.5 && \
    mkdir bin && cd bin && \
    wget https://github.com/geneontology/pathways2GO/releases/download/v1.1.5/biopax2go.jar

RUN mkdir bin

RUN cd bin && \
    wget https://github.com/balhoff/blazegraph-runner/releases/download/v${BLAZEGRAPH_RUNNER_VERSION}/blazegraph-runner-${BLAZEGRAPH_RUNNER_VERSION}.tgz && \
    tar zxvf blazegraph-runner-${BLAZEGRAPH_RUNNER_VERSION}.tgz && \
    rm blazegraph-runner-${BLAZEGRAPH_RUNNER_VERSION}.tgz

RUN cd bin && wget https://github.com/geneontology/minerva/releases/download/v0.6.2/minerva-cli.jar 

COPY pipeline.sh .

CMD ["bash", "pipeline.sh"]
