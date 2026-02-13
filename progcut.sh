#! /bin/sh

# Description:
#     Make video with ffmpeg.
#
# Depend:
#     dirname, basename, realpath
#     bc, sed
#     say, ffmpeg, ffprobe, jq
#
# Author:
#     cddwx525 <cddwx525@163.com>
#
# Changelog:
#     * 2025-12-26
#         * Fix: Error shift when action is make_film.
#         * Fix: No output in parse_subtitle_file.
#         * Code: Use h264_videotoolbox to encode in ffmpeg.
#     * 2025-12-21
#         * Fix: Not use FILTERV_PARAMETERS_POST, use FFMPEG_VIDEO set pix_fmt.
#     * 2025-12-19
#         * Code: Rename "genjson" to "gen_clip_image", use subshell.
#         * Code: Global variable only uppercase first character.
#         * Code: Help function format change.
#         * Fix: In gen_clip_video, video file and srt may not one to one.
#     * 2025-12-18
#         * Interface: Json file format more easy understood.
#                 All video, audio, text, subtitle have sub items list.
#         * Code: Uppercase variable is global.
#         * Logic: Subshell for all functions.
#         * Logic: Simplify logical for make_simple and make_concat.
#         * Logic: Insert silent audio instead of delay speech audio.
#         * Logic: Save timeline infomation to json when parse subtitle.
#         * Logic: Subtitle drawtext filter use fontsize directly.
#         * Fix: FFmpeg base filters fps and format wrong at first.
#         * Fix: Add trap command.
#         * Fix: Function return 1 may ignore when used in non-simple commmand.
#                 Always use simple command when call function, use
#                     a="$(func arg1 arg2)"
#                     b="${a} hello}"
#                 instead of
#                     b="$(func arg1 arg2) hello"
#     * 2025-12-11
#         * Feature: Add option to generate clip json for video files and srt.
#     * 2025-12-10
#         * Code: Use external function for srt, lrc file parse.
#         * Code: Change "font" to "fontfile".
#         * Feature: Add more parameters to subtitles filter.
#     * 2025-12-09
#         * Feature: Add srt subtitle parse.
#         * Code: Simplify null + file operation logic, all use filter_complex.
#     * 2025-12-08
#         * Feature: Add video_concat + audio_concat.
#         * Feature: Add parse subtitle for audio.
#         * Feature: Add lrc to subtitle.
#         * Modify: Subtitle default size to 3, use
#                 "SUBTITLE_MARGINBOTTOM_DEFAULT" instead of 
#                 "subtitle_region", use shadow instread of box.
#         * Modify: Subtitle time precise default to 0.01 s.
#         * Fix: Indent cause more blank in multiline text in drawtext filter.
#     * 2025-12-07
#         * Fix: Treat unknown "--*" as unknown file.
#     * 2025-06-14
#         * Code: Volume adjust item is now under video key.
#     * 2025-06-14
#         * Modify: Null + file, video file use array.
#         * Feature: Image, video auto scale and pad.
#         * Feature: Volume adjust.
#         * Feature: Video speed adjust.
#         * Feature: Subtitle.
#         * Code: Not prefix and suffix ${NL} to *_parameter
#               , add when use in ffmpeg.
#     * 2025-05-31
#         * Feature: Loop audio, fade in/out.
#     * 2025-05-30
#         * Feature: Parallel, but cause OS outof memory, when deal with large
#                 data, so not use it.
#         * Code: All temporary file prefix ${id}.
#         * Code: Use $(:) format filter parameters string.
#         * Code: Filter parameters variable all begin with "<NL>, ".
#         * Code: Indent parameters string to fit command line indent.
#         * Fix: Combine unnecessary reencoding.
#     * 2025-05-29
#         * Feature: Recursive.
#     * 2025-05-28
#         * Fix: Null + image lack audio track.
#         * Code: Parse speech function, divided to three functions.
#     * 2025-05-27
#         * Feature: Generate json for a directory.
#         * Feature: Deal with missing epsion.
#     * 2025-05-21
#         * Fix: Skip logic wrong.
#         * Fix: No need escape % and \, in json, use \% to get %, use \\\\
#                 to get a \ in drawtext.
#     * 2025-05-18
#         * Code: Parse incicator and text use different function.
#         * Code: Incicator and image in parse speech, use different variables.
#         * Code: Build dir, absolute path
#         * Bug: Display unit, use hardcode int value, or will be un aligned.
#         * Feature: Partial build
#     * 2025-05-17
#         * Done
#     * 2025-05-09
#         * Begin
#
# Changelog(tmpplate):
#     * 2025-12-09
#         * Modify: Rename variable "current_file" to "as_me".
#     * 2025-12-07
#         * Add: Add "VERSION", "current_file" variable.
#     * 2025-07-14
#         * Done
#

set -e # errexit. Exit when error.
#set -n # noexit. Read commands but do not execute them, check syntax.
#set -x # xtrace. Write command to stand error before excute, debugging.
#set -v # verbose. Write input to stand error, debugging.

LC_ALL=C
#LC_ALL=en_US.UTF-8
export LC_ALL

trap "exit 130" INT

DIR="$(dirname "$(realpath "${0}")")"
ME="$(basename "$(realpath "${0}")")"

VERSION="2025-12-26"

. "${DATADIR}"/share/shell/io.sh
. "${DATADIR}"/share/shell/str.sh
. "${DATADIR}"/share/shell/filetype.sh
. "${DATADIR}"/share/shell/file.sh

################################################################################
# @description Help.
#
#     Changelog(template):
#         * 2025-12-13
#             * Code: Use $ME, $VERSION..
#         * 2025-12-10
#             * Code: Add return 0.
#             * Doc: Remove return comment.
#         * 2025-07-17
#             * Done
# @depend $ME, $VERSION
# @depend printf
# @param None
################################################################################
help ()
{
    (
    printf "%s\n" "Progcut ${VERSION}"
    printf "%s\n" ""
    printf "%s\n" "NOTE:"
    printf "%s\n" "    (1) Filename must [a-zA-Z0-9-_.]."
    printf "%s\n" "    (2) Adjust number width, default 4(0--9999)."
    printf "%s\n" ""
    printf "%s\n" "Usage:"
    printf "%s\n" "    ${ME} [option [option] ...] {film_json}"
    printf "%s\n" ""
    printf "%s\n" "    option:"
    printf "%s\n" "        --soft_sub        Do NOT encode subtitle to video."
    printf "%s\n" ""
    printf "%s\n" "    ${ME} --gen_clip_image {directory} {base} {ext} $(:
            ){interval} {is_titleclip} {parent_name} {parent_title}"
    printf "%s\n" "            Generate clip json for images in directory."
    printf "%s\n" ""
    printf "%s\n" "    ${ME} --gen_clip_video {diirectory} {base} {ext} $(:
            ){speedup} {volume}"
    printf "%s\n" "            Generate clip json for video in directory."
    printf "%s\n" ""
    printf "%s\n" "    ${ME} --json_to_sub {file_json}"
    printf "%s\n" "            Convert json sub file to progcut sub."
    printf "%s\n" ""
    printf "%s\n" "    ${ME} --lrc_to_sub  {file_lrc}"
    printf "%s\n" "            Convert lrc file to progcut sub."

    return 0
    )
}



################################################################################
# @description Generate video json clip for images.
#
#     Changelog(template):
#         * 2025-12-19
#             * Modify: Depend command and function.
#             * Modify: Add @output type.
#         * 2025-12-11
#             * Modify: Add "Changelog(template)" tag.
#         * 2025-12-10
#             * Modify: Remove return doc, remove variable type.
# @depend printf
# @depend io_print_error(), file_recursive()
# @param directory
# @param base_dir
# @param ext
# @param interval
# @param is_titleclip
# @param parent_name
# @param parent_title
# @output json result
################################################################################
gen_clip_image ()
{
    (
    directory="${1}"

    Base_dir="${2}"
    Ext="${3}"
    Interval="${4}"
    Is_titleclip="${5}"
    Parent_name="${6}"
    Parent_title="${7}"

    file_recursive_diraction ()
    {
        (
        file_path_abs="${1}"
        file_path_relative="${2}"

        directory_name="$(basename "${file_path_abs}")"

        clip_number="${directory_name%%_*}"
        clip_title="${directory_name#*_}"
        clipname="${Parent_name}_${clip_number}_${clip_title}"

        if test "X${Is_titleclip}" = "X1"
        then
            #
            # Title clip.
            #
            printf "%s\n" "{"
            printf "%s\n" "    \"name\": \"${clipname}_title\","
            printf "%s\n" "    \"video\": {\"type\": \"color\", \"duration\": 3},"
            printf "%s\n" "    \"audio\": {}"
            printf "%s\n" "    \"text\":"
            printf "%s\n" "    {"
            printf "%s\n" "        \"type\": \"text\","
            printf "%s\n" "        \"target\": \"video\","
            printf "%s\n" "        \"items\":"
            printf "%s\n" "        ["
            printf "%s\n" "            {"
            printf "%s\n" "                \"content\":"
            printf "%s\n" "                ["
            printf "%s\n" "                    \"${Parent_title}\""
            printf "%s\n" "                ],"
            printf "%s\n" "                \"position\": [\"c\", 11],"
            printf "%s\n" "                \"size\": 4"
            printf "%s\n" "            },"
            printf "%s\n" "            {"
            printf "%s\n" "                \"content\":"
            printf "%s\n" "                ["
            printf "%s\n" "                    \"${clip_number} ${clip_title}\""
            printf "%s\n" "                ],"
            printf "%s\n" "                \"position\": [\"c\", 16],"
            printf "%s\n" "                \"size\": 6"
            printf "%s\n" "            }"
            printf "%s\n" "        ]"
            printf "%s\n" "    },"
            printf "%s\n" "    \"subtitle\": {}"
            printf "%s\n" "},"
        else
            :
        fi

        #
        # Item clip.
        #
        printf "%s\n" "{"
        printf "%s\n" "    \"name\": \"${clipname}\","
        printf "%s\n" "    \"video\":"
        printf "%s\n" "    {"
        printf "%s\n" "        \"type\": \"image\","
        printf "%s\n" "        \"items\":"
        printf "%s\n" "        ["

        cd "${file_path_abs}" || return 1
        for file in ./*.${Ext}
        do
            if test ! -e "${file}"
            then
                #
                # Break when above expansion failed(no match).
                #
                io_print_error "Directory \"${file_path_relative}\" $(:
                        )have no these files."
                return 1
            else
                file_path_item="${Base_dir}/${file_path_relative}$(:
                        )/$(basename "${file}")"
                printf "%s\n" "            \"${file_path_item}\","
            fi
        done
        cd ..

        printf "%s\n" "        ],"
        printf "%s\n" "        \"interval\": ${Interval}"
        printf "%s\n" "    },"
        printf "%s\n" "    \"audio\": {},"

        if test "X${Is_titleclip}" = "X1"
        then
            printf "%s\n" "    \"text\": {},"
        else
            printf "%s\n" "    \"text\":"
            printf "%s\n" "    {"
            printf "%s\n" "        ["
            printf "%s\n" "            {"
            printf "%s\n" "                \"content\":"
            printf "%s\n" "                ["
            printf "%s\n" "                    \"${Parent_title}\""
            printf "%s\n" "                ],"
            printf "%s\n" "                \"position\": [4, 2],"
            printf "%s\n" "                \"size\": 3"
            printf "%s\n" "            },"
            printf "%s\n" "            {"
            printf "%s\n" "                \"content\":"
            printf "%s\n" "                ["
            printf "%s\n" "                    \"${clip_number} ${clip_title}\""
            printf "%s\n" "                ],"
            printf "%s\n" "                \"position\": [4, 5],"
            printf "%s\n" "                \"size\": 2"
            printf "%s\n" "            }"
            printf "%s\n" "        ]"
            printf "%s\n" "    },"
        fi
        printf "%s\n" "    \"subtitle\": {}"
        printf "%s\n" "},"

        return 0
        )
    }

    file_recursive_fileaction ()
    {
        (
        return 0
        )
    }

    if test ! -d "${directory}"
    then
        io_print_error "Error: Directory \"${directory}\" does not exists."
        return 1
    else
        :
    fi

    file_recursive "$(realpath "${directory}")" "${directory}"

    return 0
    )
}

################################################################################
# @description Generate video json clip for videos.
#
#     Changelog(template):
#         * 2025-12-11
#             * Modify: Add "Changelog(template)" tag.
#         * 2025-12-10
#             * Modify: Remove return doc, remove variable type.
# @depend printf
# @depend io_print_error(), file_recursive()
# @param directory
# @param base_dir
# @param ext
# @param speedup
# @param volume
################################################################################
gen_clip_video ()
{
    (
    directory="${1}"

    Base_dir="${2}"
    Ext="${3}"
    Speedup="${4}"
    Volume="${5}"

    file_recursive_diraction ()
    {
        (
        file_path_abs="${1}"
        file_path_relative="${2}"

        directory_name="$(basename "${file_path_abs}")"

        clip_number="${directory_name%%_*}"
        clip_title="${directory_name#*_}"
        clipname="${clip_number}_${clip_title}"

        #
        # Title clip.
        #
        printf "%s\n" "{"
        printf "%s\n" "    \"name\": \"${clipname}_title\","
        printf "%s\n" "    \"video\": {\"type\": \"color\", \"duration\": 3},"
        printf "%s\n" "    \"audio\": {}"
        printf "%s\n" "    \"text\":"
        printf "%s\n" "    {"
        printf "%s\n" "        \"type\": \"text\","
        printf "%s\n" "        \"target\": \"video\","
        printf "%s\n" "        \"items\":"
        printf "%s\n" "        ["
        printf "%s\n" "            {"
        printf "%s\n" "                \"content\":"
        printf "%s\n" "                ["
        printf "%s\n" "                    \"${clip_number}\""
        printf "%s\n" "                ],"
        printf "%s\n" "                \"position\": [\"c\", 11],"
        printf "%s\n" "                \"size\": 4"
        printf "%s\n" "            },"
        printf "%s\n" "            {"
        printf "%s\n" "                \"content\":"
        printf "%s\n" "                ["
        printf "%s\n" "                    \"${clip_title}\""
        printf "%s\n" "                ],"
        printf "%s\n" "                \"position\": [\"c\", 16],"
        printf "%s\n" "                \"size\": 6"
        printf "%s\n" "            }"
        printf "%s\n" "        ]"
        printf "%s\n" "    },"
        printf "%s\n" "    \"subtitle\": {}"
        printf "%s\n" "},"

        #
        # Item clip.
        #
        printf "%s\n" "{"
        printf "%s\n" "    \"name\": \"${clipname}\","
        printf "%s\n" "    \"video\":"
        printf "%s\n" "    {"
        printf "%s\n" "        \"type\": \"file\","
        printf "%s\n" "        \"items\":"
        printf "%s\n" "        ["

        cd "${file_path_abs}" || return 1
        for file in ./*.${Ext}
        do
            if test ! -e "${file}"
            then
                #
                # Break when above expansion failed(no match).
                #
                io_print_error "Directory \"${file_path_relative}\" $(:
                        )have no these files."
                return 1
            elif test ! -e "${file%.*}.srt"
            then
                io_print_error "Video file \"${file_path_relative}/$(:
                        )$(basename "${file}")\" miss srt file."
                return 1
            else
                file_path_item="${Base_dir}/${file_path_relative}$(:
                        )/$(basename "${file}")"
                printf "%s\n" "            \"${file_path_item}\","
            fi
        done
        cd ..

        printf "%s\n" "        ],"
        printf "%s\n" "        \"volume\": \"${Volume}\","
        printf "%s\n" "        \"speedup\": ${Speedup}"
        printf "%s\n" "    },"
        printf "%s\n" "    \"audio\": {},"
        printf "%s\n" "    \"text\": {},"
        printf "%s\n" "    \"subtitle\":"
        printf "%s\n" "    {"
        printf "%s\n" "        \"type\": \"file\","
        printf "%s\n" "        \"target\": \"video\","
        printf "%s\n" "        \"items\":"
        printf "%s\n" "        ["

        cd "${file_path_abs}" || return 1
        for file in ./*.srt
        do
            if test ! -e "${file}"
            then
                #
                # Break when above expansion failed(no match).
                #
                io_print_error "Directory \"${file_path_relative}\" $(:
                        )have no these files."
                return 1
            elif test ! -e "${file%.*}.${Ext}"
            then
                #
                # Found extra srt file..
                #
                io_print_error "Extra srt file \"${file_path_relative}/$(:
                        )$(basename "${file}")\"."
                return 1
            else
                file_path_item="${Base_dir}/${file_path_relative}/$(:
                        )$(basename "${file}")"
                printf "%s\n" "            \"${file_path_item}\","
            fi
        done
        cd ..

        printf "%s\n" "        ]"
        printf "%s\n" "    }"
        printf "%s\n" "},"

        return 0
        )
    }

    file_recursive_fileaction( )
    {
        (
        return 0
        )
    }

    if test ! -d "${directory}"
    then
        io_print_error "Error: Directory \"${directory}\" does not exists."
        return 1
    else
        :
    fi

    file_recursive "$(realpath "${directory}")" "${directory}"

    return 0
    )
}



################################################################################
# @description
#         TODO: Indent may cause multiline text extra blank in drawtext.
#
#     Changelog(template):
#         * 2025-12-11
#             * Modify: Add "Changelog(template)" tag.
#         * 2025-12-10
#             * Modify: Remove return doc, remove variable type.
# @depend printf, sed
# @param string
# @param amount
################################################################################
indent ()
{
    (
    string="${1}"
    amount="${2}"

    count="0"
    indent_amount=""
    while test "${count}" -lt "${amount}"
    do
        indent_amount="${indent_amount}${INDENT}"
        count="$((${count} + 1))"
    done

    #
    # Note: Add another newline here, becaue the last newline wil lost after
    #         command substitution expansion.
    #
    printf "%s" "${string}${NL}" | sed -e "s|^|${indent_amount}|"

    return 0
    )
}


################################################################################
# @description Escape string for drawtext filter of ffmpeg.
#
#     Changelog(template):
#         * 2025-12-11
#             * Modify: Add "Changelog(template)" tag.
#         * 2025-12-10
#             * Modify: Remove return doc, remove variable type.
# @depend printf, sed
# @param string
################################################################################
escape_text ()
{
    (
    string="${1}"

    printf "%s" "${string}" \
            | sed -e 's|'\''|'\''\\'\''\\\\\\'\''\\'\'\''|g'

    return 0
    )
}

################################################################################
# @description Get media file duration.
#
#     Changelog(template):
#         * 2025-12-11
#             * Modify: Add "Changelog(template)" tag.
#         * 2025-12-10
#             * Modify: Remove return doc, remove variable type.
# @depend ffprobe
# @param file_path
################################################################################
get_media_duration ()
{
    (
    file_path="${1}"

    ffprobe \
            -loglevel error \
            -show_entries 'format=duration'\
            -output_format 'default=noprint_wrappers=1:nokey=1' \
            "${file_path}"

    return 0
    )
}

################################################################################
# @description Generate speech audio file from subtitle.
#
#     Changelog(template):
#         * 2025-12-11
#             * Modify: Add "Changelog(template)" tag.
#         * 2025-12-10
#             * Modify: Remove return doc, remove variable type.
# @depend say
# @param file_speech
# @param subtitle
################################################################################
generate_speech_audio ()
{
    (
    file_speech="${1}"
    subtitle="${2}"

    say -v Tingting -r 200 "${subtitle}" -o "${file_speech}"

    ffmpeg \
            ${FFMPEG_OPTIONS} \
            -i "${file_speech}" \
            ${FFMPEG_AUDIO} \
            ${FFMPEG_CODEC_A} \
            -f mp4 \
            "${file_speech}.tmp"
    mv "${file_speech}.tmp" "${file_speech}"

    return 0
    )
}

################################################################################
# @description Generate sient audio file.
#
#     Changelog(template):
#         * 2025-12-11
#             * Modify: Add "Changelog(template)" tag.
#         * 2025-12-10
#             * Modify: Remove return doc, remove variable type.
# @depend ffmpeg
# @param file_slient
# @param duration
################################################################################
generate_slient_audio ()
{
    (
    file_slient="${1}"
    duration="${2}"

    ffmpeg \
            ${FFMPEG_OPTIONS} \
            -f lavfi -i "anullsrc='duration=${duration}'" \
            ${FFMPEG_AUDIO} \
            ${FFMPEG_CODEC_A} \
            -f mp4 \
            "${file_slient}"

    return 0
    )
}

################################################################################
# @description Get config value of a json.
#
#     Changelog(template):
#         * 2025-12-11
#             * Modify: Add "Changelog(template)" tag.
#         * 2025-12-10
#             * Modify: Remove return doc, remove variable type.
# @depend printf, jq
# @depend io_print_error()
# @param file_json_text
# @param default_duration
# @param key
################################################################################
get_text_config ()
{
    (
    file_json_text="${1}"
    default_duration="${2}"
    key="${3}"

    result=""

    case "${key}" in
    ("content")
        # content
        file_json_text_contentarray="${Dir_build}/${clipname}__textcontentarray.json"
        jq -r ".content[]" "${file_json_text}" >"${file_json_text_contentarray}"

        text_content=""
        while IFS= read -r content
        do
            content="$(escape_text "${content}")"

            text_content="${text_content}${content}${NL}"
        done <"${file_json_text_contentarray}"
        rm "${file_json_text_contentarray}"

        result="${text_content%${NL}}"
        ;;

    ("fontfile")
        # fontfile
        if test "$(jq '. | has("fontfile")' "${file_json_text}")" = "true"
        then
            result="$(jq -r '.fontfile' "${file_json_text}")"
        else
            result="${TEXT_FONTFILE_DEFAULT}"
        fi
        ;;

    ("fontsize")
        # fontsize
        if test "$(jq '. | has("size")' "${file_json_text}")" = "true"
        then
            result="$(printf "%s" \
                        "scale=${BC_SCALE}
                        $(jq -r '.size' "${file_json_text}") \
                        * ${DISPLAY_UNIT_W} / ${FONT_FACTOR}" \
                        | bc)"
        else
            # Auto compute fill useable space
            text_rows="$(jq ".content | length" "${file_json_text}")"
            text_cols="$(jq ".content[0] | length" "${file_json_text}")"
            text_fontsize_w="(
                    (main_w - ${BLANK_W_DEFAULT} * ${DISPLAY_UNIT_W})
                    / ${text_cols}
                    ) / ${FONT_FACTOR}"
            text_fontsize_h="(
                    (main_h - ${BLANK_H_DEFAULT} * ${DISPLAY_UNIT_H})
                    / ${text_rows}
                    ) / ${FONT_RATIO} / ${FONT_FACTOR}"

            result="min(${text_fontsize_w}, ${text_fontsize_h})"
        fi
        ;;

    ("color")
        # color
        if test "$(jq '. | has("color")' "${file_json_text}")" = "true"
        then
            result="$(jq -r '.color' "${file_json_text}")"
        else
            result="${TEXT_COLOR_DEFAULT}"
        fi
        ;;

    ("box")
        # box
        if test "$(jq '. | has("box")' "${file_json_text}")" = "true"
        then
            result="1"
        else
            result="0"
        fi
        ;;

    ("boxcolor")
        # boxcolor
        if test "$(jq '. | has("box")' "${file_json_text}")" = "true"
        then
            result="$(jq -r '.boxcolor' "${file_json_text}")"
        else
            result="black"
        fi
        ;;

    ("linespacing")
        # linespacing
        if test "$(jq '. | has("linespacing")' "${file_json_text}")" = "true"
        then
            result="$(jq -r '.linespacing' "${file_json_text}")"
        else
            result="${TEXT_LINESPACING_DEFAULT}"
        fi
        ;;

    ("position_x")
        # position_x
        if test "$(jq '. | has("position")' "${file_json_text}")" = "true"
        then
            text_position_x="$(jq -r '.position[0]' "${file_json_text}")"
            if test "${text_position_x}" = "c"
            then
                result="main_w / 2 - text_w / 2"
            else
                result="$(printf "%s" \
                        "scale=${BC_SCALE}
                        ${text_position_x} * ${DISPLAY_UNIT_W}" \
                        | bc)"
            fi
        else
            result="main_w / 2 - text_w / 2"
        fi
        ;;

    ("position_y")
        # position_y
        if test "$(jq '. | has("position")' "${file_json_text}")" = "true"
        then
            text_position_y="$(jq -r '.position[1]' "${file_json_text}")"
            if test "${text_position_y}" = "c"
            then
                result="main_h / 2 - text_h / 2"
            else
                result="$(printf "%s" \
                        "scale=${BC_SCALE}
                        ${text_position_y} * ${DISPLAY_UNIT_H}" \
                        | bc)"
            fi
        else
            result="main_h / 2 - text_h / 2"
        fi
        ;;

    ("time_start")
        if test "$(jq '. | has("time")' "${file_json_text}")" = "true"
        then
            result="$(jq -r '.time[0]' "${file_json_text}")"
        else
            result="0"
        fi
        ;;

    ("time_end")
        if test "$(jq '. | has("time")' "${file_json_text}")" = "true"
        then
            result="$(jq -r '.time[1]' "${file_json_text}")"
            if test "${result}" -eq 0
            then
                result="${default_duration}"
            else
                :
            fi
        else
            result="${default_duration}"
        fi
        ;;

    ("subtitle_start")
        result="$(jq -r '.subtitle[0]' "${file_json_text}")"
        ;;

    ("subtitle_end")
        result="$(jq -r '.subtitle[1]' "${file_json_text}")"
        ;;

    (*)
        io_print_error "Unknown text key \"${key}\"."
        return 1
        ;;
    esac

    printf "%s" "${result}"

    return 0
    )
}

################################################################################
# @description Get duration for subtitle target item.
#
#     Changelog(template):
#         * 2025-12-11
#             * Modify: Add "Changelog(template)" tag.
#         * 2025-12-10
#             * Modify: Remove return doc, remove variable type.
# @depend printf, jq
# @depend io_print_error()
# @param file_clipjson
# @param subtitle_duration_sum
# @param index
################################################################################
get_subtarget_duration ()
{
    (
    file_clipjson="${1}"
    subtitle_duration_sum="${2}"
    index="${3}"

    result="0"

    target="$(jq -r '.subtitle.target' "${file_clipjson}")"
    v_type="$(jq -r ".video.type" "${file_clipjson}")"
    a_type="$(jq -r ".audio.type" "${file_clipjson}")"

    case "${target}" in
    ("video")
        case "${v_type}" in
        ("file")
            media="${Dir_main}/$(
                    jq -r ".video.items[${index}]" "${file_clipjson}")"
            result="$(get_media_duration "${media}")"
            ;;
        ("image")
            if test "X$(jq '.video | has("interval")' "${file_clipjson}")" \
                    = "Xtrue"
            then
                result="$(jq -r ".video.interval" "${file_clipjson}")"
            else
                io_print_error "Video type \"${v_type}\" miss interval value."
                return 1
            fi
            ;;
        ("color")
            if test "X$(jq '.video | has("duration")' "${file_clipjson}")" \
                    = "Xtrue"
            then
                result="$(jq -r ".video.duration" "${file_clipjson}")"
            else
                io_print_error "Video type \"${v_type}\" miss duration value."
                return 1
            fi
            ;;
        (*)
            io_print_error "Unknown video type \"${v_type}\"."
            return 1
            ;;
        esac
        ;;

    ("audio")
        case "${a_type}" in
        ("file")
            media="${Dir_main}/$(
                    jq -r ".audio.items[${index}]" "${file_clipjson}")"
            result="$(get_media_duration "${media}")"
            ;;
        ("speech")
            result="${subtitle_duration_sum}"
            ;;
        (*)
            io_print_error "Unknown audio type \"${a_type}\"."
            return 1
            ;;
        esac
        ;;

    (*)
        io_print_error "Unknown subtitle target \"${target}\"."
        return 1
        ;;
    esac

    printf "%s" "${result}"

    return 0
    )
}

################################################################################
# @description Get duration for text target item.
#
#     Changelog(template):
#         * 2025-12-11
#             * Modify: Add "Changelog(template)" tag.
#         * 2025-12-10
#             * Modify: Remove return doc, remove variable type.
# @depend printf, jq
# @depend io_print_error()
# @param file_clipjson
# @param file_json_subtimeline
# @param index
################################################################################
get_texttarget_duration ()
{
    (
    file_clipjson="${1}"
    file_json_subtimeline="${2}"
    index="${3}"

    result="0"

    target="$(jq -r '.text.target' "${file_clipjson}")"
    v_type="$(jq -r ".video.type" "${file_clipjson}")"
    a_type="$(jq -r ".audio.type" "${file_clipjson}")"

    case "${target}" in
    ("video")
        case "${v_type}" in
        ("file")
            media="${Dir_main}/$(
                    jq -r ".video.items[${index}]" "${file_clipjson}")"
            result="$(get_media_duration "${media}")"
            ;;
        ("image")
            if test "X$(jq '.video | has("interval")' "${file_clipjson}")" \
                    = "Xtrue"
            then
                result="$(jq -r ".video.interval" "${file_clipjson}")"
            else
                io_print_error "Video type \"${v_type}\" miss interval value."
                return 1
            fi
            ;;
        ("color")
            if test "X$(jq '.video | has("duration")' "${file_clipjson}")" \
                    = "Xtrue"
            then
                result="$(jq -r ".video.duration" "${file_clipjson}")"
            else
                io_print_error "Video type \"${v_type}\" miss duration value."
                return 1
            fi
            ;;
        (*)
            io_print_error "Unknown video type \"${v_type}\"."
            return 1
            ;;
        esac
        ;;

    ("audio")
        case "${a_type}" in
        ("file")
            media="${Dir_main}/$(
                    jq -r ".audio.items[${index}]" "${file_clipjson}")"
            result="$(get_media_duration "${media}")"
            ;;
        ("speech")
            result="$(jq -r ".items[${index}].sum" "${file_json_subtimeline}")"
            ;;
        (*)
            io_print_error "Unknown audio type \"${a_type}\"."
            return 1
            ;;
        esac
        ;;

    (*)
        io_print_error "Unknown text target \"${target}\"."
        return 1
        ;;
    esac

    printf "%s" "${result}"

    return 0
    )
}


################################################################################
# @description Get clip duration.
#
#     Changelog(template):
#         * 2025-12-11
#             * Modify: Add "Changelog(template)" tag.
#         * 2025-12-10
#             * Modify: Remove return doc, remove variable type.
# @depend ffprobe
# @param file_clipjson
# @param video_duration_sum
# @param image_duration_sum
# @param audio_duration_sum
# @param file_json_subtimeline
################################################################################
get_clip_duration ()
{
    (
    file_clipjson="${1}"
    video_duration_sum="${2}"
    image_duration_sum="${3}"
    audio_duration_sum="${4}"
    file_json_subtimeline="${5}"

    result="0"

    v_type="$(jq -r '.video.type' "${file_clipjson}")"
    case "${v_type}" in
    ("file")
        result="${video_duration_sum}"
        ;;

    ("image")
        if test "X$(jq '.video | has("interval")' "${file_clipjson}")" \
                = "Xtrue"
        then
            result="${image_duration_sum}"
        elif test "X$(jq -r '.audio.type' "${file_clipjson}")" = "Xfile"
        then
            result="${audio_duration_sum}"
        else
            result="$(jq -r ".sum" "${file_json_subtimeline}")"
        fi
        ;;

    ("color")
        if test "X$(jq '.video | has("duration")' "${file_clipjson}")" \
                = "Xtrue"
        then
            result="$(jq -r ".video.duration" "${file_clipjson}")"
        elif test "X$(jq -r '.audio.type' "${file_clipjson}")" = "Xfile"
        then
            result="${audio_duration_sum}"
        else
            result="$(jq -r ".sum" "${file_json_subtimeline}")"
        fi
        ;;

    (*)
        io_print_error "Unknown video type \"${v_type}\"."
        return 1
        ;;
    esac

    printf "%s" "${result}"

    return 0
    )
}


################################################################################
# @description Parse video files, get duration, update concat file.
#
#     Changelog(template):
#         * 2025-12-11
#             * Modify: Add "Changelog(template)" tag.
#         * 2025-12-10
#             * Modify: Remove return doc, remove variable type.
# @depend printf, jq, bc, rm
# @depend get_media_duration()
# @param file_clipjson
# @param clipnamen
# @param file_videoconcat
################################################################################
parse_video ()
{
    (
    file_clipjson="${1}"
    clipname="${2}"
    file_videoconcat="${3}"

    video_duration_sum="0"

    if test "X$(jq -r '.video.type' "${file_clipjson}")" != "Xfile"
    then
        return 0
    else
        :
    fi

    file_json_video_filearray="${Dir_build}/${clipname}__video_filearray.json"

    jq -r ".video.items[]" "${file_clipjson}" >"${file_json_video_filearray}"
    while IFS= read -r file_path
    do
        file_video="${Dir_main}/${file_path}"

        printf "%s\n" "file '${file_video}'" >>"${file_videoconcat}"

        video_duration="$(get_media_duration "${file_video}")"
        video_duration_sum="$(printf "%s" \
                "scale=${BC_SCALE}
                ${video_duration_sum} + ${video_duration}" \
                | bc)"
    done <"${file_json_video_filearray}"
    rm "${file_json_video_filearray}"

    printf "%s" "${video_duration_sum}"

    return 0
    )
}


################################################################################
# @description Parse image files, get duration, update concat file.
#
#     Changelog(template):
#         * 2025-12-11
#             * Modify: Add "Changelog(template)" tag.
#         * 2025-12-10
#             * Modify: Remove return doc, remove variable type.
# @depend printf, jq, bc, rm
# @param file_clipjson
# @param clipnamen
# @param file_imageconcat
# @param file_json_subtimeline
################################################################################
parse_image ()
{
    (
    file_clipjson="${1}"
    clipname="${2}"
    file_imageconcat="${3}"
    file_json_subtimeline="${4}"

    image_duration_sum="0"

    if test "X$(jq -r '.video.type' "${file_clipjson}")" != "Ximage"
    then
        return 0
    else
        :
    fi

    if test "$(jq '.video | has("interval")' "${file_clipjson}")" != "true"
    then
        #
        # Use subtitle time.
        #
        sub_count="$(jq -r ".items | length" "${file_json_subtimeline}")"
        image_count="$(jq -r ".video.items | length" "${file_clipjson}")"
        if test "${sub_count}" -lt "${image_count}"
        then
            io_print_error "No enough subtitle items to get time."
            return 1
        else
            :
        fi

        file_json_imagearray="${Dir_build}/${clipname}__video_imagearray.json"
        index="0"

        jq -r ".video.items[]" "${file_clipjson}" >"${file_json_imagearray}"
        while IFS= read -r file_path
        do
            duration="$(jq -r ".items[${index}].sum" \
                    "${file_json_subtimeline}")"
            file_image="${Dir_main}/${file_path}"
            printf "%s\n" "file '${file_image}'" >>"${file_imageconcat}"
            printf "%s\n" "duration ${duration}" >>"${file_imageconcat}"

            index="$((${index} + 1))"
        done <"${file_json_imagearray}"
        rm "${file_json_imagearray}"

        printf "%s\n" "file '${file_image}'" >>"${file_imageconcat}"

        return 0
    else
        :
    fi

    interval="$(jq -r ".video.interval" "${file_clipjson}")"
    file_json_imagearray="${Dir_build}/${clipname}__video_imagearray.json"

    jq -r ".video.items[]" "${file_clipjson}" >"${file_json_imagearray}"
    while IFS= read -r file_path
    do
        file_image="${Dir_main}/${file_path}"
        printf "%s\n" "file '${file_image}'" >>"${file_imageconcat}"
        printf "%s\n" "duration ${interval}" >>"${file_imageconcat}"

        image_duration_sum="$(printf "%s" \
                "scale=${BC_SCALE}
                ${image_duration_sum} + ${interval}" \
                | bc)"
    done <"${file_json_imagearray}"
    rm "${file_json_imagearray}"

    printf "%s\n" "file '${file_image}'" >>"${file_imageconcat}"

    printf "%s" "${image_duration_sum}"

    return 0
    )
}


################################################################################
# @description Parse audio files, get duration, update concat file.
#
#     Changelog(template):
#         * 2025-12-11
#             * Modify: Add "Changelog(template)" tag.
#         * 2025-12-10
#             * Modify: Remove return doc, remove variable type.
# @depend printf, jq, bc, rm
# @depend get_media_duration()
# @param file_clipjson
# @param clipnamen
# @param file_audioconcat
################################################################################
parse_audio ()
{
    (
    file_clipjson="${1}"
    clipname="${2}"
    file_audioconcat="${3}"

    audio_duration_sum="0"

    if test "X$(jq -r '.audio.type' "${file_clipjson}")" != "Xfile"
    then
        return 0
    else
        :
    fi

    file_json_audio_filearray="${Dir_build}/${clipname}__audio_filearray.json"

    jq -r ".audio.items[]" "${file_clipjson}" >"${file_json_audio_filearray}"
    while IFS= read -r file_path
    do
        file_audio="${Dir_main}/${file_path}"

        printf "%s\n" "file '${file_audio}'" >>"${file_audioconcat}"

        audio_duration="$(get_media_duration "${file_audio}")"
        audio_duration_sum="$(printf "%s" \
                "scale=${BC_SCALE}
                ${audio_duration_sum} + ${audio_duration}" \
                | bc)"
    done <"${file_json_audio_filearray}"
    rm "${file_json_audio_filearray}"

    printf "%s" "${audio_duration_sum}"

    return 0
    )
}

################################################################################
# @description Parse text parameters for drawtext filter of ffmpeg.
#
#     Changelog(template):
#         * 2025-12-11
#             * Modify: Add "Changelog(template)" tag.
#         * 2025-12-10
#             * Modify: Remove return doc, remove variable type.
# @depend printf, jq, rm
# @depend get_text_config()
# @param file_clipjson
# @param clipname
# @param file_json_subtimeline
################################################################################
parse_text ()
{
    (
    file_clipjson="${1}"
    clipname="${2}"
    file_json_subtimeline="${3}"

    result=""

    if test "X$(jq -r '.text.type' "${file_clipjson}")" != "Xtext"
    then
        return 0
    else
        :
    fi

    file_json_textgrouparray="${Dir_build}/${clipname}__textgrouparray.json"
    jq -c ".text.items[]" "${file_clipjson}" >"${file_json_textgrouparray}"

    item_duration_sum="0"
    index="0"

    #
    # Loop: file_json_textgrouparray
    #
    while IFS= read -r textgroup_data
    do
        file_json_textarray="${Dir_build}/${clipname}__textarray.json"
        printf "%s" "${textgroup_data}" | jq -c ".[]" >"${file_json_textarray}"

        item_duration="$(get_texttarget_duration \
                "${file_clipjson}" \
                "${file_json_subtimeline}" \
                "${index}" \
                )"

        #
        # Loop: file_json_textarray
        #
        while IFS= read -r text_data
        do
            file_json_text="${Dir_build}/${clipname}__text.json"
            printf "%s" "${text_data}"  >"${file_json_text}"

            text_fontfile="$(get_text_config \
                    "${file_json_text}" \
                    "${item_duration}" \
                    "fontfile"
                    )"
            text_content="$(get_text_config \
                    "${file_json_text}" \
                    "${item_duration}" \
                    "content"
                    )"
            text_fontsize="$(get_text_config \
                    "${file_json_text}" \
                    "${item_duration}" \
                    "fontsize"
                    )"
            text_color="$(get_text_config \
                    "${file_json_text}" \
                    "${item_duration}" \
                    "color"
                    )"
            text_box="$(get_text_config \
                    "${file_json_text}" \
                    "${item_duration}" \
                    "box"
                    )"
            text_boxcolor="$(get_text_config \
                    "${file_json_text}" \
                    "${item_duration}" \
                    "boxcolor"
                    )"
            text_linespacing="$(get_text_config \
                    "${file_json_text}" \
                    "${item_duration}" \
                    "linespacing"
                    )"
            text_position_x="$(get_text_config \
                    "${file_json_text}" \
                    "${item_duration}" \
                    "position_x"
                    )"
            text_position_y="$(get_text_config \
                    "${file_json_text}" \
                    "${item_duration}" \
                    "position_y"
                    )"

            if test "$(jq '. | has("subtitle")' "${file_json_text}")" = "true"
            then
                text_subtitle_start="$(get_text_config \
                        "${file_json_text}" \
                        "${item_duration}" \
                        "subtitle_start"
                        )"
                text_time_start="$(jq -r \
                        ".items[${index}].subtitles[${text_subtitle_start}][0]" \
                        "${file_json_subtimeline}" \
                        )"

                text_subtitle_end="$(get_text_config \
                        "${file_json_text}" \
                        "${item_duration}" \
                        "subtitle_end" \
                        )"
                text_time_end="$(jq -r \
                        ".items[${index}].subtitles[${text_subtitle_end}][1]" \
                        "${file_json_subtimeline}" \
                        )"
            else
                text_time_start="$(get_text_config \
                        "${file_json_text}" \
                        "${item_duration}" \
                        "time_start" \
                        )"
                text_time_start="$(printf "%s" \
                        "scale=${BC_SCALE}
                        ${item_duration_sum} + ${text_time_start}" \
                        | bc)"

                text_time_end="$(get_text_config \
                        "${file_json_text}" \
                        "${item_duration}" \
                        "time_end" \
                        )"
                text_time_end="$(printf "%s" \
                        "scale=${BC_SCALE}
                        ${item_duration_sum} + ${text_time_end}" \
                        | bc)"

            fi

            result="${result}${NL}$(:
                    ), drawtext='${NL}$(:
                    )        fontfile=${text_fontfile}${NL}$(:
                    )        :text='\''${text_content}'\''${NL}$(:
                    )        :fontsize=${text_fontsize}${NL}$(:
                    )        :fontcolor=${text_color}${NL}$(:
                    )        :box=${text_box}${NL}$(:
                    )        :boxcolor=${text_boxcolor}${NL}$(:
                    )        :y_align=font${NL}$(:
                    )        :line_spacing=${text_linespacing}${NL}$(:
                    )        :x=${text_position_x}${NL}$(:
                    )        :y=${text_position_y}${NL}$(:
                    )        :enable=between(t, ${text_time_start}, ${text_time_end})'"

            rm "${file_json_text}"
        done <"${file_json_textarray}"
        rm "${file_json_textarray}"

        item_duration_sum="$(printf "%s" \
                "scale=${BC_SCALE}
                ${item_duration_sum} + ${item_duration}" \
                | bc)"

        index="$((${index} + 1))"
    done <"${file_json_textgrouparray}"
    rm "${file_json_textgrouparray}"

    printf "%s" "${result}"

    return 0
    )
}


################################################################################
# @description Parse srt files to one full srt file for current clip.
#
#     Changelog(template):
#         * 2025-12-11
#             * Modify: Add "Changelog(template)" tag.
#         * 2025-12-10
#             * Modify: Remove return doc, remove variable type.
# @depend printf, jq, rm
# @depend filetype_srt_offset(), get_media_duration()
# @param file_clipjson
# @param clipname
# @param file_srt_clip
################################################################################
parse_subtitle_file ()
{
    (
    file_clipjson="${1}"
    clipname="${2}"
    file_srt_clip="${3}"

    result=""

    if test "X$(jq -r '.subtitle.type' "${file_clipjson}")" != "Xfile"
    then
        return 0
    else
        :
    fi

    file_json_srt_filearray="${Dir_build}/${clipname}__srt_filearray.json"
    jq -r ".subtitle.items[]" "${file_clipjson}" >"${file_json_srt_filearray}"

    item_duration_sum=0
    subtitle_number=1
    index="0"

    while IFS= read -r file_path
    do
        file_srt="${Dir_main}/${file_path}"

        file_ret="${Dir_build}/${clipname}__ret.txt"
        filetype_srt_offset \
                "${file_srt}" \
                "${item_duration_sum}" \
                "${subtitle_number}" \
                "" \
                "${file_ret}" \
                >>"${file_srt_clip}"
        subtitle_number="$(cat "${file_ret}")"
        rm "${file_ret}"

        item_duration="$(get_subtarget_duration \
                "${file_clipjson}" \
                "" \
                "${index}" \
                )"
        item_duration_sum="$(printf "%s" \
                "scale=${BC_SCALE}
                ${item_duration_sum} + ${item_duration}" \
                | bc)"

        index="$((${index} + 1))"
    done <"${file_json_srt_filearray}"
    rm "${file_json_srt_filearray}"

    if test "X${Is_softsub}" = "X1"
    then
        :
    else
        result="${NL}$(:
                ), subtitles='${NL}$(:
                )        filename=${file_srt_clip}${NL}$(:
                )        :original_size=${FILM_WIDTH_DEFAULT}x${FILM_HEIGHT_DEFAULT}${NL}$(:
                )        :force_style='\''$(:
                                 )Fontname=${SUBTITLE_ASS_FONT_DEFAULT}$(:
                                 ),FontSize=${SUBTITLE_ASS_FONTSIZE_DEFAULT}$(:
                                 ),PrimaryColour=${SUBTITLE_ASS_PRIMARYCOLOUR_DEFAULT}$(:
                                 ),OutlineColour=${SUBTITLE_ASS_OUTLINECOLOUR_DEFAULT}$(:
                                 ),BackColour=${SUBTITLE_ASS_BACKCOLOUR_DEFAULT}$(:
                                 ),Bold=${SUBTITLE_ASS_BOLD_DEFAULT}$(:
                                 ),Italic=${SUBTITLE_ASS_ITALIC_DEFAULT}$(:
                                 ),BorderStyle=${SUBTITLE_ASS_BORDERSTYLE_DEFAULT}$(:
                                 ),Outline=${SUBTITLE_ASS_OUTLINE_DEFAULT}$(:
                                 ),Shadow=${SUBTITLE_ASS_SHADOW_DEFAULT}$(:
                                 ),Alignment=${SUBTITLE_ASS_ALIGNMENT_DEFAULT}$(:
                                 ),MarginL=${SUBTITLE_ASS_MARGINL_DEFAULT}$(:
                                 ),MarginR=${SUBTITLE_ASS_MARGINR_DEFAULT}$(:
                                 ),MarginV=${SUBTITLE_ASS_MARGINV_DEFAULT}$(:
                                 )'\'"
    fi

    #
    # Whole film srt generation.
    #
    if test "$(jq '.video | has("speedup")' "${file_clipjson}")" = "true"
    then
        speedup_srt="$(jq -r '.video.speedup' "${file_clipjson}")"
    else
        speedup_srt=""
    fi
    file_ret="${Dir_build}/${clipname}__ret.txt"
    film_duration="$(cat "${File_ret_film_duration}")"
    film_sub_number="$(cat "${File_ret_film_sub_number}")"
    filetype_srt_offset \
            "${file_srt_clip}" \
            "${film_duration}" \
            "${film_sub_number}" \
            "${speedup_srt}" \
            "${file_ret}" \
            >>"${File_film_sub}"
    film_sub_number="$(cat "${file_ret}")"
    printf "%s" "${film_sub_number}"  >"${File_ret_film_sub_number}"
    rm "${file_ret}"

    printf "%s" "${result}"

    return 0
    )
}


################################################################################
# @description Parse subtitile content for drawtext fileter of ffmpeg.
#
#     Changelog(template):
#         * 2025-12-11
#             * Modify: Add "Changelog(template)" tag.
#         * 2025-12-10
#             * Modify: Remove return doc, remove variable type.
# @depend printf, jq, bc, rm
# @param file_clipjson
# @param clipname
# @param file_speechconcat
# @param file_speechlist
# @param file_json_subtimeline
################################################################################
parse_subtitle_text ()
{
    (
    file_clipjson="${1}"
    clipname="${2}"
    file_speechconcat="${3}"
    file_speechlist="${4}"
    file_json_subtimeline="${5}"

    result=""

    if test "X$(jq -r '.subtitle.type' "${file_clipjson}")" != "Xtext"
    then
        return 0
    else
        :
    fi

    file_json_subtitlegrouparray="${Dir_build}/${clipname}__subtitlegrouparray.json"
    jq -c ".subtitle.items[]" "${file_clipjson}" >"${file_json_subtitlegrouparray}"

    item_duration_sum="0"
    index="0"
    subtitle_duration_sum="0"
    speech_duration_sum="0"
    index_subtitle="0"

    #
    # Generate subtimeline.
    #
    printf "%s\n" "{" >>"${file_json_subtimeline}"
    printf "%s\n" "    \"items\":" >>"${file_json_subtimeline}"
    printf "%s\n" "    [" >>"${file_json_subtimeline}"

    #
    # Loop: file_json_subtitlegrouparray
    #
    while IFS= read -r subtitlegroup_data
    do
        file_json_subtitlearray="${Dir_build}/${clipname}__subtitlearray.json"
        printf "%s" "${subtitlegroup_data}" | jq -c ".[]" \
                >"${file_json_subtitlearray}"

        #
        # Generate subtimeline.
        #
        printf "%s\n" "        {" >>"${file_json_subtimeline}"
        printf "%s\n" "            \"subtitles\": " >>"${file_json_subtimeline}"
        printf "%s\n" "            [" >>"${file_json_subtimeline}"

        #
        # Loop: file_json_subtitlearray
        #
        while IFS= read -r subtitle_data
        do
            subtitle_content="$(printf "%s" "${subtitle_data}" | jq -r '.[1]')"

            if test "X$(printf "%s" "${subtitle_data}" \
                    | jq '.[0] | length')" = "X0"
            then
                #
                # Time not set.
                #
                if test "X$(jq -r '.audio.type' "${file_clipjson}")" \
                        != "Xspeech"
                then
                    io_print_error "Subtitle miss time at:"
                    io_print_error "    \"$(printf "%s" "${subtitle_data}" \
                            | jq -c '.')\""
                    return 1
                else
                    #
                    # Generate speech audio.
                    #
                    file_speech="${Dir_build}/${clipname}_$(
                            printf "%0${NUMBER_WIDTH}d" "${index_subtitle}"
                            ).mp4"
                    generate_speech_audio "${file_speech}" "${subtitle_content}"
                    speech_duration="$(get_media_duration "${file_speech}")"
                    printf "%s\n" "${file_speech}" >>"${file_speechlist}"
                    printf "%s\n" "file '${file_speech}'" >>"${file_speechconcat}"

                    speech_duration_sum="$(printf "%s" \
                            "scale=${BC_SCALE}
                            ${speech_duration_sum} + ${speech_duration}" \
                            | bc)"

                    subtitle_time_start="$(printf "%s" \
                            "scale=${BC_SCALE}
                            ${item_duration_sum} + ${subtitle_duration_sum}" \
                            | bc)"
                    subtitle_time_end="$(printf "%s" \
                            "scale=${BC_SCALE}
                            ${subtitle_time_start} + ${speech_duration}" \
                            | bc)"
                    subtitle_duration_sum="$(printf "%s" \
                            "scale=${BC_SCALE}
                            ${subtitle_duration_sum} + ${speech_duration}" \
                            | bc)"
                fi
            else
                #
                # Time set.
                #
                subtitle_time_start="$(printf "%s" "${subtitle_data}" \
                        | jq -r '.[0][0]')"
                subtitle_time_start="$(printf "%s" \
                        "scale=${BC_SCALE}
                        ${item_duration_sum} + ${subtitle_time_start}" \
                        | bc)"
                subtitle_time_end="$(printf "%s" "${subtitle_data}" \
                        | jq -r '.[0][1]')"
                subtitle_time_end="$(printf "%s" \
                        "scale=${BC_SCALE}
                        ${item_duration_sum} + ${subtitle_time_end}" \
                        | bc)"

                if test "X$(printf "%s" \
                        "${subtitle_time_start} < ${subtitle_duration_sum}" \
                        | bc)" = "X1"
                then
                    io_print_error "Subtitle overlap before at:"
                    io_print_error "    \"$(printf "%s" "${subtitle_data}" \
                            | jq -c '.')\""
                    return 1
                else
                    :
                fi

                subtitle_duration_sum="${subtitle_time_end}"

                if test "X$(printf "%s" \
                        "${subtitle_time_end} <= ${subtitle_time_start}" \
                        | bc)" = "X1"
                then
                    io_print_error "Subtitle end time too little at:"
                    io_print_error "    \"$(printf "%s" "${subtitle_data}" \
                            | jq -c '.')\""
                    return 1
                else
                    :
                fi

                if test "X$(jq -r '.audio.type' "${file_clipjson}")" \
                        != "Xspeech"
                then
                    :
                else
                    #
                    # Generate speech audio.
                    #
                    file_speech="${Dir_build}/${clipname}_$(
                            printf "%0${NUMBER_WIDTH}d" "${index_subtitle}"
                            ).mp4"
                    generate_speech_audio "${file_speech}" "${subtitle_content}"
                    speech_duration="$(get_media_duration "${file_speech}")"

                    subtitle_duration="$(printf "%s" \
                            "scale=${BC_SCALE}
                            ${subtitle_time_end} - ${subtitle_time_start}" \
                            | bc)"
                    if test "X$(printf "%s" \
                            "${speech_duration} > ${subtitle_duration}" \
                            | bc)" = "X1"
                    then
                        io_print_error "Speech exceed subtitle time at:"
                        io_print_error "    \"$(printf "%s" "${subtitle_data}" \
                                | jq -c '.')\""
                        return 1
                    else
                        :
                    fi

                    slient_duration="$(printf "%s" \
                            "scale=${BC_SCALE}
                            ${subtitle_time_start} \
                            - ${speech_duration_sum}" \
                            | bc)"

                    if test "X$(printf "%s" \
                            "${slient_duration} < 0" \
                            | bc)" = "X1"
                    then
                        io_print_error "Slient speech duration < 0."
                        return 1
                    elif test "X${slient_duration}" = "X0"
                    then
                        printf "%s\n" "${file_speech}" >>"${file_speechlist}"
                        printf "%s\n" "file '${file_speech}'" \
                                >>"${file_speechconcat}"
                        speech_duration_sum="$(printf "%s" \
                                "scale=${BC_SCALE}
                                ${speech_duration_sum} + ${speech_duration}" \
                                | bc)"
                    else
                        file_slient="${Dir_build}/${clipname}_slient_$(
                                printf "%0${NUMBER_WIDTH}d" "${index_subtitle}"
                                ).mp4"
                        generate_slient_audio \
                                "${file_slient}" "${slient_duration}"
                        slient_duration="$(get_media_duration "${file_slient}")"
                        printf "%s\n" "${file_slient}" >>"${file_speechlist}"
                        printf "%s\n" "file '${file_slient}'" \
                                >>"${file_speechconcat}"
                        printf "%s\n" "${file_speech}" >>"${file_speechlist}"
                        printf "%s\n" "file '${file_speech}'" \
                                >>"${file_speechconcat}"

                        speech_duration_sum="$(printf "%s" \
                                "scale=${BC_SCALE}
                                ${speech_duration_sum} + ${speech_duration} \
                                + ${slient_duration}" \
                                | bc)"
                    fi
                fi
            fi


            subtitle_content="$(escape_text "${subtitle_content}")"
            if test "$(jq '.subtitle | has("fontfile")' "${file_clipjson}")" \
                    = "true"
            then
                subtitle_fontfile="$(jq -r \
                        '.subtitle.fontfile' "${file_clipjson}")"
            else
                subtitle_fontfile="${SUBTITLE_FONTFILE_DEFAULT}"
            fi

            if test "$(jq '.subtitle | has("fontsize")' "${file_clipjson}")" \
                    = "true"
            then
                subtitle_fontsize="$(jq -r \
                        '.subtitle.fontsize' "${file_clipjson}")"
            else
                subtitle_fontsize="${SUBTITLE_FONTSIZE_DEFAULT}"
            fi

            result="${result}${NL}$(:
                    ), drawtext='${NL}$(:
                    )        fontfile=${subtitle_fontfile}${NL}$(:
                    )        :text='\''${subtitle_content}'\''${NL}$(:
                    )        :fontsize=${subtitle_fontsize}${NL}$(:
                    )        :fontcolor=${SUBTITLE_COLOR_DEFAULT}${NL}$(:
                    )        :box=0${NL}$(:
                    )        :boxcolor=${SUBTITLE_BGCOLOR_DEFAULT}${NL}$(:
                    )        :shadowx=-3${NL}$(:
                    )        :shadowy=-1${NL}$(:
                    )        :shadowcolor=black${NL}$(:
                    )        :y_align=font${NL}$(:
                    )        :line_spacing=${SUBTITLE_LINESPACING_DEFAULT}${NL}$(:
                    )        :x=main_w / 2 - text_w / 2${NL}$(:
                    )        :y=main_h - $(:
                                     ) ${SUBTITLE_MARGINBOTTOM_DEFAULT}${NL}$(:
                    )        :enable=between(t, ${subtitle_time_start}, ${subtitle_time_end})'"


            printf "%s\n" \
                    "                [${subtitle_time_start}, ${subtitle_time_end}]," \
                    >>"${file_json_subtimeline}"

            index_subtitle="$((${index_subtitle} + 1))"
        done <"${file_json_subtitlearray}"
        rm "${file_json_subtitlearray}"

        item_duration="$(get_subtarget_duration \
                "${file_clipjson}" \
                "${subtitle_duration_sum}" \
                "${index}" \
                )"
        item_duration_sum="$(printf "%s" \
                "scale=${BC_SCALE}
                ${item_duration_sum} + ${item_duration}" \
                | bc)"

        #
        # Generate subtimeline.
        #
        sed -e "$ s/,$//" "${file_json_subtimeline}" >"${file_json_subtimeline}.tmp"
        mv "${file_json_subtimeline}.tmp" "${file_json_subtimeline}"
        printf "%s\n" "            ]," >>"${file_json_subtimeline}"
        printf "%s\n" "            \"sum\": ${item_duration}" \
                >>"${file_json_subtimeline}"
        printf "%s\n" "        }," >>"${file_json_subtimeline}"

        index="$((${index} + 1))"
    done <"${file_json_subtitlegrouparray}"
    rm "${file_json_subtitlegrouparray}"

    #
    # Generate subtimeline.
    #
    sed -e "$ s/,$//" "${file_json_subtimeline}" >"${file_json_subtimeline}.tmp"
    mv "${file_json_subtimeline}.tmp" "${file_json_subtimeline}"
    printf "%s\n" "    ]," >>"${file_json_subtimeline}"
    printf "%s\n" "    \"sum\": ${item_duration_sum}" \
            >>"${file_json_subtimeline}"
    printf "%s\n" "}" >>"${file_json_subtimeline}"

    printf "%s" "${result}"

    return 0
    )
}




################################################################################
# @description Get final filterv parameter.
#
#     Changelog(template):
#         * 2025-12-19
#             * Modify: Depend command and function.
#             * Modify: Add @output type.
#         * 2025-12-11
#             * Modify: Add "Changelog(template)" tag.
#         * 2025-12-10
#             * Modify: Remove return doc, remove variable type.
# @depend printf
# @depend io_print_error()
# @param type
# @param text
# @param subtitle_file
# @param subtitle_text
# @param extra
# @output parameter
################################################################################
get_filterv_parameters ()
{
    (
    type="${1}"
    text="${2}"
    subtitle_file="${3}"
    subtitle_text="${4}"
    extra="${5}"

    parameter="$(:
            )${text}$(:
            )${subtitle_file}$(:
            )${subtitle_text}$(:
            )${extra}$(
            )"

    case "${type}" in
    ("concat")
        if test "X${parameter}" = "X"
        then
            parameter="null"
        else
            parameter="$(:
                    )${parameter}$(:
                    )"
        fi
        ;;

    ("clip")
        parameter="$(:
                )${FILTERV_PARAMETERS_BASE}$(:
                )${parameter}$(:
                )"
        ;;

    (*)
        io_print_error "Unknown type \"${type}\"."
        return 1
        ;;
    esac

    parameter="${parameter#${NL}, }"

    printf "%s" "${parameter}"

    return 0
    )
}

################################################################################
# @description Add scale bar to picture.
#
#     Changelog(template):
#         * 2025-12-19
#             * Modify: Depend command and function.
#             * Modify: Add @output type.
#         * 2025-12-11
#             * Modify: Add "Changelog(template)" tag.
#         * 2025-12-10
#             * Modify: Remove return doc, remove variable type.
# @depend printf
# @param parameter
# @output parameter
################################################################################
get_filtera_parameters ()
{
    (
    parameter="${1}"

    parameter="${parameter#${NL}, }"

    if test "X${parameter}" = "X"
    then
        parameter="anull"
    else
        :
    fi

    printf "%s" "${parameter}"

    return 0
    )
}

################################################################################
# @description Make a simple clip.
#
#         audio_file:
#             video_color:
#                 subtitle  : YES
#                 duration  : audio
#                 lavfi + aconcat
#                 [0:v]vf[vout];[1:a]af[aout]
#
#             * video_image:
#                 subtitle  : YES
#                 duration  : audio
#                 iconcat + aconcat
#                 [0:v]vf[vout];[1:a]af[aout]
#
#             * video_file:
#                 subtitle  : YES
#                 duration  : video
#                 vconcat + aconcat
#                 [0:v]vf[vout];[0:a][1:a]amix,af[aout]
#
#         audio_null:
#             * video_color:
#                 subtitle  : NO
#                 duration  : vv
#                 lavfi + lavfi
#                 [0:v]vf[vout];[1:a]af[aout]
#
#             video_image:
#                 subtitle  : NO
#                 duration  : image
#                 iconcat + lavfi
#                 [0:v]vf[vout];[1:a]af[aout]
#
#             * video_file:
#                 subtitle  : YES
#                 duration  : video
#                 vconcat
#                 [0:v]vf[vout];[0:a]af[aout]
#
#         audio_speech: *subtitle only from speech*
#             video_color:
#                 duration  : speech
#                 lavfi + spconcat
#                 [0:v]vf[vout];[1:a]af[aout]
#
#             video_image:
#                 duration  : speech
#                 iconcat + spconcat
#                 [0:v]vf[vout];[1:a]af[aout]
#
#             video_file:
#                 duration  : video
#                 vconcat + spconcat
#                 [0:v]vf[vout];[0:a][1:a]af[aout]
#
#     Changelog(template):
#         * 2025-12-11
#             * Modify: Add "Changelog(template)" tag.
#         * 2025-12-10
#             * Modify: Remove return doc, remove variable type.
#
# @depend jq, rm
# @depend io_message(), do_encode()
# @depend parse_video(), parse_image(), parse_audio()
# @depend parse_text(), parse_subtitle_file(), parse_subtitle_text()
# @param file_clipjson
# @param file_clip
# @param clipname
# @param indent_current
# @param is_only_parse
################################################################################
make_simple ()
{
    (
    file_clipjson="${1}"
    file_clip="${2}"
    clipname="${3}"
    indent_current="${4}"
    is_only_parse="${5}"

    virtualv_parameters=""
    virtuala_parameters=""

    filterv_parameters=""
    filterv_parameters_text=""
    filterv_parameters_subtitle_file=""
    filterv_parameters_subtitle_text=""
    filterv_parameters_extra=""

    filtera_parameters=""

    filter_complex_parameters=""

    file_videoconcat="${Dir_build}/${clipname}__videoconcat.txt"
    file_imageconcat="${Dir_build}/${clipname}__imageconcat.txt"
    file_audioconcat="${Dir_build}/${clipname}__audioconcat.txt"
    file_speechconcat="${Dir_build}/${clipname}__speechconcat.txt"
    file_speechlist="${Dir_build}/${clipname}__speechlist.txt"
    file_srt_clip="${Dir_build}/${clipname}__subtitle.srt"
    file_json_subtimeline="${Dir_build}/${clipname}__subtimeline.json"

    v_type="$(jq -r '.video.type' "${file_clipjson}")"
    a_type="$(jq -r '.audio.type' "${file_clipjson}")"

    if test "X${is_only_parse}" = "X1"
    then
        io_message "${indent_current}\"${clipname}\": Parse subtitle file ..."
        : >"${file_srt_clip}"
        filterv_parameters_subtitle_file="$(parse_subtitle_file \
                "${file_clipjson}" \
                "${clipname}" \
                "${file_srt_clip}" \
                )"
        rm "${file_srt_clip}"
        return 0
    else
        :
    fi

    io_message "${indent_current}\"${clipname}\": Clip ${v_type} + ${a_type}"

    io_message "${indent_current}\"${clipname}\": Parse subtitle file ..."
    : >"${file_srt_clip}"
    filterv_parameters_subtitle_file="$(parse_subtitle_file \
            "${file_clipjson}" \
            "${clipname}" \
            "${file_srt_clip}" \
            )"

    io_message "${indent_current}\"${clipname}\": Parse subtitle text..."
    : >"${file_speechconcat}"
    : >"${file_speechlist}"
    : >"${file_json_subtimeline}"
    filterv_parameters_subtitle_text="$(parse_subtitle_text \
            "${file_clipjson}" \
            "${clipname}" \
            "${file_speechconcat}" \
            "${file_speechlist}" \
            "${file_json_subtimeline}" \
            )"

    io_message "${indent_current}\"${clipname}\": Parse text ..."
    filterv_parameters_text="$(parse_text \
            "${file_clipjson}" \
            "${clipname}" \
            "${file_json_subtimeline}" \
            )"

    io_message "${indent_current}\"${clipname}\": Parse image ..."
    : >"${file_imageconcat}"
    image_duration_sum="$(parse_image \
            "${file_clipjson}" \
            "${clipname}" \
            "${file_imageconcat}" \
            "${file_json_subtimeline}" \
            )"

    io_message "${indent_current}\"${clipname}\": Parse video ..."
    : >"${file_videoconcat}"
    video_duration_sum="$(parse_video \
            "${file_clipjson}" \
            "${clipname}" \
            "${file_videoconcat}" \
            )"

    io_message "${indent_current}\"${clipname}\": Parse audio ..."
    : >"${file_audioconcat}"
    audio_duration_sum="$(parse_audio \
            "${file_clipjson}" \
            "${clipname}" \
            "${file_audioconcat}" \
            )"

    clip_duration="$(get_clip_duration \
            "${file_clipjson}" \
            "${video_duration_sum}" \
            "${image_duration_sum}" \
            "${audio_duration_sum}" \
            "${file_json_subtimeline}" \
            )"

    if test "$(jq '.video | has("speedup")' "${file_clipjson}")" = "true"
    then
        speedup="$(jq -r '.video.speedup' "${file_clipjson}")"
        pts_scale="$(printf "%s" "scale=${BC_SCALE}; 1 / ${speedup}" | bc)"

        filtera_parameters="${filtera_parameters}${NL}$(:
                ), atempo='${speedup}'"

        filterv_parameters_extra="${filterv_parameters_extra}${NL}$(:
                ), setpts='expr=${pts_scale} * PTS'"

        clip_duration="$(printf "%s" \
                "scale=${BC_SCALE}
                ${clip_duration} / ${speedup}" \
                | bc)"
    else
        :
    fi

    if test "$(jq '.video | has("volume")' "${file_clipjson}")" = "true"
    then
        filtera_parameters="${filtera_parameters}${NL}$(:
                ), volume='${NL}$(:
                )       volume=$(jq -r '.video.volume' "${file_clipjson}")'"
    else
        :
    fi

    filterv_parameters="$(get_filterv_parameters \
            "clip" \
            "${filterv_parameters_text}" \
            "${filterv_parameters_subtitle_file}" \
            "${filterv_parameters_subtitle_text}" \
            "${filterv_parameters_extra}" \
            )"
    filtera_parameters="$(get_filtera_parameters \
            "${filtera_parameters}" \
            )"

    #
    # Set ffmpeg arguments.
    #
    set --

    if test "X${v_type}" = "Xcolor"
    then
        virtualv_parameters="${NL}$(:
                ), color='${NL}$(:
                )        color=${FILM_COLOR_DEFAULT}${NL}$(:
                )        :size=${FILM_WIDTH_DEFAULT}x${FILM_HEIGHT_DEFAULT}'"
        virtualv_parameters="${virtualv_parameters#${NL}, }"
        set -- "${@}" -f lavfi -i "${NL}${virtualv_parameters}${NL}"
    else
        if test "X${v_type}" = "Xfile"
        then
            set -- "${@}" -f concat -safe 0 -i "${file_videoconcat}"
        else
            # image
            set -- "${@}" -f concat -safe 0 -i "${file_imageconcat}"
        fi
    fi

    if test "X${a_type}" = "Xnull" \
            && test "X${v_type}" != "Xfile"
    then
        virtuala_parameters="${NL}$(:
                ), anullsrc='${NL}$(:
                )       sample_rate=${SAMPLERATE}'"
        virtuala_parameters="${virtuala_parameters#${NL}, }"
        set -- "${@}" -f lavfi -i "${NL}${virtuala_parameters}${NL}"
    else
        if test "X${a_type}" = "Xfile"
        then
            set -- "${@}" -f concat -safe 0 -i "${file_audioconcat}"
        elif test "X${a_type}" = "Xspeech"
        then
            set -- "${@}" -f concat -safe 0 -i "${file_speechconcat}"
        else
            :
        fi
    fi


    if test "X${v_type}" = "Xfile"
    then
        if test "X${a_type}" != "Xnull"
        then
            filter_complex_parameters="$(:
                    )[0:v]${NL}$(:
                    )        ${filterv_parameters}${NL}$(:
                    )        [vout];${NL}$(:
                    )[0:a]${NL}$(:
                    )        ${filtera_parameters}${NL}$(:
                    )        [aout1];${NL}$(:
                    )[aout1][1:a]${NL}$(:
                    )        amix='inputs=2${NL}$(:
                    )                :duration=first${NL}$(:
                    )                :dropout_transition=0${NL}$(:
                    )                :normalize=0'${NL}$(:
                    )        [aout]"
        else
            filter_complex_parameters="$(:
                    )[0:v]${NL}$(:
                    )        ${filterv_parameters}${NL}$(:
                    )        [vout];${NL}$(:
                    )[0:a]${NL}$(:
                    )        ${filtera_parameters}${NL}$(:
                    )        [aout]"
        fi
    else
        filter_complex_parameters="$(:
                )[0:v]${NL}$(:
                )        ${filterv_parameters}${NL}$(:
                )        [vout];${NL}$(:
                )[1:a]${NL}$(:
                )        ${filtera_parameters}${NL}$(:
                )        [aout]"
    fi

    set -- "${@}" -filter_complex "${NL}${filter_complex_parameters}${NL}"
    set -- "${@}" -map "[vout]" -map "[aout]"

    io_message "${indent_current}\"${clipname}\": Enccoding ..."
    ffmpeg \
            ${FFMPEG_OPTIONS} \
            "${@}" \
            ${FFMPEG_CODEC_V} \
            ${FFMPEG_VIDEO} \
            ${FFMPEG_CODEC_A} \
            ${FFMPEG_AUDIO} \
            -t "${clip_duration}" \
            "${file_clip}"

    rm "${file_videoconcat}"
    rm "${file_imageconcat}"
    rm "${file_audioconcat}"
    rm "${file_speechconcat}"
    rm "${file_srt_clip}"
    rm "${file_json_subtimeline}"

    while read -r file_speech
    do
        rm "${file_speech}"
    done < "${file_speechlist}"
    rm "${file_speechlist}"

    return 0

    )
}

################################################################################
# @description Make a concat clip.
#         TODO: These actions may reencoding.
#
#            null
#                    -f concat -safe 0 -i "${file_subclipconcat}" \
#                    -c:v copy \
#                    -c:a copy \
#            text
#                    -f concat -safe 0 -i "${file_subclipconcat}" \
#                    ${FFMPEG_CODEC_V} \
#                    -c:a copy \
#
#            audio loop
#                    -f concat -safe 0 -i "${file_subclipconcat}" \
#                    -stream_loop -1 -i "${file_audio}" \
#                    -c:v copy \
#                    ${FFMPEG_AUDIO} \
#                    ${FFMPEG_CODEC_A} \
#
#            audio loop + text
#                    -f concat -safe 0 -i "${file_subclipconcat}" \
#                    -stream_loop -1 -i "${file_audio}" \
#                    ${FFMPEG_CODEC_V} \
#                    ${FFMPEG_AUDIO} \
#                    ${FFMPEG_CODEC_A} \
#
#            audioconcat
#                    -f concat -safe 0 -i "${file_subclipconcat}" \
#                    -f concat -safe 0 -i "${file_audioconcat}" \
#                    -c:v copy \
#                    ${FFMPEG_AUDIO} \
#                    ${FFMPEG_CODEC_A} \
#
#            audioconcat + text
#                    -f concat -safe 0 -i "${file_subclipconcat}" \
#                    -f concat -safe 0 -i "${file_audioconcat}" \
#                    ${FFMPEG_CODEC_V} \
#                    ${FFMPEG_AUDIO} \
#                    ${FFMPEG_CODEC_A} \
#
#     Changelog(template):
#         * 2025-12-19
#             * Modify: Depend command and function.
#             * Modify: Add @output type.
#         * 2025-12-11
#             * Modify: Add "Changelog(template)" tag.
#         * 2025-12-10
#             * Modify: Remove return doc, remove variable type.
# @depend printf, jq, ffmpeg
# @depend io_message()
# @param file_clipjson
# @param clipname
# @param indent_current
# @param file_subclipconcat
# @param clip_duration
# @output normal
################################################################################
make_concat ()
{
    (
    file_clipjson="${1}"
    file_clip="${2}"
    clipname="${3}"
    indent_current="${4}"
    file_subclipconcat="${5}"
    clip_duration="${6}"

    filterv_parameters=""
    filterv_parameters_text=""
    filterv_parameters_subtitle_file=""
    filterv_parameters_subtitle_text=""
    filterv_parameters_extra=""

    filtera_parameters=""

    filter_complex_parameters=""


    file_audioconcat="${Dir_build}/${clipname}__audioconcat.txt"
    : >"${file_audioconcat}"

    v_type="$(jq -r '.video.type' "${file_clipjson}")"
    a_type="$(jq -r '.audio.type' "${file_clipjson}")"
    a_mode="$(jq -r '.audio.mode' "${file_clipjson}")"

    io_message "${indent_current}\"${clipname}\" combine: Parse text ..."
    filterv_parameters_text="$(parse_text \
            "${file_clipjson}" \
            "${clipname}" \
            "${file_json_subtimeline}" \
            )"

    io_message "${indent_current}\"${clipname}\" combine: Parse audio ..."
    audio_duration_sum="$(parse_audio \
            "${file_clipjson}" \
            "${clipname}" \
            "${file_audioconcat}" \
            )"

    filterv_parameters="$(get_filterv_parameters \
            "concat" \
            "${filterv_parameters_text}" \
            "${filterv_parameters_subtitle_file}" \
            "${filterv_parameters_subtitle_text}" \
            "${filterv_parameters_extra}" \
            )"
    filtera_parameters="$(get_filtera_parameters \
            "${filtera_parameters}" \
            )"

    #
    # Set ffmpeg arguments.
    #
    set --
    set -- "${@}" -f concat -safe 0 -i "${file_subclipconcat}"

    if test "X${a_type}" = "Xfile"
    then
        if "X${a_mode}" = "Xloop"
        then
            file_audio="${Dir_main}/$(jq -r ".audio.items[0]" "${file_clipjson}")"
            set -- "${@}" -stream_loop -1 -i "${file_audio}"
        else
            set -- "${@}" -f concat -safe 0 -i "${file_audioconcat}"
        fi
    else
        :
    fi

    if test "X${filterv_parameters}" = "Xnull" \
            || test "X${filtera_parameters}" = "Xanull"
    then
        if test "X${filterv_parameters}" = "Xnull"
        then
            set -- "${@}" -c:v copy
        else
            set -- "${@}" -filter:v "${NL}${filterv_parameters}${NL}"
            set -- "${@}" ${FFMPEG_CODEC_V} ${FFMPEG_VIDEO}
        fi


        if test "X${filtera_parameters}" = "Xanull"
        then
            set -- "${@}" -c:a copy
        else
            set -- "${@}" -filter:a "${NL}${filtera_parameters}${NL}"
            set -- "${@}" ${FFMPEG_CODEC_A} ${FFMPEG_AUDIO}
        fi
    else
        if test "X${a_mode}" = "Xloop"
        then
            fade_in_time_start="0"
            fade_out_time_start="$(printf "%s" \
                    "scale=${BC_SCALE}
                    ${clip_duration} - ${FADE_OUT_DEFAULT}" \
                    | bc)"
            filter_complex_parameters="$(:
                    )[0:v]${NL}$(:
                    )        ${filterv_parameters}${NL}$(:
                    )        [vout];${NL}$(:
                    )[1:a]${NL}$(:
                    )        afade='type=in${NL}$(:
                    )                :start_time=${fade_in_time_start}${NL}$(:
                    )                :duration=${FADE_IN_DEFAULT}'${NL}$(:
                    )        , afade='type=out${NL}$(:
                    )                :start_time=${fade_out_time_start}${NL}$(:
                    )                :duration=${FADE_OUT_DEFAULT}'${NL}$(:
                    )        [afade];${NL}$(:
                    )[0:a][afade]${NL}$(:
                    )        amix='inputs=2${NL}$(:
                    )                :duration=first${NL}$(:
                    )                :dropout_transition=0${NL}$(:
                    )                :normalize=0'${NL}$(:
                    )        [aout]"
        else
            filter_complex_parameters="$(:
                    )[0:v]${NL}$(:
                    )        ${filterv_parameters}${NL}$(:
                    )        [vout];${NL}$(:
                    )[0:a][1:a]${NL}$(:
                    )        amix='inputs=2${NL}$(:
                    )                :duration=first${NL}$(:
                    )                :dropout_transition=0${NL}$(:
                    )                :normalize=0'${NL}$(:
                    )        [aout]"
        fi

        set -- "${@}" -filter_complex "${NL}${filter_complex_parameters}${NL}"
        set -- "${@}" -map "[vout]" -map "[aout]"
        set -- "${@}" ${FFMPEG_CODEC_V} ${FFMPEG_VIDEO}
        set -- "${@}" ${FFMPEG_CODEC_A} ${FFMPEG_AUDIO}
    fi


    #
    # Message.
    #
    if test "X$(jq '.text.type' "${file_clipjson}")" != "Xnull"
    then
        io_message "${indent_current}\"${clipname}\" combine action: Add text."
    else
        :
    fi

    if test "X${a_type}" = "Xnull"
    then
        :
    elif test "X${a_type}" = "Xfile"
    then
        if test "X${a_mode}" = "Xloop"
        then
            add_audio="Add loop audio"
        else
            add_audio="Add concat audio"
        fi
        io_message "${indent_current}\"${clipname}\" combine action: ${add_audio}."
    else
        :
    fi

    io_message "${indent_current}\"${clipname}\" combine: Concat ..."
    ffmpeg \
            ${FFMPEG_OPTIONS} \
            "${@}" \
            -t "${clip_duration}" \
            "${file_clip}"

    rm "${file_audioconcat}"

    return 0
    )
}



################################################################################
# @description Make clip recursively.
#
#     Changelog(template):
#         * 2025-12-19
#             * Modify: Depend command and function.
#             * Modify: Add @output type.
#         * 2025-12-11
#             * Modify: Add "Changelog(template)" tag.
#         * 2025-12-10
#             * Modify: Remove return doc, remove variable type.
# @depend printf, jq, rm
# @depend io_message(), make_simple(), make_concat
# @param file_clipjson
# @param file_clip
# @param clipname
# @param indent_current
# @param is_only_parse
# @output normal
################################################################################
recursive_make ()
{
    (
    file_clipjson="${1}"
    file_clip="${2}"
    clipname="${3}"
    indent_current="${4}"
    is_only_parse="${5}"

    if test "$(jq '.clips | length' "${file_clipjson}")" -eq 0
    then
        make_simple \
                "${file_clipjson}" \
                "${file_clip}" \
                "${clipname}" \
                "${indent_current}" \
                "${is_only_parse}"
    else
        file_subclipconcat="${Dir_build}/${clipname}__subclipconcat.txt"
        file_subcliplist="${Dir_build}/${clipname}__subcliplist.txt"
        file_json_subcliparray="${Dir_build}/${clipname}__subcliparray.json"

        subclip_count="$(jq '.clips | length' "${file_clipjson}")"

        : >"${file_subclipconcat}"
        : >"${file_subcliplist}"
        io_message "${indent_current}Sub clips: ${subclip_count}"
        jq -c ".clips[]" "${file_clipjson}" >"${file_json_subcliparray}"

        duration_sum="0"
        index="0"
        while IFS= read -r subclip
        do
            file_json_subclip="${Dir_build}/${clipname}__subclip_$(
                    printf "%0${NUMBER_WIDTH}d" "${index}"
                    ).json"
            printf "%s" "${subclip}"  >"${file_json_subclip}"

            subclipname="$(jq -r '.name' "${file_json_subclip}")"
            sub_clipname="${clipname}__$(
                    printf "%0${NUMBER_WIDTH}d" "${index}"
                    )_${subclipname}"
            file_subclip="${Dir_build}/${sub_clipname}.mp4"

            io_message "${indent_current}\"${sub_clipname}\": make ...$(
                    :), $((${index} + 1))/${subclip_count}"

            if \
                test "$(jq '
                        .clips['${index}'].name as $x
                        | .build | length > 0 and index($x) == null
                        ' "${file_clipjson}"
                        )" = "true" \
                && \
                test -e "${file_subclip}"
            then
                io_message "${indent_current}${INDENT}\"${sub_clipname}\": $(:
                        )Use exist clip." "warn"
                is_only_parse="1"
            else
                is_only_parse="0"
            fi

            recursive_make \
                    "${file_json_subclip}" \
                    "${file_subclip}" \
                    "${sub_clipname}" \
                    "${indent_current}${INDENT}" \
                    "${is_only_parse}"

            rm "${file_json_subclip}"
            io_message ""

            subclip_duration="$(get_media_duration "${file_subclip}")"

            #
            # Whole film srt generation.
            #
            printf "%s" "$(printf "%s" \
                    "scale=${BC_SCALE}
                    $(cat "${File_ret_film_duration}") + ${subclip_duration}" \
                    | bc)" \
                    >"${File_ret_film_duration}"

            duration_sum="$(printf "%s" \
                    "scale=${BC_SCALE}
                    ${duration_sum} + ${subclip_duration}" \
                    | bc)"

            printf "%s\n" "${file_subclip}" >>"${file_subcliplist}"
            printf "%s\n" "file '${file_subclip}'" >>"${file_subclipconcat}"

            index="$((${index} + 1))"
        done <"${file_json_subcliparray}"
        rm "${file_json_subcliparray}"

        clip_duration="${duration_sum}"

        io_message "${indent_current}\"${clipname}\" combine subclips ..."
        make_concat \
                "${file_clipjson}" \
                "${file_clip}" \
                "${clipname}" \
                "${indent_current}${INDENT}" \
                "${file_subclipconcat}" \
                "${clip_duration}"

        rm "${file_subclipconcat}"
        #
        # Remove subclips.
        #
        #while read -r file_subclip
        #do
        #    rm "${file_subclip}"
        #done < "${file_subcliplist}"
        rm "${file_subcliplist}"
    fi

    return 0
    )
}

################################################################################
# @description Make film according to json.
#
#     Changelog(template):
#         * 2025-12-19
#             * Modify: Depend command and function.
#             * Modify: Add @output type.
#         * 2025-12-11
#             * Modify: Add "Changelog(template)" tag.
#         * 2025-12-10
#             * Modify: Remove return doc, remove variable type.
# @depend printf, mkdir, rm, realpath, dirname, jq
# @depend io_message()
# @param filmjson
# @output normal
################################################################################
make_film ()
{
    (
    filmjson="${1}"

    if test ! -e "${filmjson}"
    then
        io_print_error "Error: File \"${filmjson}\" does not exists."
        return 1
    else
        :
    fi

    file_filmjson="$(realpath "${filmjson}")"
    Dir_main="$(dirname "${file_filmjson}")"
    Dir_build="${Dir_main}/build"

    clipname="$(jq -r '.name' "${file_filmjson}")"
    file_clip="${Dir_build}/${clipname}.mp4" 

    cd "${Dir_main}"
    mkdir -p "${Dir_build}"

    #
    # Whole film srt generation.
    #
    File_film_sub="${Dir_build}/${clipname}.srt"
    : >"${File_film_sub}"
    File_ret_film_duration="${Dir_build}/${clipname}__ret_film_duration.txt"
    printf "%s" "0" >"${File_ret_film_duration}"
    File_ret_film_sub_number="${Dir_build}/${clipname}__ret_film_sub_number.txt"
    printf "%s" "1" >"${File_ret_film_sub_number}"

    io_message "Make \"${clipname}\" ..."
    recursive_make \
            "${file_filmjson}" \
            "${file_clip}" \
            "${clipname}" \
            "${INDENT}" \
            "0"
    io_message "Done!"

    #
    # Whole film srt generation.
    #
    rm "${File_ret_film_duration}"
    rm "${File_ret_film_sub_number}"

    return 0
    )
}

################################################################################
#
# Main
#
################################################################################
NL="$(printf "\n_")"
NL="${NL%_}"
INDENT="    "

################################################################################
# Film.
################################################################################
FILM_WIDTH_DEFAULT="1920"
FILM_HEIGHT_DEFAULT="1080"
BLANK_W_DEFAULT="16"
BLANK_H_DEFAULT="8"
FILM_COLOR_DEFAULT="#202020" #"#FAFAFA"
TEXT_COLOR_DEFAULT="#B4B4B4" #"#404040"

################################################################################
# Font.
################################################################################
#FONTFILE="/Users/fjc/Library/Fonts/adobe/AdobeHeitiStd-Regular.otf"
#FONTFILE="/Users/fjc/Library/Fonts/adobe/AdobeSongStd-Light.otf"
#FONTFILE="/Users/fjc/Library/Fonts/adobe/AdobeKaitiStd-Regular.otf"
#FONTFILE="/Users/fjc/Library/Fonts/google/NotoSansMonoCJKsc-VF.otf"
#FONTFILE="/System/Library/Fonts/Supplemental/Andale Mono.ttf"
#FONTFILE="/System/Library/Fonts/SFNSMono.ttf"
#FONTFILE="/System/Library/Fonts/SFNS.ttf"
#FONTFILE="/System/Library/Fonts/SFNSMono.ttf"

#
# For NotoSansMonoCJKsc font.
#
TEXT_FONT_DEFAULT="Adobe Heiti Std"
TEXT_FONTFILE_DEFAULT="/Users/fjc/Library/Fonts/google/NotoSansMonoCJKsc-VF.otf"
TEXT_LINESPACING_DEFAULT=0
FONT_FACTOR="0.5"   # pixelsize / fontsize
FONT_RATIO="2.9"    # region_height / rigion_width
DISPLAY_UNIT_W="10"
DISPLAY_UNIT_H="29"

#DISPLAY_ROWS=36     # segment of height length
#DISPLAY_COLS=185.6  # segment of width length
#DISPLAY_COLS="$(printf "scale=${BC_SCALE}; ${DISPLAY_ROWS} | bc")"
#DISPLAY_UNIT_W="$(printf "%s" \
#        "scale=${BC_SCALE}
#        ${FILM_HEIGHT_DEFAULT} / ${DISPLAY_ROWS} / ${FONT_RATIO}" \
#        | bc)"
#DISPLAY_UNIT_H="$(printf "%s" \
#        "scale=${BC_SCALE}
#        ${FILM_HEIGHT_DEFAULT} / ${DISPLAY_ROWS}" \
#        | bc)"


################################################################################
# FFmpeg drawtext filter subtitle.
################################################################################
SUBTITLE_FONT_DEFAULT="Adobe Heiti Std"
SUBTITLE_FONTFILE_DEFAULT="/Users/fjc/Library/Fonts/adobe/AdobeSongStd-Light.otf"
SUBTITLE_FONTSIZE_DEFAULT="50"
SUBTITLE_LINESPACING_DEFAULT=0
SUBTITLE_MARGINBOTTOM_DEFAULT="120"
SUBTITLE_COLOR_DEFAULT="White"
SUBTITLE_BGCOLOR_DEFAULT="Black@0.5"

################################################################################
# FFmpeg subtitles filter subtitle.
################################################################################
SUBTITLE_ASS_EMBED_DEFAULT="0"
SUBTITLE_ASS_FONT_DEFAULT="Adobe Heiti Std"
SUBTITLE_ASS_FONTSIZE_DEFAULT="20"
SUBTITLE_ASS_PRIMARYCOLOUR_DEFAULT="&H00FFFFFF"
SUBTITLE_ASS_OUTLINECOLOUR_DEFAULT="&H00000000"
SUBTITLE_ASS_BACKCOLOUR_DEFAULT="&HFF000000" #"&H80000000"
SUBTITLE_ASS_BOLD_DEFAULT="0"
SUBTITLE_ASS_ITALIC_DEFAULT="0"
SUBTITLE_ASS_BORDERSTYLE_DEFAULT="1"
SUBTITLE_ASS_OUTLINE_DEFAULT="1" #"2"
SUBTITLE_ASS_SHADOW_DEFAULT="2" #"2"
SUBTITLE_ASS_ALIGNMENT_DEFAULT="2"
SUBTITLE_ASS_MARGINL_DEFAULT="10"
SUBTITLE_ASS_MARGINR_DEFAULT="10"
SUBTITLE_ASS_MARGINV_DEFAULT="10"

################################################################################
# Other.
################################################################################
TALK_SPEED="10"     # Chars per second
FADE_IN_DEFAULT="5"
FADE_OUT_DEFAULT="5"
BC_SCALE="10"       # BC tool, scale
NUMBER_WIDTH="4"    # Filename number prefix width

################################################################################
# FFmpeg.
################################################################################
FFMPEG_OPTIONS="
        -y
        -hide_banner
        -loglevel error
        -nostdin
        "
        #-loglevel info
        #-loglevel debug
        #-loglevel error

FPS="25"
PIX_FMT="yuv420p"
SAMPLERATE="44100"
FILTERV_PARAMETERS_BASE="${NL}$(:
        ), scale='${NL}$(:
        )        width=${FILM_WIDTH_DEFAULT}${NL}$(:
        )        :height=${FILM_HEIGHT_DEFAULT}${NL}$(:
        )        :force_original_aspect_ratio=decrease'${NL}$(:
        ), pad='${NL}$(:
        )        width=${FILM_WIDTH_DEFAULT}${NL}$(:
        )        :height=${FILM_HEIGHT_DEFAULT}${NL}$(:
        )        :x=(out_w - in_w) / 2${NL}$(:
        )        :y=(out_h - in_h) / 2'${NL}$(
        ), setsar='sar=1':${NL}$(:
        ), fps='fps=${FPS}'"
#FILTERV_PARAMETERS_POST="${NL}$(:
#        ), format='${NL}$(:
#        )        pix_fmts=${PIX_FMT}${NL}$(:
#        )        :color_spaces=bt709${NL}$(:
#        )        :color_ranges=tv'"

#
# NOTE: Do NOT contain newline in flowing variables.
#         They are used in "set -- ${var}".
#
FFMPEG_CODEC_V="-c:v h264_videotoolbox" #"-c:v libx264"
FFMPEG_VIDEO="-pix_fmt ${PIX_FMT} -r ${FPS}"
FFMPEG_CODEC_A="-c:a aac"
FFMPEG_AUDIO="-ac 2 -ar ${SAMPLERATE}"

#test_font
#test_escape
#test_filterscript
#test_filterscript_textfile
#indent "${FILTERV_PARAMETERS_BASE}" 2
#exit

################################################################################
# Arguments.
################################################################################
Is_softsub="0"
Dir_main=""
Dir_build=""
File_ret_film_duration=""
File_ret_film_sub_number=""
File_film_sub=""

action=""
has_option="true"

if test "${#}" -lt 1
then
    help
    exit 1
else
    :
fi

case "${1}" in
("--gen_clip_image")
    action="gen_clip_image"
    shift
    ;;
("--gen_clip_video")
    action="gen_clip_video"
    shift
    ;;
("--json_to_sub")
    action="json_to_sub"
    shift
    ;;
("--lrc_to_sub")
    action="lrc_to_sub"
    shift
    ;;
(*)
    action="make_film"
    ;;
esac

case "${action}" in
("make_film")
    while test "${has_option}" = "true"
    do
        case "${1}" in
        ("--soft_sub")
            Is_softsub="1"
            shift
            ;;
        ("--"*)
            io_print_error "Unknown option \"${1}\", exit."
            exit 1
            ;;
        (*)
            has_option="false"
            ;;
        esac
    done

    make_film "${@}"
    ;;

("gen_clip_image")
    if test "${#}" -ne 7
    then
        help
        exit 1
    else
        :
    fi

    gen_clip_image "${@}"
    ;;

("gen_clip_video")
    if test "${#}" -ne 5
    then
        help
        exit 1
    else
        :
    fi

    gen_clip_video "${@}"
    ;;

("json_to_sub")
    if test "${#}" -ne 1
    then
        help
        exit 1
    else
        :
    fi

    filetype_jsonsub_to_sub "${@}"
    ;;

("lrc_to_sub")
    if test "${#}" -lt 1
    then
        help
        exit 1
    else
        :
    fi

    filetype_lrc_to_sub "${@}"
    ;;
esac

