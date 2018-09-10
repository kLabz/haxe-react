import haxe.macro.Context;
import haxe.macro.Expr;
import massive.munit.Assert;

class AssertTools
{
	macro static public function assertHasProps(oExpr:Expr, namesExpr:ExprOf<Array<String>>, ?valuesExpr:ExprOf<Array<Dynamic>>)
	{
		return macro {
			var o:Dynamic = ${oExpr}, names:Array<String> = ${namesExpr}, values:Array<Dynamic> = ${valuesExpr};
			var props = Reflect.fields(o);
			Assert.areEqual(names.length, props.length);
			for (i in 0...names.length)
			{
				var name = names[i];
				Assert.areNotEqual( -1, props.indexOf(name));
				if (values != null && values[i] != null)
					Assert.areEqual(values[i], Reflect.field(o, name));
			}
		}
	}

	// Thanks to back2dos: https://github.com/back2dos/travix/issues/19#issuecomment-222100034
	macro static public function assertCompilationFails(e:Expr, with:String) {
		try {
			Context.typeof(e);
			return macro Assert.areEqual('Compilation failure', 'Successful compilation');
		} catch (ex:Dynamic) {
			var exception = trimLines(Std.string(ex));
			return macro Assert.areEqual($v{exception}, $v{with});
		}
	}

	static function trimLines(str:String):String {
		return str.split("\n").map(function(l) return StringTools.trim(l)).join("\n");
	}
}
