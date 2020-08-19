package react;

import haxe.Constraints.Function;
import haxe.extern.EitherType;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;

abstract ReactType(Dynamic)
#else
import react.ReactComponent;

private typedef Node = EitherType<EitherType<String, Function>, Class<ReactComponent<Dynamic, Dynamic>>>;

abstract ReactType(Node) to Node
#end
{
	#if !macro
	@:from
	static public function fromString(s:String):ReactType
	{
		#if debug
		if (s == null) return isNull();
		#end
		return cast s;
	}

	@:from
	static public function fromFunction(f:Void->ReactFragment):ReactType
	{
		#if debug
		if (f == null) return isNull();
		#end
		return cast f;
	}

	@:from
	static public function fromFunctionWithProps<TProps>(f:TProps->ReactFragment):ReactType
	{
		#if debug
		if (f == null) return isNull();
		#end
		return cast f;
	}

	@:from
	static public function fromComp(cls:Class<ReactComponent<Dynamic, Dynamic>>):ReactType
	{
		#if debug
		if (cls == null) return isNull();
		#end

		if (untyped cls.__jsxStatic != null)
			return untyped cls.__jsxStatic;

		return cast cls;
	}

	#if debug
	static public function isNull():ReactType {
		js.Browser.console.error(
			'Runtime value for ReactType is null.'
			+ ' Something may be wrong with your externs.'
		);

		return cast "div";
	}
	#end
	#end

	@:from
	static public macro function fromExpr(expr:Expr)
	{
		switch (Context.typeof(expr)) {
			case TType(_.get() => def, _):
				try {
					switch (Context.getType(def.module)) {
						case TInst(_.get() => clsType, _):
							if (!clsType.meta.has(react.jsx.JsxStaticMacro.META_NAME))
								Context.error(
									'Incompatible class for ReactType: expected a ReactComponent or a @:jsxStatic component',
									expr.pos
								);
							else
								return macro {
									$expr.__jsxStatic;
								};

						default: throw '';
					}
				} catch (e:Dynamic) {
					Context.error(
						'Incompatible expression for ReactType',
						expr.pos
					);
				}

			default:
				Context.error(
					'Incompatible expression for ReactType',
					expr.pos
				);
		}

		return null;
	}
}

abstract ReactTypeOf<TProps>(ReactType) to ReactType {
	private inline function new(node:ReactType) this = node;

	#if !macro
	@:from
	static public function fromFunctionWithProps<TProps>(f:TProps->ReactFragment):ReactTypeOf<TProps>
	{
		return new ReactTypeOf(f);
	}

	@:from
	static public function fromComp<TProps:{}, TState:{}>(
		cls:Class<ReactComponentOf<TProps, TState>>
	):ReactTypeOf<TProps>
	{
		return new ReactTypeOf(cls);
	}

	@:from
	static public function fromFunctionWithoutProps<TProps>(f:Void->ReactFragment):ReactTypeOf<TProps>
	{
		return new ReactTypeOf(f);
	}

	@:from
	static public function fromCompWithoutProps<TProps:{}, TState:{}>(
		cls:Class<ReactComponentOf<react.Empty, TState>>
	):ReactTypeOf<TProps>
	{
		return new ReactTypeOf(cls);
	}
	#end

	#if coconut_react_core
	public function fromHxx(hxxMeta:{ ?key:coconut.react.Key }, props:TProps):ReactElement
	{
		return React.createElement(this, js.Object.assign(cast props, hxxMeta));
	}
	#end

	@:from
	static public macro function fromExpr(expr:Expr)
	{
		if (!isReactType(expr))
		{
			Context.error('Incompatible expression for ReactType', expr.pos);
			return null;
		}

		switch (Context.getExpectedType()) {
			case TAbstract(_, [TType(_.get() => tProps, [])]):
				Context.error(
					'Props do not unify with ${tProps.name}',
					expr.pos
				);

			case TAbstract(
				_.toString() => 'Null',
				[TAbstract(_, [TType(_.get() => tProps, [])])]
			):
				Context.error(
					'Props do not unify with ${tProps.name}',
					expr.pos
				);

			default:
				Context.error('Props do not unify', expr.pos);
		}

		return null;
	}

	#if macro
	static function isReactType(expr:Expr):Bool
	{
		try {
			Context.typeExpr(macro { var a:react.ReactType = $e{expr}; });
			return true;
		} catch (e:Dynamic) {
			return false;
		}
	}
	#end
}

