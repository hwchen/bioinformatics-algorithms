module util;
import std::collections;
import std::core::string;
import std::io;
import std::sort;

import test;

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

// Just like frequent words, except instead of matching just each kmer,
// we create a neighbohood(d) for each kmer and that neighborhood is compared against the text
fn String[] frequent_words_with_mismatches(String text, int k, int d, Allocator alloc= allocator::heap()) {
	@pool() {
		FrequencyTable freq_map;
		freq_map.new_init(allocator: alloc);
		for (int i = 0; i <= text.len - k; i += 1) {
			String pattern = text[i:k];
			String[] neighborhood = neighbors(pattern, d, allocator::temp());
			foreach (neighbor : neighborhood) {
				freq_map.@get_or_set(neighbor, 0); // don't need to clone, keys copied into table
				if (try int* count = freq_map.get_ref(neighbor)) {
					*count += 1;
				}
			}
		}

		int[] counts = freq_map.value_tlist();
		int max = 0;
		freq_map.@each(; String _k, int count) {
			if (count > max) max = count;
		};

		List(<String>) res;
		res.temp_init();
		freq_map.@each(; String key, int v) {
			if (v == max) {
				res.push(key.copy(alloc));
			}
		};
		return res.to_new_array(alloc);
	};
}

struct FreqWordsMismatchesTest {
	String text;
	int k;
	int d;
	String[] expected;
}
fn void test_frequent_words_with_mismatches() @test {
	FreqWordsMismatchesTest[] tests = {
		{
			.text = "ACGTTGCATGTCGCATGATGCATGAGAGCT",
			.k = 4,
			.d = 1,
			.expected = {"ATGT", "GATG", "ATGC"},
		},
		{
			.text = "AGGT",
			.k = 2,
			.d = 1,
			.expected = {"GG"},
		},
		{
			.text = "AGGGT",
			.k = 2,
			.d = 0,
			.expected = {"GG"},
		},
		{
			.text = "AGGCGG",
			.k = 3,
			.d = 0,
			.expected = {"AGG", "GGC", "GCG", "CGG"},
		},
	};
	foreach (t : tests) {
		String[] matches = frequent_words_with_mismatches(t.text, t.k, t.d);
		test::expect_equal_slices_sorted(t.expected, matches);
	}
}

// Build neighbors by building kmers over the neighborhood of each suffix.
// So basically, start iterating from the last element (as the base suffix)
// neighborhood, and build up kmers within d using the previous neighborhood +
// a prefix element.
fn String[] neighbors(String pattern, int d, Allocator alloc = allocator::heap())
{
	if (d == 0) return {pattern};
	if (pattern.len == 0) return {};
	List(<String>) neighborhood;
	neighborhood.temp_init_with_array({"A", "C", "G", "T"});
	List(<String>) suffix_neighborhood;
	suffix_neighborhood.temp_init();
	for (int i = 1; i < pattern.len; i += 1) {
		// swap suffix_neighborhood and neighborhood. The previous
		// neighborhood becomes the new suffix_neighborhood to iterate
		// over. Now we need a place to collect the next neighborhood into,
		// so we reuse the memory from the old suffix_neighborhood, which is
		// no longer useful for future calculation, as its results have already
		// been moved into the old neighborhood/new suffix_neighborhood as
		// calculated during the last iteration. (otherwise we have to keep
		// allocating new memory to collect the next neighborhood into).
		List(<String>) swap_var;
		swap_var = suffix_neighborhood;
		suffix_neighborhood = neighborhood;
		neighborhood = swap_var;
		neighborhood.clear();

		int suffix_idx = pattern.len - i;
		String suffix = pattern[suffix_idx..];
		//io::printfn("%s, suffix_neighborhood = %s, neighborhood = %s", suffix, suffix_neighborhood, neighborhood);
		foreach (suffix_neighbor : suffix_neighborhood) {
			//io::printfn("%s, %s, %s, %s", suffix, suffix_neighbor, suffix_neighborhood, neighborhood);
			if (hamming_distance(suffix, suffix_neighbor) < d) {
				// adding the additional base will be at most hamming dist == d,
				// TODO we can reuse the memory of neighborhoods by swapping, can we
				// do something about all the new strings?
				neighborhood.push("A".tconcat(suffix_neighbor));
				neighborhood.push("C".tconcat(suffix_neighbor));
				neighborhood.push("G".tconcat(suffix_neighbor));
				neighborhood.push("T".tconcat(suffix_neighbor));
			} else {
				// hamming distance == d. It can't be more, because the neighbors are
				// generated up to hamming distance d. Adding the first symbol from the
				// original pattern cannot increase the hamming distance.
				neighborhood.push(pattern[suffix_idx - 1:1].tconcat(suffix_neighbor));
			}
		}
	}
	String[] res = allocator::new_array(alloc, String, neighborhood.len());
	foreach (i, neighbor : neighborhood) {
		res[i] = neighbor.copy(alloc);
	}
	return res;
}

struct NeighborsTest {
	String text;
	int d;
	String[] expected;
}
fn void test_neighbors() @test {
	NeighborsTest[] tests = {
		{
			.text = "ACG",
			.d = 1,
			.expected = {"ACG", "ACT", "ACA", "ACC", "ATG", "AGG", "AAG", "TCG", "GCG", "CCG"},
		},
		{
			.text = "AGA",
			.d = 0,
			.expected = {"AGA"},
		},
		{
			.text = "AAA",
			.d = 1,
			.expected = {"AAA", "AAC", "AAG", "AAT", "ACA", "AGA", "ATA", "CAA", "GAA", "TAA"},
		},
		{
			.text = "A",
			.d = 1,
			.expected = {"A", "C", "T", "G"},
		},
	};
	foreach (t : tests) {
		String[] matches = neighbors(t.text, t.d);
		test::expect_equal_slices_sorted(t.expected, matches);
	}
}


