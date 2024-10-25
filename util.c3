module util;
import std::collections;

def FrequencyTable = HashMap(<String, int>);

// counts of kmers in a text.
fn FrequencyTable frequency_table(String text, int k, Allocator alloc = allocator::heap()) {
	FrequencyTable kmer_counts;
	kmer_counts.new_init(allocator: alloc);
	for (int i = 0; i <= text.len - k; i += 1) {
		// TODO get_or_update? Annoying to get twice
		kmer_counts.@get_or_set(text[i:k], 0); // don't need to clone, keys copied into table
		if (try int* count = kmer_counts.get_ref(text[i:k])) {
			*count += 1;
		}
	}
	return kmer_counts;
}

fn String[] clump_finding(
	String genome,
	int k,
	int region_len, // L
	int clump_threshold, // t
	Allocator alloc = allocator::heap())
{
	if (k == 0 || genome.len == 0) return {};
	String[] res;
	@pool() {
		HashMap(<String, char>) clumps; // a set
		clumps.temp_init();
		for (int i = 0; i <= genome.len - region_len; i += 1) {
			@pool(allocator::temp()) {
				FrequencyTable freq_map = frequency_table(genome[i:region_len], k, allocator::temp());
				freq_map.@each(; String kmer, int count) {
					if (count >= clump_threshold) {
						// TODO can probably just use a growable array on small inputs
						// Also, careful: hashmap copies keys! Here that means keys copied
						// to temp allocator.
						clumps.set(kmer, 0);
					}
				};
			};
		}
		return clumps.copy_keys(alloc);
	};
}

fn void test_clump_finding() @test {
    String input = "CGGACTCGACAGATGTGAAGAACGACAATGTGAAGACTCGACACGACAGAGTGAAGAGAAGAGGAAACATTGTAA";
	assert(clump_finding(input, 5, 50, 4) == {"CGACA", "GAAGA"});
}
