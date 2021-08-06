# bashaaparse

## _Automate arg-parsing / usage generation in sh / bash / zsh_

There are currently three argument parsers, all of which generate `--help` usage messages compatible with bash completion (`complete -F _longopt mytool`):
- [`min-template.sh`](min-template.sh): minimalistic sh / bash / zsh parser that still supports --long-opt=value with auto-generated usage. Least code; best for any new script not limited by existing contract. Limitations: other types of options can be implemented, but won't show up in auto-generated help
- [`simple-template.sh`](simple-template.sh): use as scaffolding for your Bash scripts; includes auto-help for more complex options, and various utilities that most scripts require
- [`bashaap`](bashaap/k9s0ke_bashaap-2.0.sh): not currently documented or maintained.

## min-template

You don't need to copy/paste `min-template` &mdash; if you source it, override `__main()` (the default prints positional and option arguments), and call `__parse_args "$@"`, it works **out of the box in bash / zsh**. To generate a (possibly stripped) POSIX **`sh` version**, to be sourced or pasted into code, call
```
bash -uec '. ./min-template.sh; __parse_args ----gen=sh-strip >mt.sh'
# or zsh -uec...; also ... ----gen=bash[-strip]; "bash" versions ok in zsh too
```

All option arguments must be of the form `--long-opt=value`, and must come before any positional arguments (`--` stops option processing). You **don't need any code to parse these**: all options are stored in globals of the form `_O_long_opt` (`_O_` is easy to type / search, and quite intuitive). Additionally, `--no-some-opt` is interpreted as `--some-opt=false` and `--some-opt` (if not covered by previous cases) as `--some-opt=true` (see note on [Bash booleans](#bash-booleans)). If you predeclare defaults for the `_O_globals` (even empty strings, e.g. `_O_dir=`), then `--help` will automatically list the corresponding flags.

To initiate parsing , call `__parse_args "$@"`, which in turn calls itself recursively; when it exhausts option arguments, it calls `__main` with the remaining (if any) positional arguments. You shouldn't place any code after the calling `__parse_args` &mdash; it probably won't return anything usable. If your script is a wrapper for some other program, you might as well `exec` it at the end of `__main()`, to avoid a dangling shell process waiting for nothing.

Extra processing, such as separated / short versions of the longopts (e.g. `-f` as an alias for `--force`, `-b branch` etc), sanity / security checks, or setting the `--help` header and footer, can be defined by overriding (or modifying) `__process_arg()`.

## simple-template

If you follow some simple conventions, this script generates a usage message **directly from argument parsing code** (which should be structured as a big `case` statement). It uses bash's introspection capabilities (`declare -f`) to inspect the function that parses arguments and extract the command-line switches. You'll need to copy and modify `usage()` and `parse_args()` from the template, which already provide boilerplate to loop over arguments comortably.

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

If you stick to long options and `--arg=value` (not `--arg value`), you have it *this* easy. To combine long- and short-options, or handle separate-valued arguments, see section 2 inside `parse_args`. It's not much more difficult or verbose, but for maximum efficiency and maintainability (as in [DRY](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself)), it's easier to *not* use those.

### Bash booleans

An interesting trick for testing booleans is to evaluate them directly (that is, `if $_O_USE_GIT ...` **without quotes**). This works because in Bash, `true` and `false` are actual commands that return success / failure exit codes, which can be acted on by conditionals. This is *not* inefficient, as `true` and `false` are Bash built-ins.

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
[^2]: if you run the `sed` command shown at the top of the `simple-template.sh`, the embedded test code will be uncommented, bash will run the modified script from `stdin`, and various sample arguments (or the `--help`, if requested) will be shown in the terminal.
