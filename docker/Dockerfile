FROM obolibrary/robot:latest

RUN apt-get update \
    && apt-get install -y --no-install-recommends python3 python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --break-system-packages --no-cache-dir \
    rdflib==7.6.0 \
    pyshacl==0.40.1

# A JVM do ROBOT lê arquivos de consulta usando o charset padrão do sistema.
# Sem locale definido (LC_CTYPE=POSIX) esse padrão é ASCII, e texto acentuado
# dentro do corpo de uma consulta SPARQL sai corrompido — os dados RDF não são
# afetados porque os parsers declaram UTF-8 explicitamente. Esta ontologia é
# escrita em português: o locale UTF-8 é requisito, não conveniência.
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

WORKDIR /work
ENTRYPOINT ["/bin/sh"]
