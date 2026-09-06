# Revisão do modelo de domínio — design

Data: 2026-09-06
Status: aprovado e revisado (entrevista e revisão com o mantenedor do domínio em 2026-09-06)
Substitui: partes de `docs/superpowers/specs/2026-09-06-ontologia-v1-design.md`

## 1. Motivação

A leitura do modelo v1 pelo mantenedor do domínio revelou erros de
terminologia e, mais grave, erros de estrutura. O v1 errou por **excesso de
restrição**: afirmou como axioma obrigatório coisas que a realidade do
movimento contradiz.

O caso central é `esp:Casa ⊑ ∃parteDe.Federativa` — o modelo declarava que
toda casa espírita é parte de uma estrutura federativa. É falso em dois
níveis: a casa **não é parte** da federativa (ela é autônoma) e **pode não
ter vínculo nenhum** (a adesão é decisão dela).

O v2 tem deliberadamente **menos** restrições existenciais que o v1, não
mais.

## 2. Escopo

Esta ontologia cobre o **movimento espírita kardecista** organizado no
Brasil — casas espíritas de orientação kardecista e a estrutura federativa
que as apoia.

Umbanda, candomblé e outras vertentes não são modeladas. Isso vira anotação
explícita na ontologia para que nenhum consumidor carregue dados do tipo
errado achando que cabem.

## 3. Decisões

Cada linha veio de uma resposta direta do mantenedor na entrevista.

| # | Decisão | Consequência |
|---|---|---|
| D1 | Casa **não é** órgão | `Casa` e `Orgao` são ramos irmãos e disjuntos sob `Instituicao` |
| D2 | Hospital, lar e livraria **são** casas | viram subclasses de `Casa`, ao lado de `Centro` |
| D3 | Atividade e Evento são **coisas distintas** | irmãos sob `Realizacao`, disjuntos — `Evento` deixa de ser subclasse de `Atividade` |
| D4 | Atividade é o que a casa faz **periodicamente** | ganha `periodicidade`; Evento ganha data de início/fim e edição |
| D5 | COFEMG é **órgão interno** da UEM | `OrgaoUnificador orgaoInternoDe Federativa`; mesmo padrão para CFN/FEB |
| D6 | A casa **adere** à federativa estadual | `adesaA` substitui `parteDe`; `parteDe` sobra só entre órgãos |
| D7 | A adesão é **opcional** | nenhuma restrição existencial sobre `adesaA` |
| D8 | Voluntário atua em casa **ou** órgão | um único papel `Voluntario`, com `atuaEm → Instituicao` |
| D9 | Coordenador coordena atividade **ou** área | `Coordenador ⊑ Voluntario`, um só papel, dois alvos possíveis |
| D10 | Área é estrutura de órgão; da casa é **opcional** | `mantemArea` com domínio `Instituicao`, sem obrigação |
| D11 | Atividade é **apoiada por** 0..N áreas | `apoiadaPor` sem cardinalidade mínima; nunca `parteDe` |
| D12 | Tipos de atividade vivem em **catálogo** | acrescentar um tipo não toca o modelo lógico |
| D13 | Frequentador e Assistido sob **PublicoAlvo** | `Beneficiario` é renomeado para `Assistido` |
| D14 | **10** áreas federativas — AG fica de fora | ver §9 |
| D15 | Nível nacional **entra** | `FederativaNacional` (FEB) e seu unificador (CFN) |
| D16 | Sem sufixo "Espírita" em termo autoexplicativo | `esp:Casa`, não `esp:CasaEspirita` — o namespace já diz |
| D17 | Existe casa **só virtual**, mas o vínculo municipal é legal e obrigatório | mantém `Casa ⊑ ∃localizadaEm.Municipio`; entra `modalidade` como atributo |
| D18 | Órgãos **também** têm atividades, não só eventos | `realiza` sem restrição de combinação; a distinção é periódica × datada, não quem realiza |
| D19 | Atividade e evento **informam modalidade** | `modalidade` exigida em `Realizacao`; recomendada em `Casa` |

### Decisão de abordagem

Escolhida a alternativa **A — TBox enxuto + catálogo + SHACL**, entre três
avaliadas:

- **A** — o modelo lógico carrega só o que é universal ao movimento. Nomes
  locais, tipos de atividade e o mapa área × atividade vivem no catálogo de
  referência. Regras de qualidade viram SHACL, não axioma OWL.
- **B** — TBox expressivo, cada tipo e regra como axioma OWL. Rejeitada:
  reintroduz o erro do v1, e faria de Minas Gerais o modelo em vez de um
  exemplo.
- **C** — renomear apenas. Rejeitada: não resolve evento × atividade,
  adesão, órgão unificador nem macro/micro região.

### Versionamento

`owl:versionInfo` permanece **1.0.0** e o IRI permanece
`https://w3id.org/ontologia-espirita/v1#`. A ontologia ainda não foi
publicada nem consumida — não há de quem preservar compatibilidade. Os
termos do v1 são substituídos, não depreciados.

## 4. Modelo — instituições

```
Instituicao                            (topo; substitui Organizacao)
├── Casa                               disjunta de Orgao
│   ├── Centro                         o caso comum
│   ├── Hospital
│   ├── Lar                            abrigo, asilo
│   └── Livraria                       inclui editora
└── Orgao
    ├── Federativa
    │   ├── FederativaNacional         FEB
    │   └── FederativaEstadual         UEM
    ├── OrgaoUnificador                COFEMG, CFN
    ├── OrgaoRegional
    │   ├── MacroRegiao                "Regional", em MG
    │   └── MicroRegiao                "CRE", em MG
    └── OrgaoMunicipal                 AME, CEM
```

`Casa` e `Orgao` são declarados disjuntos: nenhuma instituição é as duas
coisas. É a formalização direta de D1.

### Regional e CRE saem do TBox

`esp:Regional` e `esp:CRE` deixam de ser classes. Passam a ser **instâncias**
de `MacroRegiao` e `MicroRegiao` no catálogo, com o nome local guardado em
`nomeLocal`.

Motivo: `analise-demografica/docs/specs/regions.md` estabelece que uma
federativa estadual tem 0, 1 ou 2 subníveis (categorias A, B e C). Um estado
categoria A não tem CRE nenhuma; um categoria B tem um só nível. Com `CRE` e
`Regional` no TBox, e com `CRE ⊑ ∃parteDe.Regional` como o v1 declara, esses
estados são impossíveis de representar. Minas Gerais é um exemplo do modelo,
não o modelo.

Outros estados usam URE, Polo, Setor. Todos cabem como `nomeLocal`.

## 5. Modelo — adesão

```
Casa Luz do Caminho
  adesaA        → UEM                        vínculo formal, opcional
  statusAdesao  = "Adesa"                    Adesa | Pendente | Previsto | Conhecido
  atendidaPor   → AME Uberaba, 16ª CRE, Regional Triângulo
  localizadaEm  → Uberaba                    IBGE 3170206
```

- `adesaA` — o vínculo formal, sempre com uma `Federativa`. **Sem restrição
  existencial**: uma casa sem adesão é um dado válido e comum.
- `atendidaPor` — o caminho administrativo por onde a casa é apoiada. Vários,
  ou nenhum.
- `parteDe` — sobrevive apenas entre órgãos (COFEMG `parteDe` UEM; uma
  microrregião `parteDe` uma macrorregião). Transitiva. **Nunca** parte de
  uma casa.
- `orgaoInternoDe` — subpropriedade de `parteDe`, do unificador para sua
  federativa. Nomeia o caso COFEMG/UEM e CFN/FEB sem confundi-lo com
  hierarquia regional.
- `abrange` — de um `OrgaoRegional` ou `OrgaoMunicipal` para os municípios
  que ele cobre. É o que torna representável a AME intermunicipal.

Duas restrições existenciais do v1 **permanecem**, porque são verdadeiras
sem exceção: toda `Casa` está localizada em um `Municipio`, e todo
`Municipio` pertence a uma `UnidadeFederativa`. São as únicas do modelo.

### Casa virtual

Existem casas de funcionamento **somente virtual**. Elas não enfraquecem a
restrição acima — pela legislação, uma casa precisa de vínculo municipal de
qualquer forma. O `Municipio` de uma casa é o **vínculo jurídico**, não a
garantia de que há gente se reunindo naquele endereço.

A distinção entra como atributo, não como subclasse: `modalidade`, com
valores `presencial`, `virtual` ou `hibrida`, validado por SHACL. Casa
virtual é um modo de operar, não outro tipo de casa — uma casa presencial
que migra para híbrida não muda de classe.

Consequência para quem consome: o painel de demografia conta casas por
município para estimar cobertura territorial. Uma casa virtual atribuída a um
município **não representa presença física ali** e infla o indicador. Com
`modalidade` no modelo, o painel consegue separar as duas leituras; sem ela,
não conseguiria nem saber que o problema existe.

`modalidade` não é só da casa: **toda `Realizacao` também informa a sua** —
atividade e evento igualmente. Uma palestra pública transmitida ao vivo e uma
presencial são coisas diferentes para quem planeja alcance, e o modelo
precisa distingui-las.

Em SHACL isso vira exigência (`minCount 1`) sobre `Atividade` e `Evento`.
Sobre `Casa` a mesma modalidade fica **recomendada, não exigida**: o cadastro
federativo existente não tem esse campo, e torná-lo obrigatório invalidaria
todas as casas já cadastradas de uma vez. Vira aviso, não erro, até o
cadastro alcançar o modelo.

Como a propriedade se aplica a `Casa` e a `Realizacao`, que não têm supertipo
comum, ela é declarada **sem `rdfs:domain`** — dois domínios em OWL
significariam interseção, não união. O alvo fica em SHACL, mesmo padrão de
`coordena` (§8).

## 6. Modelo — realizações

```
Realizacao
├── Atividade      periódica, da casa      periodicidade, doTipo, coordenador
└── Evento         datado, pontual         dataInicio, dataFim, edicao
```

Declarados **disjuntos**. É o único axioma forte novo do v2, e vem direto de
D3/D4: a Semana Espírita não é uma atividade, a palestra de quinta não é um
evento.

### Quem realiza o quê

`realiza` tem domínio `Instituicao` e imagem `Realizacao`, e os dois lados se
combinam livremente: **órgãos também têm atividades**, não só eventos. Uma
CRE com reunião mensal de dirigentes realiza uma atividade tanto quanto uma
casa com sua palestra de quinta.

Isso corrige uma restrição que chegou a ser proposta neste design ("só casa
realiza atividade") e foi derrubada na revisão. O que separa `Atividade` de
`Evento` é a **natureza da realização** — periódica contra datada — e não
quem a realiza. A frase de origem ("atividade é algo que a Casa realiza
periodicamente") define o termo pelo caso mais comum; não restringe o
sujeito.

Nenhuma regra SHACL limita a combinação.

As subclasses `AcaoSocial` e `EstudoDoutrinario` do v1 desaparecem do TBox —
são tipos de atividade, e passam ao catálogo.

### Catálogo de tipos de atividade

`TipoDeAtividade` é uma classe cujas **instâncias** vivem no catálogo de
referência. É lá que fica registrado quais áreas apoiam cada tipo:

```turtle
esp:PalestraPublica a esp:TipoDeAtividade ;
    rdfs:label "Palestra pública"@pt-BR ;
    esp:apoiadaPor esp:AEE, esp:AEEJ, esp:AAE, esp:APSE, esp:AESP, esp:ACSE .

esp:ReuniaoMediunica a esp:TipoDeAtividade ;
    rdfs:label "Reunião mediúnica"@pt-BR ;
    esp:apoiadaPor esp:AOM, esp:AEE, esp:AEEJ, esp:AAE .
```

Uma atividade concreta de uma casa aponta para seu tipo com `doTipo`.
Acrescentar "Grupo de Estudo d'O Livro dos Espíritos" custa quatro linhas no
catálogo e nenhuma mudança no `core.ttl`.

`apoiadaPor` **não tem cardinalidade mínima**. Uma área técnica ou
especializada pode apoiar zero atividades, e um tipo de atividade pode não
ter área nenhuma que o apoie. A relação nunca é de composição: uma atividade
não é parte de uma área.

## 7. Modelo — áreas federativas

`AreaDeAtuacao` é renomeada para **`AreaFederativa`** ("federativa" não é
sufixo redundante aqui: separa da área geográfica).

As dez áreas deixam de ser subclasses e passam a ser **instâncias** de
`AreaFederativa` no catálogo:

| Sigla | Área |
|---|---|
| AAE | Atendimento Espiritual |
| AA | Arte |
| ACSE | Comunicação Social Espírita |
| AEE | Estudo do Espiritismo |
| AEEJ | Estudo do Evangelho de Jesus |
| AESP | Esperanto |
| AFam | Família |
| AIJ | Infância e Juventude |
| AOM | Orientação Mediúnica |
| APSE | Promoção Social Espírita |

Motivo desta mudança, que não foi pedida diretamente: se os tipos de
atividade são instâncias (D12) e apontam para áreas via `apoiadaPor`, então
as áreas precisam ser instâncias também. Uma instância não pode apontar para
uma classe em OWL DL sem recorrer a *punning*, o que quebraria o raciocinador
ELK usado pelo CI. Além disso as dez áreas nunca teriam instâncias próprias —
são um vocabulário controlado, não tipos de coisa.

`mantemArea` liga uma `Instituicao` a uma área. Órgãos estruturam áreas com
frequência; casas raramente, e o modelo permite sem exigir (D10).

## 8. Modelo — pessoas

```
Pessoa
├── Voluntario            atuaEm → Instituicao (casa ou órgão)
│   │                     atuaNaArea → 0..N AreaFederativa
│   └── Coordenador       coordena → Atividade ou AreaFederativa
├── Dirigente             dirige → Instituicao
└── PublicoAlvo
    ├── Frequentador      participa de atividades regulares
    └── Assistido         recebe amparo social ou espiritual
```

`Beneficiario` → `Assistido`.

`coordena` fica **sem `rdfs:range` declarado**, com a restrição expressa em
SHACL (`sh:or` entre `Atividade` e `AreaFederativa`). Um range de união em
OWL sairia do perfil EL e quebraria o `robot reason --reasoner ELK` do CI.
Essa é a divisão de trabalho da abordagem A: o TBox fica no perfil EL, e o
que ele não expressa vai para SHACL.

Uma mesma pessoa acumular papéis continua sendo responsabilidade do app
consumidor, como no v1.

## 9. Propriedades — resumo

Object properties:

| Propriedade | Domínio | Imagem | Nota |
|---|---|---|---|
| `parteDe` | `Orgao` | `Orgao` | transitiva; nunca envolve `Casa` |
| `orgaoInternoDe` | `OrgaoUnificador` | `Federativa` | subpropriedade de `parteDe` |
| `adesaA` | `Casa` | `Federativa` | opcional |
| `atendidaPor` | `Casa` | `Orgao` | 0..N |
| `abrange` | `Orgao` | `Municipio` | 0..N |
| `mantemArea` | `Instituicao` | `AreaFederativa` | comum em órgão, raro em casa |
| `realiza` | `Instituicao` | `Realizacao` | atividade ou evento |
| `doTipo` | `Atividade` | `TipoDeAtividade` | |
| `apoiadaPor` | `TipoDeAtividade` | `AreaFederativa` | **sem cardinalidade mínima** |
| `temPublicoAlvo` | `Realizacao` | `PublicoAlvo` | |
| `atuaEm` | `Voluntario` | `Instituicao` | |
| `atuaNaArea` | `Voluntario` | `AreaFederativa` | 0..N |
| `coordena` | `Coordenador` | — | imagem só em SHACL (ver §8) |
| `dirige` | `Dirigente` | `Instituicao` | |
| `frequenta` | `Frequentador` | `Casa` | |
| `localizadaEm` | `Instituicao` | `Municipio` | obrigatória para `Casa` |
| `pertenceA` | `Municipio` | `UnidadeFederativa` | obrigatória |

Data properties:

| Propriedade | Domínio | Tipo | Nota |
|---|---|---|---|
| `sigla` | `Instituicao`, `AreaFederativa` | `xsd:string` | UEM, COFEMG, ACSE |
| `nomeLocal` | `Orgao` | `xsd:string` | "CRE", "Regional", "URE", "Polo" |
| `statusAdesao` | `Casa` | `xsd:string` | enum via SHACL |
| `modalidade` | — | `xsd:string` | `presencial` \| `virtual` \| `hibrida`; alvo (`Casa`, `Realizacao`) e enum só em SHACL |
| `codigoIBGE` | `Municipio` | `xsd:string` | |
| `periodicidade` | `Atividade` | `xsd:string` | |
| `dataInicio` | `Evento` | `xsd:date` | |
| `dataFim` | `Evento` | `xsd:date` | |
| `edicao` | `Evento` | `xsd:string` | "XII Semana Espírita" |

Propriedades do v1 que **saem**: `atuaEm` com domínio `Casa` e imagem
`AreaDeAtuacao` (substituída por `mantemArea`), e `atua` com domínio
`Voluntario` (renomeada para `atuaNaArea`).

## 10. Área de Gestão (AG) — fora

`analise-demografica/docs/taxonomia.md` lista 11 áreas, incluindo AG —
Gestão, e há uma lente escrita em `specs/lentes/ag.md`.

Decisão do mantenedor: **AG fica fora**. Nas palavras dele, a área está
referenciada em livro, mas ele nunca viu atuação de AG em Minas Gerais — por
isso a deixa de lado. É não-observação pessoal, não um levantamento
institucional; se aparecer atuação, a decisão se revisita.

Isso deixa uma inconsistência **naquele** repositório (11 lentes para 10
áreas), não neste. Fica registrada aqui como pendência de lá.

## 11. Mecanismo de teste do conhecimento

Pedido explícito do mantenedor: uma forma de testar se o modelo está certo.
Três camadas, sobre o `make` e o Docker que já existem.

### `examples/mg.ttl` — o movimento mineiro como dado

Um ABox de exemplo com as entidades reais citadas na entrevista: FEB, CFN,
UEM, COFEMG, Regional Triângulo, 16ª CRE, AME Uberaba, Casa Luz do Caminho,
uma casa conhecida mas não adesa, palestra pública, reunião mediúnica,
evangelização infantil, uma Semana Espírita como `Evento`, e as pessoas
(Maria voluntária de casa, João voluntário de órgão na ACSE, Ana coordenadora
de atividade, Paulo coordenador de área, Rosa assistida, Antônio
frequentador).

Não é dado de produção. É o caso de teste que exercita todas as decisões
acima de uma vez.

### `make verify` — testes que quebram o CI

Perguntas de competência escritas como consulta de **violação**: zero linhas
significa passou. Convenção já estabelecida em `competency-questions/README.md`.

Conjunto a escrever:

| Arquivo | Verifica |
|---|---|
| `cq-00-labels-pt-br.rq` | todo termo tem rótulo pt-BR *(mantido do v1)* |
| `cq-01-casa-nao-e-orgao.rq` | nenhuma instituição é casa e órgão ao mesmo tempo |
| `cq-02-areas-no-catalogo.rq` | toda `AreaFederativa` tem sigla e rótulo |
| `cq-03-papeis-sob-pessoa.rq` | todo papel humano é subclasse de `Pessoa` |
| `cq-04-atividade-nao-e-evento.rq` | nada é `Atividade` e `Evento` ao mesmo tempo |
| `cq-05-casa-tem-localizacao.rq` | toda casa do exemplo tem município *(mantido do v1)* |
| `cq-06-sem-classes-orfas.rq` | nenhuma classe sem supertipo *(mantido do v1)* |
| `cq-07-apoio-so-para-area.rq` | `apoiadaPor` só aponta para `AreaFederativa` |
| `cq-08-sem-ciclo-em-parte-de.rq` | nenhum órgão é parte de si mesmo |

`cq-01-casa-parte-de-federativa.rq` do v1 é **deletada**: ela testa
exatamente o axioma derrubado por D6/D7 e, se ficasse, o CI reimporia o erro.

#### Armadilha: teste que passa sem provar nada

`cq-01` e `cq-04` verificam disjunções. Rodadas só contra `examples/mg.ttl`,
que é um exemplo **válido**, elas nunca encontram violação — passariam
vazias, parecendo cobertura quando não são.

Por isso entra um segundo arquivo, `examples/contra-exemplos.ttl`: instâncias
deliberadamente erradas (uma "casa" que também é declarada órgão, uma
realização declarada como atividade e evento ao mesmo tempo). O alvo
`make contra-exemplos` roda as mesmas consultas contra ele e **só passa se
cada uma retornar linhas**. É o teste do teste.

### `make perguntas` — o modelo respondendo em voz alta

Alvo novo. Roda consultas `SELECT` de `queries/` contra `core.ttl` +
catálogo + `examples/mg.ttl` e **imprime a resposta em tabela**. É a
ferramenta de inspeção que o mantenedor pediu: ele lê a saída e diz se a
resposta está errada.

```
$ make perguntas

── Quais áreas apoiam a palestra pública da Casa Luz do Caminho? ──
  AEE   Estudo do Espiritismo
  AEEJ  Estudo do Evangelho de Jesus
  AAE   Atendimento Espiritual
  APSE  Promoção Social Espírita
  AESP  Esperanto
  ACSE  Comunicação Social Espírita

── Quem coordena o quê, e onde? ──
  Ana    Evangelização Infantil    Casa Luz do Caminho
  Paulo  AIJ                       16ª CRE

── Casas conhecidas que NÃO são adesas ──
  Casa Fraternidade (Uberaba)   status: Conhecido
```

A saída acima é **ilustrativa**, não especificação de formato: `robot query`
escreve em arquivo, e a formatação em tabela fica a cargo do script que
envolve a chamada. O que importa é a resposta estar visível e legível, não o
alinhamento exato das colunas.

Distinção importante: `make verify` **falha** quando o modelo está errado;
`make perguntas` **mostra** o que o modelo pensa. As duas coisas são
necessárias — `robot verify` trata zero linhas como sucesso, então uma
consulta que só pergunta passaria trivialmente sem provar nada.

### Complemento opcional

Documentação HTML navegável gerada por Widoco, para consulta visual sem
código. Fora deste design; entra se for pedido.

## 12. Impacto por arquivo

| Arquivo | Ação |
|---|---|
| `ontology/core.ttl` | reescrito |
| `ontology/reference-catalog.ttl` | UEM ganha tipo definido; entram FEB, CFN, COFEMG, Regional Triângulo, 16ª CRE, AME Uberaba, as 10 áreas e os tipos de atividade |
| `ontology/context.jsonld` | regerado por `make context` — nunca editado à mão |
| `shapes/reference-catalog.shacl.ttl` | atualizado: enums de `statusAdesao` e `modalidade`, `modalidade` exigida em `Realizacao` e recomendada em `Casa`, alvo de `coordena`, `nomeLocal` obrigatório em órgão regional |
| `competency-questions/` | 1 deletada, 3 reescritas, 4 novas |
| `examples/mg.ttl` | novo |
| `examples/contra-exemplos.ttl` | novo — fixture inválida, para o `make contra-exemplos` |
| `queries/` | novo |
| `Makefile`, `docker/validate.sh` | alvos `perguntas` e `contra-exemplos`; `examples/mg.ttl` entra no merge do `verify` |
| `docs/glossario.md` | reescrito |
| `docs/modelo-de-dominio.md` | reescrito |
| `docs/decisoes/0002-revisao-do-modelo.md` | novo ADR |
| `CHANGELOG.md` | entrada da revisão |

## 13. Fora de escopo

- Hierarquia geográfica fina (distrito, localidade, setor censitário) — vive
  no painel de demografia.
- Indicadores demográficos (IDHM, IVS, população) — idem.
- As classes de fenômeno social do `taxonomia.md` (Ghosting, Melindre,
  Resistência Federativa) — são categorias analíticas, não estrutura do
  domínio.
- Dados cadastrais (CNPJ, data de fundação, capacidade) — entram quando um
  app consumidor precisar.
- Instâncias reais de casas e pessoas — vivem nos apps; `examples/mg.ttl` é
  ficção de teste.
