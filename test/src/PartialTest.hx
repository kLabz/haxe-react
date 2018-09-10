package;

import massive.munit.Assert;
import react.Partial;

typedef ABCD = {
	a:String,
	b:String,
	c:FromString,
	d:FromIntWithFunction
}

abstract FromString(Dynamic) from String {}

abstract FromIntWithFunction(String) {
	@:from
	static public function fromInt(i:Int)
	{
		return cast (i == 42 ? "the answer" : "something");
	}
}

class PartialTest
{
	public function new() {}

	@Test
	public function make_fields_optional()
	{
		var test:Partial<ABCD> = {
			a: "a",
			b: "b"
		};

		Assert.areEqual(test.a, "a");
	}

	@Test
	public function fields_keep_their_type()
	{
		AssertTools.assertCompilationFails({
			var test:react.Partial<ABCD> = {a: 42};
		}, "Int should be Null<String>\nInt should be String");
	}

	@Test
	public function cannot_add_extra_fields()
	{
		AssertTools.assertCompilationFails({
			var test:react.Partial<ABCD> = {a: "42", e: "test"};
		}, "{ e : String, a : String } has extra field e");
	}

	@Test
	public function supports_abstracts()
	{
		var test:Partial<ABCD> = {
			c: "test"
		};

		Assert.areEqual(test.c, "test");
	}

	@Test
	public function supports_abstract_with_from()
	{
		var test:Partial<ABCD> = {
			d: 42
		};

		Assert.areEqual(test.d, "the answer");
	}
}
