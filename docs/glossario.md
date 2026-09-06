# Glossário

Termos em português, na ordem em que aparecem em `ontology/core.ttl`.

| Termo (pt-BR) | IRI | Definição |
|---|---|---|
| Organização | `esp:Organizacao` | Classe de topo para qualquer entidade organizacional do movimento. |
| Pessoa | `esp:Pessoa` | Classe de topo para qualquer indivíduo humano que se relaciona com uma Casa. |
| Atividade | `esp:Atividade` | Classe de topo para o que uma Casa realiza (evento, ação social, estudo). |
| Localização | `esp:Localizacao` | Classe de topo da geografia básica (Município, Unidade Federativa). |
| Área de Atuação | `esp:AreaDeAtuacao` | Classe de topo das áreas temáticas de uma Casa (infância, promoção social etc.). |
| Federativa | `esp:Federativa` | Organização que faz parte da estrutura federativa (Federação, Regional, CRE, AME). |
| Casa | `esp:Casa` | Centro/casa espírita local, parte de alguma estrutura federativa e localizada em um Município. |
| Voluntário | `esp:Voluntario` | Pessoa que atua em uma Área de Atuação. |
| Dirigente | `esp:Dirigente` | Pessoa que dirige uma Casa. |
| Frequentador | `esp:Frequentador` | Pessoa que frequenta uma Casa. |
| Beneficiário | `esp:Beneficiario` | Pessoa que é público-alvo de uma Atividade. |
| Município | `esp:Municipio` | Localização onde uma Casa está situada; carrega o código IBGE. |
| Unidade Federativa | `esp:UnidadeFederativa` | Estado ao qual um Município pertence. |

Para a lista completa de classes e propriedades (incluindo as dez Áreas de
Atuação), ver `ontology/context.jsonld`, gerado automaticamente a partir de
`ontology/core.ttl`.
