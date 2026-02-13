################################################################################
# @description Strip leading zeros of a string.
#         * 2025-12-10
#             * Doc: Remove return comment.
#         * 2025-12-09
#             * Modify: Simplify logic, variable put front.
#         * 2025-07-17
#             * Done
# @depend printf
# @param string.
# @param allow_empty  Allow empty.
################################################################################
str_strip_leadingzeros ()
{
    (
    string="${1}"
    allow_empty="${2}"
    result=""

    result="${string#${string%%[!0]*}}"

    if test "${result}" = "" && test "${allow_empty}" != "1"
    then
        result="0"
    else
        :
    fi

    printf "%s\n" "${result}"

    return 0
    )
}

################################################################################
# @description Convert a string to case insensitive search pattern.
#
#     Changelog(template):
#         * 2025-12-11
#             * Modify: Add "Changelog(template)" tag.
#         * 2025-12-10
#             * Modify: Remove return doc, remove variable type.
# @depend printf, grep, tr
# @param string
################################################################################
str_to_casei ()
{
    (
    pattern_tmp="${1}"

    pattern_ci=""

    while test "${pattern_tmp}" != ""
    do
        pattern_tmp_rest="${pattern_tmp#?}"
        char_orig="${pattern_tmp%"${pattern_tmp_rest}"}"

        status=0
        echo "${char_orig}" | grep -q -e "[[:alpha:]]" || status=1

        if test "${status}" -eq 0
        then
            char_lower="$(echo "${char_orig}" | tr "[:upper:]" "[:lower:]")"
            char_upper="$(echo "${char_orig}" | tr "[:lower:]" "[:upper:]")"

            char_class="[${char_lower}${char_upper}]"
            pattern_ci="${pattern_ci}${char_class}"
        else
            pattern_ci="${pattern_ci}${char_orig}"
        fi

        pattern_tmp="${pattern_tmp_rest}"
    done

    printf "%s" "${pattern_ci}"

    return 0
    )
}



################################################################################
# @description Get part of date string YYYY-MM-DD.
#         * 2025-12-10
#             * Doc: Remove return comment.
#         * 2025-12-09
#             * Modify: Print error message before return 1.
#             * Modify: Variable put front before use.
#         * 2025-07-17
#             * Done
# @depend printf, io_print_error
# @param date.
# @param part.
################################################################################
str_parse_date ()
{
    (
    date="${1}"
    field="${2}"
    result=""

    case "${field}" in
    ("year")
        result="${date%%-*}"
        ;;

    ("month")
        result="${date%-*}";
        result="${result#*-}"
        ;;

    ("day")
        result="${date##*-}"
        ;;

    (*)
        io_print_error "Unkown srt time part \"${field}\"."
        return 1
        ;;
    esac

    printf "%s\n" "${result}"

    return 0
    )
}

################################################################################
# @description Parse srt time.
#         * 2025-12-10
#             * Doc: Remove return comment.
#         * 2025-12-09
#             * Done
# @depend printf, bc, io_print_error, str_strip_leadingzeros
# @param string.
# @param field.
################################################################################
str_parse_srttime ()
{
    (
    string="${1}"
    field="${2}"
    result=""

    case "${field}" in
    ("time_to_seconds")
        hour="${string%%:*}"
        hour="$(str_strip_leadingzeros "${hour}")"

        minute="${string#*:}"
        minute="${minute%%:*}"
        minute="$(str_strip_leadingzeros "${minute}")"

        second="${string%,*}"
        second="${second##*:}"
        second="$(str_strip_leadingzeros "${second}")"

        msecond="${string#*,}"

        result="$(printf "%s" \
                "scale=3
                ${hour} * 3600 + ${minute} * 60 + ${second}.${msecond}" \
                | bc)"
        ;;

    ("seconds_to_time")
        result="$(printf "%02d:%02d:%02d,%03d" \
                "$(printf "%s" "scale=0; ${string} / 1 / 60 / 60" | bc)" \
                "$(printf "%s" "scale=0; ${string} / 1 / 60 % 60" | bc)" \
                "$(printf "%s" "scale=0; ${string} / 1 % 60" | bc)" \
                "$(printf "%s" "scale=0; ${string} % 1 * 1000 / 1" | bc)" \
                )"
        ;;

    ("hour")
        result="${string%%:*}"
        ;;

    ("minute")
        result="${string#*:}"
        result="${result%%:*}"
        ;;

    ("second")
        result="${string%,*}"
        result="${result##*:}"
        ;;

    ("msecond")
        result="${string#*,}"
        ;;

    (*)
        io_print_error "Unkown srt time part \"${field}\"."
        return 1
        ;;
    esac

    printf "%s\n" "${result}"

    return 0
    )
}


################################################################################
# @description Parse lrc time mm:ss:ms.
#         * 2025-12-10
#             * Done
# @depend printf, bc, io_print_error, str_strip_leadingzeros
# @param string.
# @param field.
################################################################################
str_parse_lrctime ()
{
    (
    string="${1}"
    field="${2}"
    result=""

    case "${field}" in
    ("time_to_seconds")
        minute="${string%%:*}"
        minute="$(str_strip_leadingzeros "${minute}")"

        second=${string#*:}
        second=${second%.*}
        second="$(str_strip_leadingzeros "${second}")"

        msecond=${string#*.}

        result="$(printf "%s" \
                "scale=3
                ${minute} * 60 + ${second}.${msecond}" \
                | bc)"
        ;;

    ("seconds_to_time")
        result="$(printf "%02d:%02d.%02d" \
                "$(printf "%s" "scale=0; ${string} / 1 / 60 % 60" | bc)" \
                "$(printf "%s" "scale=0; ${string} / 1 % 60" | bc)" \
                "$(printf "%s" "scale=0; ${string} % 1 * 100 / 1" | bc)" \
                )"
        ;;

    ("minute")
        result="${string%%:*}"
        ;;

    ("second")
        result=${string#*:}
        result=${result%.*}
        ;;

    ("msecond")
        result=${string#*.}
        ;;

    (*)
        io_print_error "Unkown lrc time part \"${field}\"."
        return 1
        ;;
    esac

    printf "%s\n" "${result}"

    return 0
    )
}

