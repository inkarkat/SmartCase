This is an extended fork of [Vimscript #1359 by Yuheng Xie](http://www.vim.org/scripts/script.php?script_id=1359).

An example, you may want to replace any FileSize appears in your program into LastModifiedTime. Since it appears everywhere as both uppercases and lowercases, you have to write it several times:

    :%s/FileSize/LastModifiedTime/g      " function names
    :%s/file_size/last_modified_time/g   " variable names
    :%s/FILE_SIZE/LAST_MODIFIED_TIME/g   " macros
    :%s/File size/Last modified time/g   " document/comments

This script copes with the case style for you so that you need write just one command:

    :%s/file\A\?size/\=SmartCase("LastModifiedTime")/ig

An alternative way:
  first search for the string:  `/\cfile\A\?size`
  then run a command:  `:%SmartCase "LastModifiedTime"`

By the way, SmartCase can also cope with the circumstance where you want to replace the string's case style while keeping its words. For example:

    FileSize => file_size
    LastModifiedTime => last_modified_time
    ......

This can be done with the following command:

    :%s/\(\u\l\+\)\{2,}/\=SmartCase(0,"reference_style")/g

To sum up: the first argument to SmartCase is the reference words, the second argument is the reference styles, if the second argument omitted, it's `submatch(0)`.
