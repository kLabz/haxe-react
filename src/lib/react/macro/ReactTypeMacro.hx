package react.macro;

import haxe.macro.TypeTools;
import haxe.macro.ComplexTypeTools;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypeTools;

class ReactTypeMacro
{
	static public inline var ALTER_SIGNATURES_BUILDER = 'AlterSignatures';
	static public inline var ENSURE_RENDER_OVERRIDE_BUILDER = 'EnsureRenderOverride';
	static public inline var CHECK_GET_DERIVED_STATE_BUILDER = 'CheckDerivedState';
	static public inline var IGNORE_EMPTY_RENDER_META = ':ignoreEmptyRender';

	#if macro
	public static function alterComponentSignatures(inClass:ClassType, fields:Array<Field>):Array<Field>
	{
		if (inClass.isExtern) return fields;

		var types = MacroUtil.extractComponentTypes(inClass);
		var tprops = types.tprops == null ? macro :Dynamic : types.tprops;
		var tstate = types.tstate == null ? macro :Dynamic : types.tstate;

		// Only alter setState signature for non-dynamic states
		switch (ComplexTypeTools.toType(tstate))
		{
			case TType(_) if (!hasSetState(fields)):
				addSetStateType(fields, inClass, tprops, tstate);

			default:
		}

		return fields;
	}

	public static function ensureRenderOverride(inClass:ClassType, fields:Array<Field>):Array<Field>
	{
		if (!(inClass.isExtern || inClass.meta.has(IGNORE_EMPTY_RENDER_META)))
			if (!Lambda.exists(fields, function(f) return f.name == 'render'))
				Context.warning(
					'Component ${inClass.name}: '
					+ 'No `render` method found: you may have forgotten to '
					+ 'override `render` from `ReactComponent`.',
					inClass.pos
				);

		return fields;
	}

	public static function checkGetDerivedState(inClass:ClassType, fields:Array<Field>):Array<Field>
	{
		if (!inClass.isExtern) {
			var getDerived = MacroUtil.getField(fields, "getDerivedStateFromProps");

			if (getDerived != null) {
				switch (getDerived.kind)
				{
					case FFun(fun) if (Lambda.has(getDerived.access, AStatic)):
						var types = MacroUtil.extractComponentTypes(inClass);
						var tprops = types.tprops == null ? macro :Dynamic : types.tprops;
						var tstate = types.tstate == null ? macro :Dynamic : types.tstate;

						var expected = macro :$tprops->$tstate->react.Partial<$tstate>;
						var ct = TypeTools.toComplexType(MacroUtil.functionToType(fun));

						Context.typeof(macro @:pos(getDerived.pos) {
							var a:$ct = null;
							var b:$expected = a;
						});

					default:
						Context.warning(
							'Component ${inClass.name}: '
							+ 'Field getDerivedStateFromProps should be a static function '
							+ 'with `props` and `prevState` as arguments.',
							getDerived.pos
						);

				}
			}
		}

		return fields;
	}

	static function hasSetState(fields:Array<Field>) {
		for (field in fields)
		{
			if (field.name == 'setState')
			{
				return switch (field.kind) {
					case FFun(f): true;
					default: false;
				}
			}
		}

		return false;
	}

	static function addSetStateType(
		fields:Array<Field>,
		inClass:ClassType,
		propsType:ComplexType,
		stateType:ComplexType
	) {
		fields.push((macro class C {
			@:extern
			@:overload(function(nextState:$stateType -> react.Partial<$stateType>, ?callback:Void -> Void):Void {})
			@:overload(function(nextState:$stateType -> $propsType -> react.Partial<$stateType>, ?callback:Void -> Void):Void {})
			override public function setState(nextState: react.Partial<$stateType>, ?callback:Void -> Void): Void
				#if haxe4
				// explictly omit function body
				// newer haxe 4 builds (preview 5 and up) don't require a function body – however haxe4 flag is not set until rc1
				#else
				{ super.setState(nextState, callback); }
				#end
			;
		}).fields[0]);
	}

	#end
}
