// clump finding from inputs
// args are:
// - genome
// - k (word length)
// - L (region length)
// - t (threshold number for frequent word to qualify as clump)

module clump_finding;
import std::io;
import std::io::file;
import std::collections;

import util;

fn void! main(String[] args) {
	if (args.len != 5) {
		io::eprintn("Please supply path, k, L, t to data file");
		return IoError.FILE_NOT_FOUND?;
	}
	File! f = file::open(args[1], "rb");
	if (catch err = f) {
		io::eprintn("Missing data file");
		return IoError.FILE_NOT_FOUND?;
	}
	defer (void)f.close();
	String genome = (String)io::read_new_fully(&f)!;
	int k = args[2].to_integer(int)!;
	int region_len = args[3].to_integer(int)!; // L
	int clump_threshold = args[4].to_integer(int)!; // t
	String[] clumps = util::clump_finding(genome, k, region_len, clump_threshold);
	io::printfn("%s ", clumps.len);
}

