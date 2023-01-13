function! recover#swapexists()
	let filename = expand("%:p")

	" check if it's because the file is open
	let handled = recover#check_loaded(v:swapname, filename)
	if !empty(handled)
		let v:swapchoice = handled
		return
	endif

	let ftime = getftime(filename)

	if getftime(v:swapname) < ftime " Old Swapfile - kill it
		call confirm("Swapfile older than on-disk file - deleting it")
		call delete(v:swapname)
		let v:swapchoice = 'e'
		return
	elseif ftime == -1 " File does not exist, nothing to diff
		let v:swapchoice = 'r'
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

" checks if the file is already loaded (in another instance)
function! recover#check_loaded(swapname, filename)
	return ''
	if exists("*swapinfo") && has("unix")
		let si = swapinfo(a:swapname)
		if isdirectory("/proc/" . si.pid)
			call confirm("File is being edited by another instance! (pid " . si.pid . ")", '', 1, 'E')
			return 'q'
		endif
		" TODO windows support
		" TODO try open the existing instance? or some hook to do that?
	endif
	return ''
endfunction
