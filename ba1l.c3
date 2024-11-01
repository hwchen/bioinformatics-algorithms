// Neighbors

module ba1l;
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
	String pattern = io::treadline(&f)!;
	int d = io::treadline(&f)!.to_integer(int)!;
	String[] matches = util::neighbors(pattern, d);
	foreach (match : matches) {
		io::printf("%s ", match);
	}
}


