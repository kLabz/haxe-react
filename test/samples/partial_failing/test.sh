#!/bin/bash

cd "$(dirname "$0")"

main30expected="Int should be String"
main30err=$(haxe test.hxml 2>&1 | grep "Main.hx:30:" | grep -c -m 1 "$main30expected")
if [ ! "$main30err" == "1" ]; then
	echo "Missing expected error: $main30expected"
	exit 1
fi

main35expected="{ e : String, a : String } has extra field e"
main35err=$(haxe test.hxml 2>&1 | grep "Main.hx:35:" | grep -c -m 1 "$main35expected")
if [ ! "$main35err" == "1" ]; then
	echo "Missing expected error: $main35expected"
	exit 1
fi

