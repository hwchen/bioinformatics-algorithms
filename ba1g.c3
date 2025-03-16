// hamming distance

module ba1g;
import std::io;
import std::io::file;
import std::collections;

import util;

fn int main(String[] args) {
	if (args.len != 2) {
		io::eprintn("Please supply path to data file");
		return 1;
	}
	File f = file::open(args[1], "rb")!!;
	String s1 = io::treadline(&f)!!;
	String s2 = io::treadline(&f)!!;
	io::printn(util::hamming_distance(s1, s2));
	return 0;
}
