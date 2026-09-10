# Ontologia do Movimento Espírita Brasileiro

Vocabulário comum e modelo conceitual do movimento espírita federativo brasileiro,
em OWL/Turtle. **É a fonte normativa de vocabulário para todo o ecossistema**: quando
dois sistemas precisam concordar sobre o que é uma casa, uma adesão, uma atividade ou
uma área, é aqui que a resposta está escrita.

Sem um vocabulário único, cada sistema inventa o seu, e a conversa entre eles vira
tradução permanente. Um painel conta "casas ativas", outro conta "casas adesas", e
ninguém sabe se os números discordam ou se falam de coisas diferentes. Esta ontologia
existe para que essa pergunta tenha uma resposta verificável.

> **Modelar não é normatizar a vida das casas.**
> Este modelo descreve como o movimento **é**, não como alguém acha que deveria ser.
> Por isso a adesão de uma casa é opcional no modelo: a casa espírita é autônoma, e um
> modelo que exigisse vínculo estaria simplesmente errado sobre a realidade.

## Quem mantém

Mantido pela **Área de Comunicação Social Espírita (ACSE) da União Espírita Mineira
(UEM)**, federativa estadual de Minas Gerais.

> **Estágio institucional.** Esta é uma iniciativa de trabalho da ACSE. Os projetos
> **ainda não receberam endosso institucional formal** da UEM nem do COFEMG. Nada
> aqui deve ser lido como posição oficial da União Espírita Mineira, do COFEMG ou da
> Federação Espírita Brasileira. O termo de endosso, a definição formal dos papéis de
> proteção de dados e a nomeação do Encarregado estão pendentes.

Este repositório **não contém dados pessoais**: apenas o modelo conceitual e um
catálogo de entidades federativas públicas.

## O que este repositório contém

| Caminho | Conteúdo |
| :--- | :--- |
| `ontology/core.ttl` | O modelo: classes, propriedades e axiomas |
| `ontology/reference-catalog.ttl` | Catálogo de referência: áreas, tipos de atividade, estrutura federativa de MG, FEB e CFN |
| `ontology/context.jsonld` | Contexto JSON-LD para consumo pelos aplicativos — **gerado, nunca editado à mão** |
| `shapes/` | Restrições SHACL: o que o perfil lógico não expressa |
| `competency-questions/` | Perguntas que o modelo precisa saber responder |
| `examples/` | Exemplo válido (`mg.ttl`) e violações plantadas (`contra-exemplos.ttl`) |
| `queries/` | Consultas de inspeção, para ler o que o modelo responde |
| `docs/` | Glossário, modelo de domínio narrativo, guia de contribuição e decisões |

**Identificador:** `https://w3id.org/ontologia-espirita/v1#`

## O modelo em cinco frases

1. **Casa e órgão são coisas diferentes e disjuntas.** Um centro, um hospital, um lar
   ou uma livraria espírita são casas. Uma federativa, um conselho regional ou uma
   aliança municipal são órgãos. Um hospital espírita nunca é um órgão.
2. **A casa adere; ela não é parte.** A adesão é opcional e reversível, porque a casa
   é autônoma. Uma casa sem adesão é dado válido e comum, não é lacuna.
3. **Atividade e evento são irmãos, não pai e filho.** Atividade é periódica, a
   palestra de toda quinta. Evento é datado, a Semana Espírita de outubro.
4. **Atividade não pertence a uma área.** Ela pode ser **apoiada por** várias áreas,
   ou por nenhuma. Uma palestra pública é apoiada por estudo, comunicação e
   atendimento espiritual ao mesmo tempo.
5. **Minas Gerais é exemplo, não modelo.** Os níveis regionais são macrorregião e
   microrregião; "Regional", "CRE", "URE" e "Polo" são nomes locais, atributos da
   instância. Um estado pode ter dois níveis, um ou nenhum.

Narrativa completa em [`docs/modelo-de-dominio.md`](docs/modelo-de-dominio.md);
termo a termo em [`docs/glossario.md`](docs/glossario.md).

## Escopo

Cobre o **movimento espírita kardecista** organizado no Brasil. Umbanda, candomblé e
outras vertentes não fazem parte do domínio modelado. Isso é delimitação técnica de
escopo, e **nunca** juízo sobre outras religiões ou práticas.

Fora do escopo, por decisão: hierarquia geográfica fina, indicadores demográficos
(vivem nos painéis), dados cadastrais como CNPJ e data de fundação, e instâncias
reais de casas e de pessoas (vivem nos aplicativos). O `examples/mg.ttl` é ficção de
teste.

## Como inspecionar o modelo

```bash
make perguntas          # imprime o que o modelo responde
make verify             # falha quando o modelo está errado
make contra-exemplos    # prova que as verificações pegam erro de verdade
make profile            # confirma o perfil lógico do modelo
make validate           # pipeline completo
```

A distinção importa: **`make verify` falha** quando o modelo está errado;
**`make perguntas` mostra** o que o modelo pensa, e é a ferramenta para ler as
respostas e apontar o que não confere com a realidade do movimento.

`make contra-exemplos` existe porque uma verificação que nunca encontra nada passa
para sempre sem provar nada. Ele roda as mesmas consultas contra erros plantados de
propósito, e **só passa quando os encontra**.

## Como o ecossistema consome este modelo

```text
             Ontologia (este repositório)
                       │
        vocabulário e modelo normativo
                       │
     ┌─────────────────┼─────────────────┐
     ▼                 ▼                 ▼
Casas Espíritas   Voluntário       Painéis de
                  Espírita         Demografia
```

Nenhum outro repositório redefine um termo daqui. Quando um sistema precisa de
significado diferente, o caminho é mudar a ontologia (decisão que envolve o COFEMG)
ou **declarar o desvio** no próprio repositório, com justificativa e prazo. Definição
paralela silenciosa é o que este projeto existe para impedir.

## Como contribuir

O ciclo é: edite o modelo, acrescente a pergunta de competência que prova a mudança,
regenere o contexto JSON-LD, rode a validação completa e abra o Pull Request. Detalhes
em [`docs/guia-de-contribuicao.md`](docs/guia-de-contribuicao.md).

Mudanças em **elemento crítico** — a hierarquia de instituições, seus axiomas de
disjunção, ou qualquer termo já consumido por um aplicativo — exigem, além da
validação verde, aprovação explícita do mantenedor do domínio. Alterações no modelo
de dados nacional são decisão do COFEMG, conforme o
[processo de decisão](https://github.com/ACSE-UEM/governanca/blob/main/processo-de-decisao.md).

**Não é preciso saber OWL para contribuir.** A contribuição mais valiosa aqui é de
quem conhece o movimento por dentro: rodar `make perguntas`, ler as respostas e dizer
"isto não é assim na prática". Corrigir o modelo é fácil; descobrir que ele está
errado é o trabalho difícil.

> ### Vaga aberta: suplente do mantenedor do domínio
>
> A ontologia depende hoje de **uma única pessoa** para validar se o modelo
> corresponde à realidade do movimento. Se essa pessoa se afastar, os quatro projetos
> ficam sem quem responda "o modelo está certo?".
>
> Procuramos um voluntário com experiência em órgão de unificação ou em coordenação
> de área federativa. **Conhecimento técnico não é requisito** — é ensinável, e a
> validação que importa é a do domínio. Responsabilidades detalhadas em
> [papéis e responsabilidades](https://github.com/ACSE-UEM/governanca/blob/main/papeis-e-responsabilidades.md).
>
> Preencher esta vaga é requisito para o lançamento público de qualquer produto do
> ecossistema.

## Versionamento

Versionamento semântico aplicado ao modelo e ao `CHANGELOG.md`. Correção de rótulo é
alteração de correção; classe nova que não quebra nada é alteração menor; renomear,
remover ou mudar hierarquia de algo já consumido é alteração maior, e implica uma
nova versão no caminho do identificador (`v2`), preservando a anterior para quem
ainda depende dela.

## Licença

[CC BY 4.0](LICENSE) — use, adapte e redistribua, inclusive comercialmente, desde que
cite a fonte. O uso do nome e dos símbolos das instituições do movimento é regulado
pela
[política de marca](https://github.com/ACSE-UEM/governanca/blob/main/politica-de-marca.md).

Este é **trabalho voluntário, sem finalidade lucrativa**.
