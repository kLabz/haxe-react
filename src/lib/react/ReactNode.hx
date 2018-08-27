package react;

import haxe.Constraints.Function;
import haxe.extern.EitherType;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;

abstract ReactNode(Dynamic)
#else
import react.ReactComponent;

private typedef Node = EitherType<EitherType<String, Function>, Class<ReactComponent>>;
abstract ReactNode(Node) to Node
#end
{
	#if !macro
	@:from
	static public function fromString(s:String):ReactNode
	{
		#if debug
		if (s == null) return isNull();
		#end
		return cast s;
	}

	@:from
	static public function fromFunction(f:Void->ReactFragment):ReactNode
	{
		#if debug
		if (f == null) return isNull();
		#end
		return cast f;
	}

	@:from
	static public function fromFunctionWithProps<TProps>(f:TProps->ReactFragment):ReactNode
	{
		#if debug
		if (f == null) return isNull();
		#end
		return cast f;
	}

	@:from
	static public function fromComp(cls:Class<ReactComponent>):ReactNode
	{
		#if debug
		if (cls == null) return isNull();
		#end

		if (untyped cls.__jsxStatic != null)
			return untyped cls.__jsxStatic;

		return cast cls;
	}

	#if debug
	static public function isNull():ReactNode {
		js.Browser.console.error(
			'Runtime value for ReactNode is null.'
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
									'Incompatible class for ReactNode: expected a ReactComponent or a @:jsxStatic component',
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
						'Incompatible expression for ReactNode',
						expr.pos
					);
				}

			default:
				Context.error(
					'Incompatible expression for ReactNode',
					expr.pos
				);
		}

		return null;
	}
}

abstract ReactNodeOf<TProps>(ReactNode) to ReactNode {
	#if !macro
	@:from
	static public function fromFunctionWithProps<TProps, T:TProps>(f:T->ReactFragment):ReactNodeOf<TProps>
	{
		return cast f;
	}

	@:from
	static public function fromComp<TProps, T:TProps, TState>(cls:Class<ReactComponentOf<T, TState>>):ReactNodeOf<TProps>
	{
		return cast cls;
	}

	@:from
	static public function fromFunctionWithoutProps<TProps>(f:Void->ReactFragment):ReactNodeOf<TProps>
	{
		return cast f;
	}

	@:from
	static public function fromCompWithoutProps<TProps, TState>(cls:Class<ReactComponentOf<react.Empty, TState>>):ReactNodeOf<TProps>
	{
		return cast cls;
	}
	#end

	@:from
	static public macro function fromExpr(expr:Expr)
	{
		if (!isReactNode(expr))
		{
			Context.error('Incompatible expression for ReactNode', expr.pos);
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
	static function isReactNode(expr:Expr):Bool
	{
		try {
			Context.typeExpr(macro { var a:react.ReactNode = $e{expr}; });
			return true;
		} catch (e:Dynamic) {
			return false;
		}
	}
	#end
}

