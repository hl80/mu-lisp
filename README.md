# mu-lisp

Yet another lisp dialect written in common lisp.

## Installation

mu-lisp requires common lisp to run. Load the file ` main.lisp ` in your common lisp implementation and then run ` (mu-repl) `.
For example with sbcl -
```console
sbcl --load "main.lisp"
(mu-repl)
```
and you are good to go!
Tested with sbcl and ecl. There is no implementation dependent code, so any common lisp implementation will work fine.

## Philosophy

mu-lisp is a minimal lisp dialect, created with simplicity in mind. One of the key features is that symbol tables are stored as hashtables and hashtables are treated as first class objects. For example you can retrieve the value associated with key `key` from hashtable `table` by running
```lisp
(table 'key)
```
You can add a new entry into a table by using `define`
```lisp
(define a 10 table)
```
If the destination hashtable is not specified, it writes to the global symbol table.
```lisp
(define a 10)
==>10
a
==>10
```
Create an empty hashtable with `(empty)`

Divert all define statements to another hashtable using `(to hashtable body)`

And finally append that hashtable to the global environment with `(with-append)`

For example,
```lisp
(define my-library (empty))
(to my-library (load "my-library.lisp"))
(my-library-function) ;will return error!!
(with-append (my-library) (my-library-function)) ; correct
; or
((my-library 'my-library-function))
```

## Commonly used functions and operators
- `function` - create a function, (equivalent of `lambda` in common lisp). For example,
```lisp
(define my-add (function (a b) (+ a b)))
```
- `macro` create a macro
- `pair` - equivalent of cons in common lisp
- `list` - create a list.
- `first` - equivalent of car
- `rest` - equivalent of cdr.
- `def` and `define` - add a new entry to a hashtable (global environment table by default). `def` evaluates the key argument while define doesn't.
- `set` and `setq` - replaces the value of the first entry of a symbol in the symbol table with the specified value.
- `basic` - returns a hashtable with the all the builtin functions.
- `empty` returns an empty hashtable.
- `pack` - equivalent of `progn`
- `let` - create local variable bindings.
- `run` - equivalent of `eval`
- `load` - load a file.
- `format`, `print` and `println` - print to standard output.

## Notes
- mu-lisp is Lisp-1, it does not have a separate namespace for functions.
- mu-lisp has two environment variables. One is a list of hashtables, which is used for symbol lookup (can be obtained by calling `(read-envrs)`), while the other is a hashtable to which new definitions are added (can be obtained by calling `(envr)`). Use `with` and `with-append` to modify the first, and `to` to modify the second.
-  Constructs like ` function macro if to with with-append let ` all take only one statement as argument, if you want multiple statements use `(pack)` (equivalent of `(progn)` in common lisp).

## Interface to Common lisp functions

You can add common lisp functions to mu-lisp. Open `main.lisp` and inside the `global-env` function add an entry for your function. For example to add the sine function, add the following entry -
```lisp
(sine (muify #'sin))
```

## To do

mu-lisp is very much a work in progress. There is a lot left to do, including
- Write a debugger. Currently it drops to host lisp implementations debugger upon error.
- Tail call optimization
- IDE support
- Argument list validation, currently if you provide more arguments than necessary to a function, it ignores the extra arguments.
- `&optional &key &rest` arguments
- Improve documentation.