module ba1a;

import std::io;
import std::io::file;
import std::collections;

fn void! main(String[] args) {
	if (args.len != 2) {
		io::eprintn("Please supply path to data file");
		return IoError.FILE_NOT_FOUND?;
	}
	File f = file::open(args[1], "rb")!;
	String text = io::treadline(&f)!;
	String pattern = io::treadline(&f)!;
	io::printn(pattern_count(text, pattern));
}

fn int pattern_count(String text, String pattern) {
	if (pattern.len == 0) return 0;
	int count = 0 ;
	for (int i = 0; i <= text.len - pattern.len; i += 1) {
		if (text[i:pattern.len] == pattern) {
			count += 1;
		}
	}
	return count;
}

fn void test_pattern_count() @test {
	assert(pattern_count("GCGCG", "") == 0);
	assert(pattern_count("GCGCG", "G") == 3);
	assert(pattern_count("GCGCG", "GCG") == 2);
}

