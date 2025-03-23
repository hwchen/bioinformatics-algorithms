// minimum skew

module ba1f;
import std::io;
import std::io::file;
import std::collections;

import util;

alias IntList = List{ulong};

fn int main(String[] args) {
	if (args.len != 2) {
		io::eprintn("Please supply path to data file");
		return 1;
	}
	File f = file::open(args[1], "rb")!!;
	String genome = io::treadline(&f)!!;
	ulong[] min_skew_idxs = minimum_skew_idxs(genome);
	foreach (i : min_skew_idxs) {
		io::printf("%d ", i);
	}
	return 0;
}

// TODO use min heap
fn ulong[] minimum_skew_idxs(String genome, Allocator alloc = allocator::heap()) {
	IntList idxs;
	idxs.tinit();
	int min_skew = 0;
	int skew = 0;
	foreach (i, base : genome) {
		// skew[0] is 0, skew[1] is the skew
		// after genome[0]
		ulong skew_idx = i + 1;
		switch (base) {
			case 'C': skew -= 1;
			case 'G': skew += 1;
		}
		switch {
			case skew < min_skew:
				min_skew = skew;
				idxs.clear();
				idxs.push(skew_idx);
			case skew == min_skew:
				idxs.push(skew_idx);
		}
	}
	return idxs.to_array(alloc);
}

fn void test_minimum_skew_idxs() @test {
	assert(minimum_skew_idxs("TAAAGACTGCCGAGAGGCCAACACGAGTGCTAGAACGAGGGGCGTAAACGCGGGTCCGAT", tmem) == {11, 24});
}
