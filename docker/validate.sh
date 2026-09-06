#!/bin/sh
set -e

cd /work

echo "== 1/3: robot reason (consistência lógica do TBox) =="
robot reason --input ontology/core.ttl --reasoner ELK --output /tmp/core-reasoned.ttl

echo "== 2/3: competency questions (robot verify) =="
if [ -d competency-questions ] && ls competency-questions/*.rq >/dev/null 2>&1; then
    if [ -f ontology/reference-catalog.ttl ]; then
        robot merge --input ontology/core.ttl --input ontology/reference-catalog.ttl verify --queries competency-questions/*.rq
    else
        robot verify --input ontology/core.ttl --queries competency-questions/*.rq
    fi
else
    echo "  (nenhum arquivo .rq encontrado ainda — pulando)"
fi

echo "== 3/3: SHACL do catálogo de referência =="
if [ -f ontology/reference-catalog.ttl ] && ls shapes/*.shacl.ttl >/dev/null 2>&1; then
    for shape in shapes/*.shacl.ttl; do
        echo "  -- $shape --"
        pyshacl -s "$shape" -d ontology/reference-catalog.ttl -e ontology/core.ttl -i rdfs
    done
else
    echo "  (catálogo de referência ou shapes ainda não existem — pulando)"
fi

echo "== validação concluída com sucesso =="
