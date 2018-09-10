package;

import react.Partial;

typedef ABCD = {
	a:String,
	b:String,
	c:FromString,
	d:FromIntWithFunction
}

abstract FromString(Dynamic) from String {}

abstract FromIntWithFunction(String) to String {
	@:from
	static public function fromInt(i:Int)
	{
		return cast (i == 42 ? "the answer" : "something");
	}
}

class Main {
	public static function main() {
		make_fields_optional();
		supports_abstracts();
		supports_abstracts_with_from();
	}

	static function make_fields_optional() {
		var test:Partial<ABCD> = {
			a: "a",
			b: "b"
		};

		if (test.a != "a") throw "";
		if (test.b != "b") throw "";
	}

	static function supports_abstracts()
	{
		var test:Partial<ABCD> = {
			c: "test"
		};

		if (test.c != "test") throw "";
	}

	static function supports_abstracts_with_from()
	{
		var test:Partial<ABCD> = {
			d: 42
		};

		if (test.d != "the answer") throw "";
	}
}
