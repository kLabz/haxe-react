# New React Refs API (React 16.3)

Externs have been added for [`React.createRef()`][createRef] and
[`React.forwardRef()`][forwardRef] from the new refs API introduced in React
`16.3`.

## Example usage

```haxe
import js.html.InputElement;
import react.React;
import react.ReactRef;
import react.ReactComponent;
import react.ReactMacro.jsx;

class TestComponent extends ReactComponentOfState<{message: String}> {
	var inputRef:ReactRef<InputElement> = React.createRef();

	public function new(props) {
		super(props);

		state = {message: null};
	}

	override public function render() {
		return jsx('
			<>
				<span>${state.message}</span>
				<input ref=${inputRef} type="text" />
				<button onClick=${updateMessage}>Update</button>
			</>
		');
	}

	function updateMessage() {
		setState({message: inputRef.current.value});
	}
}
```

We can also use `var inputRef = React.createRef();` but I personally prefer to
type my refs to the underlying element.

[createRef]: https://reactjs.org/docs/react-api.html#reactcreateref
[forwardRef]: https://reactjs.org/docs/react-api.html#reactforwardref
