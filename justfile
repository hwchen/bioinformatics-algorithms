build:
    werk build --jobs=1 -Dprofile=release

run problem *args="":
    werk build --jobs=1 -Dprofile=release && time -pq ./target/{{problem}}.bin {{args}}

bench problem *args="":
    just build {{problem}} -O5 && \
    poop "./{{problem}} {{args}}"

# can inspect results with `perf report`
# sudo sysctl kernel.perf_event_paranoid=1
# sudo sysctl kernel.kptr_restrict=0
perf bin *args="":
    perf record --call-graph dwarf ./{{bin}} {{args}} > /dev/null

# stackcollapse-perf.pl and flamegraph.pl symlinked into path from flamegraph repo
flamegraph:
    perf script | stackcollapse-perf.pl | flamegraph.pl > perf.svg


