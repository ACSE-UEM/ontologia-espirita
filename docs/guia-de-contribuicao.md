# Guia de contribuição

## Como propor uma mudança

1. Edite `ontology/core.ttl` (Protégé Desktop ou texto direto) ou
   `ontology/reference-catalog.ttl`.
2. Se adicionar um caso de uso novo, adicione uma competency question em
   `competency-questions/*.rq` (ver `competency-questions/README.md`).
3. Se `core.ttl` mudou, regenere `ontology/context.jsonld`:
   ```bash
   docker build -t ontologia-espirita-ci -f docker/Dockerfile docker/
   docker run --rm --entrypoint python3 -v "$(pwd)":/work -w /work ontologia-espirita-ci scripts/generate_context.py
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
