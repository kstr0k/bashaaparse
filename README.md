# bashaaparse

## _Automated arg-parsing / `--help` generation for POSIX `sh` / bash / zsh_

There are currently three argument parsers, all of which generate `--help` usage messages compatible with bash completion (`complete -F _longopt mytool`):
- [`min-template.sh`](#min-template): compact POSIX **sh** / bash / zsh parser (see [testing / portability](#testing-and-portability)) that automatically reads `--long-opt=value` and generates `--help` for expected options (`'-?'` shows **defaults** too). Least coding required (see [usage](#usage)); best option for scripts not limited by existing contract. Other syntaxes can be implemented, but won't show up in the auto-generated help.
- [`simple-template.sh`](#simple-template): scaffolding for Bash scripts; includes auto-help for more complex options, and various utilities that most scripts require
- [`bashaap`](bashaap/k9s0ke_bashaap-2.0.sh): not currently documented or maintained.

*Notes*
- development takes place at [GitLab `bashaaparse`](https://gitlab.com/kstr0k/bashaaparse) but you can also report issues at the [GitHub `bashaaparse` mirror](https://github.com/kstr0k/bashaaparse)

## min-template

### Setup

If you source [`min-template.sh` (downloadable link)](https://gitlab.com/kstr0k/bashaaparse/-/raw/master/min-template.sh), override `__main()` (the default prints positional and option arguments), and call `__parse_args "$@"`, it works **out of the box in sh / bash / zsh**.

To generate a (possibly optimized and stripped) **shell-specific version**, to be checked in a repo and sourced (or pasted into code directly), run
```
bash -euc '. /original/min-template.sh ----gen={bash|sh}[-strip]' >./min-t.sh

## pure sh:
s=/original/min-template.sh
(. "$s";  __parse_args ----gen={bash|sh}[-strip] --src="$s") >./min-t.sh

## from the web, no separate download:
mt=$(curl -s 'https://gitlab.com/kstr0k/bashaaparse/-/raw/master/min-template.sh')
(eval "$mt"; __parse_args --src="$mt" ----gen=sh-strip >./min-t.sh)

## sh/bash used to generate doesn't affect result, but may save keystrokes
## gen=bash result works in zsh too
## --src can be source code, file, '-', 'http://', or full URL
```

### Incorporating

`min-template` must be either copy/pasted into, or sourced from scripts that use it. If sourcing, see [the wiki](https://gitlab.com/kstr0k/bashaaparse/-/wikis/Parsers/min_template) for why this is a non-trivial task. Some choices:
- hard-code a path in the user's cache directory (`"${XDG_CACHE_HOME:-$HOME/.cache}"/mypkg/min-t.sh`, or similarly under `${XDG_DATA_HOME:-$HOME/.local/share}/`); either download if missing, or copy as an installation step.
- install `min-template` under a predictable system path beforehand
- accept `$(dirname "$0")` if the cost is negligible
- copy/paste `min-template.sh` into scripts to squeeze every bit of performance and avoid usage hassles (but deal with updates manually).
- it's possible (but involved) to download `min-template` on the fly, strip it, and save it next to a script that needs it, *only if missing*. See `examples/get-min-template.sh --help` for ideas.

### Usage

- all option arguments have the form `--long-opt=value` (with `--my_opt` silently translated to `--my-opt`), and must come before any positional arguments (`--` stops option processing). You **don't need any code to parse these**: all options are stored in globals of the form `_O_long_opt` (intuitive, and easy to type / search for)
- `--no-some-opt` is interpreted as `--some-opt=false` and `--some-opt` (if not covered by previous cases) as `--some-opt=true` (see note on [shell booleans](#shell-booleans))
- if you predeclare defaults for the `_O_globals` (even empty strings, e.g. `_O_dir=`), then `--help` will automatically list the corresponding flags ( `-?` will also show their values).

To initiate parsing and execution
- call `__parse_args "$@"`, which processes one argument at a time and calls itself recursively
- when `__parse_args` exhausts option arguments, it calls `__main` with the remaining (if any) positional arguments
- don't place any code after calling `__parse_args` &mdash; it probably won't return anything usable. If the script is a wrapper for some other program, it might as well `exec` it at the end of `__main()`, to avoid a dangling shell waiting for nothing.

Extra processing, such as separated / short versions of the longopts (e.g. `-f` as an alias for `--force`, `-b branch` etc), sanity / security checks, or setting the `--help` header and footer, can be defined by overriding `__process_arg()`.

More details on the [min-template wiki](https://gitlab.com/kstr0k/bashaaparse/-/wikis/Parsers/min_template).

### Testing and portability

`min-template` has been tested with several shells (`dash`, `bash`, FreeBSD `sh`, `busybox sh`, `zsh` + its emulations) and `sed` implementations (GNU / BSD sed, perl [`psed`](https://metacpan.org/pod/App::s2p)). Tests (see [`mintemplate.t`](https://gitlab.com/kstr0k/bashaaparse/-/blob/master/t/min-template.t#L6)) use the [`t3st`](https://gitlab.com/kstr0k/t3st) framework.

## simple-template

If you follow some simple conventions, this script generates a usage message **directly from argument parsing code** (which should be structured as a big `case` statement). It uses bash's introspection capabilities (`declare -f`) to inspect the function that parses arguments and extract the command-line switches. You'll need to copy and modify `usage()` and `parse_args()` from the template, which already provide boilerplate to loop over arguments comortably.

You might want to have a look at the structure of the [code](simple-template.sh) to undertand the following details.

This script is ready-to-run (and contains self-testing[^2], if enabled); copy it to scaffold new scripts and add options / modify as desired. Out of the box:
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

### Shell booleans

An interesting trick for testing booleans is to evaluate them directly (that is, `if "$_O_USE_GIT" ...` **without `test` or `[ ... ]`**). This works because `true` and `false` are actual shell commands (builtins, even &mdash; no performance loss) that set success / failure exit codes, which can be acted on by conditionals.

### Positional arguments

&hellip; (starting at the first non-option, or after `--`) are left in the `ARGV` array. The script calls `main()` with these arguments (which become `$1`, `$2` etc inside the function), but if you're modifying an existing script (e.g. to replace an existing parser), you can discard the `main` call and do
```
set -- "${ARGV[@]}"
```
right after `parse_args`. This will set the global `$1`, `$2` to the remaining args, as most hand-rolled scripts expect after handling flags.

## Copyright

`Alin Mr. <almr.oss@outlook.com>` / MIT license

## See also

* [`t3st`](https://gitlab.com/kstr0k/t3st): a shell TAP testing framework &mdash; this is what `min-template` currently uses.
* [`f8ksh`](https://gitlab.com/kstr0k/f8ksh): shell logging and profiling
* Other shell argument parsers
  - https://argbash.io/
  - https://github.com/Anvil/bash-argsparse
  - https://github.com/nhoffman/argparse-bash
  - https://github.com/massenz/common-utils
  - https://github.com/ko1nksm/getoptions

[^1]: you might object to this definition of "verbose", but the goal here is to get up and running as quickly as possible &mdash; you're welcome to change this default to something more elaborate (OTOH, your script will have debugging capabilities without writing a single line of code).
[^2]: if you run the `sed` command shown at the top of the `simple-template.sh`, the embedded test code will be uncommented, bash will run the modified script from `stdin`, and various sample arguments (or the `--help`, if requested) will be shown in the terminal.
