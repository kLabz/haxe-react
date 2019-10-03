package react.jsx;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import react.macro.MacroUtil;

using haxe.macro.Tools;

private typedef JsxStaticDecl = {
	var module:String;
	var className:String;
	var displayName:String;
	var fieldName:String;
}

private enum MetaValueType {
	NoMeta;
	NoParams(meta:MetadataEntry);
	WithParams(meta:MetadataEntry, params:Array<Expr>);
}

@:dce
class JsxStaticMacro
{
	static public inline var DISALLOW_IN_REACT_COMPONENT_BUILDER = 'JsxStaticDisallowInReactComponent';
	static public inline var META_NAME = ':jsxStatic';
	static public inline var FIELD_NAME = '__jsxStatic';

	static var decls:Array<JsxStaticDecl> = [];

	static public function build():Array<Field>
	{
		var cls = Context.getLocalClass();
		if (cls == null) return null;
		var inClass = cls.get();

		if (inClass.meta.has(META_NAME))
		{
			var fields = Context.getBuildFields();
			var proxyName = extractMetaString(inClass.meta, META_NAME);
			if (proxyName == null) return null;

			var metaPos = inClass.meta.extract(META_NAME)[0].pos;
			var pos = inClass.meta.extract(META_NAME)[0].params[0].pos;

			for (f in fields) {
				if (f.name == FIELD_NAME) return null;

				#if (haxe4 && react_auto_jsx)
				if (f.name == proxyName) react.jsx.JsxMacro.wrapMarkupInField(f);
				#end
			}

			fields.push({
				access: [APublic, AStatic],
				name: FIELD_NAME,
				#if react_check_jsxstatic_type
				kind: FVar(macro :react.ReactType, macro @:pos(pos) $i{proxyName}),
				#else
				kind: FVar(null, macro $i{proxyName}),
				#end
				doc: null,
				meta: null,
				pos: metaPos
			});

			return fields;
		}

		return null;
	}

	static public function disallowInReactComponent(
		inClass:ClassType,
		fields:Array<Field>
	):Array<Field> {
		if (inClass.meta.has(META_NAME))
			Context.error(
				'@${META_NAME} cannot be used on ReactComponent classes.',
				inClass.meta.extract(META_NAME)[0].pos
			);

		return fields;
	}

	static public function addHook()
	{
		// Add hook to generate __init__ at the end of the compilation
		Context.onAfterTyping(afterTypingHook);
	}

	static public function injectDisplayNames(type:Expr)
	{
		#if !debug
		return;
		#end

		switch (Context.typeExpr(type).expr) {
			case TConst(TString(_)):
				// HTML component, nothing to do

			case TTypeExpr(TClassDecl(_)):
				// ReactComponent, should already handle its displayName

			case TField(_, FStatic(clsTypeRef, _.get() => {kind: FMethod(_), name: fieldName})):
				var clsType = clsTypeRef.get();
				var displayName = handleJsxStaticMeta(clsType, fieldName);

				addDisplayNameDecl({
					module: clsType.module,
					className: clsType.name,
					displayName: displayName,
					fieldName: fieldName
				});

			case TCall({expr: TField(_, FStatic(clsTypeRef, clsField))}, _):
				var clsType = clsTypeRef.get();
				var fieldName = clsField.get().name;
				var displayName = StringTools.startsWith(fieldName, 'get_')
					? handleJsxStaticMeta(clsType, fieldName.substr(4))
					: fieldName;

				addDisplayNameDecl({
					module: clsType.module,
					className: clsType.name,
					displayName: displayName,
					fieldName: fieldName
				});

			case TLocal({name: varName}):
				// Local vars not handled at the moment

			case TField(_, FInstance(_, _, _)):
				// Instance fields not handled at the moment

			case TField(_, FStatic(_, _)):
				// Static variables not handled at the moment

			default:
				// Unknown type, not handled
				// trace(typedExpr);
		}
	}

	static public function handleJsxStaticProxy(type:Expr)
	{
		var typedExpr = Context.typeExpr(type);

		switch (typedExpr.expr)
		{
			case TTypeExpr(TClassDecl(_.get() => c)):
				if (c.meta.has(META_NAME))
					type.expr = EField(
						{expr: EConst(CIdent(c.name)), pos: type.pos},
						extractMetaString(c.meta, META_NAME)
					);

			default:
		}
	}

	static function extractMeta(meta:MetaAccess, name:String):MetaValueType
	{
		if (!meta.has(name)) return NoMeta;

		var metas = meta.extract(name);
		if (metas.length == 0) return NoMeta;

		var meta = metas.pop();
		var params = meta.params;
		if (params.length == 0) return NoParams(meta);

		return WithParams(meta, params);
	}

	static public function extractMetaString(meta:MetaAccess, name:String):String
	{
		return switch(extractMeta(meta, name)) {
			case NoMeta: null;

			case WithParams(_, params):
				var param = params[0];
				var name = MacroUtil.extractMetaString(param);
				if (name == null) {
					Context.fatalError(
						'@${META_NAME}: invalid parameter. Expected static function name.',
						param.pos
					);
				}
				name;

			case NoParams(meta):
				Context.fatalError(
					'Parameter required for @${META_NAME}(nameOfStaticFunction)',
					meta.pos
				);
		};
	}

	static function handleJsxStaticMeta(clsType:ClassType, displayName:String)
	{
		var jsxStatic = extractMetaString(clsType.meta, META_NAME);
		if (jsxStatic != null && jsxStatic == displayName) return clsType.name;
		return displayName;
	}

	static function addDisplayNameDecl(decl:JsxStaticDecl)
	{
		var previousDecl = Lambda.find(decls, function(d) {
			return d.module == decl.module
				&& d.className == decl.className
				&& d.fieldName == decl.fieldName;
		});

		if (previousDecl == null) decls.push(decl);
	}

	static function afterTypingHook(modules:Array<ModuleType>)
	{
		var initModule = "JsxStaticInit__";

		try {
			Context.getType(initModule);
			return;
		}
		catch (e:Dynamic) {}

		var exprs = decls.map(function(decl) {
			var fName = decl.fieldName;
			return macro {
				untyped $i{decl.className}.$fName.displayName =
				$i{decl.className}.$fName.displayName || $v{decl.displayName};
			};
		});

		var cls = macro class $initModule {
			static function __init__() {
				$a{exprs};
			}
		};

		var imports = decls.map(function(decl) return generatePath(decl.module));
		Context.defineModule(initModule, [cls], imports);
	}

	static function generatePath(module:String)
	{
		var parts = module.split('.');

		return {
			mode: ImportMode.INormal,
			path: parts.map(function(part) return {pos: (macro null).pos, name: part})
		};
	}
}
