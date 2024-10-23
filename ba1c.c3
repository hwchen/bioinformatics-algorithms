// reverse complement

module ba1c;

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
	io::printfn(reverse_complement(pattern));
}

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
	assert(reverse_complement("AAAACCCGGT") == "ACCGGGTTTT");
}
