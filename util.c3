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

fn int hamming_distance(String s1, String s2) {
	assert(s1.len == s2.len);
	int count = 0;
	for (int i = 0; i < s1.len; i += 1) {
		if (s1[i] != s2[i]) {
			count += 1;
		}
	}
	return count;
}

fn void test_hamming_distance() @test {
	assert(hamming_distance("GGGCCGTTGGT", "GGACCGTTGAC") == 3);
}

// d is the hamming_distance maximum threshold
fn int[] approximate_pattern_matching(
	String pattern,
	String genome,
	int d,
	Allocator alloc = allocator::heap())
{
	if (pattern.len == 0 || genome.len == 0) return {};
	List(<int>) res;
	@pool() {
		res.temp_init();
		for (int i = 0; i <= genome.len - pattern.len; i += 1) {
			// TODO more efficient to break early when calculating hamming distance
			if (util::hamming_distance(genome[i:pattern.len], pattern) <= d) {
				res.push(i);
			}
		}
		return res.to_new_array(alloc);
	};
}

struct ApproxMatchTest {
	String pattern;
	String genome;
	int d;
	int[] expected;
}
fn void test_approximate_pattern_matching() @test {
	ApproxMatchTest[] tests = {
		{
			.pattern = "ATA",
			.genome = "CGATCGAGTACCATAAG",
			.d = 1,
			.expected = {2, 7, 12},
		},
		{
			.pattern = "ATTCTGGA",
			.genome = "CGCCCGAATCCAGAACGCATTCCCATATTTCGGGACCACTGGCCTCCACGGTACGGACGTCAATCAAAT",
			.d = 3,
			.expected = {6, 7, 26, 27},
		},
		{
			.pattern = "AAA",
			.genome = "TTTTTTAAATTTTAAATTTTTT",
			.d = 2,
			.expected = {4, 5, 6, 7, 8, 11, 12, 13, 14, 15},
		},
	};
	foreach (t : tests) {
		int[] matches = approximate_pattern_matching(t.pattern, t.genome, t.d);
		assert(matches == t.expected, "Expected %s, found %s", t.expected, matches);
	}
}


