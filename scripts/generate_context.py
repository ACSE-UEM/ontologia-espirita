#!/usr/bin/env python3
"""Gera ontology/context.jsonld a partir de ontology/core.ttl."""
import json

import rdflib
from rdflib.namespace import OWL, RDF

BASE = "https://w3id.org/ontologia-espirita/v1#"


def local_names(graph, rdf_type):
    for subject in set(graph.subjects(RDF.type, rdf_type)):
        iri = str(subject)
        if iri.startswith(BASE):
            yield iri[len(BASE):]


def main():
    graph = rdflib.Graph()
    graph.parse("ontology/core.ttl", format="turtle")

    context = {"esp": BASE}
    for rdf_type in (OWL.Class, OWL.ObjectProperty, OWL.DatatypeProperty):
        for name in local_names(graph, rdf_type):
            context[name] = f"esp:{name}"

    output = {"@context": context}
    with open("ontology/context.jsonld", "w", encoding="utf-8") as handle:
        json.dump(output, handle, ensure_ascii=False, indent=2, sort_keys=True)
        handle.write("\n")


if __name__ == "__main__":
    main()
