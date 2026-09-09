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
NaoAdesa ou EmRevisao — sem exigir vínculo.

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
make profile            # confirma que o TBox está no perfil OWL 2 EL
make validate           # pipeline completo (profile + reason + verify + shacl)
```

## O que fica fora

- Hierarquia geográfica fina (distrito, localidade, setor censitário).
- Indicadores demográficos — vivem no painel.
- Dados cadastrais (CNPJ, data de fundação, capacidade).
- Instâncias reais de casas e pessoas — vivem nos apps consumidores.
  `examples/mg.ttl` é ficção de teste.
