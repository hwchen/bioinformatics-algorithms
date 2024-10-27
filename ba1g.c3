// hamming distance

module ba1g;
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
	String s1 = io::treadline(&f)!;
	String s2 = io::treadline(&f)!;
	io::printn(util::hamming_distance(s1, s2));
}
