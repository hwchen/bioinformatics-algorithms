// clump finding

module ba1e;
import std::io;
import std::io::file;
import std::collections;

import util;

fn void! main(String[] args) {
	if (args.len != 2) {
		io::eprintn("Please supply path to data file");
		return IoError.FILE_NOT_FOUND?;
	}
	File f = file::open(args[1], "rb")!;
	String genome = io::treadline(&f)!;
	String ints = io::treadline(&f)!;
	String[] ints_split = ints.tsplit(" ");
	int k = ints_split[0].to_integer(int)!;
	int region_len = ints_split[1].to_integer(int)!; // K
	int clump_threshold = ints_split[2].to_integer(int)!; // t
	String[] clumps = clump_finding(genome, k, region_len, clump_threshold);
	foreach (clump : clumps) {
		io::printf("%s ", clump);
	}
}

fn String[] clump_finding(
	String genome,
	int k,
	int region_len, // K
	int clump_threshold, // t
	Allocator alloc = allocator::heap())
{
	if (k == 0 || genome.len == 0) return {};
	String[] res;
	@pool() {
		HashMap(<String, char>) clumps; // a set
		clumps.temp_init();
		for (int i = 0; i <= genome.len - region_len; i += 1) {
			FrequencyTable freq_map = util::frequency_table(genome[i:region_len], k);
			freq_map.@each(; String kmer, int count) {
				if (count >= clump_threshold) {
					// TODO can probably just use a growable array on small inputs
					// Also, careful: hashmap copies keys! Here that means keys copied
					// to temp allocator.
					clumps.set(kmer, 0);
				}
			};
		}
		return clumps.copy_keys(alloc);
	};
}

fn void test_clump_finding() @test {
    String input = "CGGACTCGACAGATGTGAAGAACGACAATGTGAAGACTCGACACGACAGAGTGAAGAGAAGAGGAAACATTGTAA";
	assert(clump_finding(input, 5, 50, 4) == {"CGACA", "GAAGA"});
}



