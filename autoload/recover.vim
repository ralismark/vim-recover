function! recover#swapexists()
	" check if it's because the file is open
	let handled = recover#check_loaded(expand('%:p'))
	if !empty(handled)
		let v:swapchoice = handled
		return
	endif

	" Old Swapfile - kill it
	if getftime(v:swapname) < getftime(expand('%'))
		call confirm("Swapfile older than on-disk file - deleting it")
		call delete(v:swapname)
		let v:swapchoice = 'e'
		return
	endif

	" Actual swapexists
	" check difference between recovered file and original file
	" if same, delete swap
	au BufWinEnter * ++once call recover#swapcheck()
	let b:swapname = v:swapname
	let v:swapchoice = 'r'
endfunction!

" check recovered and original
function! recover#swapcheck()
	recover
	let recov_buf = bufnr('%')
	let recov_len = line('$')
	" Similar to :DiffOrig
	new
	set bt=nofile
	r ++edit #
	0d_
	exe 'file' fnameescape(expand('#') . ' (on-disk pre-recovery)')
	let orig_buf = bufnr('%')
	let orig_len = line('$')
	wincmd p " go back to orig

	let diff = 0

	" check the files
	if recov_len != orig_len
		let diff = 1
	endif
	for line in range(1, orig_len + 1)
		if diff
			break
		endif
		let diff = getbufline(recov_buf, line) !=# getbufline(orig_buf, line)
	endfor

	if diff
		call confirm("Recovered file differs from on-disk original! See open buffers", '', 1, 'E')
	else
		call confirm("No difference between on-disk and recovered - swap deleted")
		" delete extra buffer
		exec 'bdelete!' orig_buf
		call delete(b:swapname)
	endif
endfunction

" gets a list of opened files, for use in recover#check_loaded
function! recover#list_opened_files()
	let loaded_bufnrs = filter(range(1, bufnr("$")), "bufloaded(v:val)")
	let opened_paths = map(loaded_bufnrs, "expand('#' . v:val . ':p')")
	return getpid() . "\n" . join(opened_paths, "\n")
endfunction

" checks if the file is already loaded (in another instance)
function! recover#check_loaded(filename)
	let servers = has('nvim')
		\ ? systemlist(['nvr', '--serverlist'])
		\ : split(serverlist(), "\n")
	if type(servers) != v:t_list
		return '' " nvr failed
	endif

	" nvr can duplicate servers
	for server in uniq(servers)
		" Skip ourselves.
		if server ==? v:servername
			continue
		endif

		" Get all files that a server has open
		let remote_exec_output = has('nvim')
			\ ? system(['nvr', '--servername', server, '--remote-expr', "recover#list_opened_files()"])
			\ : remote_expr(server, "recover#list_opened_files()")
		" first line is pid, the rest are paths
		let lines = split(remote_exec_output, "\n")
		if index(lines[1:], a:filename) >= 0
			" Tell the user what is happening.
			call confirm("File is being edited by " . server . " (pid " . lines[0] . ")", '', 1, 'E')
			return 'q'
		endif
	endfor
	return ''
endfunction
