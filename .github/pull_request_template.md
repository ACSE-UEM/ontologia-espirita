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
