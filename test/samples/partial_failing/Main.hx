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
		fields_keep_their_type();
		cannot_add_extra_fields();
	}

	static function fields_keep_their_type()
	{
		var test:react.Partial<ABCD> = {a: 42};
	}

	static function cannot_add_extra_fields()
	{
		var test:react.Partial<ABCD> = {a: "42", e: "test"};
	}
}

