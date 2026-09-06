# Registro no w3id.org

Este diretório contém o `.htaccess` a ser submetido como Pull Request no
repositório https://github.com/perma-id/w3id.org, dentro de uma pasta
`ontologia-espirita/` na raiz daquele repositório (não deste).

Passos (ação manual, fora deste repositório):

1. Fork de `perma-id/w3id.org`.
2. Copiar `ontologia-espirita/.htaccess` (o arquivo deste diretório) para a
   raiz do fork, dentro de uma pasta `ontologia-espirita/`.
3. Abrir PR seguindo o `CONTRIBUTING.md` daquele repositório.
4. Após aprovado, `https://w3id.org/ontologia-espirita/v1#` passa a
   resolver para o GitHub Pages deste repositório.
5. Ativar GitHub Pages neste repositório (Settings → Pages → servir a
   partir de `/ontology` ou de uma branch `gh-pages` publicando
   `ontology/core.ttl`) — esta é a peça que falta para o redirect acima
   funcionar de fato; sem isso, o PR do w3id.org pode ser aberto mas o
   link ainda não resolve para conteúdo real.
