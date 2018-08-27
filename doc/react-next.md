# React #next

Branch `#next` of my haxe-react fork aims to move haxe-react forward to `2.0.0+`
with an increased freedom to break things until I get them right.

This version of haxe-react can be considered unstable (even though it is
currently being used in production) due to these huge changes it can go through.
You may want to lock your dependencies to the latest commit of the branch
instead of the branch itself, if you are not willing to update your code every
now and then. I am available in
[haxe-react gitter](https://gitter.im/haxe-react/Lobby) if you need help.

## Different jsx parser

Based off [back2dos](https://github.com/back2dos)'s
[PR #95](https://github.com/massiveinteractive/haxe-react/pull/95),
[`tink_hxx`](https://github.com/haxetink/tink_hxx) is used to handle jsx.

### Syntax changes

The change of parser implies some little syntax changes:
* `prop=$42` and such are no longer allowed, use `prop=${42}` or `prop={42}`
* `prop=${true}` can now be expressed as simply `prop`

### Misc changes

Other changes introduced by tink_hxx:
* Props are type-checked against the component's `TProps`
* You cannot pass props not recognized by the target component
* [Needs a tink_hxx release] You can use `${/* comments */}` / `{/* comments */}`in jsx

### Further changes added in `#next`

#### [`6e8fe8d`](https://github.com/kLabz/haxe-react/commit/6e8fe8d) Allow String variables as jsx node

The new parser will resolve `String` variables for node names:

```haxe
var Node = isTitle ? 'h2' : 'p';
return jsx('<$Node>${props.children}</$Node>');
```

**Warning**: it only works for variable names starting with an uppercase letter.

#### [`d173de0`](https://github.com/kLabz/haxe-react/commit/d173de0) Fix error position when using invalid nodes in jsx

Using an invalid node inside jsx, such as `<$UnknownComponent />`, resulted in
an error inside `haxe.macro.MacroStringTools`.

This fix ensures that the position points to "UnknownComponent" inside the jsx
string.

#### [`578c55d`](https://github.com/kLabz/haxe-react/commit/578c55d) Disallow invalid values inside jsx when a fragment is expected

For example, the following used to compile:

	jsx('<div>${function() return 42}</div>');

But resulted in a runtime error:

	Warning: Functions are not valid as a React child. This may happen if you
	return a Component instead of <Component /> from render. Or maybe you meant
	to call this function rather than return it.

Or, for objects: `jsx('<div>${{test: 42}}</div>');` resulted in:

	Uncaught Error: Objects are not valid as a React child (found: object with
	keys {test}). If you meant to render a collection of children,
	use an array instead.

Now we get a compilation error (see below for `react.ReactFragment`):

	src/Index.hx:31: characters 7-17 : { test : Int } should be react.ReactFragment
	src/Index.hx:31: characters 7-17 : For function argument 'children'

#### [`425cb6c`](https://github.com/kLabz/haxe-react/commit/425cb6c) Ensure individual prop typing, allowing abstract props to do their magic

Makes sure each prop resolves to its type, with a `(prop :TypeOfProp)`.

This will trigger abstracts `@:from` / `@:to` which may be needed in some cases
to do their magic.

#### [`150b76d`](https://github.com/kLabz/haxe-react/commit/150b76d) + [`91bc8a9`](https://github.com/kLabz/haxe-react/commit/91bc8a9) Jsx: display compilation warning on missing props

Tries to extract the list of needed props and adds a compilation warning when
some of them are not passed in a jsx "call".

**Limitations:**
* If you use the spread operator on the props of a component, this test is not
executed (it becomes hard and even sometimes impossible to know what props are
passed through the spread).

## ReactComponentOf cleanup

Cherry-picked and improved
[PR #108](https://github.com/massiveinteractive/haxe-react/pull/108), which
removed the legacy `TRefs` from `ReactComponent`.

#### So now we have
* `ReactComponentOf<TProps, TState>` (or `ReactComponentOfPropsAndState<TProps, TState>`)
* `ReactComponentOfProps<TProps>`
* `ReactComponentOfState<TState>`
* And still `ReactComponent` which has untyped props and state (`Dynamic`)

#### Strict props & state access

This is actually a big change, since `ReactComponentOfProps` and
`ReactComponentOfState` use `react.Empty` type as `TState` (resp. `TProps`).

`react.Empty` is an empty typedef, disabling state access/update on
`ReactComponentOfProps`, and props access in `ReactComponentOfState`.

## `ReactFragment`

`ReactFragment` (in `react.ReactComponent` module) tries to be closer to react
in describing a valid element. It replaces `ReactElement` in most API, allowing
them to use other types allowed by react.

#### `ReactFragment` unifies with either

* `ReactElement`
* `String`
* `Float` (and `Int`)
* `Bool`
* `Array<ReactFragment>`

#### APIs now using ReactFragment

* `React.createElement()` returns a ReactFragment
* `ReactChildren.map()` callback is now `ReactFragment -> ReactFragment`
* `ReactChildren.foreach()` callback is now `ReactFragment -> Void`
* `ReactComponent's render()` returns a ReactFragment
* `ReactDOM.render()` uses ReactFragment for first argument and return type
* `ReactDOM.hydrate()` uses ReactFragment for first argument and return type
* `ReactDOM.createPortal()` uses ReactFragment for first argument and return type

## `ReactNode` and `ReactNodeOf`

`react.ReactNode` replaces `CreateElementType` and allows:
* `String`
* `Void->ReactFragment`
* `TProps->ReactFragment`
* `Class<ReactComponent>`
* `@:jsxStatic` components

There is also `ReactNodeOf<TProps>`, for cases when you want a component
accepting some specific props.

`CreateElementType`, still in the `react.React` module, is now **deprecated**
but still available as a proxy to `ReactNode`.

## More debug tools

#### [`98233c3`](https://github.com/kLabz/haxe-react/commit/98233c3) Add warning if ReactComponent's render has no override

Adds a compile-time check for an override of the `render` function in your
components. This helps catching following runtime warning sooner:

	Warning: Index(...): No `render` method found on the returned component
	instance: you may have forgotten to define `render`.

Catching it at compile-time also ensures it does not happen to a component only
visible for a few specific application state.

You can disable this with the `-D react_ignore_empty_render` compilation flag.

#### [`ef0b0f1`](https://github.com/kLabz/haxe-react/commit/ef0b0f1) React runtime warnings: add check for state initialization

React runtime warnings, disabled by default, can be enabled with the
`-D react_runtime_warnings` compilation flag (only when `-debug` is enabled).

They were previously enabled with `-D react_render_warning`, and only added the
warning about avoidable re-renders. Note that this warning can have false
positive due to the legacy context API (react-router for example). You can
disable it for a specific component by adding `@:ignoreReRender` meta to this
component ([`a7860c6`](https://github.com/kLabz/haxe-react/commit/a7860c6)).

A new warning has been added: if a component having a state does not have a
constructor or has one but doesn't initialize its state in it, you will get a
compilation error warning you about it (instead of a runtime react error).

These warnings are now more accurate since the strict props/state types have
been added to `ReactComponentOf` typedefs. Compatibility has been handled
mainly in [`1719431`](https://github.com/kLabz/haxe-react/commit/1719431) and
[`241a13b`](https://github.com/kLabz/haxe-react/commit/241a13b).
