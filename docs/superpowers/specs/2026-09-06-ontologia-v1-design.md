# Ontologia do Movimento Espírita — Design v1.0

Status: aprovado para virar plano de implementação
Data: 2026-09-06

## Contexto

Este repositório guarda a ontologia de referência do movimento espírita
brasileiro, usada como base conceitual por projetos consumidores (app do
voluntário, app da casa, painel de demografia cruzando IBGE/Atlas/IPEA/cadastro
federativo). Havia material exploratório desorganizado em `desorganizados/`:
um esboço real em OWL (WebProtege) com parte da estrutura federativa
(`AME`, `Área`, `Regional`, `Federativa`, `Casa`, `CRE`, indivíduo `UEM`), e
conversas de pesquisa sobre o que é ontologia, taxonomia, DIKW, Bloom e como
validar consistência semântica.

Objetivo desta rodada: chegar a uma documentação estável 1.0, cobrindo a
maior parte dos casos de uso citados, com um plano concreto de defesa contra
edições que quebrem a consistência da ontologia.

## Fora de escopo

- Documentação de produto dos apps consumidores (personas, roadmap,
  compliance/LGPD do app do voluntário etc.) — vive nos repositórios desses
  produtos. O arquivo `app-voluntario-doc-map.md` referenciava esse escopo e
  foi identificado como pertencente a outro repositório, não a este.
- Crosswalk completo de municípios/IBGE (tabela de 5.570 municípios) — este
  repositório expõe apenas o "gancho" (propriedade que aponta para um código
  externo), não os dados geográficos em si.
- ABox completo (instâncias individuais de Casas, voluntários) — fica nos
  bancos de dados dos apps consumidores.

## Decisões

### 1. Escopo de conteúdo v1.0

Três dimensões entram no v1.0:

- **Estrutura federativa**: Federação, Regional, CRE, UEM, AME, Casa/Centro,
  Área de atuação (com suas subclasses: Infância e Juventude, Estudo do
  Evangelho, Promoção Social, Orientação Mediúnica, Esperanto, Arte,
  Comunicação Social, Família, Atendimento Espiritual, Estudo do
  Espiritismo).
- **Pessoas e papéis**: voluntário, dirigente, frequentador, beneficiário, e
  as relações de participação/atuação entre pessoa e centro/área.
- **Atividades e ações sociais/doutrinárias**: evento, atividade, ação
  social, estudo doutrinário, e a quem se destinam.
- **Geografia básica** (adicionado durante a entrevista, por ser
  pré-requisito direto do painel de demografia): hierarquia mínima
  Casa → Município/UF, com uma propriedade de dados apontando para o código
  IBGE do município como identificador externo simples. Sem hierarquia
  geográfica fina (setor censitário) nem tabela de municípios — isso é dado,
  não ontologia, e fica a cargo do painel de demografia.

### 2. TBox + catálogo de referência (não ABox completo)

O repositório guarda o modelo (TBox: classes, propriedades, axiomas) mais um
catálogo de referência limitado (ABox): as entidades federativas reais que
são estáveis e servem de "tabela mestra" para os apps (federações estaduais,
regionais, uniões como UEM). Casas e voluntários individuais **não** entram
aqui — vivem nos apps.

Isso mantém o reasoning (`robot reason`) focado no TBox, e valida o catálogo
de referência via SHACL.

### 3. IRI definitivo

Base: `https://w3id.org/ontologia-espirita/v1#`, redirecionando para
`https://acse.github.io/ontologia-espirita/v1/` (GitHub Pages deste
repositório).

- Registro do namespace feito via PR no repositório `w3c/perma-id`
  (w3id.org) — é uma tarefa bloqueante do plano de implementação, antes de
  qualquer publicação "final" de v1.0.
- IRIs legíveis, não opacas: `#CentroEspirita`, `#Regional`,
  `#AreaDeAtuacao`, em vez dos IDs opacos do WebProtege
  (`R7nG6dzUvA32DJnIpdsL676`). Essencial para o fluxo de revisão via Pull
  Request por pessoas não necessariamente familiarizadas com OWL.
- Na migração do `.owl`/`.owx` original para `core.ttl`, corrigir os
  problemas identificados no rascunho: `Casa`, `Federativa` e `Regional`
  estavam sem `subClassOf`; "Área de Comunicação Social Espírita" não
  herdava de `Área`; typos (`Espíritismo` → `Espiritismo`, `Atendimento
  Espíritual` → `Espiritual`).

### 4. Formato canônico e ferramenta de edição

- **Fonte da verdade**: OWL/Turtle (`ontology/core.ttl`), com axiomas e
  restrições completos, validável por reasoner.
- **Edição**: Protégé Desktop (ou edição direta de texto) + Git. Mudanças
  entram via Pull Request com diff legível, não diretamente no WebProtege.
- JSON-LD (`ontology/context.jsonld`) é **gerado** a partir do TTL para
  consumo direto pelos apps — não é editado manualmente.

### 5. Estrutura do repositório

```text
ontologia-espirita/
├── README.md
├── CHANGELOG.md
├── ontology/
│   ├── core.ttl                 # TBox: classes, propriedades, axiomas (fonte da verdade)
│   ├── reference-catalog.ttl     # ABox limitado: federações/regionais/UEM etc. reais e estáveis
│   └── context.jsonld            # @context gerado, para consumo pelos apps
├── competency-questions/
│   ├── README.md                  # o que é, como cada pergunta vira um teste
│   └── *.rq                       # SPARQL ASK/SELECT, uma pergunta por arquivo
├── shapes/
│   └── *.shacl.ttl                # regras estruturais (ex: toda Casa tem localizadaEm)
├── docs/
│   ├── glossario.md               # termos pt-BR, 1 por classe/propriedade
│   ├── modelo-de-dominio.md       # visão narrativa do grafo (federativa, pessoas, atividades, geografia)
│   ├── decisoes/                  # ADRs
│   └── guia-de-contribuicao.md    # como propor mudança, o que é "crítico"
├── docker/
│   └── Dockerfile                 # imagem baseada em obolibrary/robot
└── .github/workflows/ci.yml       # roda o pipeline de validação a cada PR
```

`desorganizados/` é eliminado: o `.owl`/`.owx` vira a base migrada e
corrigida de `core.ttl`; os `.md` exploratórios viram a base de
`docs/modelo-de-dominio.md` e um ADR registrando as decisões desta rodada de
design; `app-voluntario-doc-map.md` é removido deste repositório (pertence
ao repositório do app do voluntário).

### 6. Pipeline de validação (defesa contra edições incorretas)

Um único container Docker com a ferramenta **ROBOT** (OBO Tool) roda quatro
passos a cada Pull Request via GitHub Actions:

1. **`robot reason`** — reasoner (ELK/HermiT) sobre `core.ttl`. Falha se
   alguma classe virar `owl:Nothing` (inconsistência lógica) ou houver ciclo.
2. **`robot report`** — lint de qualidade: toda classe/propriedade precisa
   de `rdfs:label` em pt-BR; sem classes órfãs sem `subClassOf`; sem
   duplicatas.
3. **`robot verify`** — roda as *competency questions* de
   `competency-questions/*.rq` (SPARQL ASK) contra `core.ttl` +
   `reference-catalog.ttl`. Cada pergunta que a ontologia "deveria
   conseguir responder" é um teste de regressão versionado. Isso serve dois
   objetivos ao mesmo tempo: definir "cobre a maior parte dos casos" de
   forma testável (perguntas registradas = casos cobertos) e detectar
   edição incorreta (pergunta que passava e passa a falhar = regressão).
4. **SHACL** (`shapes/*.shacl.ttl`) valida a forma do catálogo de
   referência (ABox): toda instância de `Federativa`/`Casa` no catálogo tem
   os campos obrigatórios.

**Apoio humano em caso crítico**: PRs que tocam elementos definidos como
críticos em `docs/guia-de-contribuicao.md` (raiz da hierarquia federativa,
classes consumidas por mais de um app) exigem, além do CI verde, que o
mantenedor marque explicitamente um checklist de revisão manual no template
de PR antes de mergear. Não é um segundo aprovador humano (fase atual do
projeto tem um único mantenedor) — é uma trava deliberada contra merge
apressado.

### 7. Versionamento

SemVer aplicado à ontologia (`v1.0.0`), com `v1` já embutido no path da IRI
(`.../ontologia-espirita/v1#...`), permitindo conviver com uma futura `v2`
sem quebrar consumidores da v1.

- **patch**: correção de rótulo/typo, sem mudar estrutura.
- **minor**: nova classe/propriedade que não quebra nada existente (ex:
  adicionar dimensão geográfica fina em versão futura).
- **major**: renomear/remover/mudar hierarquia de algo que apps já
  consomem.

`CHANGELOG.md` + tag git a cada release.

## Definição de "pronto" para v1.0

- `core.ttl` cobre as três dimensões de conteúdo + geografia básica (seção 1).
- IRI registrado em w3id.org e resolvendo para o GitHub Pages do repositório.
- Pipeline de CI (ROBOT + SHACL) rodando e verde na branch principal.
- Ao menos um conjunto inicial de competency questions cobrindo os casos de
  uso conhecidos dos três apps consumidores (voluntário, casa, demografia),
  aprovado como a régua de "cobre a maior parte dos casos".
- `docs/glossario.md`, `docs/modelo-de-dominio.md` e
  `docs/guia-de-contribuicao.md` escritos.
- `desorganizados/` removido do repositório.
