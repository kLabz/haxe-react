# Typing your props with haxe-react

One of the points of using Haxe to develop javascript applications is to benefit
from a statically typed language. So, naturally, you'll want your components to
be able to define the type of props they are going to get and are able to use.

## Using `PropTypes`?

In React, this is usually done using [`PropTypes`][react-proptypes], which uses
an object with validators for each prop. These validators are runtime ones (they
can also be used by flow or typescript at compile-time), and are not types but
descriptors of types.

A simplified example from the documentation:

```javascript
MyComponent.propTypes = {
	optionalArray: PropTypes.array,
	optionalBool: PropTypes.bool,
	optionalFunc: PropTypes.func,
	optionalNumber: PropTypes.number,
	requiredFunc: PropTypes.func.isRequired
};
```

You can declare them with haxe-react by using `react.ReactPropTypes`:

```haxe
import react.ReactComponent;
import react.ReactPropTypes as PropTypes;

class MyComponent extends ReactComponent {
	static var propTypes = {
		optionalArray: PropTypes.array,
		optionalBool: PropTypes.bool,
		optionalFunc: PropTypes.func,
		optionalNumber: PropTypes.number,
		requiredFunc: PropTypes.func.isRequired
	};

	// ...
}
```

Note that this won't do any compile-time check, though, as it is not the primary
typing system for props in haxe-react.

## Use real static typing with `TProps`

In Haxe React, props typing is usually done using `TProps`, a typedef typing the
props your component can use and should be called with.

These types are enforced at compile time when using `jsx`, and will be available
for completion within your component.

The above example would be implemented with something like that:

```haxe
import react.ReactComponent;

typedef MyComponentProps = {
	var requiredFunc:String->Void;
	@:optional var optionalArray:Array<Int>;
	@:optional var optionalBool:Bool;
	@:optional var optionalFunc:Int->String;
	@:optional var optionalNumber:Int;
}

class MyComponent extends ReactComponentOfProps<MyComponentProps> {
	// ...
}
```

### Stateful components

You can type your `state` the same way, using the second type parameter of
`ReactComponentOf` or using `ReactComponentOfState` if your component does not
use props:

```haxe
import react.ReactComponent;

private typedef Props = {
	var requiredFunc:String->Void;
	@:optional var optionalBool:Bool;
}

private typedef State = {
	var open:Bool;
}

class MyStatefulComponent extends ReactComponentOf<Props, State> {
	public function new(props:Props) {
		super(props);

		state = {
			open: false
		};
	}

	// ...
}

class MyStatefulComponentWithoutProps extends ReactComponentOfState<State> {
	public function new() {
		super();

		state = {
			open: false
		};
	}

	// ...
}
```

[react-proptypes]: https://reactjs.org/docs/typechecking-with-proptypes.html
