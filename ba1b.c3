module ba1b;

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
	String text = io::treadline(&f)!!;
	String k_str = io::treadline(&f)!!;
	int k = k_str.to_integer(int)!!;
	foreach(word: frequent_words(text, k)) {
		io::printf("%s ", word);
	}
	io::printn();
	return 0;
}

fn String[] frequent_words(String text, int k, Allocator alloc= allocator::heap()) {
	@pool() {
		FrequencyTable freq_map = util::frequency_table(text, k, allocator::temp());

		int[] counts = freq_map.tvalues();
		int max = 0;
		freq_map.@each(; String _k, int count) {
			if (count > max) max = count;
		};

		List{String} res;
		res.tinit();
		freq_map.@each(; String key, int v) {
			if (v == max) {
				res.push(key.copy(alloc));
			}
		};
		return res.to_array(alloc);
	};
}

fn void test_frequent_words() @test {
	String[] words = frequent_words("ACGTTGCATGTCGCATGATGCATGAGAGCT", 4, tmem());
	assert(words.len == 2);
	assert(words.contains("CATG"));
	assert(words.contains("GCAT"));
}
fn bool String[].contains(ss, String target) {
	foreach (s : ss) {
		if (s == target) {
			return true;
		}
	}
	return false;
}
