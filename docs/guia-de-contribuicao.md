# Guia de contribuição

## Como propor uma mudança

1. Edite `ontology/core.ttl` (Protégé Desktop ou texto direto) ou
   `ontology/reference-catalog.ttl`.
2. Se adicionar um caso de uso novo, adicione uma competency question em
   `competency-questions/*.rq` (ver `competency-questions/README.md`). Se a
   CQ verifica uma disjunção ou qualquer outra propriedade que só aparece
   em dado ruim (isto é, uma consulta que deveria retornar vazio sobre dado
   bom e não-vazio sobre dado violando a regra), ela também precisa de uma
   violação plantada em `examples/contra-exemplos.ttl` e de uma entrada
   correspondente no laço de `docker/contra-exemplos.sh` — do contrário a
   CQ passa vazia para sempre e não prova nada. Ver a nota no topo de
   `examples/contra-exemplos.ttl`.
3. Se `core.ttl` mudou, regenere `ontology/context.jsonld`:
   ```bash
   make context
   ```
4. Rode a validação completa localmente antes de abrir o PR:
   ```bash
   make validate
   make contra-exemplos
   ```
5. Abra o Pull Request. O template pede pra marcar se a mudança toca um
   elemento crítico.

## O que é um elemento crítico

Qualquer mudança na hierarquia de instituições e suas axiomas de disjunção
— `esp:Instituicao`, `esp:Casa`, `esp:Orgao`, `esp:Federativa`,
`esp:Atividade`, `esp:Evento`, `esp:AreaFederativa` — ou em qualquer
classe/propriedade já consumida por um dos apps (voluntário, casa, painel
de demografia). PRs que tocam esses elementos exigem, além do CI verde,
revisão manual explícita do mantenedor (checkbox no template de PR) antes
de mergear.

## Versionamento

SemVer aplicado a `owl:versionInfo` em `ontology/core.ttl` e a
`CHANGELOG.md`:

- **patch**: correção de rótulo/typo, sem mudar estrutura.
- **minor**: nova classe/propriedade que não quebra nada existente.
- **major**: renomear/remover/mudar hierarquia de algo já consumido pelos
  apps. Uma mudança major implica uma nova versão no path da IRI (`v2`),
  preservando `v1` para quem ainda depende dela.
