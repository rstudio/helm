#!/usr/bin/env bash
if git status --porcelain=1 2>&1 | grep -E "^.|\bwarning\b" | grep -vE "\.gitignore"; then
	echo "Error: uncommitted changes detected."
	exit 1
fi
