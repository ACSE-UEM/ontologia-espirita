#!/bin/sh
# Prova que as verificacoes de disjuncao realmente detectam violacao.
# Passa quando CADA reasoner isolado detecta sua violacao e CADA consulta
# encontra a violacao plantada correspondente.
set -e

cd /work

MESCLADO=/tmp/merged-invalido.ttl
robot merge --input ontology/core.ttl \
            --input ontology/reference-catalog.ttl \
            --input examples/contra-exemplos.ttl \
            --output "$MESCLADO"

FALHOU=0

# Um unico robot reason sobre o grafo mesclado nao prova nada por eixo: as
# duas violacoes plantadas sao independentes, entao a perda de UM dos dois
# axiomas de disjuncao deixa o grafo ainda inconsistente por causa do outro,
# e o reasoner continua falhando "com sucesso" — a lacuna some sem que nada
# detecte. Por isso cada axioma e verificado isoladamente: removemos do
# grafo mesclado o individuo que viola o OUTRO axioma antes de raciocinar,
# para que cada verificacao so possa passar (incorretamente) se o axioma
# que ela prova estiver mesmo faltando.

CASA_ORGAO_SO=/tmp/contra-casa-orgao-so.ttl
# --term precisa da IRI completa aqui: nesta versao do ROBOT (1.9.10), um
# CURIE (esp:...) em --term nao e resolvido para remocao e faz o comando
# descartar quase todo o grafo (sobra so o cabecalho da ontologia) em vez
# de remover so o individuo indicado — confirmado empiricamente antes de
# depender disso.
robot remove --input "$MESCLADO" \
             --term "https://w3id.org/ontologia-espirita/v1#CoisaQueEhAtividadeEEvento" \
             --output "$CASA_ORGAO_SO"

# Se o individuo indicado tiver sido renomeado ou removido de
# examples/contra-exemplos.ttl, a IRI acima deixa de existir no grafo e
# --term vira um no-op silencioso (confirmado com `robot diff`): a
# filtragem nao isola mais nada, as DUAS violacoes continuam no grafo, e
# cada verificacao abaixo passaria "corretamente" mesmo com o axioma que
# ela deveria provar ausente — a mesma lacuna que este script existe para
# fechar. Por isso a filtragem em si e verificada antes de confiar nela.
if grep -q "CoisaQueEhAtividadeEEvento" "$CASA_ORGAO_SO"; then
    echo "FALHA: a filtragem nao removeu esp:CoisaQueEhAtividadeEEvento do grafo — a verificacao Casa/Orgao nao esta isolada"
    FALHOU=1
fi

if robot reason --input "$CASA_ORGAO_SO" --reasoner ELK --output /tmp/contra-casa-orgao-reasoned.ttl >/tmp/contra-casa-orgao-reason.log 2>&1; then
    echo "FALHA: robot reason nao detectou inconsistencia isolando a violacao Casa/Orgao"
    echo "       esp:Casa owl:disjointWith esp:Orgao pode estar faltando."
    cat /tmp/contra-casa-orgao-reason.log
    FALHOU=1
else
    echo "OK: robot reason detectou inconsistencia isolada de esp:Casa owl:disjointWith esp:Orgao, como esperado"
fi

ATIVIDADE_EVENTO_SO=/tmp/contra-atividade-evento-so.ttl
robot remove --input "$MESCLADO" \
             --term "https://w3id.org/ontologia-espirita/v1#CoisaQueEhCasaEOrgao" \
             --output "$ATIVIDADE_EVENTO_SO"

if grep -q "CoisaQueEhCasaEOrgao" "$ATIVIDADE_EVENTO_SO"; then
    echo "FALHA: a filtragem nao removeu esp:CoisaQueEhCasaEOrgao do grafo — a verificacao Atividade/Evento nao esta isolada"
    FALHOU=1
fi

if robot reason --input "$ATIVIDADE_EVENTO_SO" --reasoner ELK --output /tmp/contra-atividade-evento-reasoned.ttl >/tmp/contra-atividade-evento-reason.log 2>&1; then
    echo "FALHA: robot reason nao detectou inconsistencia isolando a violacao Atividade/Evento"
    echo "       esp:Atividade owl:disjointWith esp:Evento pode estar faltando."
    cat /tmp/contra-atividade-evento-reason.log
    FALHOU=1
else
    echo "OK: robot reason detectou inconsistencia isolada de esp:Atividade owl:disjointWith esp:Evento, como esperado"
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
