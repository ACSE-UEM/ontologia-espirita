#!/bin/sh
# Prova que as verificacoes de disjuncao realmente detectam violacao.
# Passa quando CADA consulta encontra a violacao plantada.
set -e

cd /work

MESCLADO=/tmp/merged-invalido.ttl
robot merge --input ontology/core.ttl \
            --input ontology/reference-catalog.ttl \
            --input examples/contra-exemplos.ttl \
            --output "$MESCLADO"

FALHOU=0

if robot reason --input "$MESCLADO" --reasoner ELK --output /tmp/contra-reasoned.ttl >/tmp/contra-reason.log 2>&1; then
    echo "FALHA: robot reason nao detectou inconsistencia no grafo mesclado de contra-exemplos"
    echo "       As axiomas owl:disjointWith podem nao estar sendo verificadas por nada."
    cat /tmp/contra-reason.log
    FALHOU=1
else
    echo "OK: robot reason detectou inconsistencia no grafo mesclado (disjuncoes Casa/Orgao e Atividade/Evento), como esperado"
fi

for consulta in competency-questions/cq-01-casa-nao-e-orgao.rq \
                competency-questions/cq-04-atividade-nao-e-evento.rq \
                competency-questions/cq-07-apoio-so-para-area.rq \
                competency-questions/cq-08-sem-ciclo-em-parte-de.rq ; do
    robot query --input "$MESCLADO" --query "$consulta" /tmp/contra.csv
    LINHAS=$(wc -l < /tmp/contra.csv)
    if [ "$LINHAS" -le 1 ]; then
        echo "FALHA: $consulta nao detectou a violacao plantada em examples/contra-exemplos.ttl"
        echo "       A verificacao esta passando vazia — nao prova nada."
        FALHOU=1
    else
        echo "OK: $consulta detectou $((LINHAS - 1)) violacao(oes), como esperado"
    fi
done

if [ "$FALHOU" -ne 0 ]; then
    echo ""
    echo "== contra-exemplos FALHOU =="
    exit 1
fi

echo ""
echo "== contra-exemplos: as verificacoes de disjuncao estao funcionando =="
