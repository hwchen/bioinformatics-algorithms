module ba1b;

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
	String text = io::treadline(&f)!;
	String k_str = io::treadline(&f)!;
	int k = k_str.to_integer(int)!;
	foreach(word: frequent_words(text, k)) {
		io::printf("%s ", word);
	}
	io::printn();
}

fn String[] frequent_words(String text, int k, Allocator alloc= allocator::heap()) {
	@pool() {
		FrequencyTable freq_map = util::frequency_table(text, k, allocator::temp());

		int[] counts = freq_map.value_tlist();
		int max = 0;
		freq_map.@each(; String _k, int count) {
			if (count > max) max = count;
		};

		List(<String>) res;
		res.temp_init();
		freq_map.@each(; String key, int v) {
			if (v == max) {
				res.push(key.copy(alloc));
			}
		};
		return res.to_new_array(alloc);
	};
}

fn void test_frequent_words() @test {
	io::printfn("%s", frequent_words("ACGTTGCATGTCGCATGATGCATGAGAGCT", 4));
	assert(frequent_words("ACGTTGCATGTCGCATGATGCATGAGAGCT", 4) == {"CATG", "GCAT"});
}
