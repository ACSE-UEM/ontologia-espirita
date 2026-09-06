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
