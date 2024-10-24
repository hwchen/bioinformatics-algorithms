// Pattern matching

module ba1d;
import std::io;
import std::io::file;
import std::collections;

fn void! main(String[] args) {
	if (args.len != 2) {
		io::eprintn("Please supply path to data file");
		return IoError.FILE_NOT_FOUND?;
	}
	File f = file::open(args[1], "rb")!;
	String pattern = io::treadline(&f)!;
	String genome = io::treadline(&f)!;
	int[] idxs = pattern_matching(pattern, genome);
	foreach (idx : idxs) {
		io::printf("%d ", idx);
	}
}

fn int[] pattern_matching(String pattern, String genome, Allocator alloc = allocator::heap()) {
	if (pattern.len == 0 || genome.len == 0) return {};
	List(<int>) res;
	@pool() {
		res.temp_init();
		for (int i = 0; i <= genome.len - pattern.len; i += 1) {
			if (genome[i:pattern.len] == pattern) {
				res.push(i);
			}
		}
		return res.to_new_array(alloc);
	};
}

fn void test_pattern_matching() @test {
	assert(pattern_matching("ATAT", "GATATATGCATATACTT") == {1, 3, 9});
}


