# Changelog

Todas as mudanças notáveis da ontologia são documentadas aqui.
Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
versionamento [SemVer](https://semver.org/lang/pt-BR/).

## [1.0.0] - 2026-09-06

Versão inicial, revisada no mesmo dia com o mantenedor do domínio antes de
qualquer publicação. Como nada foi publicado nem consumido, a revisão não
gerou bump de versão — ver `docs/decisoes/0002-revisao-do-modelo.md`.

### Adicionado
- TBox: instituições (casa e órgão disjuntos), adesão, realizações
  (atividade e evento disjuntos), pessoas e papéis, áreas federativas,
  geografia básica.
- Catálogo de referência: 10 áreas federativas, tipos de atividade com o mapa
  `apoiadaPor`, estrutura federativa de Minas Gerais, FEB e CFN.
- ABox de exemplo (`examples/mg.ttl`) e contra-exemplos
  (`examples/contra-exemplos.ttl`).
- Alvos `make perguntas` (inspeção), `make contra-exemplos` (teste do teste) e
  `make profile` (perfil OWL 2 EL).
- Pipeline de validação Docker (ROBOT + SHACL) rodando em CI.
- Documentação: glossário, modelo de domínio, guia de contribuição, ADRs 0001
  e 0002.
- IRI definitivo via w3id.org + GitHub Pages.
