" Script Name: smartcase.vim
" Version:     1.0.2
" Last Change: January 12, 2006
" 				/^-- 20-Jan-2012 Allow use of backreferences &
" 				and \0 .. \9 in str_words. 
" 				/^-- 13-Apr-2011 Enhanced :SmartCase command to take the same
" 				arguments as :substitute, so that no previous search is
" 				necessary, and the invocation is more intuitive. 
" 				Added include and version guard, as this now requires Vim 7.0. 
" Author:      Yuheng Xie <elephant@linux.net.cn>
"
" Description: replacing words while keeping original lower/uppercase style
"
"              An example, you may want to replace any FileSize appears in
"              your program into LastModifiedTime. Since it appears everywhere
"              as both uppercases and lowercases, you have to write it several
"              times:
"
"                :%s/FileSize/LastModifiedTime/g      " function names
"                :%s/file_size/last_modified_time/g   " variable names
"                :%s/FILE_SIZE/LAST_MODIFIED_TIME/g   " macros
"                :%s/File size/Last modified time/g   " document/comments
"                ......
"
"              This script copes with the case style for you so that you need
"              write just one command:
"
"                :%s/file\A\?size/\=SmartCase("LastModifiedTime")/ig
"
" Details:     SmartCase(str_words, str_styles = 0) make a new string using
"              the words from str_words and the lower/uppercases styles from
"              str_styles. If any of the arguments is a number n, it's
"              equivalent to submatch(n). str_word can include the
"              |sub-replace-special| strings & and \0 .. \9 that refer to the
"              (whole or parts of the) matched pattern.
"              If str_styles is omitted, it's 0.
"
"              SmartCase recognizes words in three case styles: 1: xxxx (all
"              lowercases), 2: XXXX(all uppercases) and 3: Xxxx(one uppercase
"              following by lowercases).
"
"              For example, str_styles "getFileName" will be cut into three
"              words: "get"(style 1), "File"(style 3) and "Name"(style 3). If
"              str_words is "MAX_SIZE", it will be treated as two words: "max"
"              and "size", their case styles is unimportant. The final result
"              string will be "maxSize".
"
"              A note, in the case some uppercases following by some
"              lowercases, e.g. "HTMLFormat", SmartCase will treat it as
"              "HTML"(2) and "Format"(3) instead of "HTMLF"(2) and "ormat"(1).
"
" Usage:       1. call SmartCase(str_words, str_styles) in replace expression
"
"              The simplest way: (in most cases, you will need the /i flag)
"
"                :%s/goodday/\=SmartCase("HelloWorld")/ig
"
"              This will replace any GoodDay into HelloWorld, GOODDAY into
"              HELLOWORLD, etc.
"
"              For convenience, if str_styles is omitted, it will be set to
"              submatch(0). Or if any of the arguments is a number n, it will
"              be set to submatch(n). Example:
"
"                :%s/good\(day\)/\=SmartCase("HelloWorld", 1)/ig
"
"              It's equivalent to:
"
"                :%s/good\(day\)/\=SmartCase("HelloWorld", submatch(1))/ig
"
"              2. use SmartCase as command
"
"              (Note that a range is needed, and it doesn't matter whether you
"              say "hello world" or "HelloWorld" as long as words could be
"              discerned. Also, there's no need to use \c or pass the /i flag,
"              the search will be case-insensitive automatically.)
"
"                :%SmartCase /goodday/hello world/g
"
"              This will do exactly the same as mentioned in usage 1.
"
"              If you want to re-use the previous search string, you can omit
"              the full substitution argument and just pass the replacement: 
"
"                /\cgoodday
"                :%SmartCase hello world
"
"              This will do a global substitution, without explicitly passing
"              the /i flag, so the current case sensitivity applies. 
"
"              3. replacing lower/uppercases style, keeping original words
"
"              As an opposition to usage 1., this can be achieved by using
"              submatch(0) as str_words instead of str_styles. Example:
"
"                :%s/\(\u\l\+\)\+/\=SmartCase(0, "x_x")/g
"
"              This will replace any GoodDay into good_day, HelloWorld into
"              hello_world, etc.

" Avoid installing twice or when in unsupported Vim version. 
if exists('g:loaded_smartcase') || (v:version < 700)
	finish
endif
let g:loaded_smartcase = 1

function! s:SmartCaseSubstitution( substitutionArgs )
	let l:matches = matchlist(a:substitutionArgs, '\(\s*\(\A\).*\%(\%(^\|[^\\]\)\%(\\\\\)*\\\)\@<!\2\)\(.*\)\(\%(\%(^\|[^\\]\)\%(\\\\\)*\\\)\@<!\2\S*\)\(\s\+\S.*\)\?')
	if empty(l:matches)
		return '//\=SmartCase(' . string(escape(a:substitutionArgs, '/')) . ')/g'
	else
		let [l:pattern, l:separator, l:replacement, l:flags, l:count] = l:matches[1:5]
	endif

	":<line1>,<line2>s//\=SmartCase(<f-args>)/g
	return l:pattern . '\=SmartCase(' . string(l:replacement) . ')' . l:flags . (l:flags =~# 'i' ? '' : 'i') . l:count
endfunction
command! -range -nargs=+ SmartCase execute '<line1>,<line2>substitute' <SID>SmartCaseSubstitution(<q-args>)
"****D command! -range -nargs=+ SmartCaseDebug execute 'echomsg' string(<SID>SmartCaseSubstitution(<q-args>))

function! s:ExpandReplacement( str )
	let unescapedExpr = '\%(\%(^\|[^\\]\)\%(\\\\\)*\\\)\@<!'
	let str = a:str

	if a:str =~# l:unescapedExpr . (&magic ? '' : '\\') . '&'
		" handle & for whole matched pattern
		let str = substitute(str, unescapedExpr . (&magic ? '' : '\\') . '&', submatch(0), 'g')
	endif

	for backref in filter(map(split(a:str, unescapedExpr . '\\\d\zs'), 'strpart(v:val, strlen(v:val) - 1)'), 'v:val =~# "\\d"')
		" handle back references \0 .. \9
		let str = substitute(str, unescapedExpr . '\\' . backref, submatch(backref), '')
	endfor
	return str
endfunction
" make a new string using the words from str_words and the lower/uppercase
" styles from str_styles
function! SmartCase(...) " SmartCase(str_words, str_styles = 0)
	if a:0 == 0
		return
	elseif a:0 == 1
		let str_words = a:1
		let str_styles = submatch(0)
		if matchstr(str_words, '\d\+') == str_words
			let str_words = submatch(0 + str_words)
		else
			let str_words = s:ExpandReplacement(str_words)
		endif
	else
		let str_words = a:1
		let str_styles = a:2
		if matchstr(str_words, '\d\+') == str_words
			let str_words = submatch(0 + str_words)
		else
			let str_words = s:ExpandReplacement(str_words)
		endif
		if matchstr(str_styles, '\d\+') == str_styles
			let str_styles = submatch(0 + str_styles)
		endif
	endif

	let regexp = '\l\+\|\u\l\+\|\u\+\l\@!'
	let result = ""
	let i = 0
	let j = 0
	let separator = ""
	let case = 0
	while j < strlen(str_words)
		if i < strlen(str_styles)
			let s = match(str_styles, regexp, i)
			if s >= 0
				let e = matchend(str_styles, regexp, s)
				let separator = strpart(str_styles, i, s - i)
				let word = strpart(str_styles, s, e - s)
				if word ==# tolower(word)
					let case = 1  " all lowercases
				elseif word ==# toupper(word)
					let case = 2  " all uppercases
				else
					let case = 3  " one uppercase following by lowercases
				endif
				let i = e
			endif
		endif

		let s = match(str_words, regexp, j)
		if s >= 0
			let e = matchend(str_words, regexp, s)
			let word = strpart(str_words, s, e - s)
			if case == 1
				let result = result . separator . tolower(word)
			elseif case == 2
				let result = result . separator . toupper(word)
			elseif case == 3
				let result = result . separator . toupper(strpart(word, 0, 1)) . tolower(strpart(word, 1))
			else
				let result = result . separator . word
			endif
			let j = e
		else
			break
		endif
	endwhile

	while i < strlen(str_styles)
		let e = matchend(str_styles, regexp, i)
		if e >= 0
			let i = e
		else
			break
		endif
	endwhile
	let result = result . strpart(str_styles, i)

	return result
endfunction
