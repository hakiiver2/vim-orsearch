# vim-orsearch

> Powerful OR/NOT/Phrase search for Vim

vim-orsearch extends Vim's native search with OR, NOT, and phrase matching capabilities, making it easy to find exactly what you're looking for in your files.

## Features

- **OR Search**: Find lines containing ANY of multiple terms
- **NOT Search**: Exclude lines containing specific terms
- **Phrase Search**: Match exact phrases using quotes
- **Integrated Mode**: Use `/` for OrSearch (optional)
- **Auto-Detection**: Seamlessly switches between OrSearch and Vim search
- **Pure Vimscript**: No external dependencies
- **Lightweight**: ~350 lines of code
- **Japanese Support**: Full-width space normalization

## Installation

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'hakiiver2/vim-orsearch'
```

### Using [Vundle](https://github.com/VundleVim/Vundle.vim)

```vim
Plugin 'hakiiver2/vim-orsearch'
```

### Using [Pathogen](https://github.com/tpope/vim-pathogen)

```bash
cd ~/.vim/bundle
git clone https://github.com/hakiiver2/vim-orsearch.git
```

### Manual Installation

```bash
mkdir -p ~/.vim/plugin ~/.vim/doc
cp plugin/orsearch.vim ~/.vim/plugin/
cp doc/orsearch.txt ~/.vim/doc/
vim -c 'helptags ~/.vim/doc' -c quit
```

## Quick Start

### Interactive Mode

```vim
:OrSearch
```

Type your query and press Enter:

```
OR search> foo bar -baz
```

### Direct Query Mode

```vim
:OrSearch foo bar -baz
```

### Using Mapping

Default mapping: `<leader>/`

```vim
<leader>/
```

## Query Syntax

### Basic OR Search

Find lines containing ANY of the terms:

```
foo bar baz
```

Matches lines with: `foo` OR `bar` OR `baz`

### NOT Search (Exclusion)

Find lines NOT containing specific terms:

```
error -debug
```

Matches lines with: `error` but NOT `debug`

### Phrase Search

Find exact phrases using quotes:

```
"function definition"
```

Matches only the exact phrase: `function definition`

### NOT Phrase

Exclude exact phrases:

```
-"test case"
```

Excludes lines containing: `test case`

### Complex Queries

Combine all syntax types:

```
error warning -debug -"test case"
```

Matches lines with `error` OR `warning`, but NOT `debug` and NOT `test case`

## Examples

### Find Function Definitions

```vim
:OrSearch "function " "def " "fn "
```

### Find Errors (Excluding Tests)

```vim
:OrSearch error -test
```

### Find TODO/FIXME Comments

```vim
:OrSearch TODO FIXME HACK
```

### Find Imports (Excluding Tests)

```vim
:OrSearch "import React" "import Vue" -test -spec
```

### Japanese Text Search

```vim
:OrSearch エラー 警告 -デバッグ
```

## Configuration

### Disable Default Mapping

```vim
let g:orsearch_no_default_mappings = 1
```

### Custom Mapping

```vim
nmap <C-s> <Plug>OrSearch
```

### Space as OR Separator

```vim
let g:orsearch_space_or = 1  " default
```

### Integrated Mode (Use `/` for OrSearch)

Enable integrated mode to use OrSearch with the `/` command:

```vim
let g:orsearch_integrated_mode = 1
```

With integrated mode enabled:
- Press `/` to start search
- Queries with OrSearch syntax (spaces, `-`, `""`) use OrSearch
- Regular regex patterns fall back to Vim's default search
- Seamlessly switch between both modes

Examples:
```vim
/foo bar          → Uses OrSearch (contains space)
/error -debug     → Uses OrSearch (contains -)
/"exact phrase"   → Uses OrSearch (contains quotes)
/\d\+             → Uses Vim search (regex pattern)
/^function        → Uses Vim search (no OrSearch syntax)
```

Disable auto-detection (always use OrSearch in integrated mode):
```vim
let g:orsearch_integrated_mode = 1
let g:orsearch_auto_detect = 0
```

## Documentation

Full documentation is available via:

```vim
:help orsearch
```

## How It Works

1. **Query Parsing**: Input is tokenized into OR terms, NOT terms, and phrases
2. **Pattern Generation**: Creates Vim regex pattern using `\V` (very nomagic) mode
3. **Search Execution**: Performs standard Vim search with generated pattern
4. **Post-Filtering**: Skips matches containing NOT terms

## Roadmap

### v0.1
- OR / NOT / Phrase search
- Interactive and direct query modes
- Full-width space normalization

### v0.2 (Current)
- Integrated mode (`/` command integration)
- Auto-detection of OrSearch syntax
- Seamless fallback to Vim search

### v0.3 (Planned)
- AND operator (`&foo &bar`)
- Fuzzy matching (`~foo`)
- Case sensitivity toggle

### v0.4 (Planned)
- Search history
- Query completion

### v0.5 (Planned)
- Advanced Japanese text support
- Regex mode toggle
- Custom operators

## Philosophy

vim-orsearch follows Vim's philosophy:

- **Non-invasive**: Works alongside native search (`/`)
- **Composable**: Integrates with Vim's search infrastructure
- **Lightweight**: Minimal code, maximum functionality
- **Extensible**: Easy to customize and extend

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## License

MIT License - see LICENSE file for details

## Credits

Inspired by the need for flexible text search in Vim without external dependencies.

---

Made with Vim
