@check:
    \fd --glob '*.c3' -x c3c compile -C

@test:
    c3c compile-test .

# redirects outputs to stderr
@build problem *args="":
    c3c compile -O3 {{problem}}.c3 1>&2

# using compile-run prints a bunch of logs
run problem *args="":
    just build {{problem}} -O3 && ./{{problem}} {{args}} && rm ./{{problem}}