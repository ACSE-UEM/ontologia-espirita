FROM obolibrary/robot:latest

RUN apt-get update \
    && apt-get install -y --no-install-recommends python3 python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --break-system-packages --no-cache-dir \
    rdflib==7.6.0 \
    pyshacl==0.40.1

WORKDIR /work
ENTRYPOINT ["/bin/sh"]
