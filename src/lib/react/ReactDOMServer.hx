package react;

import react.ReactComponent.ReactFragment;

#if nodejs
import js.node.stream.Readable;

@:native('ReactMarkupReadableStream')
@:jsRequire('react-dom/server/ReactDOMNodeStreamRenderer', 'ReactMarkupReadableStream')
class ReactMarkupReadableStream extends Readable<ReactMarkupReadableStream> {}
#end

/**
	https://facebook.github.io/react/docs/react-dom-server.html
**/
#if (!react_global)
@:jsRequire('react-dom/server')
#end
@:native('ReactDOMServer')
extern class ReactDOMServer
{
	/**
		https://reactjs.org/docs/react-dom-server.html#rendertostring
	**/
	public static function renderToString(node:ReactFragment):String;

	/**
		https://reactjs.org/docs/react-dom-server.html#rendertostaticmarkup
	**/
	public static function renderToStaticMarkup(node:ReactFragment):String;

	#if nodejs
	/**
		https://reactjs.org/docs/react-dom-server.html#rendertonodestream
	**/
	public static function renderToNodeStream(node:ReactFragment):ReactMarkupReadableStream;

	/**
		https://reactjs.org/docs/react-dom-server.html#rendertostaticnodestream
	**/
	public static function renderToStaticNodeStream(node:ReactFragment):ReactMarkupReadableStream;
	#end
}
