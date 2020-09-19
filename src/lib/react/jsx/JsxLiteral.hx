package react.jsx;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import react.macro.ReactComponentMacro;

#if (haxe_ver < 4)
private typedef ObjectField = {field:String, expr:Expr};
#end

class JsxLiteral {
	static public function genLiteral(type:Expr, props:Expr, ref:Expr, key:Expr, pos:Position)
	{
		if (key == null) key = macro null;
		if (ref == null) ref = macro null;

		var fields:Array<ObjectField> = [
			#if haxe4
			{field: "$$typeof", quotes: Quoted, expr: macro js.Syntax.code("$$tre")},
			#else
			{field: "@$__hx__$$typeof", expr: macro untyped __js__("$$tre")},
			#end
			{field: 'type', expr: macro (${type} : react.ReactType)},
			{field: 'props', expr: props}
		];

		if (key != null) fields.push({field: 'key', expr: key});
		if (ref != null) fields.push({field: 'ref', expr: ref});
		var obj = {expr: EObjectDecl(fields), pos: pos};

		return macro @:pos(pos) ($obj : react.ReactComponent.ReactElement);
	}

	static public function canUseLiteral(typeInfo:ComponentInfo, ref:Expr)
	{
		#if (debug || react_no_inline)
		return false;
		#end

		// do not use literals for externs: we don't know their defaultProps
		if (typeInfo != null && typeInfo.isExtern) return false;

		// no ref is always ok
		if (ref == null) return true;

		// only refs as functions are allowed in literals, strings require the full createElement context
		return switch (Context.typeof(ref)) {
			case TFun(_): true;
			default: false;
		}
	}
}
#end
