// approximate pattern match

module ba1h;
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
	String pattern = io::treadline(&f)!!;
	String genome = io::treadline(&f)!!;
	String d_str = io::treadline(&f)!!;
	int d = d_str.to_integer(int)!!;
	int[] matches = util::approximate_pattern_matching(pattern, genome, d);
	foreach (match : matches) {
		io::printf("%d ", match);
	}
	return 0;
}
