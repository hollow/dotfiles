function remove_substring(target, str,  start) {
    if (start = index(target, str)) {
        return substr(target, 1, start-1) substr(target, start+length(str))
    } else {
        return target
    }
}

/^\+[0-9]+\.[0-9]{6}[0-9]* / {
    if (match($0, /IFS=.+:[0-9]+> /)) {
        extra = substr($0, RSTART, RLENGTH)
        if (match(extra, / \+[0-9]+\.[0-9]{6}[0-9]* .+:[0-9]+> $/)) {
            $0 = remove_substring($0, substr(extra, RSTART+1, RLENGTH-1))
        }
    }

    match($0, /\+[0-9]+\./)
    seconds = substr($0, RSTART+1, RLENGTH-2)
    match($0, /\.[0-9]{6}/)
    microseconds = substr($0, RSTART+1, RLENGTH-1)

    this_time = 1000000*seconds + microseconds
    if (previous_time != 0) {
        time_difference = this_time - previous_time
        print time_difference " " previous_command
    }
    previous_time = this_time

    match($0, / .+/)
    previous_command = substr($0, RSTART+1, RLENGTH-1)
}
