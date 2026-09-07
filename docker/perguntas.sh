#!/bin/sh
# Roda as perguntas de queries/ contra o modelo + catalogo + exemplos e
# imprime as respostas. Nao falha por conteudo: e ferramenta de inspecao,
# nao de verificacao. Quem falha e o `make verify`.
set -e

cd /work

MESCLADO=/tmp/merged.ttl
robot merge --input ontology/core.ttl \
            --input ontology/reference-catalog.ttl \
            --input examples/mg.ttl \
            --output "$MESCLADO"

for consulta in queries/*.rq; do
    TITULO=$(head -1 "$consulta" | sed 's/^#[[:space:]]*//')
    echo ""
    echo "── $TITULO ──"
    robot query --input "$MESCLADO" --query "$consulta" /tmp/resposta.csv
    if [ "$(wc -l < /tmp/resposta.csv)" -le 1 ]; then
        echo "  (sem resultados)"
    else
        tail -n +2 /tmp/resposta.csv | sed 's/,/  |  /g' | sed 's/^/  /'
    fi
done

echo ""
