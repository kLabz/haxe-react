package react.macro;

#if macro
import haxe.macro.ComplexTypeTools;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Type;
import haxe.macro.TypeTools;

import react.jsx.JsxStaticMacro;

typedef Builder = ClassType -> Array<Field> -> Array<Field>;
typedef BuilderWithKey = {?key:String, build:Builder};

#if (haxe_ver < 4)
private typedef ObjectField = {field:String, expr:Expr};
#end

typedef ComponentInfo = {
	isExtern:Bool,
	ref:Expr,
	tprops:Null<ComplexType>,
	props:Array<ObjectField>
}

typedef ExtendedObjectField = {
	> ObjectField,
	?isConstant:Bool
}

@:dce
class ReactComponentMacro {
	static public inline var REACT_COMPONENT_BUILDER = "ReactComponent";
	@:deprecated static public inline var ACCEPTS_MORE_PROPS_META = ReactMeta.AcceptsMoreProps;

	#if (js_es == '6')
	static public inline var ES6_CONSTRUCTOR_FIX = "ReactComponent_ES6_CONSTRUCTOR_FIX";
	#end

	static var componentsMap:Map<String, ComponentInfo> = new Map();

	static var builders:Array<BuilderWithKey> = [
		{build: buildComponent, key: REACT_COMPONENT_BUILDER},

		#if (haxe4 && react_auto_jsx)
		{build: react.jsx.JsxMacro.handleMarkup, key: "todo"},
		#end

		{build: ContextMacro.buildComponent, key: ContextMacro.REACT_CONTEXT_BUILDER},
		{build: ReactTypeMacro.alterComponentSignatures, key: ReactTypeMacro.ALTER_SIGNATURES_BUILDER},

		// Disable unneeded builders for completion
		#if !display
		{build: JsxStaticMacro.disallowInReactComponent, key: JsxStaticMacro.DISALLOW_IN_REACT_COMPONENT_BUILDER},
		#end

		{build: ReactWrapperMacro.buildComponent, key: ReactWrapperMacro.WRAP_BUILDER},
		{build: PureComponentMacro.buildComponent, key: PureComponentMacro.PURE_COMPONENT_BUILDER},

		// Disable unneeded builders for completion
		#if !display
		#if !react_ignore_empty_render
		{build: ReactTypeMacro.ensureRenderOverride, key: ReactTypeMacro.ENSURE_RENDER_OVERRIDE_BUILDER},
		#end

		#if debug
		{build: ReactTypeMacro.checkGetDerivedState, key: ReactTypeMacro.CHECK_GET_DERIVED_STATE_BUILDER},
		#end

		#if (debug && react_runtime_warnings)
		{build: ReactDebugMacro.buildComponent, key: ReactDebugMacro.REACT_DEBUG_BUILDER},
		#end
		#end

		#if (js_es == '6')
		{build: fixES6Constructor, key: ES6_CONSTRUCTOR_FIX},
		#end
	];

	static public function appendBuilder(builder:Builder, ?key:String):Void {
		builders.push({build: builder, key: key});
	}

	static public function prependBuilder(builder:Builder, ?key:String):Void {
		builders.unshift({build: builder, key: key});
	}

	static public function hasBuilder(key:String):Bool {
		if (key == null) return false;
		return Lambda.exists(builders, function(b) return b.key == key);
	}

	static public function insertBuilderBefore(before:String, builder:Builder, ?key:String):Void {
		var index = -1;
		if (before != null) {
			for (i in 0...builders.length) {
				if (builders[i].key == before) {
					index = i;
					break;
				}
			}
		}

		if (index == -1) return appendBuilder(builder, key);
		builders.insert(index, {build: builder, key: key});
	}

	static public function insertBuilderAfter(after:String, builder:Builder, ?key:String):Void {
		var index = -1;
		if (after != null) {
			for (i in 0...builders.length) {
				if (builders[i].key == after) {
					index = i + 1;
					break;
				}
			}
		}

		if (index == -1) return appendBuilder(builder, key);
		builders.insert(index, {build: builder, key: key});
	}

	static public function build():Array<Field> {
		var inClass = Context.getLocalClass().get();

		#if !react_skip_extend_component_restriction
		if (!inClass.isExtern) {
			switch (inClass.superClass) {
				case {params: params, t: _.toString() => cls}
				if (cls == 'react.ReactComponentOf' || cls == 'react.PureComponentOf'):
					// Ok

				default:
					Context.fatalError(
						'A react component must be a direct child of either `ReactComponent` or `PureComponent`.',
						inClass.pos
					);
			}
		}
		#end

		return Lambda.fold(
			builders,
			function(builder, fields) return builder.build(inClass, fields),
			Context.getBuildFields()
		);
	}

	/* METADATA */

	static public function buildVariadic():ComplexType {
		return switch (Context.getLocalType()) {
			case TInst(_, []):
				#if react_disable_dynamic_components
				return macro :react.ReactComponent.ReactComponentOf<react.Empty, react.Empty>;
				#else
				return macro :react.ReactComponent.ReactComponentOf<Dynamic, Dynamic>;
				#end

			case TInst(_, [tprops]):
				var ctprops = TypeTools.toComplexType(tprops);
				return macro :react.ReactComponent.ReactComponentOf<$ctprops, Empty>;

			case TInst(_, [tprops, tstate]):
				var ctprops = TypeTools.toComplexType(tprops);
				var ctstate = TypeTools.toComplexType(tstate);
				return macro :react.ReactComponent.ReactComponentOf<$ctprops, $ctstate>;

			default: throw false;
		}
	}

	/**
	 * Process React components
	 */
	static public function buildComponent(inClass:ClassType, fields:Array<Field>):Array<Field> {
		var pos = Context.currentPos();

		#if (!debug && !react_no_inline)
		storeComponentInfos(fields, inClass, pos);
		#end

		if (!inClass.isExtern)
			tagComponent(fields, inClass, pos);

		return fields;
	}

	#if (js_es == '6')
	// Rewrite field inits for ES6 generator: remove init expressions and move
	// them right after super() call
	// Note: it's safe because if you use those fields before super() call, haxe
	// will see it and generate "Must call `super()` [...]" error accordingly
	static public function fixES6Constructor(inClass:ClassType, fields:Array<Field>):Array<Field> {
		var fieldInits = [];
		var constructor:Null<Field> = null;

		function registerInit(f:Field, t:Null<ComplexType>, e:Expr):ComplexType {
			var fname = f.name;
			fieldInits.push(macro this.$fname = $e);

			// Guess constant types
			if (t == null) {
				switch (e.expr) {
					case EConst(c):
						t = switch (c) {
							case CInt(_): macro :Int;
							case CFloat(_): macro :Float;
							case CString(_, _): macro :String;
							case CRegexp(_, _): macro :EReg;
							case CIdent('true') | CIdent('false'): macro :Bool;
							case CIdent(_): null;
						};

					case _:
				}
			}

			if (t == null) {
				// Rewrite error to remove the confusing part
				// Need to use fatal error to make sure the build macro
				// chain stops and this error is not shadowed by some
				// unexpected side effect
				Context.fatalError('Variable requires type-hint', f.pos);
			}

			return t;
		}

		for (f in fields) {
			if (f.name == "new") {
				constructor = f;
				continue;
			}

			if (f.access != null && Lambda.has(f.access, AStatic)) continue;

			switch (f.kind) {
				case FVar(_, null) | FProp(_, _, _, null) | FFun(_):

				case FVar(t, e):
					t = registerInit(f, t, e);
					f.kind = FVar(t, null);

				case FProp(g, s, t, e):
					t = registerInit(f, t, e);
					f.kind = FProp(g, s, t, null);
			}
		}

		if (fieldInits.length > 0) {
			if (constructor == null) {
				fields.push((macro class {
					public function new(props) {
						super(props);
						@:mergeBlock $b{fieldInits};
					}
				}).fields[0]);
			} else {
				switch (constructor.kind) {
					case FFun(f):
						function mapExpr(e) {
							return switch (e.expr) {
								case ECall({expr: EConst(CIdent("super"))}, params):
									macro @:pos(e.pos) @:mergeBlock {
										super($a{params});
										@:mergeBlock $b{fieldInits};
									};

								case _: ExprTools.map(e, mapExpr);
							}
						}

						f.expr = ExprTools.map(f.expr, mapExpr);

					case _:
				}
			}
		}

		return fields;
	}
	#end

	/**
	 * Extract component default props
	 */
	static function storeComponentInfos(fields:Array<Field>, inClass:ClassType, pos:Position)
	{
		var key = getClassKey(inClass);

		for (field in fields)
			if (field.name == 'defaultProps')
			{
				switch (field.kind) {
					case FieldType.FVar(ct, _.expr => EObjectDecl(props)):
						if (ct == null) {
							var types = MacroUtil.extractComponentTypes(inClass);
							var tprops = TypeTools.toComplexType(
								Context.follow(ComplexTypeTools.toType(types.tprops))
							);

							ct = switch (tprops) {
								case TPath({name: "Dynamic", params: [], pack: []}): macro :Dynamic;
								default: macro :react.Partial<$tprops>;
							};
						} else {
							ct = TypeTools.toComplexType(
								Context.follow(ComplexTypeTools.toType(ct))
							);
						}

						componentsMap.set(key, {
							ref: getClassRef(inClass),
							isExtern: inClass.isExtern,
							tprops: ct,
							props: props.copy()
						});

						return;
					default:
						break;
				}
			}

		componentsMap.set(key, {
			props: null,
			tprops: null,
			ref: getClassRef(inClass),
			isExtern: inClass.isExtern
		});
	}

	/**
	 * For a given type, resolve default props and resolve user-defined constant
	 * props out (if not constant, we cannot be sure it won't resolve to
	 * `js.Lib.undefined` and have different behavior)
	 */
	static public function getDefaultProps(typeInfo:ComponentInfo, attrs:Array<ExtendedObjectField>)
	{
		if (typeInfo == null) return null;

		if (typeInfo.props != null)
			return typeInfo.props.filter(function(defaultProp) {
				var name = defaultProp.field;
				for (prop in attrs) if (prop.field == name) return !prop.isConstant;
				return true;
			});

		return null;
	}

	/**
	 * Annotate React components for run-time JS reflection
	 */
	static function tagComponent(fields:Array<Field>, inClass:ClassType, pos:Position)
	{
		#if !debug return; #end
		if (inClass.isExtern) return;

		addDisplayName(fields, inClass, pos);

		#if react_hot
		addTagSource(fields, inClass, pos);
		#end
	}

	static function addTagSource(fields:Array<Field>, inClass:ClassType, pos:Position)
	{
		// add a __fileName__ static field
		var className = inClass.name;
		var fileName = Context.getPosInfos(inClass.pos).file;

		fields.push({
			name:'__fileName__',
			access:[Access.AStatic],
			kind:FieldType.FVar(null, macro $v{fileName}),
			pos:pos
		});
	}

	static function addDisplayName(fields:Array<Field>, inClass:ClassType, pos:Position)
	{
		for (field in fields)
			if (field.name == 'displayName') return;

		// add 'displayName' static property to see class names in React inspector panel
		var className = macro $v{inClass.name};
		var field:Field = {
			name:'displayName',
			access:[Access.AStatic, Access.APrivate],
			kind:FieldType.FVar(null, className),
			pos:pos
		}
		fields.push(field);
		return;
	}

	static public function getComponentInfo(expr:Expr):ComponentInfo
	{
		var key = getExprKey(expr);
		return key != null ? componentsMap.get(key) : null;
	}

	static function getClassKey(inClass:ClassType)
	{
		var qname = inClass.pack.concat([inClass.name]).join('.');
		return 'Class<$qname>';
	}

	static function getExprKey(expr:Expr)
	{
		return try switch (Context.typeof(expr)) {
			case Type.TType(_.get() => t, _): t.name;
			default: null;
		}
	}

	static function getClassRef(inClass:ClassType, ?pos:Position):Expr
	{
		if (pos == null) pos = Context.currentPos();

		var mod = inClass.module;
		if (!StringTools.endsWith(mod, '.' + inClass.name)) {
			mod += '.' + inClass.name;
		}

		return macro @:pos(pos) $p{mod.split('.')};
	}
}
#end
