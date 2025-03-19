module util;
import std::collections;
import std::core::mem;
import std::core::string;
import std::io;
import std::sort;

import test;

fn String reverse_complement(String pattern, Allocator alloc = allocator::heap()) {
	char[] s = allocator::alloc_array(alloc, char, pattern.len);
	foreach (i, c : pattern) {
		ulong idx = s.len - i - 1;
		switch (c) {
			case 'A': s[idx] = 'T';
			case 'C': s[idx] = 'G';
			case 'T': s[idx] = 'A';
			case 'G': s[idx] = 'C';
			default: $$unreachable();
		}
	}
	return (String)s;
}

fn void test_reverse_complement() @test {
	assert(reverse_complement("AAAACCCGGT", tmem()) == "ACCGGGTTTT");
}

alias FrequencyTable = HashMap{String, int};

// counts of kmers in a text.
// Lifetime of result is same as that of `text` param.
fn FrequencyTable frequency_table(String text, int k, Allocator alloc = allocator::heap()) {
	FrequencyTable kmer_counts;
	kmer_counts.init(allocator: alloc);
	for (int i = 0; i <= text.len - k; i += 1) {
		// TODO get_or_update? Annoying to get twice
		// Modified std so that hashmap doesn't copy keys, but these
		// keys lifetime is the same as `text`.
		String key = text[i:k];
		kmer_counts.@get_or_set(key, 0);
		if (try count = kmer_counts.get_ref(key)) {
			*count += 1;
		}
	}
	return kmer_counts;
}

// Lifetime of result is that of the `genome` param.
fn String[] clump_finding(
	String genome,
	int k,
	int region_len, // L
	int clump_threshold, // t
	Allocator alloc = allocator::heap())
{
	if (k == 0 || genome.len == 0) return {};
	HashMap{String, char} clumps; // a set
	@pool() {
		clumps.tinit();
		for (int i = 0; i <= genome.len - region_len; i += 1) {
			@pool() {
				FrequencyTable freq_map = frequency_table(genome[i:region_len], k, tmem());
				freq_map.@each(; String kmer, int count) {
					if (count >= clump_threshold) {
						// TODO can probably just use a growable array on small inputs
						// std hashmap modified to not copy keys, lifetime of kmer is that of
						// the `genome` param
						clumps.set(kmer, 0);
					}
				};
			};
		}
		return clumps.keys(alloc);
	};
}

fn void test_clump_finding() @test {
    String input = "CGGACTCGACAGATGTGAAGAACGACAATGTGAAGACTCGACACGACAGAGTGAAGAGAAGAGGAAACATTGTAA";
	assert(clump_finding(input, 5, 50, 4, tmem()) == {"CGACA", "GAAGA"});
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
	List{int} res;
	@pool() {
		res.tinit();
		for (int i = 0; i <= genome.len - pattern.len; i += 1) {
			// TODO more efficient to break early when calculating hamming distance
			if (util::hamming_distance(genome[i:pattern.len], pattern) <= d) {
				res.push(i);
			}
		}
		return res.to_array(alloc);
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
		int[] matches = approximate_pattern_matching(t.pattern, t.genome, t.d, tmem());
		assert(matches == t.expected, "Expected %s, found %s", t.expected, matches);
	}
}

// Just like frequent words, except instead of matching just each kmer,
// we create a neighbohood(d) for each kmer and that neighborhood is compared against the text
fn String[] _frequent_words_with_mismatches(
	String text,
	int k,
	int d,
	bool with_rc,
	Allocator alloc= allocator::heap())
{
	@pool() {
		if (with_rc) {
			text = text.tconcat(reverse_complement(text, allocator::temp()));
		}
		FrequencyTable freq_map;
		freq_map.init(allocator: alloc);
		for (int i = 0; i <= text.len - k; i += 1) {
			String pattern = text[i:k];
			String[] neighborhood = neighbors(pattern, d, allocator::temp());
			foreach (neighbor : neighborhood) {
				freq_map.@get_or_set(neighbor, 0);
				if (try int* count = freq_map.get_ref(neighbor)) {
					*count += 1;
				}
			}
		}

		int[] counts = freq_map.tvalues();
		int max = 0;
		freq_map.@each(; String _k, int count) {
			if (count > max) max = count;
		};

		List{String} res;
		res.tinit();
		freq_map.@each(; String key, int v) {
			if (v == max) {
				res.push(key.copy(alloc));
			}
		};
		return res.to_array(alloc);
	};
}

fn String[] frequent_words_with_mismatches(String text, int k, int d, Allocator alloc= allocator::heap()) {
	return _frequent_words_with_mismatches(text, k, d, false, alloc);
}
fn String[] frequent_words_with_mismatches_and_rc(String text, int k, int d, Allocator alloc= allocator::heap()) {
	return _frequent_words_with_mismatches(text, k, d, true, alloc);
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
		@pool() {
			String[] matches = frequent_words_with_mismatches(t.text, t.k, t.d, tmem());
			test::expect_equal_slices_sorted(t.expected, matches);
		};
	}
}
fn void test_frequent_words_with_mismatches_and_rc() @test {
	FreqWordsMismatchesTest[] tests = {
		{
			.text = "ACGTTGCATGTCGCATGATGCATGAGAGCT",
			.k = 4,
			.d = 1,
			.expected = {"ATGT", "ACAT"},
		},
	};
	foreach (t : tests) {
		String[] matches = frequent_words_with_mismatches_and_rc(t.text, t.k, t.d, tmem());
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
	@pool() {
		DynamicArenaAllocator neighborhood_arena;
		DynamicArenaAllocator suffix_neighborhood_arena;
		neighborhood_arena.init(tmem(), 1024);
		suffix_neighborhood_arena.init(tmem(), 1024);
		List{String} neighborhood;
		List{String} suffix_neighborhood;
		neighborhood.init_with_array(&neighborhood_arena, {"A", "C", "G", "T"});
		suffix_neighborhood.init(&suffix_neighborhood_arena, 16);
		for (int i = 1; i < pattern.len; i += 1) {
			// swap suffix_neighborhood and neighborhood. The previous
			// neighborhood becomes the new suffix_neighborhood to iterate
			// over. Now we need a place to collect the next neighborhood into,
			// so we reuse the memory from the old suffix_neighborhood, which is
			// no longer useful for future calculation, as its results have already
			// been moved into the old neighborhood/new suffix_neighborhood as
			// calculated during the last iteration. (otherwise we have to keep
			// allocating new memory to collect the next neighborhood into).
			//
			// The memory itself is cleared for reuse by the arena holding the
			// List (see next swap)
			List{String} swap_var;
			swap_var = suffix_neighborhood;
			suffix_neighborhood = neighborhood;
			neighborhood = swap_var;

			// Same swap with the arenas
			// Old strings and the List holding them all get cleared
			DynamicArenaAllocator swap_arena;
			swap_arena = suffix_neighborhood_arena;
			suffix_neighborhood_arena = neighborhood_arena;
			neighborhood_arena = swap_arena;

			// clear out the old neighborhood for use in next iteration
			neighborhood_arena.free();
			neighborhood.init(&neighborhood_arena, suffix_neighborhood.len(),);

			int suffix_idx = pattern.len - i;
			String suffix = pattern[suffix_idx..];
			//io::printfn("%s, suffix_neighborhood = %s, neighborhood = %s", suffix, suffix_neighborhood, neighborhood);
			foreach (suffix_neighbor : suffix_neighborhood) {
				//io::printfn("%s, %s, %s, %s", suffix, suffix_neighbor, suffix_neighborhood, neighborhood);
				if (hamming_distance(suffix, suffix_neighbor) < d) {
					// adding the additional base will be at most hamming dist == d,
					neighborhood.push("A".concat(&suffix_neighborhood_arena, suffix_neighbor));
					neighborhood.push("C".concat(&suffix_neighborhood_arena, suffix_neighbor));
					neighborhood.push("G".concat(&suffix_neighborhood_arena, suffix_neighbor));
					neighborhood.push("T".concat(&suffix_neighborhood_arena, suffix_neighbor));
				} else {
					// hamming distance == d. It can't be more, because the neighbors are
					// generated up to hamming distance d. Adding the first symbol from the
					// original pattern cannot increase the hamming distance.
					neighborhood.push(pattern[suffix_idx - 1:1].concat(&suffix_neighborhood_arena, suffix_neighbor,));
				}
			}
		}

		// Copy strings out to final result's allocator
		String[] res = allocator::new_array(alloc, String, neighborhood.len());
		foreach (i, neighbor : neighborhood) {
			res[i] = neighbor.copy(alloc);
		}
		return res;
	};
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
		String[] matches = neighbors(t.text, t.d, tmem());
		test::expect_equal_slices_sorted(t.expected, matches);
	}
}
