# Haxe React #next: roadmap

There's still work to be done being this fork is ready for a haxe-react 2.0.0
candidate. This file will be updated with new bugs and new feature ideas that
should be included in the release.

Done tasks will be deleted from here, if you are looking for differences with
upstream haxe-react, see [React #next doc](./react-next.md).

PRs are welcome for helping with any of these, but you may want to get in touch
(via gitter for example) before doing so, as some features/fix are already
started and sometimes almost finished.

If you have wishes or suggestions, come to gitter or open issues here; I'll be
happy to consider them.

## Features needing improvements / new features

* Jsx macro performances improvement to reduce compilation time
* Implement missing React APIs (see #11)
* Update react events handling

### Some more things that **may** be added too

* Inline `@:jsxStatic` proxy field to help with performance and file size
* Some helpers to create HOCs (which can then be used with `@:wrap`)
* More stability with both runtime warnings and hot reloading enabled
* Some improvements for `Partial<T>`
* Generate `propTypes` from components' `TProps` when compiling with `-debug`
 and `-D react-generate-proptypes`

## [Documentation](README.md)

* Update README.md
* Getting started: intro
* Getting started: Haxe "jsx"
* Getting started: ReactType, ReactFragment
* Advanced topics: PureComponent
* Advanced topics: Children as render prop
* Advanced topics: Using new `context` API
* React `next`: intro
* React `next`: Migration guide
* Development tools: Compilation warnings
* Development tools: Runtime warnings

## [Samples](../samples/)

* Current examples will need to be updated
* Samples should be compiled by CI
* New sample: using context
* New sample: ??
