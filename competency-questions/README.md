# Competency Questions

Cada arquivo `.rq` é uma consulta SPARQL de **violação**: ela deve retornar
**zero linhas** quando a ontologia está correta. Se retornar alguma linha,
é uma pergunta que a ontologia deveria conseguir responder corretamente e
não consegue — `robot verify` falha o CI nesse caso.

Convenção de nomes: `cq-NN-descricao-curta.rq`, com um comentário no topo
do arquivo explicando, em português, a pergunta de competência que a
consulta verifica.
