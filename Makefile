IMAGE := ontologia-espirita-ci
WORKDIR := $(CURDIR)
DOCKER_RUN := docker run --rm -v "$(WORKDIR)":/work -w /work $(IMAGE)

.PHONY: help check-tools build validate profile reason verify shacl context context-check perguntas contra-exemplos clean

help:
	@echo "Alvos disponiveis:"
	@echo "  make build          - constroi a imagem docker de validacao"
	@echo "  make validate       - roda o pipeline completo (reason + verify + shacl)"
	@echo "  make profile        - verifica se o TBox esta no perfil OWL 2 EL"
	@echo "  make reason         - roda so o robot reason (consistencia logica do TBox)"
	@echo "  make verify         - roda so as competency questions (robot verify)"
	@echo "  make shacl          - roda so a validacao SHACL (catalogo de referencia e exemplos)"
	@echo "  make perguntas      - imprime as respostas do modelo para as perguntas de queries/"
	@echo "  make contra-exemplos - prova que as verificacoes de disjuncao pegam erro"
	@echo "  make context        - regera ontology/context.jsonld a partir de core.ttl"
	@echo "  make context-check  - falha se context.jsonld estiver desatualizado"
	@echo "  make clean          - remove artefatos gerados (cq-*.csv, etc)"

check-tools:
	@command -v docker >/dev/null 2>&1 || { \
		echo "Erro: docker nao encontrado no PATH. Instale o Docker antes de continuar."; \
		exit 1; \
	}
	@command -v git >/dev/null 2>&1 || { \
		echo "Erro: git nao encontrado no PATH."; \
		exit 1; \
	}

build: check-tools
	docker build -t $(IMAGE) -f docker/Dockerfile docker/

validate: build
	$(DOCKER_RUN) /work/docker/validate.sh

profile: build
	docker run --rm -v "$(WORKDIR)":/work -w /work $(IMAGE) -c \
		"robot validate-profile --profile EL --input ontology/core.ttl --output /tmp/el-profile-report.txt && echo OK"

reason: build
	docker run --rm -v "$(WORKDIR)":/work -w /work $(IMAGE) -c \
		"robot reason --input ontology/core.ttl --reasoner ELK --output /tmp/core-reasoned.ttl && echo OK"

verify: build
	docker run --rm -v "$(WORKDIR)":/work -w /work $(IMAGE) -c \
		"robot merge --input ontology/core.ttl --input ontology/reference-catalog.ttl --input examples/mg.ttl verify --queries competency-questions/*.rq"

shacl: build
	docker run --rm -v "$(WORKDIR)":/work -w /work $(IMAGE) -c \
		'robot merge --input ontology/core.ttl --input ontology/reference-catalog.ttl --input examples/mg.ttl --output /tmp/dados-shacl.ttl && \
		 for shape in shapes/*.shacl.ttl; do \
		   echo "-- $$shape --"; \
		   pyshacl -s "$$shape" -d /tmp/dados-shacl.ttl -i rdfs; \
		 done'

contra-exemplos: build
	$(DOCKER_RUN) /work/docker/contra-exemplos.sh

context: build
	docker run --rm --entrypoint python3 -v "$(WORKDIR)":/work -w /work $(IMAGE) scripts/generate_context.py

context-check: context
	@git diff --exit-code ontology/context.jsonld || { \
		echo "context.jsonld esta desatualizado — rode 'make context' e faca commit do resultado"; \
		exit 1; \
	}

clean:
	rm -f cq-*.csv
