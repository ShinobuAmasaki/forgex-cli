This package provides a command line tool which named `forgex-cli` for interacting with [Forgex—Fortran Regular Expression](https://github.com/ShinobuAmasaki/forgex).
The `forgex-cli` command was originally part of Forgex package, but was moved to this separate repository starting with Forgex version 3.5.

## Installation

### Getting Source Code

Clone the repository:

```shell
git clone https://github.com/shinobuamasaki/forgex-cli
```

Alternatively, download the latest source package:

```shell
wget https://github.com/ShinobuAmasaki/forgex-cli/archive/refs/tags/v3.5.tar.gz
```

In that case, decompress the archive file:

```shell
tar xvzf v3.5.tar.gz
```

### Building

Change directory to the cloned or decompressed location:

```shell
cd forgex-cli
```

Execute building with Fortran Package Manager (`fpm`):

```shell 
fpm build
```

This will automatically resolve the dependency and compile `forgex-cli`, including `forgex`.


## Operation Check

Operation of this command has been confirmed with the following compilers:

- GNU Fortran (`gfortran`) v13.2.1
- Intel Fortran Compiler (`ifx`) 2024.0.0 20231017

It is assumed that you will use the Fortran Package Manager(`fpm`).

## Usage

This article describes basic usage of `forgex-cli`.
 <!-- [Please refer to each article in the documentation](https://shinobuamasaki.github.io/forgex-cli/page/index.html) for detailed information on commands, subcommands, option flags, and displaying results. -->

### Command Line Interface

Currently, commands `find` and `debug`,  and following subcommands and sub-subcommands can be executed:

```
forgex-cli
├── find
│   └── match
│       ├── lazy-dfa <pattern> <operator> <input text>
│       ├── dense <pattern> <operator> <input text>
│       └── forgex <pattern> <operator> <input text>
└── debug
    ├── ast <pattern>
    └── thompson <pattern>
```

Run the `forgex-cli` command as follows:

```
forgex-cli <comamnd> <subcommand> ...
fpm run -- <command> <subcommand> ...
```

### Examples

#### `find` command 

Using the `find` command and the `match` subcommand, you can specify an engine and run benchmark tests on regular expression matching with `.in.` and `.match.` operators.
After the subcommand, select the engine from,

- `lazy-dfa`,
- `dense`,
- `forgex`,

and after that, specify the pattern, operator, and input string as if you were writing Fortran code using Forgex to perform matching.

For instance, execute the `find` command:

```shell
forgex-cli find match lazy-dfa '([a-z]*g+)n?' .match. 'assign'
```

If you run it through `fpm run`:

```shell
fpm run --profile release -- find match lazy-dfa '([a-z]*g+)n?' .match. 'assign'
```

and you will get output similar to the following:

<div class="none-highlight-user">

```
                pattern: ([a-z]*g+)n?
                   text: 'assign'
             parse time:        42.9μs
   extract literal time:        23.0μs
            runs engine:         T
       compile nfa time:        26.5μs
    dfa initialize time:         4.6μs
            search time:       617.1μs
        matching result:         T
 automata and tree size:     10324  bytes

========== Thompson NFA ===========
state    1: (?, 5)
state    2: <Accepted>
state    3: (n, 2)(?, 2)
state    4: (g, 7)
state    5: (["a"-"f"], 6)(g, 6)(["h"-"m"], 6)(n, 6)(["o"-"z"], 6)(?, 4)
state    6: (?, 5)
state    7: (?, 8)
state    8: (g, 9)(?, 3)
state    9: (?, 8)
=============== DFA ===============
   1 : ["a"-"f"]=>2
   2 : ["o"-"z"]=>2 ["h"-"m"]=>2 g=>3
   3A: n=>4
   4A:
state    1  = ( 1 4 5 )
state    2  = ( 4 5 6 )
state    3A = ( 2 3 4 5 6 7 8 )
state    4A = ( 2 4 5 6 )
===================================
```

</div>

#### `debug`

Using `debug` command allows you to obtain information about the abstract syntax tree and the structure of the Thompson NFA.

For example, execute the `debug` command with `ast` subcommand:

```shell
forgex-cli debug ast 'foo[0-9]+bar'
```

then, you will get output similar to the following: 

<div class="none-highlight-user">

```
        parse time:       133.8μs
      extract time:        36.8μs
 extracted literal:
  extracted prefix: foo
  extracted suffix: bar
memory (estimated):       848
(concatenate (concatenate (concatenate (concatenate (concatenate (concatenate "f" "o") "o") (concatenate [ "0"-"9";] (closure[ "0"-"9";]))) "b") "a") "r")
```

</div>

Note: Notice also that the prefix and suffix literals are now extracted.



Here's how to get a graph of the NFA. To get the Thompson NFA, run the following command:

```shell
forgex-cli debug thompson 'foo[0-9]+bar'
```

This will give you output like this:

```
        parse time:       144.5μs
  compile nfa time:        57.0μs
memory (estimated):     11589

========== Thompson NFA ===========
state    1: (f, 8)
state    2: <Accepted>
state    3: (r, 2)
state    4: (a, 3)
state    5: (b, 4)
state    6: (["0"-"9"], 9)
state    7: (o, 6)
state    8: (o, 7)
state    9: (?, 10)
state   10: (["0"-"9"], 11)(?, 5)
state   11: (?, 10)

Note: all segments of NFA were disjoined with overlapping portions.
===================================
```

### Notes

- You can get information about available option flags specifying the `--help` command line argument.
- If you use this `forgex-cli` command with PowerShell on Windows, use UTF-8 as your system locale to properly input and output Unicode characters.

## To do

The following features are planned to be implemented in the future:

- Publish the documentation
- Support CMake building
- ✅️ Add a CLI tool for debugging and benchmarking
- ✅️ Add Time measurement tools (basic)

## Code Convention

All code contained herein shall be written with a three-space indentation.

## Acknowledgements

The command-line interface design of `forgex-cli` was inspired in part by the package `regex-cli` of Rust language.

## References

1. [rust-lang/regex/regex-cli](https://github.com/rust-lang/regex/tree/master/regex-cli)

## License
Forgex-CLI is as a freely available under the MIT license. See [LICENSE](https://github.com/ShinobuAmasaki/forgex-cli/blob/main/LICENSE).
