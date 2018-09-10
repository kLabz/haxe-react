package react;

#if macro
import haxe.macro.Context.*;
import haxe.macro.Expr;
using tink.MacroApi;
#end

@:forward
abstract Partial<T>(T) {
	@:from static macro function ofAny(e:Expr) {
		var expected = getExpectedType();

		var ret = switch followWithAbstracts(expected) {
			case TDynamic(_): e;
			case TAnonymous(_.get().fields => fields):

				var found = switch followWithAbstracts(typeof(e)) {
					case TAnonymous(a): a.get().fields;
					case t: e.reject('$t should be anonymous object');
				}

				var decl = EObjectDecl([
					for (f in found) {
						var name = f.name;
						{
							field: name,
							expr: macro @:pos(f.pos) o.$name
						}
					}
				]).at(e.pos);

				var t = TAnonymous([
					for (f in fields) {
						name: f.name,
						pos: e.pos,
						kind: FProp('default', 'never', f.type.toComplex()),
						meta: [{ name: ':optional', params: [], pos: e.pos }]
					}
				]);


				macro @:pos(e.pos) {
					var o = $e;
					($decl:$t);
				}
			case v:
				fatalError('Cannot have partial $v', currentPos());
		}

		var et = expected.toComplex();
		return macro @:pos(e.pos) (cast $ret:$et);
	}
}
