package react;

import haxe.macro.ComplexTypeTools;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypeTools;

class ReactTypeMacro
{
	#if macro
	public static function ensureRenderOverride(inClass:ClassType, fields:Array<Field>):Array<Field>
	{
		if (!inClass.isExtern)
			if (!Lambda.exists(fields, function(f) return f.name == 'render'))
				Context.warning(
					'Component ${inClass.name}: '
					+ 'No `render` method found: you may have forgotten to '
					+ 'override `render` from `ReactComponent`.',
					inClass.pos
				);

		return fields;
	}
	#end
}
