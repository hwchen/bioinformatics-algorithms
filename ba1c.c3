// reverse complement

module ba1c;

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
	io::printfn(util::reverse_complement(pattern));
	return 0;
}
