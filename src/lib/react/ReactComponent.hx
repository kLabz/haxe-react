package react;
import js.Error;
import haxe.extern.EitherType;

typedef ReactComponentProps = {
	/**
		Children have to be manipulated using React.Children.*
	**/
	@:optional var children:Dynamic;
}

/**
	https://facebook.github.io/react/docs/react-component.html
**/
typedef ReactComponent = ReactComponentOf<Dynamic, Dynamic>;

typedef ReactComponentOfProps<TProps:{}> = ReactComponentOf<TProps, Empty>;
typedef ReactComponentOfState<TState:{}> = ReactComponentOf<Empty, TState>;

// Keep the old ReactComponentOfPropsAndState typedef available
typedef ReactComponentOfPropsAndState<TProps:{}, TState:{}> = ReactComponentOf<TProps, TState>;

#if (!react_global)
@:jsRequire("react", "Component")
#end
@:native('React.Component')
@:keepSub
@:autoBuild(react.ReactComponentMacro.build())
extern class ReactComponentOf<TProps:{}, TState:{}>
{
	var props(default, null):TProps;
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
	@:overload(function(nextState:Partial<TState>, ?callback:Void -> Void):Void {})
	@:overload(function(nextState:TState -> TProps -> Partial<TState>, ?callback:Void -> Void):Void {})
	function setState(nextState:TState -> Partial<TState>, ?callback:Void -> Void):Void;

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
		untyped __js__("var $$tre = (typeof Symbol === \"function\" && Symbol.for && Symbol.for(\"react.element\")) || 0xeac7");
	}
	#end
}

typedef ReactSource = {
	fileName:String,
	lineNumber:Int
}

typedef ReactElement = {
	type:Dynamic,
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

typedef ReactSingleFragment = EitherType<
	ReactElement,
	EitherType<String, EitherType<Float, Bool>>
>;

typedef ReactFragment = EitherType<
	ReactSingleFragment,
	Array<ReactFragment>
>;
