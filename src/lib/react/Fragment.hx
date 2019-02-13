package react;

import react.ReactComponent;

/**
	Warning: Fragments are only available in react 16.2.0+
	https://reactjs.org/blog/2017/11/28/react-v16.2.0-fragment-support.html
**/
#if (!react_global)
@:jsRequire("react", "Fragment")
#end
@:native('React.Fragment')
extern class Fragment extends ReactComponentOfProps<Empty> {}

