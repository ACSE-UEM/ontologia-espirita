# Modelo de domínio

Visão narrativa do grafo definido em `ontology/core.ttl`. Ver
`docs/glossario.md` para definição termo a termo.

## Estrutura federativa

Uma **Casa** é parte de (`esp:parteDe`) alguma **Federativa** (Federação,
Regional, CRE ou AME) e atua (`esp:atuaEm`) em uma ou mais **Áreas de
Atuação** (Infância e Juventude, Estudo do Evangelho, Promoção Social,
Orientação Mediúnica, Esperanto, Arte, Comunicação Social, Família,
Atendimento Espiritual, Estudo do Espiritismo). Um **CRE** é sempre parte
de uma **Regional**.

O catálogo de referência (`ontology/reference-catalog.ttl`) guarda as
entidades federativas reais e estáveis conhecidas — atualmente só a UEM
(União Espírita Mineira), migrada do rascunho original. Espera-se que este
catálogo cresça conforme mais entidades forem confirmadas pelo mantenedor
do domínio.

## Pessoas e papéis

Uma pessoa pode ser **Voluntário** (atua em uma Área), **Dirigente** (dirige
uma Casa), **Frequentador** (frequenta uma Casa) ou **Beneficiário** (é
público-alvo de uma Atividade). Uma mesma pessoa do mundo real pode
acumular papéis diferentes ao longo do tempo — isso é responsabilidade do
app consumidor modelar, não desta ontologia.

## Atividades

Uma Casa realiza (`esp:realiza`) **Atividades**: Eventos, Ações Sociais ou
Estudos Doutrinários. Toda Atividade pode ter um Beneficiário como
público-alvo.

## Geografia

Toda Casa está localizada em (`esp:localizadaEm`) um **Município**, que
pertence a (`esp:pertenceA`) uma **Unidade Federativa** e carrega um
`esp:codigoIBGE`. Esta ontologia não guarda a lista de municípios do
Brasil — isso é dado, consumido diretamente pelo painel de demografia a
partir da base do IBGE, usando o código como chave de cruzamento.

## O que fica fora do v1.0

- Hierarquia geográfica fina (bairro, setor censitário).
- Crosswalk completo de códigos IBGE/município/UF.
- Instâncias de Casas ou pessoas (vivem nos apps consumidores).
- Documentação de produto dos apps consumidores.
