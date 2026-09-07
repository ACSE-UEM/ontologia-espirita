#!/bin/sh
set -e

cd /work

for arquivo in ontology/reference-catalog.ttl examples/mg.ttl; do
    [ -f "$arquivo" ] || { echo "Erro: $arquivo nao encontrado — obrigatorio para a validacao."; exit 1; }
done
ls shapes/*.shacl.ttl >/dev/null 2>&1 || { echo "Erro: nenhum arquivo shapes/*.shacl.ttl encontrado — obrigatorio para a validacao."; exit 1; }
ls competency-questions/*.rq >/dev/null 2>&1 || { echo "Erro: nenhum arquivo competency-questions/*.rq encontrado — obrigatorio para a validacao."; exit 1; }

echo "== 1/4: perfil OWL 2 EL (robot validate-profile) =="
robot validate-profile --profile EL --input ontology/core.ttl --output /tmp/el-profile-report.txt

echo "== 2/4: robot reason (consistência lógica do TBox) =="
robot reason --input ontology/core.ttl --reasoner ELK --output /tmp/core-reasoned.ttl

echo "== 3/4: competency questions (robot verify) =="
robot merge --input ontology/core.ttl --input ontology/reference-catalog.ttl --input examples/mg.ttl \
    verify --queries competency-questions/*.rq

echo "== 4/4: SHACL (modelo + catálogo + exemplos) =="
robot merge --input ontology/core.ttl --input ontology/reference-catalog.ttl --input examples/mg.ttl \
    --output /tmp/dados-shacl.ttl
FALHOU=0
for shape in shapes/*.shacl.ttl; do
    echo "  -- $shape --"
    pyshacl -s "$shape" -d /tmp/dados-shacl.ttl -i rdfs || FALHOU=1
done
[ "$FALHOU" -eq 0 ] || { echo "== SHACL encontrou violacoes =="; exit 1; }

echo "== validação concluída com sucesso =="
