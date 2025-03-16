// Frequent words with mismatches

module ba1i;
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
	String genome = io::treadline(&f)!!;
	String ints = io::treadline(&f)!!;
	String[] ints_split = ints.tsplit(" ");
	int k = ints_split[0].to_integer(int)!!;
	int d = ints_split[1].to_integer(int)!!;
	String[] matches = util::frequent_words_with_mismatches(genome, k, d);
	foreach (match : matches) {
		io::printf("%s ", match);
	}
	return 0;
}
