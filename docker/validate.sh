#!/bin/sh
set -e

cd /work

echo "== 1/4: perfil OWL 2 EL (robot validate-profile) =="
robot validate-profile --profile EL --input ontology/core.ttl --output /tmp/el-profile-report.txt

echo "== 2/4: robot reason (consistência lógica do TBox) =="
robot reason --input ontology/core.ttl --reasoner ELK --output /tmp/core-reasoned.ttl

echo "== 3/4: competency questions (robot verify) =="
if [ -d competency-questions ] && ls competency-questions/*.rq >/dev/null 2>&1; then
    ENTRADAS="--input ontology/core.ttl"
    [ -f ontology/reference-catalog.ttl ] && ENTRADAS="$ENTRADAS --input ontology/reference-catalog.ttl"
    [ -f examples/mg.ttl ] && ENTRADAS="$ENTRADAS --input examples/mg.ttl"
    robot merge $ENTRADAS verify --queries competency-questions/*.rq
else
    echo "  (nenhum arquivo .rq encontrado ainda — pulando)"
fi

echo "== 4/4: SHACL (modelo + catálogo + exemplos) =="
if ls shapes/*.shacl.ttl >/dev/null 2>&1; then
    ENTRADAS="--input ontology/core.ttl"
    [ -f ontology/reference-catalog.ttl ] && ENTRADAS="$ENTRADAS --input ontology/reference-catalog.ttl"
    [ -f examples/mg.ttl ] && ENTRADAS="$ENTRADAS --input examples/mg.ttl"
    robot merge $ENTRADAS --output /tmp/dados-shacl.ttl
    for shape in shapes/*.shacl.ttl; do
        echo "  -- $shape --"
        pyshacl -s "$shape" -d /tmp/dados-shacl.ttl -i rdfs
    done
else
    echo "  (shapes ainda não existem — pulando)"
fi

echo "== validação concluída com sucesso =="
