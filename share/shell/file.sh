################################################################################
# @description Recursive in directory, execute action.
#         * 2025-12-11
#             * Done
# @depend printf, cd, realpath
# @depend file_recursive_diraction, file_recursive_fileaction
# @param directory_main_abs
# @param directory
################################################################################
file_recursive ()
{
    (
    directory_main_abs="${1}"
    directory="${2}"

    file_path_abs=""
    file_path_relative=""

    #
    # IN.
    #
    cd "${directory}" || return 1
    # Dont list ~ files.
    for file in ./*[!~]
    do
        if test ! -e "${file}"
        then
            #
            # Break when above expansion failed(no match).
            #
            printf "%s\n" "Warning: Directory \"""$(pwd)""\" have no these files."
            break
        else
            if test -d "${file}"
            then
                #
                # Recursive directory action.
                #
                file_path_abs="$(realpath "${file}")"
                file_path_relative="${file_path_abs#${directory_main_abs}/}"
                file_recursive_diraction \
                        "${file_path_abs}" "${file_path_relative}"
                #
                # Recursive call self.
                #
                file_recursive "${directory_main_abs}" "${file}"
            elif test -f "${file}"
            then
                #
                # Recursive file action.
                #
                file_path_abs="$(realpath "${file}")"
                file_path_relative="${file_path_abs#${directory_main_abs}/}"
                file_recursive_fileaction \
                        "${file_path_abs}" "${file_path_relative}"
            else
                printf "%s\n" "Warning: \"""${file}""\" is not normal file."
            fi
        fi
    done
    #
    # OUT.
    #
    cd ..

    return 0
    )
}
