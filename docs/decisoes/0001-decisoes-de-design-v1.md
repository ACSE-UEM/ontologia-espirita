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
