## O que muda e por quê

<!-- descreva a mudança na ontologia -->

## Este PR toca um elemento crítico?

Elementos críticos: a hierarquia de instituições e seus axiomas de
disjunção (`esp:Instituicao`, `esp:Casa`, `esp:Orgao`, `esp:Federativa`,
`esp:Atividade`, `esp:Evento`, `esp:AreaFederativa`), ou qualquer
classe/propriedade já consumida por um dos apps (voluntário, casa, painel
de demografia).

- [ ] Não — só adiciona algo novo sem alterar o que já existe.
- [ ] Sim — e eu (mantenedor) revisei manualmente o impacto antes de mergear.

## Checklist

- [ ] CI verde (perfil EL + reasoner + competency questions + SHACL + contra-exemplos).
- [ ] `context.jsonld` regenerado se `core.ttl` mudou.
- [ ] Nova competency question adicionada, se este PR cobre um caso de uso novo.
