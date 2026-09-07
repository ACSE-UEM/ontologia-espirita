---
id: 0002
status: aceito
data: 2026-09-06
---

# ADR 0002: Revisão do modelo de domínio

## Contexto

O mantenedor do domínio leu o modelo v1 e apontou erros de terminologia e de
estrutura. Ver
`docs/superpowers/specs/2026-09-06-revisao-do-modelo-design.md` para a
entrevista completa.

O erro de fundo do v1 foi **excesso de restrição**: axiomas obrigatórios que
a realidade do movimento contradiz. O caso central era
`esp:Casa ⊑ ∃parteDe.Federativa`, falso em dois níveis — a casa não é parte
da federativa, e pode não ter vínculo nenhum.

## Decisões

1. **Casa e órgão são disjuntos.** `esp:Instituicao` no topo. Um hospital ou
   uma livraria espírita é casa; nenhum dos dois é órgão.
2. **A casa adere, não é parte.** `esp:adesaA` opcional substitui
   `esp:parteDe` no vínculo casa–federativa. `esp:parteDe` sobrevive só entre
   órgãos.
3. **Atividade e evento são irmãos disjuntos.** Atividade é periódica; evento
   é datado. Ambos realizados por casas e por órgãos.
4. **Regional e CRE saem do TBox.** Viram instâncias de macro e microrregião
   com o nome local em atributo, porque estados têm zero, um ou dois níveis
   regionais. Minas Gerais é exemplo, não modelo.
5. **Áreas e tipos de atividade são indivíduos de catálogo, não classes.**
   Acrescentar um tipo de atividade não toca o modelo lógico. Consequência
   técnica: um indivíduo não pode apontar para uma classe em OWL DL sem
   punning, o que quebraria o ELK.
6. **Atividade é apoiada por 0..N áreas.** Sem cardinalidade mínima, e nunca
   por composição.
7. **Terminologia:** órgão (não organização), assistido (não beneficiário),
   área federativa (não área de atuação). Sem sufixo "Espírita" em termo
   autoexplicativo — o namespace já diz.
8. **Escopo kardecista** declarado como anotação da ontologia.
9. **AG (Área de Gestão) fica fora.** Nas palavras do mantenedor, está
   referenciada em livro, mas ele nunca viu atuação de AG em Minas Gerais. É
   não-observação pessoal, não levantamento institucional; se aparecer
   atuação, a decisão se revisita. `analise-demografica` tem 11 lentes para
   as 10 áreas daqui — inconsistência daquele repositório.
10. **Divisão TBox / SHACL.** O TBox fica no perfil EL para o ELK raciocinar.
    O que o EL não expressa — enums, união no alvo de `esp:coordena`,
    obrigatoriedades de instância — vai para `shapes/modelo.shacl.ttl`.
11. **Versão permanece 1.0.0** e o IRI permanece `.../v1#`. A ontologia não
    foi publicada; não há compatibilidade a preservar. Termos do v1 são
    substituídos, não depreciados.
12. **Modalidade** (presencial, virtual, híbrida) exigida em realização,
    recomendada em casa. Obrigatória na casa invalidaria todo o cadastro
    federativo existente de uma vez.
13. **Contra-exemplos.** `robot verify` trata zero linhas como sucesso, então
    verificações de disjunção passariam vazias. `make contra-exemplos` roda
    as mesmas consultas contra violações plantadas e só passa quando as
    encontra.
14. **O perfil EL é verificado, não presumido.** `robot reason --reasoner ELK`
    prova consistência, não pertencimento ao perfil — o ELK tolerou um
    datatype fora do perfil e passou verde. `robot validate-profile --profile
    EL` entra como passo 1 de 4 do pipeline. Foi assim que `xsd:date` em
    `esp:dataInicio`/`esp:dataFim` foi pego, e por isso essas duas propriedades
    não declaram `rdfs:range`: o tipo é exigido em SHACL.
15. **SHACL valida a união, não fragmentos.** Validar `examples/mg.ttl`
    isoladamente produz violações falsas: a inferência RDFS tipa os indivíduos
    do catálogo nas classes-alvo dos shapes, mas seus rótulos e siglas estão no
    catálogo, ausente daquele grafo. Catálogo e exemplos são um grafo só.
16. **Locale UTF-8 na imagem Docker.** A JVM do ROBOT lê arquivos de consulta
    com o charset padrão do sistema; sem locale definido isso é ASCII, e texto
    acentuado no corpo de uma consulta SPARQL sai corrompido. Os dados RDF nunca
    foram afetados porque os parsers declaram UTF-8. Esta ontologia é escrita em
    português: o locale é requisito, não conveniência.

## Consequências

- Todo consumidor do v1 quebra. Aceito: não havia consumidor.
- O modelo tem duas restrições existenciais no total, contra as quatro do v1.
- O vínculo entre federativa estadual e FEB **não** é asserido: a natureza
  dessa relação não foi definida na revisão, e asserir sem confirmação
  repetiria o erro do v1.
