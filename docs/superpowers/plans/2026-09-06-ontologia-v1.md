# Ontologia do Movimento Espírita v1.0 — Plano de Implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produzir a ontologia estável v1.0 do movimento espírita brasileiro (TBox + catálogo de referência limitado), com pipeline Docker de validação automática (reasoner + queries de competência + SHACL) e a documentação de apoio.

**Architecture:** Um arquivo Turtle (`ontology/core.ttl`) é a fonte da verdade (TBox). Um segundo arquivo (`ontology/reference-catalog.ttl`) guarda instâncias estáveis (ABox limitado). Um `Dockerfile` empacota ROBOT (reasoner ELK + `robot verify`) e pyshacl numa única imagem, usada tanto localmente quanto no CI do GitHub Actions a cada Pull Request. Cada "pergunta de competência" vira um arquivo `.rq` versionado — o equivalente, neste domínio, a um teste automatizado.

**Tech Stack:** OWL/Turtle, ROBOT (obolibrary/robot, Java/ELK), SHACL via pyshacl, Python 3 + rdflib (geração de `context.jsonld`), Docker, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-09-06-ontologia-v1-design.md`

## Global Constraints

- IRI base da ontologia: `https://w3id.org/ontologia-espirita/v1#` (prefixo `esp:`), documento da ontologia em `<https://w3id.org/ontologia-espirita/v1>`.
- Toda `owl:Class`, `owl:ObjectProperty` e `owl:DatatypeProperty` precisa de `rdfs:label` com tag de idioma `pt-BR` (verificado por consulta automática, não por revisão manual).
- Nenhum dado geográfico fino (municípios, códigos IBGE em massa) entra neste repositório — apenas o "gancho" (`esp:localizadaEm`, `esp:codigoIBGE`).
- Nenhuma instância de `Casa` ou `Pessoa` entra no catálogo de referência — só entidades federativas estáveis.
- Todo passo de validação roda dentro da imagem Docker definida na Task 2 — nenhuma ferramenta é instalada "no host" fora do container (garante que o CI e o ambiente local rodem exatamente a mesma coisa).
- Versão da ontologia: `1.0.0` (SemVer), gravada em `owl:versionInfo` e em `CHANGELOG.md`.

---

## Task 1: Scaffold do repositório

**Files:**
- Create: `ontology/.gitkeep` (removido na Task 3 quando `core.ttl` existir)
- Create: `competency-questions/.gitkeep` (removido na Task 3)
- Create: `shapes/.gitkeep` (removido na Task 8)
- Create: `docker/.gitkeep` (removido na Task 2)
- Create: `docs/.gitkeep` (removido na Task 11)
- Create: `.gitignore`
- Create: `CHANGELOG.md`

**Interfaces:**
- Produz apenas a árvore de diretórios que as tarefas seguintes populam. Nenhuma outra tarefa depende de conteúdo desta, só da existência dos diretórios.

- [ ] **Step 1: Criar a árvore de diretórios**

```bash
mkdir -p ontology competency-questions shapes docker
touch ontology/.gitkeep competency-questions/.gitkeep shapes/.gitkeep docker/.gitkeep
```

- [ ] **Step 2: Criar `.gitignore`**

```gitignore
__pycache__/
*.pyc
.venv/
```

- [ ] **Step 3: Criar `CHANGELOG.md`**

```markdown
# Changelog

Todas as mudanças notáveis da ontologia são documentadas aqui.
Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
versionamento [SemVer](https://semver.org/lang/pt-BR/).

## [Não lançado]

### Adicionado
- Estrutura inicial do repositório.
```

- [ ] **Step 4: Verificar a árvore criada**

Run: `find . -maxdepth 1 -type d -not -path './.git*' | sort`
Expected: lista incluindo `./competency-questions`, `./docker`, `./docs`, `./ontology`, `./shapes` (mais os já existentes `./desorganizados`, `./intents`, `./nog`, `./specs`).

- [ ] **Step 5: Commit**

```bash
git add ontology competency-questions shapes docker .gitignore CHANGELOG.md
git commit -m "chore: scaffold repository structure for ontologia v1.0

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01HS4qvMFDvwotFt1qNETLtf"
```

---

## Task 2: Ambiente Docker de validação

**Files:**
- Create: `docker/Dockerfile`
- Create: `docker/validate.sh`

**Interfaces:**
- Produz: a imagem Docker `ontologia-espirita-ci` (construída localmente com essa tag) e o script `docker/validate.sh`, que todas as tarefas seguintes (3–8) usam para autovalidar seu trabalho, e que a Task 10 (CI) invoca sem modificações.
- Consome: nada de tarefas anteriores além dos diretórios da Task 1.

- [ ] **Step 1: Escrever o Dockerfile**

```dockerfile
FROM obolibrary/robot:latest

RUN apt-get update \
    && apt-get install -y --no-install-recommends python3 python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --break-system-packages --no-cache-dir \
    rdflib==7.6.0 \
    pyshacl==0.40.1

WORKDIR /work
ENTRYPOINT ["/bin/sh"]
```

- [ ] **Step 2: Construir a imagem e verificar que falha (ainda não há script pra rodar)**

Run: `docker build -t ontologia-espirita-ci -f docker/Dockerfile docker/`
Expected: build completo com sucesso (a imagem em si não faz nada ainda — é só a base).

Nota de implementação (desvio deliberado do spec): o spec de design cita
`robot report` como passo de lint separado. O perfil padrão de
`robot report` pressupõe convenções de metadados do OBO Foundry (IAO,
xrefs) que esta ontologia não usa, então o lint de rótulos pt-BR é feito
como uma competency question comum (`cq-00`, Task 3) rodada via
`robot verify` — mesmo objetivo (nenhuma classe/propriedade sem rótulo),
ferramenta única e mais previsível.

- [ ] **Step 3: Escrever `docker/validate.sh`**

Este script roda dentro do container (via `docker run -v $(pwd):/work ontologia-espirita-ci /work/docker/validate.sh`) e executa, em ordem: reasoning, competency questions, SHACL do catálogo de referência.

```bash
#!/bin/sh
set -e

cd /work

echo "== 1/3: robot reason (consistência lógica do TBox) =="
robot reason --input ontology/core.ttl --reasoner ELK --output /tmp/core-reasoned.ttl

echo "== 2/3: competency questions (robot verify) =="
if [ -d competency-questions ] && ls competency-questions/*.rq >/dev/null 2>&1; then
    robot verify --input ontology/core.ttl --queries competency-questions/*.rq
else
    echo "  (nenhum arquivo .rq encontrado ainda — pulando)"
fi

echo "== 3/3: SHACL do catálogo de referência =="
if [ -f ontology/reference-catalog.ttl ] && ls shapes/*.shacl.ttl >/dev/null 2>&1; then
    for shape in shapes/*.shacl.ttl; do
        echo "  -- $shape --"
        pyshacl -s "$shape" -d ontology/reference-catalog.ttl -i rdfs
    done
else
    echo "  (catálogo de referência ou shapes ainda não existem — pulando)"
fi

echo "== validação concluída com sucesso =="
```

- [ ] **Step 4: Tornar o script executável e testar (deve falhar, `core.ttl` ainda não existe)**

```bash
chmod +x docker/validate.sh
docker run --rm -v "$(pwd)":/work ontologia-espirita-ci /work/docker/validate.sh
```

Expected: falha com erro tipo `Error: could not read input 'ontology/core.ttl'` ou `No such file`, confirmando que o script está sendo executado e checando o arquivo certo.

- [ ] **Step 5: Commit**

```bash
git add docker/Dockerfile docker/validate.sh
git rm --cached docker/.gitkeep
git commit -m "chore: add Docker validation pipeline (robot + pyshacl)

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01HS4qvMFDvwotFt1qNETLtf"
```

---

## Task 3: Cabeçalho da ontologia, classes de topo e verificação de rótulos

**Files:**
- Create: `ontology/core.ttl`
- Create: `competency-questions/README.md`
- Create: `competency-questions/cq-00-labels-pt-br.rq`

**Interfaces:**
- Produz: `ontology/core.ttl` com prefixo `esp:` = `https://w3id.org/ontologia-espirita/v1#`, e as classes de topo `esp:Organizacao`, `esp:Pessoa`, `esp:Atividade`, `esp:Localizacao`, `esp:AreaDeAtuacao`, e a propriedade `esp:parteDe`. Tarefas 4–7 fazem `rdfs:subClassOf` dessas classes.
- Consome: a imagem `ontologia-espirita-ci` e `docker/validate.sh` da Task 2.

- [ ] **Step 1: Escrever a pergunta de competência CQ-00 (falha primeiro — ainda não há ontologia)**

`competency-questions/README.md`:

```markdown
# Competency Questions

Cada arquivo `.rq` é uma consulta SPARQL de **violação**: ela deve retornar
**zero linhas** quando a ontologia está correta. Se retornar alguma linha,
é uma pergunta que a ontologia deveria conseguir responder corretamente e
não consegue — `robot verify` falha o CI nesse caso.

Convenção de nomes: `cq-NN-descricao-curta.rq`, com um comentário no topo
do arquivo explicando, em português, a pergunta de competência que a
consulta verifica.
```

`competency-questions/cq-00-labels-pt-br.rq`:

```sparql
# CQ-00: Toda classe e propriedade da ontologia tem um rótulo em pt-BR?
# (violação = entidade sem rdfs:label com tag de idioma pt-BR)
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

SELECT ?entidade
WHERE {
  { ?entidade a owl:Class }
  UNION { ?entidade a owl:ObjectProperty }
  UNION { ?entidade a owl:DatatypeProperty }
  FILTER NOT EXISTS {
    ?entidade rdfs:label ?rotulo .
    FILTER(LANGMATCHES(LANG(?rotulo), "pt-BR"))
  }
}
```

Nota: `LANGMATCHES` (comparação case-insensitive por RFC 4647), não `LANG(?rotulo) = "pt-BR"` —
o Jena (usado pelo ROBOT) normaliza tags de idioma para minúsculas (`pt-br`) ao
parsear, então uma comparação de string exata contra `"pt-BR"` falha mesmo
com dados corretos. Confirmado empiricamente durante a implementação da
Task 3.

- [ ] **Step 2: Rodar a validação e confirmar que falha (core.ttl não existe)**

Run: `docker run --rm -v "$(pwd)":/work ontologia-espirita-ci /work/docker/validate.sh`
Expected: falha na etapa 1/3 (`robot reason`), porque `ontology/core.ttl` ainda não existe.

- [ ] **Step 3: Escrever `ontology/core.ttl` com o cabeçalho e as classes de topo**

```turtle
@prefix owl: <http://www.w3.org/2002/07/owl#> .
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
@prefix esp: <https://w3id.org/ontologia-espirita/v1#> .

<https://w3id.org/ontologia-espirita/v1> a owl:Ontology ;
    rdfs:label "Ontologia do Movimento Espírita Brasileiro"@pt-BR ;
    owl:versionInfo "1.0.0" .

esp:Organizacao a owl:Class ;
    rdfs:label "Organização"@pt-BR .

esp:Pessoa a owl:Class ;
    rdfs:label "Pessoa"@pt-BR .

esp:Atividade a owl:Class ;
    rdfs:label "Atividade"@pt-BR .

esp:Localizacao a owl:Class ;
    rdfs:label "Localização"@pt-BR .

esp:AreaDeAtuacao a owl:Class ;
    rdfs:label "Área de Atuação"@pt-BR .

esp:parteDe a owl:ObjectProperty ;
    rdfs:label "parte de"@pt-BR ;
    rdfs:domain esp:Organizacao ;
    rdfs:range esp:Organizacao .
```

- [ ] **Step 4: Rodar a validação e confirmar que passa**

Run: `docker run --rm -v "$(pwd)":/work ontologia-espirita-ci /work/docker/validate.sh`
Expected: `== validação concluída com sucesso ==` (etapa 3/3 é pulada, catálogo de referência ainda não existe — isso é esperado nesta task).

- [ ] **Step 5: Commit**

```bash
git add ontology/core.ttl competency-questions/README.md competency-questions/cq-00-labels-pt-br.rq
git rm --cached ontology/.gitkeep competency-questions/.gitkeep
git commit -m "feat(ontologia): cabeçalho, classes de topo e CQ de rótulos pt-BR

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01HS4qvMFDvwotFt1qNETLtf"
```

---

## Task 4: Estrutura federativa

**Files:**
- Modify: `ontology/core.ttl`
- Create: `competency-questions/cq-01-casa-parte-de-federativa.rq`
- Create: `competency-questions/cq-02-areas-tem-supertipo.rq`

**Interfaces:**
- Consome: `esp:Organizacao`, `esp:AreaDeAtuacao`, `esp:parteDe` (Task 3).
- Produz: `esp:Federativa`, `esp:Casa`, `esp:Federacao`, `esp:Regional`, `esp:CRE`, `esp:AME` (todas subclasses de `esp:Organizacao` ou `esp:Federativa`), as 10 subclasses de `esp:AreaDeAtuacao`, e `esp:atuaEm`. Tarefas 5–7 usam `esp:Casa` como domínio de várias propriedades.

Nota de migração: o rascunho original em `desorganizados/*.owl` tinha `Casa`,
`Federativa` e `Regional` como classes soltas (sem `subClassOf`), e "Área de
Comunicação Social Espírita" sem herdar de "Área". Esta task corrige os
quatro problemas ao migrar para `core.ttl`.

- [ ] **Step 1: Escrever as competency questions (falham primeiro — classes ainda não existem)**

`competency-questions/cq-01-casa-parte-de-federativa.rq`:

```sparql
# CQ-01: Toda Casa é modelada como parte de alguma estrutura federativa?
# (violação = esp:Casa sem uma restrição owl:someValuesFrom esp:Federativa em esp:parteDe)
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX esp: <https://w3id.org/ontologia-espirita/v1#>

SELECT ?casa
WHERE {
  VALUES ?casa { esp:Casa }
  FILTER NOT EXISTS {
    ?casa rdfs:subClassOf ?restricao .
    ?restricao a owl:Restriction ;
        owl:onProperty esp:parteDe ;
        owl:someValuesFrom esp:Federativa .
  }
}
```

`competency-questions/cq-02-areas-tem-supertipo.rq`:

```sparql
# CQ-02: Toda classe de Área de atuação (IRI começando com "esp:Area") é
# subclasse de esp:AreaDeAtuacao?
# (violação = classe "AreaXyz" sem rdfs:subClassOf esp:AreaDeAtuacao)
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX esp: <https://w3id.org/ontologia-espirita/v1#>

SELECT ?area
WHERE {
  ?area a owl:Class .
  FILTER(STRSTARTS(STR(?area), STR(esp:Area)))
  FILTER(?area != esp:AreaDeAtuacao)
  FILTER NOT EXISTS { ?area rdfs:subClassOf esp:AreaDeAtuacao }
}
```

- [ ] **Step 2: Rodar a validação e confirmar que falha nas duas novas CQs**

Run: `docker run --rm -v "$(pwd)":/work ontologia-espirita-ci /work/docker/validate.sh`
Expected: falha na etapa 2/3 (`robot verify`), reportando violações para `cq-01` (esp:Casa não existe ainda, então nem casa nenhuma) — se `robot verify` reportar erro de IRI inexistente em vez de violação de linha, isso também conta como falha esperada nesta etapa.

- [ ] **Step 3: Adicionar a estrutura federativa a `ontology/core.ttl`**

Adicionar ao final do arquivo:

```turtle
esp:Federativa a owl:Class ;
    rdfs:subClassOf esp:Organizacao ;
    rdfs:label "Federativa"@pt-BR .

esp:Casa a owl:Class ;
    rdfs:subClassOf esp:Organizacao ,
        [ a owl:Restriction ;
          owl:onProperty esp:parteDe ;
          owl:someValuesFrom esp:Federativa ] ;
    rdfs:label "Casa"@pt-BR .

esp:Federacao a owl:Class ;
    rdfs:subClassOf esp:Federativa ;
    rdfs:label "Federação"@pt-BR .

esp:Regional a owl:Class ;
    rdfs:subClassOf esp:Federativa ;
    rdfs:label "Regional"@pt-BR .

esp:CRE a owl:Class ;
    rdfs:subClassOf esp:Federativa ,
        [ a owl:Restriction ;
          owl:onProperty esp:parteDe ;
          owl:someValuesFrom esp:Regional ] ;
    rdfs:label "CRE"@pt-BR .

esp:AME a owl:Class ;
    rdfs:subClassOf esp:Federativa ;
    rdfs:label "AME"@pt-BR .

esp:atuaEm a owl:ObjectProperty ;
    rdfs:label "atua em"@pt-BR ;
    rdfs:domain esp:Casa ;
    rdfs:range esp:AreaDeAtuacao .

esp:AreaInfanciaJuventude a owl:Class ;
    rdfs:subClassOf esp:AreaDeAtuacao ;
    rdfs:label "Área de Infância e Juventude"@pt-BR .

esp:AreaEstudoDoEvangelho a owl:Class ;
    rdfs:subClassOf esp:AreaDeAtuacao ;
    rdfs:label "Área de Estudo do Evangelho de Jesus"@pt-BR .

esp:AreaPromocaoSocial a owl:Class ;
    rdfs:subClassOf esp:AreaDeAtuacao ;
    rdfs:label "Área de Promoção Social Espírita"@pt-BR .

esp:AreaOrientacaoMediunica a owl:Class ;
    rdfs:subClassOf esp:AreaDeAtuacao ;
    rdfs:label "Área de Orientação Mediúnica"@pt-BR .

esp:AreaEsperanto a owl:Class ;
    rdfs:subClassOf esp:AreaDeAtuacao ;
    rdfs:label "Área de Esperanto"@pt-BR .

esp:AreaArte a owl:Class ;
    rdfs:subClassOf esp:AreaDeAtuacao ;
    rdfs:label "Área de Arte"@pt-BR .

esp:AreaComunicacaoSocial a owl:Class ;
    rdfs:subClassOf esp:AreaDeAtuacao ;
    rdfs:label "Área de Comunicação Social Espírita"@pt-BR .

esp:AreaFamilia a owl:Class ;
    rdfs:subClassOf esp:AreaDeAtuacao ;
    rdfs:label "Área da Família"@pt-BR .

esp:AreaAtendimentoEspiritual a owl:Class ;
    rdfs:subClassOf esp:AreaDeAtuacao ;
    rdfs:label "Área de Atendimento Espiritual"@pt-BR .

esp:AreaEstudoDoEspiritismo a owl:Class ;
    rdfs:subClassOf esp:AreaDeAtuacao ;
    rdfs:label "Área de Estudo do Espiritismo"@pt-BR .
```

- [ ] **Step 4: Rodar a validação e confirmar que passa**

Run: `docker run --rm -v "$(pwd)":/work ontologia-espirita-ci /work/docker/validate.sh`
Expected: `== validação concluída com sucesso ==`

- [ ] **Step 5: Commit**

```bash
git add ontology/core.ttl competency-questions/cq-01-casa-parte-de-federativa.rq competency-questions/cq-02-areas-tem-supertipo.rq
git commit -m "feat(ontologia): estrutura federativa e áreas de atuação

Migra e corrige a hierarquia federativa do rascunho WebProtege original
(Casa/Federativa/Regional ganham subClassOf; Área de Comunicação Social
Espírita passa a herdar de AreaDeAtuacao).

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01HS4qvMFDvwotFt1qNETLtf"
```

---

## Task 5: Pessoas e papéis

**Files:**
- Modify: `ontology/core.ttl`
- Create: `competency-questions/cq-03-pessoa-papeis-subclasse.rq`

**Interfaces:**
- Consome: `esp:Pessoa`, `esp:Casa`, `esp:AreaDeAtuacao` (Tasks 3–4).
- Produz: `esp:Voluntario`, `esp:Dirigente`, `esp:Frequentador`, `esp:Beneficiario` (subclasses de `esp:Pessoa`), e as propriedades `esp:atua`, `esp:dirige`, `esp:frequenta`. Task 6 usa `esp:Beneficiario` como range de `esp:temPublicoAlvo`.

- [ ] **Step 1: Escrever a competency question (falha primeiro)**

`competency-questions/cq-03-pessoa-papeis-subclasse.rq`:

```sparql
# CQ-03: Voluntário, Dirigente, Frequentador e Beneficiário são todos
# subclasses de Pessoa?
# (violação = um desses papéis sem rdfs:subClassOf esp:Pessoa)
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX esp: <https://w3id.org/ontologia-espirita/v1#>

SELECT ?papel
WHERE {
  VALUES ?papel { esp:Voluntario esp:Dirigente esp:Frequentador esp:Beneficiario }
  FILTER NOT EXISTS { ?papel rdfs:subClassOf esp:Pessoa }
}
```

- [ ] **Step 2: Rodar a validação e confirmar que falha**

Run: `docker run --rm -v "$(pwd)":/work ontologia-espirita-ci /work/docker/validate.sh`
Expected: falha na etapa 2/3 — nenhuma das quatro classes existe ainda.

- [ ] **Step 3: Adicionar pessoas e papéis a `ontology/core.ttl`**

```turtle
esp:Voluntario a owl:Class ;
    rdfs:subClassOf esp:Pessoa ;
    rdfs:label "Voluntário"@pt-BR .

esp:Dirigente a owl:Class ;
    rdfs:subClassOf esp:Pessoa ;
    rdfs:label "Dirigente"@pt-BR .

esp:Frequentador a owl:Class ;
    rdfs:subClassOf esp:Pessoa ;
    rdfs:label "Frequentador"@pt-BR .

esp:Beneficiario a owl:Class ;
    rdfs:subClassOf esp:Pessoa ;
    rdfs:label "Beneficiário"@pt-BR .

esp:atua a owl:ObjectProperty ;
    rdfs:label "atua"@pt-BR ;
    rdfs:domain esp:Voluntario ;
    rdfs:range esp:AreaDeAtuacao .

esp:dirige a owl:ObjectProperty ;
    rdfs:label "dirige"@pt-BR ;
    rdfs:domain esp:Dirigente ;
    rdfs:range esp:Casa .

esp:frequenta a owl:ObjectProperty ;
    rdfs:label "frequenta"@pt-BR ;
    rdfs:domain esp:Frequentador ;
    rdfs:range esp:Casa .
```

- [ ] **Step 4: Rodar a validação e confirmar que passa**

Run: `docker run --rm -v "$(pwd)":/work ontologia-espirita-ci /work/docker/validate.sh`
Expected: `== validação concluída com sucesso ==`

- [ ] **Step 5: Commit**

```bash
git add ontology/core.ttl competency-questions/cq-03-pessoa-papeis-subclasse.rq
git commit -m "feat(ontologia): pessoas e papéis (voluntário, dirigente, frequentador, beneficiário)

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01HS4qvMFDvwotFt1qNETLtf"
```

---

## Task 6: Atividades e ações sociais/doutrinárias

**Files:**
- Modify: `ontology/core.ttl`
- Create: `competency-questions/cq-04-atividade-subtipos.rq`

**Interfaces:**
- Consome: `esp:Atividade`, `esp:Casa`, `esp:Beneficiario` (Tasks 3–5).
- Produz: `esp:Evento`, `esp:AcaoSocial`, `esp:EstudoDoutrinario` (subclasses de `esp:Atividade`), e as propriedades `esp:realiza`, `esp:temPublicoAlvo`.

- [ ] **Step 1: Escrever a competency question (falha primeiro)**

`competency-questions/cq-04-atividade-subtipos.rq`:

```sparql
# CQ-04: Evento, Ação Social e Estudo Doutrinário são todos subclasses de
# Atividade?
# (violação = um desses tipos sem rdfs:subClassOf esp:Atividade)
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX esp: <https://w3id.org/ontologia-espirita/v1#>

SELECT ?tipo
WHERE {
  VALUES ?tipo { esp:Evento esp:AcaoSocial esp:EstudoDoutrinario }
  FILTER NOT EXISTS { ?tipo rdfs:subClassOf esp:Atividade }
}
```

- [ ] **Step 2: Rodar a validação e confirmar que falha**

Run: `docker run --rm -v "$(pwd)":/work ontologia-espirita-ci /work/docker/validate.sh`
Expected: falha na etapa 2/3.

- [ ] **Step 3: Adicionar atividades a `ontology/core.ttl`**

```turtle
esp:Evento a owl:Class ;
    rdfs:subClassOf esp:Atividade ;
    rdfs:label "Evento"@pt-BR .

esp:AcaoSocial a owl:Class ;
    rdfs:subClassOf esp:Atividade ;
    rdfs:label "Ação Social"@pt-BR .

esp:EstudoDoutrinario a owl:Class ;
    rdfs:subClassOf esp:Atividade ;
    rdfs:label "Estudo Doutrinário"@pt-BR .

esp:realiza a owl:ObjectProperty ;
    rdfs:label "realiza"@pt-BR ;
    rdfs:domain esp:Casa ;
    rdfs:range esp:Atividade .

esp:temPublicoAlvo a owl:ObjectProperty ;
    rdfs:label "tem público-alvo"@pt-BR ;
    rdfs:domain esp:Atividade ;
    rdfs:range esp:Beneficiario .
```

- [ ] **Step 4: Rodar a validação e confirmar que passa**

Run: `docker run --rm -v "$(pwd)":/work ontologia-espirita-ci /work/docker/validate.sh`
Expected: `== validação concluída com sucesso ==`

- [ ] **Step 5: Commit**

```bash
git add ontology/core.ttl competency-questions/cq-04-atividade-subtipos.rq
git commit -m "feat(ontologia): atividades e ações sociais/doutrinárias

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01HS4qvMFDvwotFt1qNETLtf"
```

---

## Task 7: Geografia básica

**Files:**
- Modify: `ontology/core.ttl`
- Create: `competency-questions/cq-05-casa-tem-localizacao.rq`

**Interfaces:**
- Consome: `esp:Localizacao`, `esp:Casa` (Tasks 3–4).
- Produz: `esp:Municipio`, `esp:UnidadeFederativa` (subclasses de `esp:Localizacao`), `esp:localizadaEm`, `esp:pertenceA`, `esp:codigoIBGE`. Esta é a última classe/propriedade nova do TBox v1.0 — a Task 8 só adiciona instâncias.

- [ ] **Step 1: Escrever a competency question (falha primeiro)**

`competency-questions/cq-05-casa-tem-localizacao.rq`:

```sparql
# CQ-05: Toda Casa é modelada como tendo uma localização (Município)?
# (violação = esp:Casa sem restrição owl:someValuesFrom esp:Municipio em esp:localizadaEm)
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX esp: <https://w3id.org/ontologia-espirita/v1#>

SELECT ?casa
WHERE {
  VALUES ?casa { esp:Casa }
  FILTER NOT EXISTS {
    ?casa rdfs:subClassOf ?restricao .
    ?restricao a owl:Restriction ;
        owl:onProperty esp:localizadaEm ;
        owl:someValuesFrom esp:Municipio .
  }
}
```

- [ ] **Step 2: Rodar a validação e confirmar que falha**

Run: `docker run --rm -v "$(pwd)":/work ontologia-espirita-ci /work/docker/validate.sh`
Expected: falha na etapa 2/3.

- [ ] **Step 3: Adicionar geografia básica a `ontology/core.ttl`**

```turtle
esp:Municipio a owl:Class ;
    rdfs:subClassOf esp:Localizacao ;
    rdfs:label "Município"@pt-BR .

esp:UnidadeFederativa a owl:Class ;
    rdfs:subClassOf esp:Localizacao ;
    rdfs:label "Unidade Federativa"@pt-BR .

esp:localizadaEm a owl:ObjectProperty ;
    rdfs:label "localizada em"@pt-BR ;
    rdfs:domain esp:Casa ;
    rdfs:range esp:Municipio .

esp:pertenceA a owl:ObjectProperty ;
    rdfs:label "pertence a"@pt-BR ;
    rdfs:domain esp:Municipio ;
    rdfs:range esp:UnidadeFederativa .

esp:codigoIBGE a owl:DatatypeProperty ;
    rdfs:label "código IBGE"@pt-BR ;
    rdfs:domain esp:Municipio ;
    rdfs:range xsd:string .

esp:Casa rdfs:subClassOf [
    a owl:Restriction ;
    owl:onProperty esp:localizadaEm ;
    owl:someValuesFrom esp:Municipio
] .

esp:Municipio rdfs:subClassOf [
    a owl:Restriction ;
    owl:onProperty esp:pertenceA ;
    owl:someValuesFrom esp:UnidadeFederativa
] .
```

- [ ] **Step 4: Rodar a validação e confirmar que passa**

Run: `docker run --rm -v "$(pwd)":/work ontologia-espirita-ci /work/docker/validate.sh`
Expected: `== validação concluída com sucesso ==`

- [ ] **Step 5: Commit**

```bash
git add ontology/core.ttl competency-questions/cq-05-casa-tem-localizacao.rq
git commit -m "feat(ontologia): geografia básica (Município, UF, código IBGE)

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01HS4qvMFDvwotFt1qNETLtf"
```

---

## Task 8: Catálogo de referência (ABox limitado) e SHACL

**Files:**
- Create: `ontology/reference-catalog.ttl`
- Create: `shapes/reference-catalog.shacl.ttl`

**Interfaces:**
- Consome: `esp:Federativa` (Task 4).
- Produz: `ontology/reference-catalog.ttl` (instância `esp:UEM`) e `shapes/reference-catalog.shacl.ttl` (shape que qualquer instância futura de `esp:Federativa` no catálogo precisa satisfazer). Nenhuma tarefa seguinte depende do conteúdo específico deste catálogo — é dado de referência, não modelo.

- [ ] **Step 1: Escrever o shape SHACL primeiro (falha ao validar um catálogo vazio/incorreto)**

`shapes/reference-catalog.shacl.ttl`:

```turtle
@prefix sh: <http://www.w3.org/ns/shacl#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix esp: <https://w3id.org/ontologia-espirita/v1#> .

esp:FederativaShape a sh:NodeShape ;
    sh:targetClass esp:Federativa ;
    sh:property [
        sh:path rdfs:label ;
        sh:minCount 1 ;
        sh:languageIn ( "pt-BR" ) ;
        sh:message "Toda entidade federativa do catálogo de referência precisa de rdfs:label em pt-BR."@pt-BR ;
    ] .
```

- [ ] **Step 2: Criar um catálogo vazio e confirmar que a validação é pulada (arquivo ainda não existe de fato com conteúdo válido)**

```bash
printf '@prefix esp: <https://w3id.org/ontologia-espirita/v1#> .\n' > ontology/reference-catalog.ttl
docker run --rm -v "$(pwd)":/work ontologia-espirita-ci /work/docker/validate.sh
```

Expected: etapa 3/3 roda (arquivo e shape existem) e passa trivialmente (conforms=True), pois não há nenhuma instância de `esp:Federativa` ainda para violar a regra.

- [ ] **Step 3: Adicionar a entidade federativa conhecida ao catálogo**

`ontology/reference-catalog.ttl`:

```turtle
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix esp: <https://w3id.org/ontologia-espirita/v1#> .

esp:UEM a esp:Federativa ;
    rdfs:label "União Espírita Mineira"@pt-BR ;
    rdfs:comment "Migrado do rascunho WebProtege original. Tipo mantido como Federativa (não refinado para Federação/Regional) até confirmação do papel exato na estrutura federativa pelo mantenedor do domínio."@pt-BR .
```

- [ ] **Step 4: Rodar a validação completa e confirmar que passa**

Run: `docker run --rm -v "$(pwd)":/work ontologia-espirita-ci /work/docker/validate.sh`
Expected: `== validação concluída com sucesso ==`, com a etapa 3/3 mostrando `Conforms: True` para `esp:UEM`.

- [ ] **Step 5: Commit**

```bash
git add ontology/reference-catalog.ttl shapes/reference-catalog.shacl.ttl
git rm --cached shapes/.gitkeep
git commit -m "feat(ontologia): catálogo de referência (UEM) e shape SHACL

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01HS4qvMFDvwotFt1qNETLtf"
```

---

## Task 9: Geração de `context.jsonld`

**Files:**
- Create: `scripts/generate_context.py`
- Create: `ontology/context.jsonld` (gerado pelo script, não editado à mão)

**Interfaces:**
- Consome: `ontology/core.ttl` (lido via rdflib).
- Produz: `ontology/context.jsonld`, o artefato de consumo pelos apps (voluntário, casa, painel de demografia). Nenhuma tarefa seguinte depende do conteúdo exato — mas toda regeneração futura de `core.ttl` deve rerodar este script (documentado na Task 11, `guia-de-contribuicao.md`).

- [ ] **Step 1: Escrever um teste que falha primeiro (o script ainda não existe)**

```bash
mkdir -p scripts
python3 -c "
import subprocess
result = subprocess.run(['python3', 'scripts/generate_context.py'], capture_output=True, text=True)
assert result.returncode != 0, 'esperava falhar porque o script ainda não existe'
print('OK: falhou como esperado')
"
```

Expected: `OK: falhou como esperado`.

- [ ] **Step 2: Escrever `scripts/generate_context.py`**

```python
#!/usr/bin/env python3
"""Gera ontology/context.jsonld a partir de ontology/core.ttl."""
import json

import rdflib
from rdflib.namespace import OWL, RDF

BASE = "https://w3id.org/ontologia-espirita/v1#"


def local_names(graph, rdf_type):
    for subject in set(graph.subjects(RDF.type, rdf_type)):
        iri = str(subject)
        if iri.startswith(BASE):
            yield iri[len(BASE):]


def main():
    graph = rdflib.Graph()
    graph.parse("ontology/core.ttl", format="turtle")

    context = {"esp": BASE}
    for rdf_type in (OWL.Class, OWL.ObjectProperty, OWL.DatatypeProperty):
        for name in local_names(graph, rdf_type):
            context[name] = f"esp:{name}"

    output = {"@context": context}
    with open("ontology/context.jsonld", "w", encoding="utf-8") as handle:
        json.dump(output, handle, ensure_ascii=False, indent=2, sort_keys=True)
        handle.write("\n")


if __name__ == "__main__":
    main()
```

- [ ] **Step 3: Rodar o script dentro do container (mesmo ambiente do CI) e verificar a saída**

```bash
docker run --rm -v "$(pwd)":/work -w /work ontologia-espirita-ci python3 scripts/generate_context.py
python3 -c "
import json
with open('ontology/context.jsonld', encoding='utf-8') as f:
    data = json.load(f)
assert data['@context']['esp'] == 'https://w3id.org/ontologia-espirita/v1#'
assert data['@context']['Casa'] == 'esp:Casa'
assert data['@context']['Voluntario'] == 'esp:Voluntario'
assert data['@context']['localizadaEm'] == 'esp:localizadaEm'
print('OK: context.jsonld gerado corretamente')
"
```

Expected: `OK: context.jsonld gerado corretamente`.

- [ ] **Step 4: Commit**

```bash
git add scripts/generate_context.py ontology/context.jsonld
git commit -m "feat: gerar context.jsonld a partir de core.ttl via rdflib

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01HS4qvMFDvwotFt1qNETLtf"
```

---

## Task 10: CI no GitHub Actions

**Files:**
- Create: `.github/workflows/ci.yml`
- Create: `.github/pull_request_template.md`

**Interfaces:**
- Consome: `docker/Dockerfile`, `docker/validate.sh` (Task 2), `scripts/generate_context.py` (Task 9).
- Produz: o workflow que roda em todo Pull Request e push para `main`.

- [ ] **Step 1: Escrever `.github/workflows/ci.yml`**

```yaml
name: Validação da ontologia

on:
  pull_request:
  push:
    branches: [main]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build da imagem de validação
        run: docker build -t ontologia-espirita-ci -f docker/Dockerfile docker/

      - name: Rodar reasoner, competency questions e SHACL
        run: docker run --rm -v "${{ github.workspace }}":/work ontologia-espirita-ci /work/docker/validate.sh

      - name: Verificar que context.jsonld está atualizado
        run: |
          docker run --rm -v "${{ github.workspace }}":/work -w /work ontologia-espirita-ci python3 scripts/generate_context.py
          git diff --exit-code ontology/context.jsonld || (echo "context.jsonld está desatualizado — rode scripts/generate_context.py e commit o resultado" && exit 1)
```

- [ ] **Step 2: Escrever o template de PR com o checklist de revisão crítica**

`.github/pull_request_template.md`:

```markdown
## O que muda e por quê

<!-- descreva a mudança na ontologia -->

## Este PR toca um elemento crítico?

Elementos críticos: raiz da hierarquia federativa (`esp:Organizacao`,
`esp:Federativa`, `esp:Casa`), ou qualquer classe/propriedade já consumida
por um dos apps (voluntário, casa, painel de demografia).

- [ ] Não — só adiciona algo novo sem alterar o que já existe.
- [ ] Sim — e eu (mantenedor) revisei manualmente o impacto antes de mergear.

## Checklist

- [ ] CI verde (reasoner + competency questions + SHACL).
- [ ] `context.jsonld` regenerado se `core.ttl` mudou.
- [ ] Nova competency question adicionada, se este PR cobre um caso de uso novo.
```

- [ ] **Step 3: Testar o workflow localmente com `act` ou validar a sintaxe do YAML**

Run: `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))" 2>&1 || python3 -m pip install --user pyyaml && python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml')); print('YAML válido')"`
Expected: `YAML válido`.

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/ci.yml .github/pull_request_template.md
git commit -m "ci: validar ontologia em todo PR (reasoner, competency questions, SHACL)

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01HS4qvMFDvwotFt1qNETLtf"
```

---

## Task 11: Documentação, ADR, registro w3id.org e limpeza

**Files:**
- Create: `README.md`
- Create: `docs/glossario.md`
- Create: `docs/modelo-de-dominio.md`
- Create: `docs/guia-de-contribuicao.md`
- Create: `docs/decisoes/0001-decisoes-de-design-v1.md`
- Create: `w3id.org-registration/.htaccess` (arquivo pronto para o PR em `w3c/perma-id`)
- Delete: `desorganizados/`

**Interfaces:**
- Consome: todo o conteúdo produzido nas Tasks 1–10 (documenta o que já existe; não adiciona classes novas).
- Produz: a documentação de apoio exigida pela "Definição de pronto" do spec.

- [ ] **Step 1: Escrever `docs/decisoes/0001-decisoes-de-design-v1.md` (ADR)**

```markdown
---
id: 0001
status: aceito
data: 2026-09-06
---

# ADR 0001: Decisões de design da ontologia v1.0

## Contexto

Ver `docs/superpowers/specs/2026-09-06-ontologia-v1-design.md` para o
processo completo de decisão.

## Decisões

1. **Escopo v1.0**: estrutura federativa, pessoas e papéis, atividades, e
   geografia básica (gancho para código IBGE, sem crosswalk completo).
2. **TBox + catálogo de referência**: este repositório não guarda instâncias
   de Casas ou pessoas individuais — apenas o modelo e um catálogo limitado
   de entidades federativas estáveis.
3. **IRI definitivo**: `https://w3id.org/ontologia-espirita/v1#`, resolvido
   via redirecionamento do w3id.org para o GitHub Pages deste repositório.
   IRIs legíveis (`#Casa`, `#Regional`), não opacas.
4. **Fonte da verdade**: OWL/Turtle, editado via Protégé Desktop + Git/PR.
   `context.jsonld` é gerado, nunca editado à mão.
5. **Validação**: uma única imagem Docker (ROBOT + pyshacl) roda reasoning,
   competency questions (SPARQL versionado) e SHACL a cada PR. Mudanças em
   elementos críticos exigem checklist de revisão manual do mantenedor,
   além do CI verde.
6. **Fora de escopo**: documentação de produto dos apps consumidores;
   crosswalk completo de municípios IBGE; ABox de Casas/pessoas.
```

- [ ] **Step 2: Escrever `docs/glossario.md`**

```markdown
# Glossário

Termos em português, na ordem em que aparecem em `ontology/core.ttl`.

| Termo (pt-BR) | IRI | Definição |
|---|---|---|
| Organização | `esp:Organizacao` | Classe de topo para qualquer entidade organizacional do movimento. |
| Pessoa | `esp:Pessoa` | Classe de topo para qualquer indivíduo humano que se relaciona com uma Casa. |
| Atividade | `esp:Atividade` | Classe de topo para o que uma Casa realiza (evento, ação social, estudo). |
| Localização | `esp:Localizacao` | Classe de topo da geografia básica (Município, Unidade Federativa). |
| Área de Atuação | `esp:AreaDeAtuacao` | Classe de topo das áreas temáticas de uma Casa (infância, promoção social etc.). |
| Federativa | `esp:Federativa` | Organização que faz parte da estrutura federativa (Federação, Regional, CRE, AME). |
| Casa | `esp:Casa` | Centro/casa espírita local, parte de alguma estrutura federativa e localizada em um Município. |
| Voluntário | `esp:Voluntario` | Pessoa que atua em uma Área de Atuação. |
| Dirigente | `esp:Dirigente` | Pessoa que dirige uma Casa. |
| Frequentador | `esp:Frequentador` | Pessoa que frequenta uma Casa. |
| Beneficiário | `esp:Beneficiario` | Pessoa que é público-alvo de uma Atividade. |
| Município | `esp:Municipio` | Localização onde uma Casa está situada; carrega o código IBGE. |
| Unidade Federativa | `esp:UnidadeFederativa` | Estado ao qual um Município pertence. |

Para a lista completa de classes e propriedades (incluindo as dez Áreas de
Atuação), ver `ontology/context.jsonld`, gerado automaticamente a partir de
`ontology/core.ttl`.
```

- [ ] **Step 3: Escrever `docs/modelo-de-dominio.md`**

```markdown
# Modelo de domínio

Visão narrativa do grafo definido em `ontology/core.ttl`. Ver
`docs/glossario.md` para definição termo a termo.

## Estrutura federativa

Uma **Casa** é parte de (`esp:parteDe`) alguma **Federativa** (Federação,
Regional, CRE ou AME) e atua (`esp:atuaEm`) em uma ou mais **Áreas de
Atuação** (Infância e Juventude, Estudo do Evangelho, Promoção Social,
Orientação Mediúnica, Esperanto, Arte, Comunicação Social, Família,
Atendimento Espiritual, Estudo do Espiritismo). Um **CRE** é sempre parte
de uma **Regional**.

O catálogo de referência (`ontology/reference-catalog.ttl`) guarda as
entidades federativas reais e estáveis conhecidas — atualmente só a UEM
(União Espírita Mineira), migrada do rascunho original. Espera-se que este
catálogo cresça conforme mais entidades forem confirmadas pelo mantenedor
do domínio.

## Pessoas e papéis

Uma pessoa pode ser **Voluntário** (atua em uma Área), **Dirigente** (dirige
uma Casa), **Frequentador** (frequenta uma Casa) ou **Beneficiário** (é
público-alvo de uma Atividade). Uma mesma pessoa do mundo real pode
acumular papéis diferentes ao longo do tempo — isso é responsabilidade do
app consumidor modelar, não desta ontologia.

## Atividades

Uma Casa realiza (`esp:realiza`) **Atividades**: Eventos, Ações Sociais ou
Estudos Doutrinários. Toda Atividade pode ter um Beneficiário como
público-alvo.

## Geografia

Toda Casa está localizada em (`esp:localizadaEm`) um **Município**, que
pertence a (`esp:pertenceA`) uma **Unidade Federativa** e carrega um
`esp:codigoIBGE`. Esta ontologia não guarda a lista de municípios do
Brasil — isso é dado, consumido diretamente pelo painel de demografia a
partir da base do IBGE, usando o código como chave de cruzamento.

## O que fica fora do v1.0

- Hierarquia geográfica fina (bairro, setor censitário).
- Crosswalk completo de códigos IBGE/município/UF.
- Instâncias de Casas ou pessoas (vivem nos apps consumidores).
- Documentação de produto dos apps consumidores.
```

- [ ] **Step 4: Escrever `docs/guia-de-contribuicao.md`**

```markdown
# Guia de contribuição

## Como propor uma mudança

1. Edite `ontology/core.ttl` (Protégé Desktop ou texto direto) ou
   `ontology/reference-catalog.ttl`.
2. Se adicionar um caso de uso novo, adicione uma competency question em
   `competency-questions/*.rq` (ver `competency-questions/README.md`).
3. Se `core.ttl` mudou, regenere `ontology/context.jsonld`:
   ```bash
   docker build -t ontologia-espirita-ci -f docker/Dockerfile docker/
   docker run --rm -v "$(pwd)":/work -w /work ontologia-espirita-ci python3 scripts/generate_context.py
   ```
4. Rode a validação completa localmente antes de abrir o PR:
   ```bash
   docker run --rm -v "$(pwd)":/work ontologia-espirita-ci /work/docker/validate.sh
   ```
5. Abra o Pull Request. O template pede pra marcar se a mudança toca um
   elemento crítico.

## O que é um elemento crítico

Qualquer mudança em `esp:Organizacao`, `esp:Federativa`, `esp:Casa`, ou em
qualquer classe/propriedade já consumida por um dos apps (voluntário, casa,
painel de demografia). PRs que tocam esses elementos exigem, além do CI
verde, revisão manual explícita do mantenedor (checkbox no template de PR)
antes de mergear.

## Versionamento

SemVer aplicado a `owl:versionInfo` em `ontology/core.ttl` e a
`CHANGELOG.md`:

- **patch**: correção de rótulo/typo, sem mudar estrutura.
- **minor**: nova classe/propriedade que não quebra nada existente.
- **major**: renomear/remover/mudar hierarquia de algo já consumido pelos
  apps. Uma mudança major implica uma nova versão no path da IRI (`v2`),
  preservando `v1` para quem ainda depende dela.
```

- [ ] **Step 5: Escrever `README.md`**

```markdown
# Ontologia do Movimento Espírita Brasileiro

Ontologia de referência (OWL/Turtle) usada como base conceitual pelos
projetos do movimento espírita brasileiro: app do voluntário, app da casa,
e o painel de demografia (correlação com IBGE, Atlas, IPEA e cadastro
federativo).

- **Modelo**: `ontology/core.ttl` (TBox — classes, propriedades, axiomas).
- **Catálogo de referência**: `ontology/reference-catalog.ttl` (ABox
  limitado — entidades federativas estáveis).
- **Consumo pelos apps**: `ontology/context.jsonld` (gerado, não editado à
  mão — ver `docs/guia-de-contribuicao.md`).
- **IRI**: `https://w3id.org/ontologia-espirita/v1#`.

## Documentação

- `docs/glossario.md` — termos em português.
- `docs/modelo-de-dominio.md` — visão narrativa do grafo.
- `docs/guia-de-contribuicao.md` — como propor e validar mudanças.
- `docs/decisoes/` — ADRs.
- `docs/superpowers/specs/` e `docs/superpowers/plans/` — histórico de
  design e implementação.

## Validação

```bash
docker build -t ontologia-espirita-ci -f docker/Dockerfile docker/
docker run --rm -v "$(pwd)":/work ontologia-espirita-ci /work/docker/validate.sh
```
```

- [ ] **Step 6: Preparar o registro no w3id.org**

```bash
mkdir -p w3id.org-registration/ontologia-espirita
```

`w3id.org-registration/ontologia-espirita/.htaccess`:

```apacheconf
RewriteEngine On
RewriteCond %{HTTP_ACCEPT} !text/html.*
RewriteCond %{REQUEST_URI} ^/ontologia-espirita/v1$
RewriteRule ^ https://acse.github.io/ontologia-espirita/v1/core.ttl [R=303,L]
RewriteRule ^v1/?$ https://acse.github.io/ontologia-espirita/v1/ [R=303,L]
```

`w3id.org-registration/README.md`:

```markdown
# Registro no w3id.org

Este diretório contém o `.htaccess` a ser submetido como Pull Request no
repositório https://github.com/perma-id/w3id.org, dentro de uma pasta
`ontologia-espirita/` na raiz daquele repositório (não deste).

Passos (ação manual, fora deste repositório):

1. Fork de `perma-id/w3id.org`.
2. Copiar `ontologia-espirita/.htaccess` (o arquivo deste diretório) para a
   raiz do fork, dentro de uma pasta `ontologia-espirita/`.
3. Abrir PR seguindo o `CONTRIBUTING.md` daquele repositório.
4. Após aprovado, `https://w3id.org/ontologia-espirita/v1#` passa a
   resolver para o GitHub Pages deste repositório.
5. Ativar GitHub Pages neste repositório (Settings → Pages → servir a
   partir de `/ontology` ou de uma branch `gh-pages` publicando
   `ontology/core.ttl`) — esta é a peça que falta para o redirect acima
   funcionar de fato; sem isso, o PR do w3id.org pode ser aberto mas o
   link ainda não resolve para conteúdo real.
```

- [ ] **Step 7: Migrar o conteúdo relevante de `desorganizados/` e removê-la**

O `.owl`/`.owx` já foi migrado (com correções) para `ontology/core.ttl` nas
Tasks 3–7. Os `.md` exploratórios foram incorporados em
`docs/modelo-de-dominio.md` e neste ADR. `app-voluntario-doc-map.md` não
pertence a este repositório (ver spec, seção "Fora de escopo").

```bash
git rm -r desorganizados/
```

- [ ] **Step 8: Atualizar `CHANGELOG.md` para a versão 1.0.0**

Editar `CHANGELOG.md`, substituindo `## [Não lançado]` por:

```markdown
## [1.0.0] - 2026-09-06

### Adicionado
- TBox v1.0: estrutura federativa, pessoas e papéis, atividades, geografia básica.
- Catálogo de referência inicial (UEM).
- Pipeline de validação Docker (ROBOT + SHACL) rodando em CI.
- Documentação: glossário, modelo de domínio, guia de contribuição, ADR 0001.
- IRI definitivo via w3id.org + GitHub Pages.
```

- [ ] **Step 9: Rodar a validação completa uma última vez**

Run: `docker run --rm -v "$(pwd)":/work ontologia-espirita-ci /work/docker/validate.sh`
Expected: `== validação concluída com sucesso ==`

- [ ] **Step 10: Commit final**

```bash
git add README.md docs/glossario.md docs/modelo-de-dominio.md docs/guia-de-contribuicao.md docs/decisoes/0001-decisoes-de-design-v1.md w3id.org-registration CHANGELOG.md
git rm --cached docs/.gitkeep 2>/dev/null || true
git commit -m "docs: documentação v1.0 completa, registro w3id.org e remoção do rascunho

Fecha a v1.0: glossário, modelo de domínio, guia de contribuição, ADR
0001, preparo do PR de registro w3id.org, e remoção de desorganizados/
(conteúdo migrado para ontology/core.ttl e docs/).

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01HS4qvMFDvwotFt1qNETLtf"
git tag -a v1.0.0 -m "Ontologia do Movimento Espírita v1.0.0"
```
