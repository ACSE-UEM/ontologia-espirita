# Glossário

Termos em português, na ordem em que aparecem em `ontology/core.ttl`.

Esta ontologia cobre o **movimento espírita kardecista**. Umbanda, candomblé
e outras vertentes não fazem parte do domínio.

## Instituições

| Termo | IRI | Definição |
|---|---|---|
| Instituição | `esp:Instituicao` | Classe de topo: qualquer entidade institucional do movimento, casa ou órgão. |
| Casa | `esp:Casa` | Instituição espírita autônoma de base. Decide por conta própria se adere ao movimento federativo. **Não é órgão.** |
| Centro | `esp:Centro` | O caso comum de casa: centro espírita que realiza atividades regulares. |
| Hospital | `esp:Hospital` | Hospital espírita. É uma casa, não um órgão. |
| Lar | `esp:Lar` | Abrigo, asilo, casa de acolhimento. |
| Livraria | `esp:Livraria` | Livraria ou editora espírita. |
| Órgão | `esp:Orgao` | Instituição de unificação e coordenação. Disjunto de Casa. |
| Federativa | `esp:Federativa` | Entidade federativa. Nacional (FEB) ou estadual (UEM). |
| Órgão Unificador | `esp:OrgaoUnificador` | Órgão interno de uma federativa, que orienta e organiza o movimento no seu âmbito. COFEMG dentro da UEM; CFN dentro da FEB. |
| Órgão Regional | `esp:OrgaoRegional` | Recorte regional de uma federativa estadual. Macrorregião ou microrregião. |
| Macrorregião | `esp:MacroRegiao` | Nível regional maior. Em MG chama-se "Regional". |
| Microrregião | `esp:MicroRegiao` | Nível regional menor. Em MG chama-se "CRE"; em outros estados, URE, Polo ou Setor. |
| Órgão Municipal | `esp:OrgaoMunicipal` | Órgão municipal ou intermunicipal de apoio às casas. AME, CEM. |

## Adesão

| Termo | IRI | Definição |
|---|---|---|
| adesa a | `esp:adesaA` | Vínculo formal de uma casa com a federativa. **Opcional** — a casa tem autonomia para decidir. |
| status de adesão | `esp:statusAdesao` | Adesa, Pendente, Previsto ou Conhecido. |
| atendida por | `esp:atendidaPor` | Caminho administrativo de apoio (AME, CRE, Regional). Independente da adesão. |
| parte de | `esp:parteDe` | Relação hierárquica **entre órgãos**. Uma casa nunca é parte de um órgão. |
| órgão interno de | `esp:orgaoInternoDe` | Do unificador para sua federativa. |

## Realizações

| Termo | IRI | Definição |
|---|---|---|
| Realização | `esp:Realizacao` | Classe de topo do que uma instituição realiza. |
| Atividade | `esp:Atividade` | Realização **periódica**. Casas e órgãos realizam atividades. |
| Evento | `esp:Evento` | Realização **datada**, com início e fim. Não é uma atividade — são disjuntos. |
| Tipo de Atividade | `esp:TipoDeAtividade` | Vocabulário de tipos (palestra pública, reunião mediúnica, ESDE...). As instâncias vivem no catálogo. |
| apoiada por | `esp:apoiadaPor` | Áreas que podem apoiar a casa num tipo de atividade. Pode ser vazia. Nunca é composição. |
| modalidade | `esp:modalidade` | presencial, virtual ou hibrida. Vale para casa e para realização. |

## Áreas federativas

| Termo | IRI | Definição |
|---|---|---|
| Área Federativa | `esp:AreaFederativa` | Área de trabalho do movimento. As dez áreas são **indivíduos** no catálogo, não classes. |
| mantém área | `esp:mantemArea` | Órgão estrutura áreas com frequência; casa raramente. Nunca obrigatório. |

As dez: AAE (Atendimento Espiritual), AA (Arte), ACSE (Comunicação Social
Espírita), AEE (Estudo do Espiritismo), AEEJ (Estudo do Evangelho de Jesus),
AESP (Esperanto), AFam (Família), AIJ (Infância e Juventude), AOM (Orientação
Mediúnica), APSE (Promoção Social Espírita).

## Pessoas

| Termo | IRI | Definição |
|---|---|---|
| Voluntário | `esp:Voluntario` | Atua em uma instituição — casa ou órgão — e pode atuar em uma ou mais áreas federativas. |
| Coordenador | `esp:Coordenador` | Voluntário que responde por uma atividade ou por uma área federativa. |
| Dirigente | `esp:Dirigente` | Dirige uma instituição. |
| Público-alvo | `esp:PublicoAlvo` | Quem a instituição atende. |
| Frequentador | `esp:Frequentador` | Participa de atividades regulares. |
| Assistido | `esp:Assistido` | Recebe amparo social ou espiritual. **Não se diz "beneficiário".** |

## Geografia

| Termo | IRI | Definição |
|---|---|---|
| Município | `esp:Municipio` | Carrega o código IBGE. É o vínculo jurídico de uma casa — inclusive de uma casa só virtual. |
| Unidade Federativa | `esp:UnidadeFederativa` | Estado brasileiro. Termo do IBGE, sem relação com o movimento federativo espírita. |

Para a lista completa e formal, ver `ontology/core.ttl` e
`ontology/reference-catalog.ttl`.
