# bashaaparse

## _Automate arg-parsing / usage generation in Bash_

There are currently two parsers:
- [`simple-template.sh`](simple-template.sh): use this as a scaffolding for your Bash scripts &mdash; it's documented below.
- [`bashaap`](bashaap/k9s0ke_bashaap-2.0.sh): more automated, but requires distributing and sourcing a separate file. Not currently documented.

## simple-template

If you follow some simple conventions, this script generates a usage message **directly from argument parsing code**. It uses bash's introspection capabilities (`declare -f`) to inspect the function that parses arguments and extract the command-line switches. You'll need to copy and modify `usage()` and `parse_args()` from the template, which already provide boilerplate to loop over arguments comortably.

You might want to have a look at the structure of the [code](simple-template.sh) to undertand the following details.

This script is ready-to-run (and contains self-testing[^2], if enabled); copy it to scaffold your new scripts and add options / modify as desired. Out of the box:
```
$ ./simple-template.sh --help
Usage: simple-template.sh [OPTION...]
Options:
  -h | --help
  -v | --verbose
  --version
Defaults:

$ ./simple-template.sh --version  # GIT last
7eff9c4:1621930881
```

### Adding options

Adding a simple action argument inside the `parse_args` loop is as easy as the builtin (admittedly rudimentary) default:
```
-v|--verbose) set -x ;;
```

That's it[^1] &mdash; the framework takes care of shifting out the current argument and listing it in the usage. In most cases, of course, flags need to set an internal variable to be acted upon later &mdash; either a boolean or a string. Option values are stored in corresponding globals `_O_*` (initialize them at the top of `parse_args`). Adding either boolean or valued arguments is also trivial, if you only use longopts (or see below):
```
## go to section 3 of parse_args; add
--use-git) ;& --no-use-git) ;& --file=*)
## uncomment the parsing code

# ... later on in your code ...
if $_O_USE_GIT; then git --log >"$_O_FILE"; fi
```

Again, that's it. All the listed arguments will show up in `--help`, and their values will be available as `_O_USE_GIT` (`true` or `false`, if you call the script with `--use-git` / `--no-use-git`) and `$_O_FILE` (if you supply `--file="$HOME/My Video.mp4"`).

An interesting trick for testing booleans is to evaluate them directly (that is, `if $_O_USE_GIT ...` **without quotes**). This works because in Bash, `true` and `false` are actual commands that return success / failure exit codes, which can be acted on by conditionals. This is *not* inefficient, as `true` and `false` are Bash built-ins.

If you stick to long options and `--arg=value` (not `--arg value`), you have it *this* easy. To combine long- and short-options, or handle separate-valued arguments, see section 2 inside `parse_args`. It's not much more difficult or verbose, but for maximum efficiency and maintainability (as in [DRY](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself)), it's easier to *not* use those.

### Positional arguments

&hellip; (starting at the first non-option, or after `--`) are left in the `ARGV` array. The script calls `main()` with these arguments (which become `$1`, `$2` etc inside the function), but if you're modifying an existing script (e.g. to replace an existing parser), you can discard the `main` call and do
```
set -- "${ARGV[@]}"
```
right after `parse_args`. This will set the global `$1`, `$2` to the remaining args, as most hand-rolled scripts expect after handling flags.

## Copyright

`Alin Mr. <almr.oss@outlook.com>` / MIT license

## See also

- https://argbash.io/
- https://github.com/Anvil/bash-argsparse
- https://github.com/nhoffman/argparse-bash
- https://github.com/massenz/common-utils
- https://github.com/ko1nksm/getoptions
- https://shellspec.info/

[^1]: you might object to this definition of "verbose", but the goal here is to get up and running as quickly as possible &mdash; you're welcome to change this default to something more elaborate (OTOH, your script will have debugging capabilities without writing a single line of code).
[^2]: If you run the `sed` command shown at the top of the `simple-template.sh`, the embedded test code will be uncommented, bash will run the modified script from `stdin`, and various sample arguments (or the `--help`, if requested) will be shown in the terminal.
