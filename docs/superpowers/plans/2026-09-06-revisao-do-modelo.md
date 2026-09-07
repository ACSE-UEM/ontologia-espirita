# Revisão do Modelo de Domínio — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reescrever o TBox e o catálogo da ontologia para refletir a revisão do mantenedor do domínio, e entregar um mecanismo executável para ele inspecionar o que o modelo responde.

**Architecture:** TBox enxuto no perfil EL (raciocinável por ELK), catálogo de referência com as entidades reais e os vocabulários controlados (áreas, tipos de atividade), regras de qualidade em SHACL, e dois ABox de exemplo — um válido (`examples/mg.ttl`) e um deliberadamente inválido (`examples/contra-exemplos.ttl`) que prova que as verificações realmente pegam erro.

**Tech Stack:** OWL/Turtle, SPARQL, SHACL. Ferramentas: ROBOT (reason/verify/query/merge) e pyshacl, ambos dentro da imagem Docker que já existe em `docker/Dockerfile`. Orquestração pelo `Makefile`.

**Spec:** `docs/superpowers/specs/2026-09-06-revisao-do-modelo-design.md`

## Global Constraints

- IRI base: `https://w3id.org/ontologia-espirita/v1#`, prefixo `esp:`. **Não muda.**
- `owl:versionInfo` permanece `"1.0.0"`. A ontologia não foi publicada; não há compatibilidade a preservar.
- Todo termo (classe, propriedade, indivíduo do catálogo) tem `rdfs:label` com tag `@pt-BR`. O `cq-00` falha o CI sem isso.
- Sem sufixo "Espírita" em termo autoexplicativo: `esp:Casa`, nunca `esp:CasaEspirita`.
- O TBox fica no **perfil EL**: sem `owl:unionOf`, sem cardinalidade, sem propriedade inversa. `robot reason --reasoner ELK` roda a cada validação. O que o EL não expressa vai para SHACL.
- Exatamente **duas** restrições existenciais no modelo inteiro: `Casa ⊑ ∃localizadaEm.Municipio` e `Municipio ⊑ ∃pertenceA.UnidadeFederativa`. Nenhuma outra. O v1 errou por excesso de restrição; não repetir.
- `ontology/context.jsonld` é **gerado** por `make context`. Nunca editar à mão.
- São **10** áreas federativas. AG (Gestão) fica fora.
- Consulta de competência (`competency-questions/*.rq`) é consulta de **violação**: zero linhas = passou.
- Toda a validação roda em Docker. Nenhum passo do plano instala ROBOT ou pyshacl na máquina.

## Estrutura de arquivos

| Arquivo | Responsabilidade |
|---|---|
| `ontology/core.ttl` | TBox: classes, propriedades, as duas restrições, as duas disjunções |
| `ontology/reference-catalog.ttl` | ABox estável: entidades federativas reais, 10 áreas, tipos de atividade |
| `ontology/context.jsonld` | gerado a partir do core |
| `shapes/reference-catalog.shacl.ttl` | shapes de catálogo (rótulos, siglas) |
| `shapes/modelo.shacl.ttl` | **novo** — regras do modelo que o EL não expressa (enums, alvo de `coordena`, obrigatoriedades) |
| `competency-questions/*.rq` | verificações de violação, rodadas por `robot verify` |
| `examples/mg.ttl` | **novo** — ABox de teste válido |
| `examples/contra-exemplos.ttl` | **novo** — ABox deliberadamente inválido |
| `queries/*.rq` | **novo** — perguntas de inspeção, respostas impressas |
| `docker/perguntas.sh` | **novo** — roda `queries/` e imprime tabelas |
| `docker/contra-exemplos.sh` | **novo** — prova que as verificações pegam erro |
| `docker/validate.sh`, `Makefile` | orquestração |
| `docs/glossario.md`, `docs/modelo-de-dominio.md` | documentação narrativa |
| `docs/decisoes/0002-revisao-do-modelo.md` | ADR |

---

### Task 1: TBox reescrito

**Files:**
- Modify: `ontology/core.ttl` (reescrita completa)
- Modify: `competency-questions/cq-03-pessoa-papeis-subclasse.rq`
- Modify: `competency-questions/cq-06-sem-classes-orfas.rq`
- Create: `competency-questions/cq-01-casa-nao-e-orgao.rq`
- Create: `competency-questions/cq-04-atividade-nao-e-evento.rq`
- Delete: `competency-questions/cq-01-casa-parte-de-federativa.rq`
- Delete: `competency-questions/cq-02-areas-tem-supertipo.rq`
- Delete: `competency-questions/cq-04-atividade-subtipos.rq`
- Modify: `ontology/context.jsonld` (via `make context`, nunca à mão)

**Interfaces:**
- Produces: todas as classes e propriedades usadas pelas Tasks 2–7. Nomes exatos na tabela ao fim desta task.

- [ ] **Step 1: Escrever as verificações que devem falhar**

`competency-questions/cq-01-casa-nao-e-orgao.rq` (novo):

```sparql
# CQ-01: Nenhuma instituição é, ao mesmo tempo, Casa e Órgão.
# (violação = indivíduo tipado como Casa e como Órgão, direta ou indiretamente)
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX esp: <https://w3id.org/ontologia-espirita/v1#>

SELECT ?instituicao
WHERE {
  ?instituicao a ?tipoCasa , ?tipoOrgao .
  ?tipoCasa rdfs:subClassOf* esp:Casa .
  ?tipoOrgao rdfs:subClassOf* esp:Orgao .
}
```

`competency-questions/cq-04-atividade-nao-e-evento.rq` (novo):

```sparql
# CQ-04: Nada é Atividade e Evento ao mesmo tempo.
# (violação = realização tipada como as duas coisas)
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX esp: <https://w3id.org/ontologia-espirita/v1#>

SELECT ?realizacao
WHERE {
  ?realizacao a ?tipoAtividade , ?tipoEvento .
  ?tipoAtividade rdfs:subClassOf* esp:Atividade .
  ?tipoEvento rdfs:subClassOf* esp:Evento .
}
```

`competency-questions/cq-03-pessoa-papeis-subclasse.rq` (substituir o conteúdo inteiro):

```sparql
# CQ-03: Todo papel humano é subclasse (direta ou indireta) de Pessoa?
# (violação = um desses papéis sem caminho rdfs:subClassOf+ até esp:Pessoa)
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX esp: <https://w3id.org/ontologia-espirita/v1#>

SELECT ?papel
WHERE {
  VALUES ?papel {
    esp:Voluntario esp:Coordenador esp:Dirigente
    esp:PublicoAlvo esp:Frequentador esp:Assistido
  }
  FILTER NOT EXISTS { ?papel rdfs:subClassOf+ esp:Pessoa }
}
```

`competency-questions/cq-06-sem-classes-orfas.rq` (substituir o conteúdo inteiro — a lista de raízes mudou):

```sparql
# CQ-06: Toda classe da ontologia (exceto as 6 classes de topo intencionais)
# tem pelo menos um rdfs:subClassOf?
# (violação = uma classe sem nenhum rdfs:subClassOf, exceto as raízes esperadas)
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX esp: <https://w3id.org/ontologia-espirita/v1#>

SELECT ?classe
WHERE {
  ?classe a owl:Class .
  FILTER(?classe != esp:Instituicao
      && ?classe != esp:Pessoa
      && ?classe != esp:Realizacao
      && ?classe != esp:TipoDeAtividade
      && ?classe != esp:AreaFederativa
      && ?classe != esp:Localizacao)
  FILTER NOT EXISTS { ?classe rdfs:subClassOf ?qualquerCoisa }
}
```

Apagar os três arquivos que testam o modelo antigo:

```bash
git rm competency-questions/cq-01-casa-parte-de-federativa.rq \
       competency-questions/cq-02-areas-tem-supertipo.rq \
       competency-questions/cq-04-atividade-subtipos.rq
```

`cq-01-casa-parte-de-federativa.rq` verifica exatamente o axioma `Casa ⊑ ∃parteDe.Federativa` que a revisão derrubou. Se ficasse, o CI reimporia o erro. `cq-02` e `cq-04` testam hierarquias que deixam de existir (áreas viram indivíduos; Evento deixa de ser subclasse de Atividade).

- [ ] **Step 2: Rodar e verificar que falha**

Run: `make verify`
Expected: FAIL. `cq-03` e `cq-06` retornam linhas porque o `core.ttl` ainda é o v1 — `esp:Coordenador`, `esp:PublicoAlvo` e `esp:Assistido` não existem, e as raízes antigas (`esp:Organizacao`, `esp:Atividade`, `esp:AreaDeAtuacao`) aparecem como classes órfãs.

- [ ] **Step 3: Reescrever `ontology/core.ttl`**

Substituir o arquivo inteiro por:

```turtle
@prefix owl: <http://www.w3.org/2002/07/owl#> .
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
@prefix esp: <https://w3id.org/ontologia-espirita/v1#> .

<https://w3id.org/ontologia-espirita/v1> a owl:Ontology ;
    rdfs:label "Ontologia do Movimento Espírita Brasileiro"@pt-BR ;
    rdfs:comment "Cobre o movimento espírita kardecista organizado no Brasil: casas espíritas de orientação kardecista e a estrutura federativa que as apoia. Umbanda, candomblé e outras vertentes não fazem parte do domínio desta ontologia."@pt-BR ;
    owl:versionInfo "1.0.0" .

##
## Classes de topo
##

esp:Instituicao a owl:Class ;
    rdfs:label "Instituição"@pt-BR ;
    rdfs:comment "Qualquer entidade institucional do movimento: uma casa ou um órgão."@pt-BR .

esp:Pessoa a owl:Class ;
    rdfs:label "Pessoa"@pt-BR .

esp:Realizacao a owl:Class ;
    rdfs:label "Realização"@pt-BR ;
    rdfs:comment "O que uma instituição realiza: atividade (periódica) ou evento (datado)."@pt-BR .

esp:TipoDeAtividade a owl:Class ;
    rdfs:label "Tipo de Atividade"@pt-BR ;
    rdfs:comment "Vocabulário de tipos de atividade. As instâncias vivem no catálogo de referência, não aqui."@pt-BR .

esp:AreaFederativa a owl:Class ;
    rdfs:label "Área Federativa"@pt-BR ;
    rdfs:comment "Área de trabalho do movimento federativo. As dez áreas são indivíduos no catálogo de referência."@pt-BR .

esp:Localizacao a owl:Class ;
    rdfs:label "Localização"@pt-BR .

##
## Instituições
##

esp:Casa a owl:Class ;
    rdfs:subClassOf esp:Instituicao ;
    owl:disjointWith esp:Orgao ;
    rdfs:label "Casa"@pt-BR ;
    rdfs:comment "Instituição espírita autônoma de base. Decide por conta própria se adere ao movimento federativo. Não é órgão."@pt-BR .

esp:Orgao a owl:Class ;
    rdfs:subClassOf esp:Instituicao ;
    rdfs:label "Órgão"@pt-BR ;
    rdfs:comment "Instituição de unificação e coordenação do movimento."@pt-BR .

esp:Centro a owl:Class ;
    rdfs:subClassOf esp:Casa ;
    rdfs:label "Centro"@pt-BR ;
    rdfs:comment "O caso comum de casa: centro espírita que realiza atividades regulares."@pt-BR .

esp:Hospital a owl:Class ;
    rdfs:subClassOf esp:Casa ;
    rdfs:label "Hospital"@pt-BR .

esp:Lar a owl:Class ;
    rdfs:subClassOf esp:Casa ;
    rdfs:label "Lar"@pt-BR ;
    rdfs:comment "Abrigo, asilo, casa de acolhimento."@pt-BR .

esp:Livraria a owl:Class ;
    rdfs:subClassOf esp:Casa ;
    rdfs:label "Livraria"@pt-BR ;
    rdfs:comment "Inclui editora espírita."@pt-BR .

esp:Federativa a owl:Class ;
    rdfs:subClassOf esp:Orgao ;
    rdfs:label "Federativa"@pt-BR .

esp:FederativaNacional a owl:Class ;
    rdfs:subClassOf esp:Federativa ;
    rdfs:label "Federativa Nacional"@pt-BR .

esp:FederativaEstadual a owl:Class ;
    rdfs:subClassOf esp:Federativa ;
    rdfs:label "Federativa Estadual"@pt-BR .

esp:OrgaoUnificador a owl:Class ;
    rdfs:subClassOf esp:Orgao ;
    rdfs:label "Órgão Unificador"@pt-BR ;
    rdfs:comment "Órgão interno de uma federativa, responsável por orientar e organizar o movimento no seu âmbito. Ex.: COFEMG dentro da UEM."@pt-BR .

esp:OrgaoRegional a owl:Class ;
    rdfs:subClassOf esp:Orgao ;
    rdfs:label "Órgão Regional"@pt-BR ;
    rdfs:comment "Recorte regional de uma federativa estadual. O nome local (Regional, CRE, URE, Polo) vai em esp:nomeLocal."@pt-BR .

esp:MacroRegiao a owl:Class ;
    rdfs:subClassOf esp:OrgaoRegional ;
    rdfs:label "Macrorregião"@pt-BR .

esp:MicroRegiao a owl:Class ;
    rdfs:subClassOf esp:OrgaoRegional ;
    rdfs:label "Microrregião"@pt-BR .

esp:OrgaoMunicipal a owl:Class ;
    rdfs:subClassOf esp:Orgao ;
    rdfs:label "Órgão Municipal"@pt-BR ;
    rdfs:comment "Órgão municipal ou intermunicipal de apoio às casas. Ex.: AME, CEM."@pt-BR .

##
## Realizações
##

esp:Atividade a owl:Class ;
    rdfs:subClassOf esp:Realizacao ;
    owl:disjointWith esp:Evento ;
    rdfs:label "Atividade"@pt-BR ;
    rdfs:comment "Realização periódica. Casas e órgãos realizam atividades."@pt-BR .

esp:Evento a owl:Class ;
    rdfs:subClassOf esp:Realizacao ;
    rdfs:label "Evento"@pt-BR ;
    rdfs:comment "Realização datada, com início e fim determinados. Não é uma atividade."@pt-BR .

##
## Pessoas e papéis
##

esp:Voluntario a owl:Class ;
    rdfs:subClassOf esp:Pessoa ;
    rdfs:label "Voluntário"@pt-BR ;
    rdfs:comment "Atua em uma instituição — casa ou órgão — e pode atuar em uma ou mais áreas federativas."@pt-BR .

esp:Coordenador a owl:Class ;
    rdfs:subClassOf esp:Voluntario ;
    rdfs:label "Coordenador"@pt-BR ;
    rdfs:comment "Voluntário que responde por uma atividade ou por uma área federativa."@pt-BR .

esp:Dirigente a owl:Class ;
    rdfs:subClassOf esp:Pessoa ;
    rdfs:label "Dirigente"@pt-BR .

esp:PublicoAlvo a owl:Class ;
    rdfs:subClassOf esp:Pessoa ;
    rdfs:label "Público-alvo"@pt-BR .

esp:Frequentador a owl:Class ;
    rdfs:subClassOf esp:PublicoAlvo ;
    rdfs:label "Frequentador"@pt-BR .

esp:Assistido a owl:Class ;
    rdfs:subClassOf esp:PublicoAlvo ;
    rdfs:label "Assistido"@pt-BR ;
    rdfs:comment "Pessoa que recebe amparo social ou espiritual."@pt-BR .

##
## Localização
##

esp:Municipio a owl:Class ;
    rdfs:subClassOf esp:Localizacao ;
    rdfs:label "Município"@pt-BR .

esp:UnidadeFederativa a owl:Class ;
    rdfs:subClassOf esp:Localizacao ;
    rdfs:label "Unidade Federativa"@pt-BR ;
    rdfs:comment "Estado brasileiro. Termo do IBGE — sem relação com o movimento federativo espírita."@pt-BR .

##
## Propriedades de objeto
##

esp:parteDe a owl:ObjectProperty , owl:TransitiveProperty ;
    rdfs:label "parte de"@pt-BR ;
    rdfs:domain esp:Orgao ;
    rdfs:range esp:Orgao ;
    rdfs:comment "Vale apenas entre órgãos. Uma casa nunca é parte de um órgão — ela adere."@pt-BR .

esp:orgaoInternoDe a owl:ObjectProperty ;
    rdfs:subPropertyOf esp:parteDe ;
    rdfs:label "órgão interno de"@pt-BR ;
    rdfs:domain esp:OrgaoUnificador ;
    rdfs:range esp:Federativa .

esp:adesaA a owl:ObjectProperty ;
    rdfs:label "adesa a"@pt-BR ;
    rdfs:domain esp:Casa ;
    rdfs:range esp:Federativa ;
    rdfs:comment "Vínculo formal e opcional. Uma casa sem adesão é dado válido."@pt-BR .

esp:atendidaPor a owl:ObjectProperty ;
    rdfs:label "atendida por"@pt-BR ;
    rdfs:domain esp:Casa ;
    rdfs:range esp:Orgao ;
    rdfs:comment "Caminho administrativo de apoio. Independente da adesão."@pt-BR .

esp:abrange a owl:ObjectProperty ;
    rdfs:label "abrange"@pt-BR ;
    rdfs:domain esp:Orgao ;
    rdfs:range esp:Municipio ;
    rdfs:comment "Municípios cobertos por um órgão. É o que torna representável a AME intermunicipal."@pt-BR .

esp:mantemArea a owl:ObjectProperty ;
    rdfs:label "mantém área"@pt-BR ;
    rdfs:domain esp:Instituicao ;
    rdfs:range esp:AreaFederativa ;
    rdfs:comment "Comum em órgão, raro em casa. Nunca obrigatório."@pt-BR .

esp:realiza a owl:ObjectProperty ;
    rdfs:label "realiza"@pt-BR ;
    rdfs:domain esp:Instituicao ;
    rdfs:range esp:Realizacao ;
    rdfs:comment "Casas e órgãos realizam tanto atividades quanto eventos."@pt-BR .

esp:doTipo a owl:ObjectProperty ;
    rdfs:label "do tipo"@pt-BR ;
    rdfs:domain esp:Atividade ;
    rdfs:range esp:TipoDeAtividade .

esp:apoiadaPor a owl:ObjectProperty ;
    rdfs:label "apoiada por"@pt-BR ;
    rdfs:domain esp:TipoDeAtividade ;
    rdfs:range esp:AreaFederativa ;
    rdfs:comment "Sem cardinalidade mínima: um tipo de atividade pode não ter área nenhuma que o apoie, e uma área técnica pode não apoiar atividade alguma. Nunca é composição."@pt-BR .

esp:temPublicoAlvo a owl:ObjectProperty ;
    rdfs:label "tem público-alvo"@pt-BR ;
    rdfs:domain esp:Realizacao ;
    rdfs:range esp:PublicoAlvo .

esp:atuaEm a owl:ObjectProperty ;
    rdfs:label "atua em"@pt-BR ;
    rdfs:domain esp:Voluntario ;
    rdfs:range esp:Instituicao .

esp:atuaNaArea a owl:ObjectProperty ;
    rdfs:label "atua na área"@pt-BR ;
    rdfs:domain esp:Voluntario ;
    rdfs:range esp:AreaFederativa .

esp:coordena a owl:ObjectProperty ;
    rdfs:label "coordena"@pt-BR ;
    rdfs:domain esp:Coordenador ;
    rdfs:comment "Alvo é uma Atividade ou uma AreaFederativa. Sem rdfs:range declarado: uma união sairia do perfil EL e quebraria o ELK. A restrição está em shapes/modelo.shacl.ttl."@pt-BR .

esp:dirige a owl:ObjectProperty ;
    rdfs:label "dirige"@pt-BR ;
    rdfs:domain esp:Dirigente ;
    rdfs:range esp:Instituicao .

esp:frequenta a owl:ObjectProperty ;
    rdfs:label "frequenta"@pt-BR ;
    rdfs:domain esp:Frequentador ;
    rdfs:range esp:Casa .

esp:localizadaEm a owl:ObjectProperty ;
    rdfs:label "localizada em"@pt-BR ;
    rdfs:domain esp:Instituicao ;
    rdfs:range esp:Municipio .

esp:pertenceA a owl:ObjectProperty ;
    rdfs:label "pertence a"@pt-BR ;
    rdfs:domain esp:Municipio ;
    rdfs:range esp:UnidadeFederativa .

##
## Propriedades de dado
##

esp:sigla a owl:DatatypeProperty ;
    rdfs:label "sigla"@pt-BR ;
    rdfs:range xsd:string .

esp:nomeLocal a owl:DatatypeProperty ;
    rdfs:label "nome local"@pt-BR ;
    rdfs:domain esp:Orgao ;
    rdfs:range xsd:string ;
    rdfs:comment "Como o nível é chamado no estado: Regional, CRE, URE, Polo, AME."@pt-BR .

esp:statusAdesao a owl:DatatypeProperty ;
    rdfs:label "status de adesão"@pt-BR ;
    rdfs:domain esp:Casa ;
    rdfs:range xsd:string ;
    rdfs:comment "Adesa, Pendente, Previsto ou Conhecido. Enum validado por SHACL."@pt-BR .

esp:modalidade a owl:DatatypeProperty ;
    rdfs:label "modalidade"@pt-BR ;
    rdfs:range xsd:string ;
    rdfs:comment "presencial, virtual ou hibrida. Aplica-se a Casa e a Realizacao — sem rdfs:domain porque dois domínios em OWL significam interseção, não união. Alvo e enum em shapes/modelo.shacl.ttl."@pt-BR .

esp:codigoIBGE a owl:DatatypeProperty ;
    rdfs:label "código IBGE"@pt-BR ;
    rdfs:domain esp:Municipio ;
    rdfs:range xsd:string .

esp:periodicidade a owl:DatatypeProperty ;
    rdfs:label "periodicidade"@pt-BR ;
    rdfs:domain esp:Atividade ;
    rdfs:range xsd:string .

esp:dataInicio a owl:DatatypeProperty ;
    rdfs:label "data de início"@pt-BR ;
    rdfs:domain esp:Evento ;
    rdfs:comment "Sem rdfs:range declarado: xsd:date não pertence ao mapa de datatypes do perfil OWL 2 EL. O tipo é exigido em shapes/modelo.shacl.ttl, mesmo padrão de esp:coordena e esp:modalidade."@pt-BR .

esp:dataFim a owl:DatatypeProperty ;
    rdfs:label "data de fim"@pt-BR ;
    rdfs:domain esp:Evento ;
    rdfs:comment "Sem rdfs:range declarado, pelo mesmo motivo de esp:dataInicio."@pt-BR .

esp:edicao a owl:DatatypeProperty ;
    rdfs:label "edição"@pt-BR ;
    rdfs:domain esp:Evento ;
    rdfs:range xsd:string .

##
## As duas únicas restrições existenciais do modelo
##

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

- [ ] **Step 4: Rodar e verificar que passa**

Run: `make reason && make verify`
Expected: ambos PASS. O `reason` prova que o TBox é consistente e está no perfil EL; o `verify` roda `cq-00`, `cq-01`, `cq-03`, `cq-04`, `cq-05`, `cq-06` com zero linhas cada.

Se `cq-00` falhar, algum termo ficou sem `rdfs:label`@pt-BR — o erro nomeia a entidade.

- [ ] **Step 5: Regerar o context.jsonld**

Run: `make context`
Expected: `ontology/context.jsonld` reescrito com os novos nomes. Conferir com `git diff --stat ontology/context.jsonld` que ele mudou. **Não editar o arquivo à mão.**

- [ ] **Step 6: Commit**

```bash
git add ontology/core.ttl ontology/context.jsonld competency-questions/
git commit -m "feat: reescreve o TBox conforme a revisão do modelo

Instituicao no topo, com Casa e Orgao disjuntos. Atividade e Evento viram
irmãos disjuntos sob Realizacao. Areas e tipos de atividade deixam de ser
classes. Sobram duas restricoes existenciais no modelo inteiro.

Remove cq-01-casa-parte-de-federativa, que verificava exatamente o axioma
derrubado pela revisao."
```

**Referência de nomes produzidos por esta task** (as Tasks 2–7 dependem destes nomes exatos):

Classes: `Instituicao` `Casa` `Centro` `Hospital` `Lar` `Livraria` `Orgao` `Federativa` `FederativaNacional` `FederativaEstadual` `OrgaoUnificador` `OrgaoRegional` `MacroRegiao` `MicroRegiao` `OrgaoMunicipal` `Pessoa` `Voluntario` `Coordenador` `Dirigente` `PublicoAlvo` `Frequentador` `Assistido` `Realizacao` `Atividade` `Evento` `TipoDeAtividade` `AreaFederativa` `Localizacao` `Municipio` `UnidadeFederativa`

Propriedades de objeto: `parteDe` `orgaoInternoDe` `adesaA` `atendidaPor` `abrange` `mantemArea` `realiza` `doTipo` `apoiadaPor` `temPublicoAlvo` `atuaEm` `atuaNaArea` `coordena` `dirige` `frequenta` `localizadaEm` `pertenceA`

Propriedades de dado: `sigla` `nomeLocal` `statusAdesao` `modalidade` `codigoIBGE` `periodicidade` `dataInicio` `dataFim` `edicao`

---

### Task 2: Catálogo de referência

**Files:**
- Modify: `ontology/reference-catalog.ttl` (reescrita completa)
- Create: `competency-questions/cq-02-areas-no-catalogo.rq`
- Create: `competency-questions/cq-07-apoio-so-para-area.rq`
- Create: `competency-questions/cq-08-sem-ciclo-em-parte-de.rq`

**Interfaces:**
- Consumes: todas as classes e propriedades da Task 1.
- Produces: os indivíduos `esp:AAE` `esp:AA` `esp:ACSE` `esp:AEE` `esp:AEEJ` `esp:AESP` `esp:AFam` `esp:AIJ` `esp:AOM` `esp:APSE` (áreas); `esp:PalestraPublica` `esp:ReuniaoMediunica` `esp:EvangelizacaoInfantil` `esp:ESDE` `esp:Passe` `esp:AtendimentoFraterno` `esp:DistribuicaoDeAlimentos` `esp:ReuniaoDeDirigentes` (tipos); `esp:FEB` `esp:CFN` `esp:UEM` `esp:COFEMG` `esp:RegionalTriangulo` `esp:CRE16` `esp:AMEUberaba` (órgãos); `esp:MinasGerais` `esp:Uberaba` (geografia). Tasks 4, 5 e 6 referenciam estes IRIs.

- [ ] **Step 1: Escrever as verificações que devem falhar**

`competency-questions/cq-02-areas-no-catalogo.rq` (novo):

```sparql
# CQ-02: Toda área federativa do catálogo tem sigla e rótulo em pt-BR?
# (violação = indivíduo esp:AreaFederativa sem esp:sigla ou sem rdfs:label@pt-BR)
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX esp: <https://w3id.org/ontologia-espirita/v1#>

SELECT ?area
WHERE {
  ?area a esp:AreaFederativa .
  FILTER(
       NOT EXISTS { ?area esp:sigla ?sigla }
    || NOT EXISTS {
         ?area rdfs:label ?rotulo .
         FILTER(LANGMATCHES(LANG(?rotulo), "pt-BR"))
       }
  )
}
```

`competency-questions/cq-07-apoio-so-para-area.rq` (novo):

```sparql
# CQ-07: esp:apoiadaPor só aponta para área federativa?
# (violação = apoio apontando para qualquer coisa que não seja esp:AreaFederativa)
PREFIX esp: <https://w3id.org/ontologia-espirita/v1#>

SELECT ?tipo ?alvo
WHERE {
  ?tipo esp:apoiadaPor ?alvo .
  FILTER NOT EXISTS { ?alvo a esp:AreaFederativa }
}
```

`competency-questions/cq-08-sem-ciclo-em-parte-de.rq` (novo):

```sparql
# CQ-08: Nenhum órgão é parte de si mesmo, direta ou indiretamente?
# (violação = ciclo na cadeia esp:parteDe — como parteDe é transitiva, um
#  ciclo tornaria todos os órgãos do laço equivalentes)
PREFIX esp: <https://w3id.org/ontologia-espirita/v1#>

SELECT ?orgao
WHERE {
  ?orgao esp:parteDe+ ?orgao .
}
```

- [ ] **Step 2: Rodar e verificar que falha**

Cuidado com um falso verde aqui: o catálogo ainda é o do v1 (só a UEM), então `cq-02` não encontra nenhum indivíduo `esp:AreaFederativa` e passa **vazia** — parecendo sucesso sem ter verificado nada.

Para provar que a consulta funciona, acrescentar temporariamente ao fim de `ontology/reference-catalog.ttl`:

```turtle
esp:AreaDeTeste a esp:AreaFederativa .
```

Run: `make verify`
Expected: FAIL — `cq-02` retorna `esp:AreaDeTeste`, que não tem sigla nem rótulo.

Remover a linha antes de seguir para o Step 3.

- [ ] **Step 3: Reescrever `ontology/reference-catalog.ttl`**

Substituir o arquivo inteiro por:

```turtle
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
@prefix esp: <https://w3id.org/ontologia-espirita/v1#> .

##
## Áreas federativas — vocabulário controlado (10 áreas)
##
## São indivíduos, não classes: tipos de atividade apontam para elas via
## esp:apoiadaPor, e uma instância não pode apontar para uma classe em OWL DL
## sem punning, o que quebraria o raciocinador ELK usado no CI.
##
## AG (Área de Gestão) fica deliberadamente fora — ver ADR 0002.
##

esp:AAE a esp:AreaFederativa ;
    esp:sigla "AAE" ;
    rdfs:label "Área de Atendimento Espiritual"@pt-BR .

esp:AA a esp:AreaFederativa ;
    esp:sigla "AA" ;
    rdfs:label "Área de Arte"@pt-BR .

esp:ACSE a esp:AreaFederativa ;
    esp:sigla "ACSE" ;
    rdfs:label "Área de Comunicação Social Espírita"@pt-BR .

esp:AEE a esp:AreaFederativa ;
    esp:sigla "AEE" ;
    rdfs:label "Área de Estudo do Espiritismo"@pt-BR .

esp:AEEJ a esp:AreaFederativa ;
    esp:sigla "AEEJ" ;
    rdfs:label "Área de Estudo do Evangelho de Jesus"@pt-BR .

esp:AESP a esp:AreaFederativa ;
    esp:sigla "AESP" ;
    rdfs:label "Área de Esperanto"@pt-BR .

esp:AFam a esp:AreaFederativa ;
    esp:sigla "AFam" ;
    rdfs:label "Área da Família"@pt-BR .

esp:AIJ a esp:AreaFederativa ;
    esp:sigla "AIJ" ;
    rdfs:label "Área de Infância e Juventude"@pt-BR .

esp:AOM a esp:AreaFederativa ;
    esp:sigla "AOM" ;
    rdfs:label "Área de Orientação Mediúnica"@pt-BR .

esp:APSE a esp:AreaFederativa ;
    esp:sigla "APSE" ;
    rdfs:label "Área de Promoção Social Espírita"@pt-BR .

##
## Tipos de atividade — catálogo editável
##
## esp:apoiadaPor registra quais áreas podem dar apoio à casa naquele tipo de
## atividade. Não é composição: a atividade não é parte da área. A lista não é
## exclusiva nem exaustiva, e um tipo pode não ter área nenhuma.
##

esp:PalestraPublica a esp:TipoDeAtividade ;
    rdfs:label "Palestra pública"@pt-BR ;
    esp:apoiadaPor esp:AEE , esp:AEEJ , esp:AAE , esp:APSE , esp:AESP , esp:ACSE .

esp:ReuniaoMediunica a esp:TipoDeAtividade ;
    rdfs:label "Reunião mediúnica"@pt-BR ;
    esp:apoiadaPor esp:AOM , esp:AEE , esp:AEEJ , esp:AAE .

esp:EvangelizacaoInfantil a esp:TipoDeAtividade ;
    rdfs:label "Evangelização infantil"@pt-BR ;
    esp:apoiadaPor esp:AIJ , esp:AEEJ , esp:AFam , esp:AA .

esp:ESDE a esp:TipoDeAtividade ;
    rdfs:label "Estudo Sistematizado da Doutrina Espírita"@pt-BR ;
    esp:apoiadaPor esp:AEE , esp:AEEJ .

esp:Passe a esp:TipoDeAtividade ;
    rdfs:label "Passe"@pt-BR ;
    esp:apoiadaPor esp:AAE , esp:AOM .

esp:AtendimentoFraterno a esp:TipoDeAtividade ;
    rdfs:label "Atendimento fraterno"@pt-BR ;
    esp:apoiadaPor esp:AAE , esp:AFam .

esp:DistribuicaoDeAlimentos a esp:TipoDeAtividade ;
    rdfs:label "Distribuição de alimentos"@pt-BR ;
    esp:apoiadaPor esp:APSE .

esp:ReuniaoDeDirigentes a esp:TipoDeAtividade ;
    rdfs:label "Reunião de dirigentes"@pt-BR ;
    rdfs:comment "Exemplo de tipo sem área de apoio — a lista de esp:apoiadaPor pode ser vazia."@pt-BR .

##
## Geografia mínima
##
## Só os dois indivíduos que o catálogo precisa referenciar. Esta ontologia
## não guarda a lista de municípios do Brasil — ver README.
##

esp:MinasGerais a esp:UnidadeFederativa ;
    esp:sigla "MG" ;
    rdfs:label "Minas Gerais"@pt-BR .

esp:Uberaba a esp:Municipio ;
    esp:codigoIBGE "3170206" ;
    esp:pertenceA esp:MinasGerais ;
    rdfs:label "Uberaba"@pt-BR .

##
## Estrutura federativa — entidades reais e estáveis
##

esp:FEB a esp:FederativaNacional ;
    esp:sigla "FEB" ;
    rdfs:label "Federação Espírita Brasileira"@pt-BR .

esp:CFN a esp:OrgaoUnificador ;
    esp:sigla "CFN" ;
    esp:orgaoInternoDe esp:FEB ;
    rdfs:label "Conselho Federativo Nacional"@pt-BR .

esp:UEM a esp:FederativaEstadual ;
    esp:sigla "UEM" ;
    rdfs:label "União Espírita Mineira"@pt-BR ;
    rdfs:comment "Entidade federativa estadual de Minas Gerais. O vínculo entre federativa estadual e FEB não é asserido aqui: a natureza dessa relação não foi definida na revisão do modelo, e asserir esp:parteDe sem confirmação repetiria o erro do v1."@pt-BR .

esp:COFEMG a esp:OrgaoUnificador ;
    esp:sigla "COFEMG" ;
    esp:orgaoInternoDe esp:UEM ;
    rdfs:label "Conselho Federativo Espírita de Minas Gerais"@pt-BR ;
    rdfs:comment "Órgão interno e unificador da própria UEM, responsável por orientar e organizar o movimento espírita no estado."@pt-BR .

esp:RegionalTriangulo a esp:MacroRegiao ;
    esp:nomeLocal "Regional" ;
    esp:parteDe esp:UEM ;
    rdfs:label "Regional Triângulo"@pt-BR .

esp:CRE16 a esp:MicroRegiao ;
    esp:nomeLocal "CRE" ;
    esp:parteDe esp:RegionalTriangulo ;
    esp:abrange esp:Uberaba ;
    rdfs:label "16ª CRE"@pt-BR ;
    rdfs:comment "Em Minas Gerais a microrregião chama-se CRE. Outros estados usam URE, Polo ou Setor — por isso o nome local é atributo, não classe."@pt-BR .

esp:AMEUberaba a esp:OrgaoMunicipal ;
    esp:nomeLocal "AME" ;
    esp:parteDe esp:CRE16 ;
    esp:abrange esp:Uberaba ;
    rdfs:label "AME Uberaba"@pt-BR .
```

- [ ] **Step 4: Rodar e verificar que passa**

Run: `make verify`
Expected: PASS. As oito consultas retornam zero linhas. Em particular `cq-08` prova que a cadeia `AMEUberaba → CRE16 → RegionalTriangulo → UEM` não tem ciclo, o que importa porque `esp:parteDe` é transitiva.

- [ ] **Step 5: Commit**

```bash
git add ontology/reference-catalog.ttl competency-questions/
git commit -m "feat: catalogo com as 10 areas, tipos de atividade e a estrutura de MG

Areas e tipos de atividade viram individuos, com o mapa apoiadaPor. Regional
e CRE deixam de ser classes: sao instancias de macro e microrregiao com o
nome local em atributo, para caber estados sem esses niveis."
```

---

### Task 3: Shapes SHACL do modelo

**Files:**
- Create: `shapes/modelo.shacl.ttl`
- Modify: `shapes/reference-catalog.shacl.ttl`
- Modify: `docker/validate.sh:20-30` (bloco `== 3/3 ==`)
- Modify: `Makefile:42-45` (alvo `shacl`)

**Interfaces:**
- Consumes: classes e propriedades da Task 1; indivíduos da Task 2.
- Produces: validação SHACL rodando sobre **dois** arquivos de dados (`ontology/reference-catalog.ttl` e `examples/mg.ttl`), não mais um só. A Task 4 depende disso.

- [ ] **Step 1: Escrever `shapes/modelo.shacl.ttl`**

Este arquivo carrega o que o perfil EL não expressa. Criar com:

```turtle
@prefix sh: <http://www.w3.org/ns/shacl#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
@prefix esp: <https://w3id.org/ontologia-espirita/v1#> .

##
## Casa
##

esp:CasaShape a sh:NodeShape ;
    sh:targetClass esp:Casa ;
    sh:property [
        sh:path esp:localizadaEm ;
        sh:minCount 1 ;
        sh:class esp:Municipio ;
        sh:message "Toda casa precisa de vínculo municipal, inclusive a de funcionamento só virtual — é exigência legal."@pt-BR ;
    ] ;
    sh:property [
        sh:path esp:statusAdesao ;
        sh:maxCount 1 ;
        sh:in ( "Adesa" "Pendente" "Previsto" "Conhecido" ) ;
        sh:message "statusAdesao só aceita Adesa, Pendente, Previsto ou Conhecido."@pt-BR ;
    ] ;
    sh:property [
        sh:path esp:modalidade ;
        sh:minCount 1 ;
        sh:severity sh:Warning ;
        sh:message "Recomendado informar a modalidade da casa (presencial, virtual ou hibrida). Aviso, não erro: o cadastro federativo existente ainda não tem esse campo."@pt-BR ;
    ] ;
    sh:property [
        sh:path esp:modalidade ;
        sh:in ( "presencial" "virtual" "hibrida" ) ;
        sh:message "modalidade só aceita presencial, virtual ou hibrida."@pt-BR ;
    ] .

##
## Realizações — atividade e evento
##

esp:RealizacaoShape a sh:NodeShape ;
    sh:targetClass esp:Atividade , esp:Evento ;
    sh:property [
        sh:path esp:modalidade ;
        sh:minCount 1 ;
        sh:in ( "presencial" "virtual" "hibrida" ) ;
        sh:message "Toda atividade e todo evento informam modalidade: presencial, virtual ou hibrida."@pt-BR ;
    ] .

esp:AtividadeShape a sh:NodeShape ;
    sh:targetClass esp:Atividade ;
    sh:property [
        sh:path esp:doTipo ;
        sh:minCount 1 ;
        sh:class esp:TipoDeAtividade ;
        sh:message "Toda atividade aponta para um tipo do catálogo."@pt-BR ;
    ] .

esp:EventoShape a sh:NodeShape ;
    sh:targetClass esp:Evento ;
    sh:property [
        sh:path esp:dataInicio ;
        sh:minCount 1 ;
        sh:datatype xsd:date ;
        sh:message "Todo evento tem data de início — é o que o separa de uma atividade."@pt-BR ;
    ] .

##
## Coordenador — o alvo que o perfil EL não expressa
##

esp:CoordenadorShape a sh:NodeShape ;
    sh:targetClass esp:Coordenador ;
    sh:property [
        sh:path esp:coordena ;
        sh:minCount 1 ;
        sh:or ( [ sh:class esp:Atividade ] [ sh:class esp:AreaFederativa ] ) ;
        sh:message "Coordenador coordena uma Atividade ou uma AreaFederativa."@pt-BR ;
    ] .

##
## Órgãos
##

esp:OrgaoRegionalShape a sh:NodeShape ;
    sh:targetClass esp:OrgaoRegional ;
    sh:property [
        sh:path esp:nomeLocal ;
        sh:minCount 1 ;
        sh:message "Órgão regional precisa do nome local (Regional, CRE, URE, Polo) — a nomenclatura varia por estado."@pt-BR ;
    ] .

esp:OrgaoUnificadorShape a sh:NodeShape ;
    sh:targetClass esp:OrgaoUnificador ;
    sh:property [
        sh:path esp:orgaoInternoDe ;
        sh:minCount 1 ;
        sh:class esp:Federativa ;
        sh:message "Órgão unificador é sempre órgão interno de uma federativa."@pt-BR ;
    ] .
```

- [ ] **Step 2: Acrescentar o shape de tipo de atividade ao catálogo**

Em `shapes/reference-catalog.shacl.ttl`, manter o `esp:FederativaShape` que já existe e acrescentar ao fim:

```turtle
esp:AreaFederativaShape a sh:NodeShape ;
    sh:targetClass esp:AreaFederativa ;
    sh:property [
        sh:path esp:sigla ;
        sh:minCount 1 ;
        sh:maxCount 1 ;
        sh:message "Toda área federativa do catálogo tem exatamente uma sigla."@pt-BR ;
    ] .

esp:TipoDeAtividadeShape a sh:NodeShape ;
    sh:targetClass esp:TipoDeAtividade ;
    sh:property [
        sh:path rdfs:label ;
        sh:minCount 1 ;
        sh:languageIn ( "pt-BR" ) ;
        sh:message "Todo tipo de atividade do catálogo precisa de rdfs:label em pt-BR."@pt-BR ;
    ] .
```

- [ ] **Step 3: Fazer o SHACL rodar sobre os dois arquivos de dados**

Em `docker/validate.sh`, substituir o bloco `== 3/3 ==` inteiro por:

```sh
echo "== 3/3: SHACL (catálogo de referência e exemplos) =="
if ls shapes/*.shacl.ttl >/dev/null 2>&1; then
    for dados in ontology/reference-catalog.ttl examples/mg.ttl; do
        [ -f "$dados" ] || continue
        for shape in shapes/*.shacl.ttl; do
            echo "  -- $shape sobre $dados --"
            pyshacl -s "$shape" -d "$dados" -e ontology/core.ttl -i rdfs
        done
    done
else
    echo "  (shapes ainda não existem — pulando)"
fi
```

Em `Makefile`, substituir o alvo `shacl` por:

```make
shacl: build
	docker run --rm -v "$(WORKDIR)":/work -w /work $(IMAGE) -c \
		'for dados in ontology/reference-catalog.ttl examples/mg.ttl; do \
		   [ -f "$$dados" ] || continue; \
		   for shape in shapes/*.shacl.ttl; do \
		     echo "-- $$shape sobre $$dados --"; \
		     pyshacl -s "$$shape" -d "$$dados" -e ontology/core.ttl -i rdfs; \
		   done; \
		 done'
```

- [ ] **Step 4: Rodar e verificar**

Run: `make shacl`
Expected: PASS. `examples/mg.ttl` ainda não existe, e o `continue` o pula sem erro. O catálogo passa: `CRE16`, `RegionalTriangulo` e `AMEUberaba`... **atenção**, `AMEUberaba` é `esp:OrgaoMunicipal`, não `esp:OrgaoRegional`, então o shape de `nomeLocal` não o alcança — ele tem `nomeLocal` mesmo assim, o que é correto mas não exigido.

Se `pyshacl` reclamar de `esp:CFN` ou `esp:COFEMG`, conferir que ambos têm `esp:orgaoInternoDe` apontando para algo tipado como `esp:Federativa` — a inferência `-i rdfs` é o que faz `esp:FederativaNacional` contar como `esp:Federativa`.

- [ ] **Step 5: Commit**

```bash
git add shapes/ docker/validate.sh Makefile
git commit -m "feat: shapes SHACL para o que o perfil EL nao expressa

Enums de statusAdesao e modalidade, alvo de coordena (uniao sairia do EL),
obrigatoriedades de atividade e evento. Modalidade e exigida em Realizacao e
apenas recomendada em Casa: obrigatoria na casa invalidaria todo o cadastro
federativo existente de uma vez.

SHACL passa a rodar sobre catalogo e exemplos, nao so o catalogo."
```

---

### Task 4: ABox de exemplo — o movimento mineiro

**Files:**
- Create: `examples/mg.ttl`
- Modify: `Makefile:38-41` (alvo `verify`)
- Modify: `docker/validate.sh:9-19` (bloco `== 2/3 ==`)

**Interfaces:**
- Consumes: classes e propriedades da Task 1; indivíduos da Task 2; shapes da Task 3.
- Produces: os indivíduos `esp:CasaLuzDoCaminho` `esp:CasaFraternidade` `esp:CasaEsperancaVirtual` `esp:PalestraLuzQuinta` `esp:ReuniaoMediunicaLuz` `esp:EvangelizacaoLuz` `esp:ReuniaoDirigentesCRE16` `esp:SemanaEspiritaUberaba2026` `esp:Maria` `esp:Joao` `esp:Ana` `esp:Paulo` `esp:Carlos` `esp:Rosa` `esp:Antonio`. A Task 6 consulta estes IRIs.

- [ ] **Step 1: Fazer as competency questions enxergarem os exemplos**

Em `Makefile`, substituir o alvo `verify` por:

```make
verify: build
	docker run --rm -v "$(WORKDIR)":/work -w /work $(IMAGE) -c \
		"robot merge --input ontology/core.ttl --input ontology/reference-catalog.ttl --input examples/mg.ttl verify --queries competency-questions/*.rq"
```

Em `docker/validate.sh`, substituir o bloco `== 2/3 ==` inteiro por:

```sh
echo "== 2/3: competency questions (robot verify) =="
if [ -d competency-questions ] && ls competency-questions/*.rq >/dev/null 2>&1; then
    ENTRADAS="--input ontology/core.ttl"
    [ -f ontology/reference-catalog.ttl ] && ENTRADAS="$ENTRADAS --input ontology/reference-catalog.ttl"
    [ -f examples/mg.ttl ] && ENTRADAS="$ENTRADAS --input examples/mg.ttl"
    robot merge $ENTRADAS verify --queries competency-questions/*.rq
else
    echo "  (nenhum arquivo .rq encontrado ainda — pulando)"
fi
```

- [ ] **Step 2: Rodar e verificar que falha**

Run: `make verify`
Expected: FAIL com erro de arquivo não encontrado — `examples/mg.ttl` ainda não existe. É a confirmação de que o merge realmente passou a incluí-lo.

- [ ] **Step 3: Escrever `examples/mg.ttl`**

```turtle
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
@prefix esp: <https://w3id.org/ontologia-espirita/v1#> .

##
## ABox de exemplo — ficção de teste, não dado de produção.
##
## Apoia-se no catálogo (ontology/reference-catalog.ttl) para as entidades
## federativas reais e para os tipos de atividade. O que está aqui são casas,
## realizações e pessoas inventadas, escolhidas para exercitar cada decisão do
## design de uma vez só.
##

##
## Casas — uma adesa, uma só conhecida, uma virtual
##

esp:CasaLuzDoCaminho a esp:Centro ;
    rdfs:label "Centro Espírita Luz do Caminho"@pt-BR ;
    esp:localizadaEm esp:Uberaba ;
    esp:modalidade "presencial" ;
    esp:adesaA esp:UEM ;
    esp:statusAdesao "Adesa" ;
    esp:atendidaPor esp:AMEUberaba , esp:CRE16 , esp:RegionalTriangulo ;
    esp:realiza esp:PalestraLuzQuinta , esp:ReuniaoMediunicaLuz , esp:EvangelizacaoLuz .

esp:CasaFraternidade a esp:Centro ;
    rdfs:label "Centro Espírita Fraternidade"@pt-BR ;
    rdfs:comment "Casa conhecida pelo movimento mas sem adesão. Prova que esp:adesaA é opcional: a autonomia da casa é dado válido, não erro."@pt-BR ;
    esp:localizadaEm esp:Uberaba ;
    esp:modalidade "presencial" ;
    esp:statusAdesao "Conhecido" .

esp:CasaEsperancaVirtual a esp:Centro ;
    rdfs:label "Grupo Espírita Esperança"@pt-BR ;
    rdfs:comment "Funciona só online. Mantém vínculo municipal por exigência legal — o município é o vínculo jurídico, não prova de presença física."@pt-BR ;
    esp:localizadaEm esp:Uberaba ;
    esp:modalidade "virtual" ;
    esp:adesaA esp:UEM ;
    esp:statusAdesao "Pendente" .

##
## Atividades da casa — periódicas
##

esp:PalestraLuzQuinta a esp:Atividade ;
    rdfs:label "Palestra pública das quintas"@pt-BR ;
    esp:doTipo esp:PalestraPublica ;
    esp:periodicidade "semanal" ;
    esp:modalidade "hibrida" ;
    esp:temPublicoAlvo esp:Antonio .

esp:ReuniaoMediunicaLuz a esp:Atividade ;
    rdfs:label "Reunião mediúnica de terça"@pt-BR ;
    esp:doTipo esp:ReuniaoMediunica ;
    esp:periodicidade "semanal" ;
    esp:modalidade "presencial" .

esp:EvangelizacaoLuz a esp:Atividade ;
    rdfs:label "Evangelização infantil de domingo"@pt-BR ;
    esp:doTipo esp:EvangelizacaoInfantil ;
    esp:periodicidade "semanal" ;
    esp:modalidade "presencial" .

##
## Atividade de órgão — prova que atividade não é exclusividade da casa
##

esp:CRE16 esp:realiza esp:ReuniaoDirigentesCRE16 .

esp:ReuniaoDirigentesCRE16 a esp:Atividade ;
    rdfs:label "Reunião mensal de dirigentes da 16ª CRE"@pt-BR ;
    esp:doTipo esp:ReuniaoDeDirigentes ;
    esp:periodicidade "mensal" ;
    esp:modalidade "virtual" .

##
## Evento — datado, com início e fim
##

esp:AMEUberaba esp:realiza esp:SemanaEspiritaUberaba2026 .

esp:SemanaEspiritaUberaba2026 a esp:Evento ;
    rdfs:label "XII Semana Espírita de Uberaba"@pt-BR ;
    esp:edicao "XII" ;
    esp:dataInicio "2026-10-12"^^xsd:date ;
    esp:dataFim "2026-10-18"^^xsd:date ;
    esp:modalidade "presencial" .

##
## Pessoas
##

esp:Maria a esp:Voluntario ;
    rdfs:label "Maria"@pt-BR ;
    rdfs:comment "Voluntária de casa: dá passes, sem vínculo com área federativa."@pt-BR ;
    esp:atuaEm esp:CasaLuzDoCaminho .

esp:Joao a esp:Voluntario ;
    rdfs:label "João"@pt-BR ;
    rdfs:comment "Voluntário de órgão. Mesmo papel que Maria, lugar diferente."@pt-BR ;
    esp:atuaEm esp:CRE16 ;
    esp:atuaNaArea esp:ACSE .

esp:Ana a esp:Coordenador ;
    rdfs:label "Ana"@pt-BR ;
    esp:atuaEm esp:CasaLuzDoCaminho ;
    esp:coordena esp:EvangelizacaoLuz .

esp:Paulo a esp:Coordenador ;
    rdfs:label "Paulo"@pt-BR ;
    rdfs:comment "Coordenador de área num órgão — mesmo papel de Ana, alvo de outro tipo."@pt-BR ;
    esp:atuaEm esp:CRE16 ;
    esp:atuaNaArea esp:AIJ ;
    esp:coordena esp:AIJ .

esp:Carlos a esp:Dirigente ;
    rdfs:label "Carlos"@pt-BR ;
    esp:dirige esp:CasaLuzDoCaminho .

esp:Antonio a esp:Frequentador ;
    rdfs:label "Antônio"@pt-BR ;
    esp:frequenta esp:CasaLuzDoCaminho .

esp:Rosa a esp:Assistido ;
    rdfs:label "Rosa"@pt-BR ;
    rdfs:comment "Recebe amparo social. Termo correto é assistida, não beneficiária."@pt-BR .

##
## Área estruturada numa casa — o caso raro que o modelo permite sem exigir
##

esp:CasaLuzDoCaminho esp:mantemArea esp:AIJ .

##
## Áreas do órgão — o caso comum
##

esp:CRE16 esp:mantemArea esp:AIJ , esp:ACSE , esp:APSE .
```

- [ ] **Step 4: Rodar e verificar que passa**

Run: `make verify && make shacl`
Expected: ambos PASS.

`make shacl` agora valida `examples/mg.ttl` de verdade. Se aparecer violação:
- "Toda atividade aponta para um tipo" → alguma `esp:Atividade` sem `esp:doTipo`.
- "Toda atividade e todo evento informam modalidade" → falta `esp:modalidade`.
- "Coordenador coordena uma Atividade ou uma AreaFederativa" → `esp:coordena` apontando para outra coisa.

Um aviso (`sh:Warning`) sobre modalidade de casa não deve aparecer: as três casas a informam.

- [ ] **Step 5: Commit**

```bash
git add examples/mg.ttl Makefile docker/validate.sh
git commit -m "test: ABox de exemplo com o movimento mineiro

Exercita cada decisao do design: casa adesa, casa so conhecida (adesao
opcional), casa virtual com vinculo municipal, atividade de orgao, evento
datado, coordenador de atividade e coordenador de area.

Competency questions e SHACL passam a rodar tambem sobre os exemplos."
```

---

### Task 5: Contra-exemplos — provar que as verificações pegam erro

**Files:**
- Create: `examples/contra-exemplos.ttl`
- Create: `docker/contra-exemplos.sh`
- Modify: `Makefile` (alvo `contra-exemplos` e `.PHONY`)

**Interfaces:**
- Consumes: `cq-01-casa-nao-e-orgao.rq` e `cq-04-atividade-nao-e-evento.rq` da Task 1.
- Produces: alvo `make contra-exemplos`.

**Por que esta task existe:** `robot verify` trata **zero linhas como sucesso**. `cq-01` e `cq-04` verificam disjunções e, rodadas só contra o exemplo válido, nunca encontram nada — passariam vazias parecendo cobertura. Este é o teste do teste.

- [ ] **Step 1: Escrever o ABox deliberadamente inválido**

`examples/contra-exemplos.ttl`:

```turtle
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix esp: <https://w3id.org/ontologia-espirita/v1#> .

##
## Violações plantadas de propósito.
##
## Este arquivo NUNCA entra no merge de `make verify` nem no `make shacl`.
## Ele existe só para o `make contra-exemplos`, que passa apenas quando cada
## consulta abaixo ENCONTRA a violação correspondente.
##

esp:CoisaQueEhCasaEOrgao a esp:Casa , esp:Orgao ;
    rdfs:label "Instituição impossível"@pt-BR ;
    rdfs:comment "Viola a disjunção Casa/Órgão. Deve ser encontrada por cq-01."@pt-BR ;
    esp:localizadaEm esp:Uberaba .

esp:CoisaQueEhAtividadeEEvento a esp:Atividade , esp:Evento ;
    rdfs:label "Realização impossível"@pt-BR ;
    rdfs:comment "Viola a disjunção Atividade/Evento. Deve ser encontrada por cq-04."@pt-BR .
```

- [ ] **Step 2: Escrever `docker/contra-exemplos.sh`**

```sh
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
for consulta in competency-questions/cq-01-casa-nao-e-orgao.rq \
                competency-questions/cq-04-atividade-nao-e-evento.rq ; do
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
```

Tornar executável:

```bash
chmod +x docker/contra-exemplos.sh
```

- [ ] **Step 3: Acrescentar o alvo ao Makefile**

Na linha `.PHONY`, acrescentar `contra-exemplos` e `perguntas`:

```make
.PHONY: help check-tools build validate reason verify shacl context context-check perguntas contra-exemplos clean
```

No bloco `help`, acrescentar depois da linha do `shacl`:

```make
	@echo "  make perguntas      - imprime as respostas do modelo para as perguntas de queries/"
	@echo "  make contra-exemplos - prova que as verificacoes de disjuncao pegam erro"
```

E o alvo, depois do alvo `shacl`:

```make
contra-exemplos: build
	$(DOCKER_RUN) /work/docker/contra-exemplos.sh
```

- [ ] **Step 4: Rodar e verificar que passa**

Run: `make contra-exemplos`
Expected: PASS, com duas linhas `OK: ... detectou 1 violacao(oes), como esperado`.

- [ ] **Step 5: Provar que o alvo falha quando deve**

Comentar temporariamente a primeira violação em `examples/contra-exemplos.ttl` (trocar `a esp:Casa , esp:Orgao` por `a esp:Casa`).

Run: `make contra-exemplos`
Expected: FAIL com `FALHA: competency-questions/cq-01-casa-nao-e-orgao.rq nao detectou a violacao plantada`.

Desfazer a alteração e rodar de novo para confirmar que volta a passar.

- [ ] **Step 6: Commit**

```bash
git add examples/contra-exemplos.ttl docker/contra-exemplos.sh Makefile
git commit -m "test: contra-exemplos provam que as verificacoes pegam erro

robot verify trata zero linhas como sucesso, entao cq-01 e cq-04 passariam
vazias contra um exemplo valido — cobertura aparente sem prova nenhuma.
O alvo contra-exemplos roda as mesmas consultas contra violacoes plantadas
e so passa quando cada uma as encontra."
```

---

### Task 6: `make perguntas` — o modelo respondendo em voz alta

**Files:**
- Create: `queries/q-01-areas-que-apoiam-as-atividades-da-casa.rq`
- Create: `queries/q-02-quem-coordena-o-que.rq`
- Create: `queries/q-03-casas-sem-adesao.rq`
- Create: `queries/q-04-estrutura-federativa.rq`
- Create: `queries/q-05-realizacoes-e-modalidades.rq`
- Create: `queries/q-06-voluntarios-e-areas.rq`
- Create: `docker/perguntas.sh`
- Modify: `Makefile` (alvo `perguntas`)

**Interfaces:**
- Consumes: indivíduos das Tasks 2 e 4.
- Produces: alvo `make perguntas`. É a ferramenta de inspeção que o mantenedor do domínio pediu — ele lê a saída e diz se a resposta está errada.

**Diferença para `make verify`:** `verify` **falha** quando o modelo está errado; `perguntas` **mostra** o que o modelo pensa. As duas coisas são necessárias.

- [ ] **Step 1: Escrever as consultas**

A primeira linha de cada arquivo é o título impresso pelo script — o `# ` inicial é removido.

`queries/q-01-areas-que-apoiam-as-atividades-da-casa.rq`:

```sparql
# Quais áreas federativas apoiam as atividades da Casa Luz do Caminho?
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX esp: <https://w3id.org/ontologia-espirita/v1#>

SELECT ?atividade ?sigla ?area
WHERE {
  esp:CasaLuzDoCaminho esp:realiza ?umaAtividade .
  ?umaAtividade rdfs:label ?atividade ;
                esp:doTipo ?tipo .
  ?tipo esp:apoiadaPor ?umaArea .
  ?umaArea esp:sigla ?sigla ;
           rdfs:label ?area .
}
ORDER BY ?atividade ?sigla
```

`queries/q-02-quem-coordena-o-que.rq`:

```sparql
# Quem coordena o quê, e onde?
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX esp: <https://w3id.org/ontologia-espirita/v1#>

SELECT ?pessoa ?coordena ?onde
WHERE {
  ?umaPessoa a esp:Coordenador ;
             rdfs:label ?pessoa ;
             esp:coordena ?alvo ;
             esp:atuaEm ?instituicao .
  ?alvo rdfs:label ?coordena .
  ?instituicao rdfs:label ?onde .
}
ORDER BY ?pessoa
```

`queries/q-03-casas-sem-adesao.rq`:

```sparql
# Casas conhecidas que NÃO são adesas ao movimento federativo
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX esp: <https://w3id.org/ontologia-espirita/v1#>

SELECT ?casa ?status ?municipio
WHERE {
  ?umaCasa a/rdfs:subClassOf* esp:Casa ;
           rdfs:label ?casa ;
           esp:localizadaEm ?umMunicipio .
  ?umMunicipio rdfs:label ?municipio .
  OPTIONAL { ?umaCasa esp:statusAdesao ?status }
  FILTER NOT EXISTS { ?umaCasa esp:adesaA ?federativa }
}
ORDER BY ?casa
```

`queries/q-04-estrutura-federativa.rq`:

```sparql
# Como está montada a estrutura federativa que o catálogo conhece?
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX esp: <https://w3id.org/ontologia-espirita/v1#>

SELECT ?orgao ?nomeLocal ?dentroDe
WHERE {
  ?umOrgao a/rdfs:subClassOf* esp:Orgao ;
           rdfs:label ?orgao .
  OPTIONAL { ?umOrgao esp:nomeLocal ?nomeLocal }
  OPTIONAL {
    ?umOrgao esp:parteDe ?superior .
    ?superior rdfs:label ?dentroDe .
  }
}
ORDER BY ?orgao
```

`queries/q-05-realizacoes-e-modalidades.rq`:

```sparql
# Quem realiza o quê, de que natureza e em que modalidade?
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX esp: <https://w3id.org/ontologia-espirita/v1#>

SELECT ?quem ?realizacao ?natureza ?modalidade
WHERE {
  ?instituicao esp:realiza ?umaRealizacao ;
               rdfs:label ?quem .
  ?umaRealizacao rdfs:label ?realizacao ;
                 esp:modalidade ?modalidade .
  BIND(IF(EXISTS { ?umaRealizacao a esp:Evento }, "evento", "atividade") AS ?natureza)
}
ORDER BY ?quem ?realizacao
```

`queries/q-06-voluntarios-e-areas.rq`:

```sparql
# Onde cada voluntário atua, e em que áreas federativas?
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX esp: <https://w3id.org/ontologia-espirita/v1#>

SELECT ?voluntario ?onde ?sigla
WHERE {
  ?umVoluntario a/rdfs:subClassOf* esp:Voluntario ;
                rdfs:label ?voluntario ;
                esp:atuaEm ?instituicao .
  ?instituicao rdfs:label ?onde .
  OPTIONAL {
    ?umVoluntario esp:atuaNaArea ?area .
    ?area esp:sigla ?sigla .
  }
}
ORDER BY ?voluntario
```

- [ ] **Step 2: Escrever `docker/perguntas.sh`**

```sh
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
```

Tornar executável:

```bash
chmod +x docker/perguntas.sh
```

O `tail -n +2` descarta a linha de cabeçalho do CSV — os nomes das variáveis SPARQL não interessam a quem lê. A formatação é simples de propósito: o que importa é a resposta estar legível, não o alinhamento das colunas.

- [ ] **Step 3: Acrescentar o alvo ao Makefile**

Depois do alvo `contra-exemplos`:

```make
perguntas: build
	$(DOCKER_RUN) /work/docker/perguntas.sh
```

- [ ] **Step 4: Rodar e conferir as respostas**

Run: `make perguntas`

Expected: seis blocos de saída. Conferir três respostas em particular, que provam decisões do design:

1. **q-01** deve listar seis áreas para a palestra pública (AAE, ACSE, AEE, AEEJ, AESP, APSE) e quatro para a reunião mediúnica (AAE, AEE, AEEJ, AOM) — exatamente o mapa que o mantenedor descreveu.
2. **q-03** deve trazer o Centro Espírita Fraternidade com status `Conhecido` — prova que casa sem adesão é dado válido.
3. **q-05** deve mostrar a 16ª CRE realizando uma **atividade** (não um evento), provando que atividade não é exclusividade da casa.

Se alguma dessas três não bater, o problema está no modelo ou nos dados, não na consulta — parar e investigar antes de commitar.

- [ ] **Step 5: Commit**

```bash
git add queries/ docker/perguntas.sh Makefile
git commit -m "feat: alvo make perguntas para inspecionar o que o modelo responde

Seis perguntas rodadas contra modelo + catalogo + exemplos, com as respostas
impressas em tabela. E a ferramenta de inspecao pedida pelo mantenedor: ele
le a saida e diz se a resposta esta errada.

verify falha quando o modelo esta errado; perguntas mostra o que ele pensa."
```

---

### Task 7: Documentação

**Files:**
- Modify: `docs/glossario.md` (reescrita completa)
- Modify: `docs/modelo-de-dominio.md` (reescrita completa)
- Create: `docs/decisoes/0002-revisao-do-modelo.md`
- Modify: `CHANGELOG.md`
- Modify: `README.md`

**Interfaces:**
- Consumes: tudo das Tasks 1–6.

- [ ] **Step 1: Reescrever `docs/glossario.md`**

```markdown
# Glossário

Termos em português, na ordem em que aparecem em `ontology/core.ttl`.

Esta ontologia cobre o **movimento espírita kardecista**. Umbanda, candomblé
e outras vertentes não fazem parte do domínio.

## Instituições

| Termo | IRI | Definição |
|---|---|---|
| Instituição | `esp:Instituicao` | Classe de topo: qualquer entidade institucional do movimento, casa ou órgão. |
| Casa | `esp:Casa` | Instituição espírita autônoma de base. Decide por conta própria se adere ao movimento federativo. **Não é órgão.** |
| Centro | `esp:Centro` | O caso comum de casa: centro espírita que realiza atividades regulares. |
| Hospital | `esp:Hospital` | Hospital espírita. É uma casa, não um órgão. |
| Lar | `esp:Lar` | Abrigo, asilo, casa de acolhimento. |
| Livraria | `esp:Livraria` | Livraria ou editora espírita. |
| Órgão | `esp:Orgao` | Instituição de unificação e coordenação. Disjunto de Casa. |
| Federativa | `esp:Federativa` | Entidade federativa. Nacional (FEB) ou estadual (UEM). |
| Órgão Unificador | `esp:OrgaoUnificador` | Órgão interno de uma federativa, que orienta e organiza o movimento no seu âmbito. COFEMG dentro da UEM; CFN dentro da FEB. |
| Órgão Regional | `esp:OrgaoRegional` | Recorte regional de uma federativa estadual. Macrorregião ou microrregião. |
| Macrorregião | `esp:MacroRegiao` | Nível regional maior. Em MG chama-se "Regional". |
| Microrregião | `esp:MicroRegiao` | Nível regional menor. Em MG chama-se "CRE"; em outros estados, URE, Polo ou Setor. |
| Órgão Municipal | `esp:OrgaoMunicipal` | Órgão municipal ou intermunicipal de apoio às casas. AME, CEM. |

## Adesão

| Termo | IRI | Definição |
|---|---|---|
| adesa a | `esp:adesaA` | Vínculo formal de uma casa com a federativa. **Opcional** — a casa tem autonomia para decidir. |
| status de adesão | `esp:statusAdesao` | Adesa, Pendente, Previsto ou Conhecido. |
| atendida por | `esp:atendidaPor` | Caminho administrativo de apoio (AME, CRE, Regional). Independente da adesão. |
| parte de | `esp:parteDe` | Relação hierárquica **entre órgãos**. Uma casa nunca é parte de um órgão. |
| órgão interno de | `esp:orgaoInternoDe` | Do unificador para sua federativa. |

## Realizações

| Termo | IRI | Definição |
|---|---|---|
| Realização | `esp:Realizacao` | Classe de topo do que uma instituição realiza. |
| Atividade | `esp:Atividade` | Realização **periódica**. Casas e órgãos realizam atividades. |
| Evento | `esp:Evento` | Realização **datada**, com início e fim. Não é uma atividade — são disjuntos. |
| Tipo de Atividade | `esp:TipoDeAtividade` | Vocabulário de tipos (palestra pública, reunião mediúnica, ESDE...). As instâncias vivem no catálogo. |
| apoiada por | `esp:apoiadaPor` | Áreas que podem apoiar a casa num tipo de atividade. Pode ser vazia. Nunca é composição. |
| modalidade | `esp:modalidade` | presencial, virtual ou hibrida. Vale para casa e para realização. |

## Áreas federativas

| Termo | IRI | Definição |
|---|---|---|
| Área Federativa | `esp:AreaFederativa` | Área de trabalho do movimento. As dez áreas são **indivíduos** no catálogo, não classes. |
| mantém área | `esp:mantemArea` | Órgão estrutura áreas com frequência; casa raramente. Nunca obrigatório. |

As dez: AAE (Atendimento Espiritual), AA (Arte), ACSE (Comunicação Social
Espírita), AEE (Estudo do Espiritismo), AEEJ (Estudo do Evangelho de Jesus),
AESP (Esperanto), AFam (Família), AIJ (Infância e Juventude), AOM (Orientação
Mediúnica), APSE (Promoção Social Espírita).

## Pessoas

| Termo | IRI | Definição |
|---|---|---|
| Voluntário | `esp:Voluntario` | Atua em uma instituição — casa ou órgão — e pode atuar em uma ou mais áreas federativas. |
| Coordenador | `esp:Coordenador` | Voluntário que responde por uma atividade ou por uma área federativa. |
| Dirigente | `esp:Dirigente` | Dirige uma instituição. |
| Público-alvo | `esp:PublicoAlvo` | Quem a instituição atende. |
| Frequentador | `esp:Frequentador` | Participa de atividades regulares. |
| Assistido | `esp:Assistido` | Recebe amparo social ou espiritual. **Não se diz "beneficiário".** |

## Geografia

| Termo | IRI | Definição |
|---|---|---|
| Município | `esp:Municipio` | Carrega o código IBGE. É o vínculo jurídico de uma casa — inclusive de uma casa só virtual. |
| Unidade Federativa | `esp:UnidadeFederativa` | Estado brasileiro. Termo do IBGE, sem relação com o movimento federativo espírita. |

Para a lista completa e formal, ver `ontology/core.ttl` e
`ontology/reference-catalog.ttl`.
```

- [ ] **Step 2: Reescrever `docs/modelo-de-dominio.md`**

```markdown
# Modelo de domínio

Visão narrativa do grafo definido em `ontology/core.ttl`. Ver
`docs/glossario.md` para definição termo a termo, e
`docs/decisoes/0002-revisao-do-modelo.md` para o porquê das escolhas.

## Escopo

Movimento espírita **kardecista** organizado no Brasil. Umbanda, candomblé e
outras vertentes não fazem parte do domínio — não é recorte temporário, é
definição de escopo.

## Casa e órgão são coisas diferentes

`esp:Instituicao` é o topo, com dois ramos **disjuntos**:

- **`esp:Casa`** — a instituição autônoma de base. Um centro, mas também um
  hospital, um lar ou uma livraria espírita.
- **`esp:Orgao`** — a estrutura de unificação: federativa nacional e estadual,
  órgão unificador, órgãos regionais e municipais.

Um hospital espírita é uma casa. Não é um órgão.

## A casa adere; ela não é parte

A casa espírita tem autonomia para decidir se adere ao movimento federativo.
Ser espírita e fazer parte da estrutura federativa são coisas separadas.

Por isso `esp:adesaA` é **opcional**: uma casa sem adesão é dado válido e
comum. O modelo registra o que se sabe dela — `esp:statusAdesao` com Adesa,
Pendente, Previsto ou Conhecido — sem exigir vínculo.

`esp:parteDe` sobrevive apenas **entre órgãos**: o COFEMG é parte da UEM, a
16ª CRE é parte da Regional Triângulo.

## O órgão unificador

A UEM é a entidade federativa estadual de Minas Gerais. O COFEMG é o órgão
interno e unificador da própria UEM, responsável por orientar e organizar o
movimento espírita no estado. A relação é `esp:orgaoInternoDe`, e o mesmo
padrão vale para o CFN dentro da FEB.

## Regiões: o modelo não é Minas Gerais

Uma federativa estadual pode ter zero, um ou dois níveis regionais. O modelo
carrega `esp:MacroRegiao` e `esp:MicroRegiao`; o nome que cada estado usa vai
em `esp:nomeLocal`.

Em Minas Gerais, macrorregião chama-se "Regional" e microrregião chama-se
"CRE". Em outros estados, URE, Polo ou Setor. Nenhum desses nomes é classe.

## Atividade e evento

São **irmãos disjuntos**, não subclasse um do outro:

- **Atividade** é periódica — a palestra pública de toda quinta.
- **Evento** é datado, com início e fim — a Semana Espírita de outubro.

Ambos são realizados tanto por casas quanto por órgãos: uma CRE com reunião
mensal de dirigentes realiza uma atividade. E ambos informam
`esp:modalidade`: presencial, virtual ou híbrida.

## Atividade não é parte de área

Uma atividade **não pertence** a uma área federativa. Ela pode ser **apoiada
por** várias — ou por nenhuma.

Uma palestra pública pode ser apoiada por estudo do espiritismo, estudo do
evangelho, atendimento espiritual, promoção social, esperanto e comunicação
social. Uma reunião mediúnica, por orientação mediúnica, estudos, estudo do
evangelho e atendimento espiritual. As listas não são exclusivas nem
exaustivas, e uma área técnica pode não apoiar atividade nenhuma.

Esse mapa vive no catálogo (`ontology/reference-catalog.ttl`), ligado ao
**tipo** de atividade. Acrescentar um tipo novo não toca o modelo lógico.

## Áreas são estrutura de órgão

Uma casa raramente tem áreas federativas estruturadas — ela se preocupa com
suas atividades. Órgãos estruturam áreas com frequência. `esp:mantemArea`
permite os dois casos e não obriga nenhum.

## Pessoas

Um voluntário atua em uma instituição — casa ou órgão — e pode atuar em uma
ou mais áreas federativas, ou em nenhuma. Um coordenador é um voluntário que
responde por uma atividade (numa casa) ou por uma área (num órgão).

Uma mesma pessoa acumular papéis é responsabilidade do app consumidor
modelar, não desta ontologia.

## Geografia

Toda casa está localizada em um município, que pertence a uma unidade
federativa e carrega o código IBGE. Vale inclusive para a casa de
funcionamento só virtual: pela legislação o vínculo municipal é necessário.
O município é o **vínculo jurídico**, não a garantia de presença física — por
isso `esp:modalidade` importa para quem calcula cobertura territorial.

Esta ontologia não guarda a lista de municípios do Brasil. O código IBGE é a
chave de cruzamento com o painel de demografia.

## Como inspecionar o modelo

```bash
make perguntas          # imprime o que o modelo responde
make verify             # falha se o modelo estiver errado
make contra-exemplos    # prova que as verificações pegam erro
make validate           # pipeline completo
```

## O que fica fora

- Hierarquia geográfica fina (distrito, localidade, setor censitário).
- Indicadores demográficos — vivem no painel.
- Dados cadastrais (CNPJ, data de fundação, capacidade).
- Instâncias reais de casas e pessoas — vivem nos apps consumidores.
  `examples/mg.ttl` é ficção de teste.
```

- [ ] **Step 3: Escrever o ADR**

`docs/decisoes/0002-revisao-do-modelo.md`:

```markdown
---
id: 0002
status: aceito
data: 2026-09-06
---

# ADR 0002: Revisão do modelo de domínio

## Contexto

O mantenedor do domínio leu o modelo v1 e apontou erros de terminologia e de
estrutura. Ver
`docs/superpowers/specs/2026-09-06-revisao-do-modelo-design.md` para a
entrevista completa.

O erro de fundo do v1 foi **excesso de restrição**: axiomas obrigatórios que
a realidade do movimento contradiz. O caso central era
`esp:Casa ⊑ ∃parteDe.Federativa`, falso em dois níveis — a casa não é parte
da federativa, e pode não ter vínculo nenhum.

## Decisões

1. **Casa e órgão são disjuntos.** `esp:Instituicao` no topo. Um hospital ou
   uma livraria espírita é casa; nenhum dos dois é órgão.
2. **A casa adere, não é parte.** `esp:adesaA` opcional substitui
   `esp:parteDe` no vínculo casa–federativa. `esp:parteDe` sobrevive só entre
   órgãos.
3. **Atividade e evento são irmãos disjuntos.** Atividade é periódica; evento
   é datado. Ambos realizados por casas e por órgãos.
4. **Regional e CRE saem do TBox.** Viram instâncias de macro e microrregião
   com o nome local em atributo, porque estados têm zero, um ou dois níveis
   regionais. Minas Gerais é exemplo, não modelo.
5. **Áreas e tipos de atividade são indivíduos de catálogo, não classes.**
   Acrescentar um tipo de atividade não toca o modelo lógico. Consequência
   técnica: um indivíduo não pode apontar para uma classe em OWL DL sem
   punning, o que quebraria o ELK.
6. **Atividade é apoiada por 0..N áreas.** Sem cardinalidade mínima, e nunca
   por composição.
7. **Terminologia:** órgão (não organização), assistido (não beneficiário),
   área federativa (não área de atuação). Sem sufixo "Espírita" em termo
   autoexplicativo — o namespace já diz.
8. **Escopo kardecista** declarado como anotação da ontologia.
9. **AG (Área de Gestão) fica fora.** Nas palavras do mantenedor, está
   referenciada em livro, mas ele nunca viu atuação de AG em Minas Gerais. É
   não-observação pessoal, não levantamento institucional; se aparecer
   atuação, a decisão se revisita. `analise-demografica` tem 11 lentes para
   as 10 áreas daqui — inconsistência daquele repositório.
10. **Divisão TBox / SHACL.** O TBox fica no perfil EL para o ELK raciocinar.
    O que o EL não expressa — enums, união no alvo de `esp:coordena`,
    obrigatoriedades de instância — vai para `shapes/modelo.shacl.ttl`.
11. **Versão permanece 1.0.0** e o IRI permanece `.../v1#`. A ontologia não
    foi publicada; não há compatibilidade a preservar. Termos do v1 são
    substituídos, não depreciados.
12. **Modalidade** (presencial, virtual, híbrida) exigida em realização,
    recomendada em casa. Obrigatória na casa invalidaria todo o cadastro
    federativo existente de uma vez.
13. **Contra-exemplos.** `robot verify` trata zero linhas como sucesso, então
    verificações de disjunção passariam vazias. `make contra-exemplos` roda
    as mesmas consultas contra violações plantadas e só passa quando as
    encontra.

## Consequências

- Todo consumidor do v1 quebra. Aceito: não havia consumidor.
- O modelo tem duas restrições existenciais no total, contra as quatro do v1.
- O vínculo entre federativa estadual e FEB **não** é asserido: a natureza
  dessa relação não foi definida na revisão, e asserir sem confirmação
  repetiria o erro do v1.
```

- [ ] **Step 4: Atualizar CHANGELOG e README**

Em `CHANGELOG.md`, substituir a seção `## [1.0.0] - 2026-09-06` inteira por:

```markdown
## [1.0.0] - 2026-09-06

Versão inicial, revisada no mesmo dia com o mantenedor do domínio antes de
qualquer publicação. Como nada foi publicado nem consumido, a revisão não
gerou bump de versão — ver `docs/decisoes/0002-revisao-do-modelo.md`.

### Adicionado
- TBox: instituições (casa e órgão disjuntos), adesão, realizações
  (atividade e evento disjuntos), pessoas e papéis, áreas federativas,
  geografia básica.
- Catálogo de referência: 10 áreas federativas, tipos de atividade com o mapa
  `apoiadaPor`, estrutura federativa de Minas Gerais, FEB e CFN.
- ABox de exemplo (`examples/mg.ttl`) e contra-exemplos
  (`examples/contra-exemplos.ttl`).
- Alvos `make perguntas` (inspeção) e `make contra-exemplos` (teste do teste).
- Pipeline de validação Docker (ROBOT + SHACL) rodando em CI.
- Documentação: glossário, modelo de domínio, guia de contribuição, ADRs 0001
  e 0002.
- IRI definitivo via w3id.org + GitHub Pages.
```

Em `README.md`, na seção `## Documentação`, acrescentar depois da linha dos ADRs:

```markdown
- `examples/` — ABox de teste: `mg.ttl` (válido) e `contra-exemplos.ttl`
  (violações plantadas).
- `queries/` — perguntas de inspeção, impressas por `make perguntas`.
```

E substituir a seção `## Validação` inteira por:

```markdown
## Validação e inspeção

```bash
make validate           # pipeline completo (reason + verify + shacl)
make perguntas          # imprime o que o modelo responde
make contra-exemplos    # prova que as verificações pegam erro
```

`make verify` **falha** quando o modelo está errado. `make perguntas`
**mostra** o que o modelo pensa — é a ferramenta para ler as respostas e
apontar o que está incorreto.
```

- [ ] **Step 5: Rodar o pipeline completo**

Run: `make validate && make contra-exemplos && make context-check`
Expected: os três PASS. `context-check` falha se `ontology/context.jsonld`
ficou desatualizado — se falhar, rodar `make context` e commitar o resultado.

- [ ] **Step 6: Commit**

```bash
git add docs/ CHANGELOG.md README.md
git commit -m "docs: atualiza glossario, modelo de dominio, ADR 0002 e README

Registra a revisao do modelo e o mecanismo de inspecao. A versao permanece
1.0.0: a ontologia nao chegou a ser publicada, entao a revisao corrige a
v1 em vez de sucede-la."
```

---

## Ordem e dependências

```
Task 1 (TBox)
  └─ Task 2 (catálogo)
       ├─ Task 3 (shapes)
       │    └─ Task 4 (examples/mg.ttl)
       │         ├─ Task 5 (contra-exemplos)
       │         └─ Task 6 (make perguntas)
       └─────────────────────────────────── Task 7 (docs)
```

Task 7 depende de tudo e deve ser a última: o glossário e o modelo de domínio
descrevem o que as tasks anteriores construíram.

## Como saber que terminou

```bash
make validate && make contra-exemplos && make perguntas && make context-check
```

- `validate` verde: TBox consistente, oito competency questions com zero
  linhas, SHACL limpo sobre catálogo e exemplos.
- `contra-exemplos` verde: as verificações de disjunção realmente detectam as
  violações plantadas.
- `perguntas`: seis blocos com respostas, incluindo as seis áreas que apoiam a
  palestra pública, a casa não adesa, e a 16ª CRE realizando uma atividade.
- `context-check` verde: `context.jsonld` em dia com o `core.ttl`.
