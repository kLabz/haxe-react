package react.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypeTools;

import react.macro.MacroUtil.isEmpty;
#end

@:dce
class ReactDebugMacro
{
	public static inline var REACT_DEBUG_BUILDER = 'ReactDebug';
	public static var firstRenderWarning:Bool = true;

	@:deprecated public static inline var IGNORE_RENDER_WARNING_META = ReactMeta.IgnoreRenderWarning;
	@:deprecated public static inline var WHY_RENDER_META = ReactMeta.WhyRender;

	#if macro
	public static function buildComponent(inClass:ClassType, fields:Array<Field>):Array<Field>
	{
		if (inClass.isExtern) return fields;

		var pos = Context.currentPos();
		var propsType = macro :Dynamic;
		var stateType = macro :Dynamic;

		switch (inClass.superClass) {
			case {params: params, t: _.toString() => cls}
			if (cls == 'react.ReactComponentOf' || cls == 'react.PureComponentOf'):
				propsType = TypeTools.toComplexType(params[0]);
				stateType = TypeTools.toComplexType(params[1]);

			default:
		}

		#if !react_runtime_warnings_ignore_rerender
		if (!inClass.meta.has(ReactMeta.IgnoreRenderWarning))
			if (!updateComponentUpdate(fields, inClass, propsType, stateType))
				addComponentUpdate(fields, inClass, propsType, stateType);
		#end

		if (!isEmpty(stateType) && !updateConstructor(fields, inClass))
			addConstructor(fields, inClass, propsType, stateType);

		return fields;
	}

	static function updateConstructor(fields:Array<Field>, inClass:ClassType) {
		for (field in fields)
		{
			if (field.name == "new")
			{
				switch (field.kind) {
					case FFun(f):
						f.expr = macro @:pos(field.pos) @:mergeBlock {
							@:mergeBlock ${f.expr};
							@:mergeBlock ${exprConstructor(inClass)};
						};

						return true;
					default:
				}
			}
		}

		return false;
	}

	static function addConstructor(
		fields:Array<Field>,
		inClass:ClassType,
		propsType:ComplexType,
		stateType:ComplexType
	) {
		var constructor = {
			args: [
				{
					meta: [],
					name: "props",
					type: propsType,
					opt: false,
					value: null
				}
			],
			ret: macro :Void,
			expr: macro {
				super(props);
				${exprConstructor(inClass)};
			}
		}

		fields.push({
			name: 'new',
			access: [APublic],
			kind: FFun(constructor),
			pos: inClass.pos
		});
	}

	static function exprConstructor(inClass:ClassType)
	{
		return macro {
			if (state == null) {
				js.Browser.console.error($v{
					'Warning: component ${inClass.name} is stateful but its '
					+ '`state` is not initialized inside its constructor.\n\n'

					+ 'Either add a `state = { ... }` statement to its constructor '
					+ 'or define this component as a `ReactComponentOfProps` '
					+ 'if it is only using `props`.\n\n'

					+ 'If it is using neither `props` nor `state`, you might '
					+ 'consider using `@:jsxStatic` to avoid unneeded lifecycle. '
					+ 'See https://github.com/kLabz/haxe-react/blob/next/doc/static-components.md '
					+ 'for more information on static components.'
				});
			}
		};
	}

	static function updateComponentUpdate(
		fields:Array<Field>,
		inClass:ClassType,
		propsType:ComplexType,
		stateType:ComplexType
	) {
		for (field in fields)
		{
			if (field.name == "componentDidUpdate")
			{
				switch (field.kind) {
					case FFun(f):
						if (f.args.length != 2)
							return Context.error('componentDidUpdate should accept two arguments', inClass.pos);

						var expr = exprComponentDidUpdate(
							inClass,
							f.args[0].name,
							f.args[1].name,
							!isEmpty(propsType),
							!isEmpty(stateType)
						);

						f.expr = macro {
							${expr}
							${f.expr}
						};

						return true;
					default:
				}
			}
		}

		return false;
	}

	static function addComponentUpdate(
		fields:Array<Field>,
		inClass:ClassType,
		propsType:ComplexType,
		stateType:ComplexType
	) {
		var expr = exprComponentDidUpdate(
			inClass,
			"prevProps",
			"prevState",
			!isEmpty(propsType),
			!isEmpty(stateType)
		);

		var componentDidUpdate = {
			args: [
				{
					meta: [],
					name: "prevProps",
					type: propsType,
					opt: false,
					value: null
				},
				{
					meta: [],
					name: "prevState",
					type: stateType,
					opt: false,
					value: null
				}
			],
			ret: macro :Void,
			expr: expr
		}

		fields.push({
			name: 'componentDidUpdate',
			access: [APublic, AOverride],
			kind: FFun(componentDidUpdate),
			pos: inClass.pos
		});
	}

	static function exprComponentDidUpdate(
		inClass:ClassType,
		prevProps:String,
		prevState:String,
		hasProps:Bool,
		hasState:Bool
	) {
		if (!hasProps && !hasState) return macro {};

		var displayLongWarning = macro {
			if (react.macro.ReactDebugMacro.firstRenderWarning) {
				react.macro.ReactDebugMacro.firstRenderWarning = false;

				js.Browser.console.warn($v{
					'Make sure your props are flattened, or implement shouldComponentUpdate.\n' +
					'See https://facebook.github.io/react/docs/optimizing-performance.html#shouldcomponentupdate-in-action' +
					'\n\nAlso note that legacy context API can trigger false positives if children ' +
					'rely on context. You can hide this warning for a specific component by adding ' +
					'`@${ReactMeta.IgnoreRenderWarning}` meta to its class.'
				});
			}
		}

		if (inClass.meta.has(ReactMeta.WhyRender)) {
			return macro {
				var propsChanges = react.ReactUtil.shallowChanges(props, prevProps);
				if (propsChanges != null) {
					js.Browser.console.log($v{'Props changed for `${inClass.name}`.'});
					js.Browser.console.log(propsChanges);
				}

				var stateChanges = react.ReactUtil.shallowChanges(state, prevState);
				if (stateChanges != null) {
					js.Browser.console.log($v{'State changed for `${inClass.name}`.'});
					js.Browser.console.log(stateChanges);
				}

				if (propsChanges == null && stateChanges == null) {
					js.Browser.console.warn($v{
						'Warning: avoidable re-render of `${inClass.name}`.'
					});

					${displayLongWarning}
				}
			};
		}

		return macro {
			${hasProps
				? macro var propsAreEqual = react.ReactUtil.shallowCompare(this.props, $i{prevProps})
				: macro {}
			};

			${hasState
				? macro var statesAreEqual = react.ReactUtil.shallowCompare(this.state, $i{prevState})
				: macro {}
			};

			var cond = ${!hasProps
				? macro statesAreEqual
				: !hasState
					? macro propsAreEqual
					: macro (propsAreEqual && statesAreEqual)
			};

			if (cond)
			{
				${hasProps ? macro {
					// Using Object.create(null) to avoid prototype for clean output
					var debugProps = untyped Object.create(null);
					debugProps.currentProps = this.props;
					debugProps.prevProps = $i{prevProps};

					js.Browser.console.warn(
						$v{'Warning: avoidable re-render of `${inClass.name}`.\n'},
						debugProps
					);
				} : macro {
					js.Browser.console.warn(
						$v{'Warning: avoidable re-render of `${inClass.name}`.\n'}
					);
				}};

				${displayLongWarning}
			}
		}
	}
	#end
}
