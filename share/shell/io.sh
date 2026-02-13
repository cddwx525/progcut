################################################################################
# @description Output message with time tag.
#         * 2025-12-10
#             * Doc: Remove return comment, remove variable type.
#         * 2025-12-09
#             * Modify: Simplify logic, add io_print_error.
#         * 2025-06-02
#             * Done
# @depend date, printf, io_print_error
# @depend $DEBUG
# @param message
# @param type
################################################################################
io_message ()
{
    (
    message="${1}"
    type="${2:-"info"}"
    result=""

    case "${type}" in
    ("error")
        result="[$(date +"%F %T")][Error   ]: ${message}"
        ;;

    ("warn")
        result="[$(date +"%F %T")][Warnning]: ${message}"
        ;;

    ("info")
        result="[$(date +"%F %T")][Info    ]: ${message}"
        ;;

    ("debug")
        if test "${DEBUG}" = "TRUE"
        then
            result="[$(date +"%F %T")][Debug   ]: ${message}"
        else
            io_print_error "Not in debug mode, message type \"${type}\" not working."
            return 1
        fi
        ;;
    (*)
        io_print_error "Unknown message type \"${type}\"."
        return 1
        ;;
    esac

    printf "%s\n" "${result}"

    return 0
    )
}

################################################################################
# @description Print message to stand error.
#         * 2025-12-10
#             * Doc: Remove return comment.
#         * 2025-12-09
#             * Done
# @depend printf
# @param message
################################################################################
io_print_error ()
{
    (
    printf "%s\n" "${1}" >&2

    return 0
    )
}
