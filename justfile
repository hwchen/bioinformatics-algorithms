@check:
    \fd --glob '*.c3' -x c3c compile -C util.c3

@test:
    c3c compile-test .

# redirects outputs to stderr
@build problem *args="":
    c3c compile {{args}} {{problem}}.c3 util.c3 test.c3 1>&2

# using compile-run prints a bunch of logs
run problem *args="":
    just build {{problem}} -O5 && time -pq ./{{problem}} {{args}} && rm ./{{problem}}

bench problem *args="":
    just build {{problem}} -O5 && \
    poop "./{{problem}}"

# can inspect results with `perf report`
# sudo sysctl kernel.perf_event_paranoid=1
# sudo sysctl kernel.kptr_restrict=0
perf bin *args="":
    perf record --call-graph dwarf ./{{bin}} {{args}} > /dev/null

# stackcollapse-perf.pl and flamegraph.pl symlinked into path from flamegraph repo
flamegraph:
    perf script | stackcollapse-perf.pl | flamegraph.pl > perf.svg


