# forgex-cli

This is a command line tool for interacting with Fortran Regular Expression.

## Features

## Usage
### Build

Operation has been confirmed with the following compilers:

- GNU Fortran (`gfortran`) v13.2.1
- Intel Fortran Compiler (`ifx`) 2024.0.0 20231017

It is assumed that you will use the Fortran Package Manager(`fpm`).


### Examples

Command:

```shell
forgex-cli find match lazy-dfa '([a-z]*g+)n?' .match. 'assign'
```

If you run it through `fpm run`:

```shell
fpm run --profile release -- find match lazy-dfa '([a-z]*g+)n?' .match. 'assign'
```

Output:

```
             pattern: ([a-z]*g+)n?
                text: 'assign'
          parse time:        42.9us
extract literal time:        23.0us
         runs engine:         T
    compile nfa time:        26.5us
 dfa initialize time:         4.6us
         search time:       617.1us
     matching result:         T
  memory (estimated):     10324

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

### Notes

- If you use this `forgex-cli` command with PowerShell on Windows, use UTF-8 as your system locale to properly input and output Unicode characters.

## To do

The following features are planned to be implemented in the future:

- [x] Add a CLI tool for debugging and benchmarking
- [ ] Publish the documentation
- [ ] Support CMake building
- [x] Add Time measurement tools (basic)

## Code Convention

All code contained herein shall be written with a three-space indentation.

## Acknowledgements

The command-line interface design of `forgex-cli` was inspired in part by the package `regex-cli` of Rust language.

## References

1. [rust-lang/regex/regex-cli](https://github.com/rust-lang/regex/tree/master/regex-cli)

## License
Forgex is as a freely available under the MIT license. See [LICENSE](https://github.com/ShinobuAmasaki/forgex/blob/main/LICENSE).
