// clump finding

module ba1e;
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
	String genome = io::treadline(&f)!;
	String ints = io::treadline(&f)!;
	String[] ints_split = ints.tsplit(" ");
	int k = ints_split[0].to_integer(int)!;
	int region_len = ints_split[1].to_integer(int)!; // L
	int clump_threshold = ints_split[2].to_integer(int)!; // t
	String[] clumps = util::clump_finding(genome, k, region_len, clump_threshold);
	foreach (clump : clumps) {
		io::printf("%s ", clump);
	}
}
