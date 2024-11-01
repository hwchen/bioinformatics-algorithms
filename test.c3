module test @test;

macro void expect_equal_slices_sorted(expected, xs) {
	assert(xs.len == expected.len, "Expected %s, found %s", expected, xs);
	foreach (x : xs) {
		bool found = false;
		foreach (exp : expected) {
			if (exp == x) {
				found = true;
			}
		}
		assert(found, "Expected %s, found %s", expected, xs);
	}
}
