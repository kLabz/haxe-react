package react;

#if haxe4
import js.lib.Error;
#else
import js.Error;
#end

import haxe.extern.EitherType;

typedef ReactComponentProps = {
	/**
		Children have to be manipulated using React.Children.*
	**/
	@:optional var children:Dynamic;
}

/**
	https://facebook.github.io/react/docs/react-component.html

	Can be used as:
	- `ReactComponent`, which means TProps = Dynamic and TState = Dynamic (not
	recommended, but can help when starting to write externs)

	- `ReactComponent<TProps>` which means your component doesn't have a state
	- `ReactComponent<TProps, TState>`

	For a component with state and no props, continue using
	`ReactComponentOfState`.
**/
@:genericBuild(react.macro.ReactComponentMacro.buildVariadic())
class ReactComponent<Rest> {}

typedef ReactComponentOfProps<TProps:{}> = ReactComponentOf<TProps, Empty>;
typedef ReactComponentOfState<TState:{}> = ReactComponentOf<Empty, TState>;

// Keep the old ReactComponentOfPropsAndState typedef available
typedef ReactComponentOfPropsAndState<TProps:{}, TState:{}> = ReactComponentOf<TProps, TState>;

#if (!react_global)
@:jsRequire("react", "Component")
#end
@:native('React.Component')
@:keepSub
@:autoBuild(react.macro.ReactComponentMacro.build())
extern class ReactComponentOf<TProps:{}, TState:{}>
{
	#if haxe4
	final props:TProps;
	#else
	var props(default, null):TProps;
	#end

	// Note: cannot use final for haxe 4.1.0 - 4.1.1 because of
	// https://github.com/HaxeFoundation/haxe/issues/9552
	var state(default, null):TState;

	#if react_deprecated_context
	// It's better to define it in your ReactComponent subclass as needed, with the right typing.
	var context(default, null):Dynamic;
	#end

	function new(?props:TProps, ?context:Dynamic);

	/**
		https://facebook.github.io/react/docs/react-component.html#forceupdate
	**/
	function forceUpdate(?callback:Void -> Void):Void;

	/**
		https://facebook.github.io/react/docs/react-component.html#setstate
	**/
	@:overload(function(nextState:TState, ?callback:Void -> Void):Void {})
	@:overload(function(nextState:TState -> TProps -> TState, ?callback:Void -> Void):Void {})
	function setState(nextState:TState -> TState, ?callback:Void -> Void):Void;

	/**
		https://facebook.github.io/react/docs/react-component.html#render
	**/
	function render():ReactFragment;

	/**
		https://facebook.github.io/react/docs/react-component.html#componentwillmount
	**/
	function componentWillMount():Void;

	/**
		https://facebook.github.io/react/docs/react-component.html#componentdidmount
	**/
	function componentDidMount():Void;

	/**
		https://facebook.github.io/react/docs/react-component.html#componentwillunmount
	**/
	function componentWillUnmount():Void;

	/**
		https://facebook.github.io/react/docs/react-component.html#componentwillreceiveprops
	**/
	function componentWillReceiveProps(nextProps:TProps):Void;

	/**
		https://facebook.github.io/react/docs/react-component.html#shouldcomponentupdate
	**/
	dynamic function shouldComponentUpdate(nextProps:TProps, nextState:TState):Bool;

	/**
		https://facebook.github.io/react/docs/react-component.html#componentwillupdate
	**/
	function componentWillUpdate(nextProps:TProps, nextState:TState):Void;

	/**
		https://facebook.github.io/react/docs/react-component.html#componentdidupdate
	**/
	function componentDidUpdate(prevProps:TProps, prevState:TState):Void;

	/**
		https://reactjs.org/blog/2017/07/26/error-handling-in-react-16.html
	**/
	function componentDidCatch(error:Error, info:{ componentStack:String }):Void;

	#if (js && !debug && !react_no_inline)
	static function __init__():Void {
		// required magic value to tag literal react elements
		#if haxe4
		js.Syntax.code("var $$tre = (typeof Symbol === \"function\" && Symbol.for && Symbol.for(\"react.element\")) || 0xeac7");
		#else
		untyped __js__("var $$tre = (typeof Symbol === \"function\" && Symbol.for && Symbol.for(\"react.element\")) || 0xeac7");
		#end
	}
	#end
}

// Used internally to make @:acceptsMoreProps and @:wrap compatible
// Needs to be tested extensively before encouraging manual use
typedef ACCEPTS_MORE_PROPS<TProps:{}> = TProps;

typedef ReactSource = {
	fileName:String,
	lineNumber:Int
}

typedef ReactElement = {
	type:ReactType,
	props:Dynamic,
	?key:Dynamic,
	?ref:Dynamic,
	?_owner:Dynamic,

	#if debug
	?_store:{validated:Bool},
	?_shadowChildren:Dynamic,
	?_source:ReactSource,
	#end
}

@:pure @:coreType abstract ReactSingleFragment
	from String
	from Float
	from Bool
	from ReactElement {}

@:pure @:coreType abstract ReactFragment
	from ReactSingleFragment
	from Array<ReactFragment>
	from Array<ReactElement>
	from Array<String>
	from Array<Float>
	from Array<Int>
	from Array<Bool>
	from Array<ReactSingleFragment> {}
