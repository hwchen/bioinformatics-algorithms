module util;
import std::collections;

def FrequencyTable = HashMap(<String, int>);

// counts of kmers in a text.
fn FrequencyTable frequency_table(String text, int k, Allocator alloc = allocator::heap()) {
	FrequencyTable kmer_counts;
	kmer_counts.new_init(allocator: alloc);
	for (int i = 0; i <= text.len - k; i += 1) {
		// TODO get_or_update? Annoying to get twice
		kmer_counts.@get_or_set(text[i:k].copy(alloc), 0);
		if (try int* count = kmer_counts.get_ref(text[i:k])) {
			*count += 1;
		}
	}
	return kmer_counts;
}
