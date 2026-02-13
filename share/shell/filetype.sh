################################################################################
# @description Adjust srt file frame offset, version 3, state machine.
#         * 2025-12-11
#             * Interface: Add one parameter to speedup srt time.
#         * 2025-12-10
#             * Done.
# @depend printf, bc, str_parse_srttime
# @param file
# @param offset_time All time need plus this value, in 1234.567 s format..
# @param offset_number The first subtitle item number in this srt file.
# @param speedup Time will divided by this value.
# @param ret_file Save new offset_number.
################################################################################
filetype_srt_offset ()
{
    (
    file_srt="${1}"
    offset_time="${2}"
    offset_number="${3}"
    speedup="${4}"
    ret_file="${5}"

    sub_number_count="${offset_number}"

    flush ()
    {
        if test "X${sub_number}" = "X"
        then
            return 0
        else
            sub_number="${sub_number_count}"

            sub_start_seconds="$(str_parse_srttime \
                    "${sub_start}" "time_to_seconds")"
            if test "X${speedup}" != "X"
            then
                sub_start_seconds="$(printf "%s" \
                        "scale=10
                        ${sub_start_seconds} / ${speedup}" \
                        | bc)"
            else
                :
            fi
            sub_start_seconds="$(printf "%s" \
                    "scale=3
                    ${offset_time} \
                    + ${sub_start_seconds}" \
                    | bc)"
            sub_start="$(str_parse_srttime \
                    "${sub_start_seconds}" "seconds_to_time")"


            sub_end_seconds="$(str_parse_srttime \
                    "${sub_end}" "time_to_seconds")"; \
            if test "X${speedup}" != "X"
            then
                sub_end_seconds="$(printf "%s" \
                        "scale=10
                        ${sub_end_seconds} / ${speedup}" \
                        | bc)"
            else
                :
            fi
            sub_end_seconds="$(printf "%s" \
                    "scale=3
                    ${offset_time} \
                    + ${sub_end_seconds}" \
                    | bc)"
            sub_end="$(str_parse_srttime \
                    "${sub_end_seconds}" "seconds_to_time")"

            printf "%s\n" "${sub_number}"
            printf "%s\n" "${sub_start} --> ${sub_end}"
            printf "%s\n" "${sub_text}"
            printf "%s\n" ""

            sub_number_count="$((${sub_number_count} + 1))"

            return 0
        fi
    }

    state="number"    # number -> time -> text
    sub_number=""
    sub_start=""
    sub_end=""
    sub_text=""

    while IFS= read -r line
    do
        case "$state" in
        ("number")
            if test "X${line}" = "X"
            then
                :
            else
                sub_number="${line}"

                state="time"
            fi
            ;;

        ("time")
            sub_start="${line%% -->*}"
            sub_end="${line##*--> }"

            state="text"
            ;;

        ("text")
            if test "X${line}" = "X"
            then
                flush

                sub_number=""
                sub_start=""
                sub_end=""
                sub_text=""

                state="number"
            else
                if test "X${sub_text}" = "X"
                then
                    # First line.
                    sub_text="${line}"
                else
                    # Later lines.
                    sub_text="${sub_text}\n${line}"
                fi
            fi
            ;;
        esac
    done <"${file_srt}"

    flush

    printf "%s" "${sub_number_count}" >"${ret_file}"

    return 0
    )
}


################################################################################
# @description Conver lrc lyrics to videomaker subtitle format, with offset.
#         NOTE: The lrc file need an last empty time as end time.
#         * 2025-12-10
#             * Done.
# @depend printf, bc, realpath, str_parse_lrctime
# @param file_lrc
# @param lrc_offset All time need plus this value, in [-]1234.567 s format.
################################################################################
filetype_lrc_to_sub ()
{
    (
    if test "${#}" -ne 2
    then
        io_print_error "Parameter number not match."
        return 1
    else
        :
    fi

    file_lrc="$(realpath "${1}")"
    lrc_offset="${2}"

    printf "%s\n" "["

    presub_start=0
    presub_end=0
    presub_content=""
    while IFS= read -r line
    do
        case "${line}" in
        (\[*:*.*]*)
            :
            ;;
        (*)
            continue
            ;;
        esac

        sub_start_time="${line%%]*}"
        sub_start_time="${sub_start_time#[\[]}"

        sub_start_seconds="$(str_parse_lrctime \
                "${sub_start_time}" "time_to_seconds")"
        sub_start_seconds="$(printf "%s" \
                "scale=3
                ${sub_start_seconds} + (${lrc_offset})" \
                | bc)"

        presub_end="$(printf "%s" \
                "scale=3
                ${sub_start_seconds} - 0.1" \
                | bc)"

        printf "%s\n" \
                "    [[${presub_start}, ${presub_end}], $(:
                        )\"${presub_content}\"],"

        presub_start="${sub_start_seconds}"
        presub_content="~${line#*]}~"

    done <"${file_lrc}"

    printf "%s\n" "],"

    return 0
    )
}

################################################################################
# @description Conver autosub json subtitle to videomaker sub.
#         * 2025-12-10
#             * Done.
# @depend printf, bc, realpath
# @param file_jsonsub
################################################################################
filetype_jsonsub_to_sub ()
{
    (
    file_jsonsub="$(realpath "${1}")"

    printf "%s\n" "["

    file_jsonsub_lines="${file_jsonsub%.*}-lines.json"
    jq -c ".[]" "${file_jsonsub}" >"${file_jsonsub_lines}"

    while IFS= read -r line
    do
        sub_start="$(printf "%s" "${line}" | jq -r '.start')"
        sub_start="$(printf "%.${time_precise}f" "${sub_start}")"

        sub_end="$(printf "%s" "${line}" | jq -r '.end')"
        sub_end="$(printf "%.${time_precise}f" "${sub_end}")"

        sub_content="$(printf "%s" "${line}" | jq -r '.content')"

        printf "%s\n" \
                "    [[${sub_start}, ${sub_end}], \"${sub_content}\"],"
    done <"${file_jsonsub_lines}"
    rm "${file_jsonsub_lines}"

    printf "%s\n" "],"

    return 0
    )
}


