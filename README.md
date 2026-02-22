# Introduction

Shell script performs video editing by parsing information from a JSON file.
The main backend is FFmpeg.

## Use example

* Create simple video just display some text and some subtitle or/and speech
* Create MV with LRC lyrics
* Reuse same begin and ending part of a video
* Want create video in programmatic way

## Feature

* Video/audio encoding and concat
* Audio mix
* Text to speech with subtitle
* Speed adjust
* Volume adjust
* Generate separate srt subtitle file
* Recursive generate, partial build

# Dependence

* `ffmpeg` to encoding media
* `ffprobe` to get media information
* `jq` to parse json file
* `bc` to caculate number
* `say` to generate speech audio from string
* `sed` to process string replace

# Quick start

## Prepare files

1. script file and required functions file

`progcut.sh` is script file, `share/shell/*.sh` is shell function lib files.

2. media file

Normally put in directory `file`, for example:

    file/
        audio/
            01.mp3
            02.mp3
        image/
            01.png
            02.png
            03.jpg
        video/
            01.MOV
            02.MOV

3. video description json file

The video is divided to some clips, the clip can contains sub clips
, but only one clip exists in root node.

    {
        "name": "videomaker_test",
        "build":
        [
        ],
        "video": {},
        "audio": {},
        "text": {},
        "subtitle": {},
        "clips":
        [
            <clip1>,
            <clip2>
                <subclip1>
                <subclip2>
                ...,
            <clip3>,
            ...
        ]
    }

Every clip has 5 items: `name`, `video`, `audio`, `text`, `subtitle`.
The root clip has extra `build` item, when set, only build these clips.

See below clip example for detail information.

## Run script

Run `DATADIR=. ./progcut.sh video.json`, the generated video will place in `build` directory.

    build/
        testfilm__0000_introduction.mp4
        testfilm__0001_part1.mp4
        testfilm__0002_part2__0000_sub1.mp4
        testfilm__0002_part2__0001_sub2.mp4
        testfilm__0002_part2__0002_sub3.mp4
        testfilm__0002_part2.mp4
        testfilm__0003_part3.mp4
        testfilm__0004_end.mp4
        testfilm.mp4

`testfile` is the name of root clip, `testfilm.mp4` is final generated video
, other files are sub clips, if kept, can skip build them to build faster.

# Clip example

1. Color video + no audio

<!---->

    "name": "color_null",
    "video": {"type": "color", "duration": 9},
    "audio": {},
    "text":
    {
        "type": "text",
        "target": "video",
        "items":
        [
            [
                {
                    "content":
                    [
                        "命令行"
                    ],
                    "time":[0.5, 2],
                    "position": ["c", 15],
                    "size": 4,
                    "color": "White"
                },
                {
                    "content":
                    [
                        "理概念认识矢量表  写指令点亮小绿灯"
                    ],
                    "time":[3, 8],
                    "position": ["c", 15],
                    "size": 4
                }
            ]
        ]
    },
    "subtitle":
    {
        "type": "text",
        "target": "video",
        "items":
        [
            [
                [[1, 2], "-M, Armv7-A 等都是 Arm 公司制定的核心架构，"],
                [[3, 4.2], "如 Armv1，Armv2 等。"],
                [[4.78, 8.56], "入式的一种变种，采用 T32 指令集。"]
            ]
        ]
    }

2. Color video + TTS speech audio

<!---->

    "name": "color_speech",
    "video": {"type": "color"},
    "audio": {"type": "speech"},
    "text":
    {
        "type": "text",
        "target": "audio",
        "items":
        [
            [
                {
                    "content":
                    [
                        "0x00000000 -+                        ",
                        "...         |-> Flash/System/RAM 别名",
                        "0x0007FFFF -+                        ",
                        "0x00080000 -+                        ",
                        "...         |-> 保留                 ",
                        "0x07FFFFFF -+                        ",
                        "0x08000000 -+                        ",
                        "...         |-> Flash(512KB)         ",
                        "0x0807FFFF -+                        ",
                        "0x08080000 -+                        ",
                        "...         |-> 保留                 ",
                        "0x1FFFEFFF -+                        ",
                        "0x1FFFF000 -+                        ",
                        "...         |-> System(2KB)          ",
                        "0x1FFFF7FF -+                        ",
                        "0x1FFFF800 -+                        ",
                        "...         |-> Option bytes(16B)    ",
                        "0x1FFFF80F -+                        ",
                        "0x1FFFF810 -+                        ",
                        "...         |-> 没说                 ",
                        "0x1FFFFFFF -+                        "
                    ],
                    "size": 1,
                    "position": [74, 7]
                },
                {
                    "content":
                    [
                        "0x00000000 -+                        ",
                        "...         |-> Flash/System/RAM 别名",
                        "0x0007FFFF -+                        "
                    ],
                    "subtitle": [2, 2],
                    "size": 1,
                    "position": [74, 7],
                    "box": 1,
                    "boxcolor": "Orange",
                    "color": "Red"
                },
                {
                    "content":
                    [
                        "0x08000000 -+                        ",
                        "...         |-> Flash(512KB)         ",
                        "0x0807FFFF -+                        "
                    ],
                    "subtitle": [3, 3],
                    "size": 1,
                    "position": [74, 13],
                    "box": 1,
                    "boxcolor": "Orange",
                    "color": "Red"
                }
            ]
        ]
    },
    "subtitle":
    {
        "type": "text",
        "target": "audio",
        "items":
        [
            [
                [[], "在 STM32F103VET6 中，这块地址又分成了几个部分。"],
                [[], "其中，Flash 区域一般是用来存储用户的程序的。"],
                [[], "第一个别名区域可以关联到 Flash，System，RAM 区域之一。"],
                [[], "默认情况下，别名区是关联到 Flash 区域的，"],
                [[], "所以可以通过访问别名区域来访问 Flash 区域。"],
                [[], "就是说访问地址 0x00000000 就是访问地址 0x08000000。"],
                [[], "因此，只要把矢量表放到 Flash 区域的开头 0x08000000 就能让核心找到了。"]
            ]
        ]
    }

3. Color video + file audio

<!---->

    "name": "color_file",
    "video": {"type": "color"},
    "audio":
    {
        "type": "file",
        "items":
        [
            "file/audio/01.mp3",
            "file/audio/02.mp3"
        ]
    },
    "text":
    {
        "type": "text",
        "target": "audio",
        "items":
        [
            [
                {
                    "content":
                    [
                        "EP01"
                    ],
                    "time":[3, 8],
                    "position": ["c", 11],
                    "size": 4
                },
                {
                    "content":
                    [
                        "小伙徐云流浪中国 扎营炒菜踏遍千山"
                    ],
                    "time":[3, 8],
                    "position": ["c", 16],
                    "size": 4
                }
            ]
        ]
    },
    "subtitle":
    {
        "type": "text",
        "target": "audio",
        "items":
        [
            [
                [[0, 36], "audio 1 subtitle 1"],
                [[42, 50], "audio 1 subtitle 2"]
            ],
            [
                [[0, 36], "audio 2 二进制格式写入文件。"],
                [[42, 50], "audio 2 写工具把文件刷入 STM32F103VET6 微控制器。"],
                [[100, 108], "audio2 不出意外的就要出意外了，写入之后什么都没发生。"]
            ]
        ]
    }

4. Image video + no audio

<!---->

    "name": "image_null",
    "video":
    {
        "type": "image",
        "items":
        [
            "file/image/01.png",
            "file/image/02.png",
            "file/image/03.png"
        ],
        "interval": 5
    },
    "audio": {},
    "text":
    {
        "type": "text",
        "target": "video",
        "items":
        [
            [
                {
                    "content":
                    [
                        "EP01"
                    ],
                    "time":[3, 8],
                    "position": ["c", 11],
                    "size": 4
                },
                {
                    "content":
                    [
                        "小伙徐云流浪中国 扎营炒菜踏遍千山"
                    ],
                    "time":[3, 8],
                    "position": ["c", 16],
                    "size": 4
                }
            ]
        ]
    },
    "subtitle":
    {
        "type": "text",
        "target": "video",
        "items":
        [
            [
                [[0, 3], "video1 subtitlle1"],
                [[3.5, 4], "video1 subtitle 2 写入之后什么都没发生。"]
            ],
            [
                [[1, 3], "video2 意外了，写入之后什么都没发生。"]
            ],
            [
                [[0, 2], "video3 subtitlle1"],
                [[3, 4], "video3 subtitle 2"]
            ]
        ]
    }

5. Image video + TTS speech audio

<!---->

    "name": "image_speech",
    "video":
    {
        "type": "image",
        "items":
        [
            "file/image/01.png",
            "file/image/02.png",
            "file/image/03.png"
        ]
    },
    "audio": {"type": "speech"},
    "text": {},
    "subtitle":
    {
        "type": "text",
        "target": "audio",
        "items":
        [
            [
                [[], "带着这个问题，我查了一些资料，尝试去进一步理解这个过程。"],
                [[], "用到的资料包括 STM32 数据手册、"]
            ],
            [
                [[], "STM32 参考手册、"]
            ],
            [
                [[], "和这个超级长，超级详细的教程。"],
                [[], "本期视频记录了我查到或理解到的相关知识点，"],
                [[], "包括相关概念、启动过程和一个机器码点灯教程。"]
            ]
        ]
    }

6. Image video + file audio + subtitle sync to video

<!---->

    "name": "image_file__sub_to_video",
    "video":
    {
        "type": "image",
        "items":
        [
            "file/image/01.png",
            "file/image/02.png",
            "file/image/03.png"
        ],
        "interval": 10
    },
    "audio":
    {
        "type": "file",
        "items":
        [
            "file/audio/01.mp3",
            "file/audio/02.mp3"
        ]
    },
    "text": {},
    "subtitle":
    {
        "type": "text",
        "target": "video",
        "items":
        [
            [
                [[3, 5], "带着这个问题，我查了一些资料，尝试去进一步理解这个过程。"],
                [[7, "8.1"], "用到的资料包括 STM32 数据手册、"]
            ],
            [
                [[0, 10], "STM32 参考手册、"]
            ],
            [
                [[1, 3], "和这个超级长，超级详细的教程。"],
                [[3, 4], "本期视频记录了我查到或理解到的相关知识点，"],
                [[5, 9], "包括相关概念、启动过程和一个机器码点灯教程。"]
            ]
        ]
    }

7. Image video + file audio + subtitle sync to audio

<!---->

    "name": "image_file__sub_to_audio",
    "video":
    {
        "type": "image",
        "items":
        [
            "file/image/01.png",
            "file/image/03.png"
        ]

    },
    "audio":
    {
        "type": "file",
        "items":
        [
            "file/audio/01.mp3",
            "file/audio/02.mp3"
        ]
    },
    "text": {},
    "subtitle":
    {
        "type": "text",
        "target": "audio",
        "items":
        [
            [
                [[2, 5], "audio 1 subtitlle1。"],
                [[10, 15], "audio 1 subtitlle2"],
                [[20, 30], "audio 1 subtitlle3 到的相关知识点，"],
                [[40, 60], "audio 1 subtitlle4 和一个机器码点灯教程。"]
            ],
            [
                [[2, 5], "audio 2，超级详细的教程。"],
                [[10, 15], "audio 2，"],
                [[20, 100], "audio 2、启动过程和一个机器码点灯教程。"]
            ]
        ]
    }

8. File video + no audio

<!---->

    "name": "file_null",
    "video":
    {
        "type": "file",
        "items":
        [
            "file/video/01.MOV",
            "file/video/02.MOV"
        ]
    },
    "audio": {},
    "text":
    {
        "type": "text",
        "target": "video",
        "items":
        [
            [
                {
                    "content":
                    [
                        "video 1"
                    ],
                    "time":[3, 8],
                    "position": ["c", 15],
                    "size": 4
                }
            ],
            [
                {
                    "content":
                    [
                        "命令行"
                    ],
                    "time":[0.5, 2],
                    "position": ["c", 15],
                    "size": 4,
                    "color": "White"
                },
                {
                    "content":
                    [
                        "video 2"
                    ],
                    "time":[3, 8],
                    "position": ["c", 15],
                    "size": 4
                }
            ]
        ]
    },
    "subtitle":
    {
        "type": "text",
        "target": "video",
        "items":
        [
            [
                [[10, 20], "上面提到的 Armv7-M, Armv7-A制定的核心架构，"],
                [[30, 40], "如 Armv1，Armv2 等。"]
            ],
            [
                [[1, 2], "上面提到的 Armv7-M, Armv7-A制定的核心架构，"],
                [[3, 4.2], "如 Armv1，Armv2 等。"],
                [[4.78, 8.56], "Cortex-M3 实现的是 Ar采用 T32 指令集。"]
            ]
        ]
    }


9. File video + TTS speech audio

<!---->

    "name": "file_speech",
    "video":
    {
        "type": "file",
        "items":
        [
            "file/video/01.MOV",
            "file/video/02.MOV"
        ]
    },
    "audio": {"type": "speech"},
    "text": {},
    "subtitle":
    {
        "type": "text",
        "target": "video",
        "items":
        [
            [
                [[2, 16], "video 1 subtitlle1"],
                [[22, 40], "video 1 subtitlle2"],
                [[50, 61], "video 1 subtitlle3"]
            ],
            [
                [[0, 16], "video 2 subtitlle1 工具把他们式写入文件。"],
                [[22, 40], "video 2 subtitle2 入 STM32F103VET6 微控制器。"],
                [[50, 61], "video 2 subtitlle3 不出意外的没发生。"]
            ]
        ]
    }

10. File video + file audio

<!---->

    "name": "file_file",
    "video":
    {
        "type": "file",
        "items":
        [
            "file/video/01.MOV",
            "file/video/02.MOV"
        ]
    },
    "audio":
    {
        "type": "file",
        "items":
        [
            "file/audio/01.mp3",
            "file/audio/02.mp3"
        ]
    },
    "text":
    {
        "type": "text",
        "target": "video",
        "items":
        [
            [
                {
                    "content":
                    [
                        "video 1"
                    ],
                    "time":[3, 8],
                    "position": ["c", 11],
                    "size": 4
                },
                {
                    "content":
                    [
                        "小伙徐云流浪中国 扎营炒菜踏遍千山"
                    ],
                    "time":[3, 8],
                    "position": ["c", 16],
                    "size": 4
                }
            ],
            [
                {
                    "content":
                    [
                        "video 2"
                    ],
                    "time":[3, 8],
                    "position": ["c", 11],
                    "size": 4
                },
                {
                    "content":
                    [
                        "小伙徐云流浪中国 扎营炒菜踏遍千山"
                    ],
                    "time":[3, 8],
                    "position": ["c", 16],
                    "size": 4
                }
            ]
        ]
    },
    "subtitle":
    {
        "type": "text",
        "target": "video",
        "items":
        [
            [
                [[0, 16], "video 1 subtitlle1"],
                [[22, 40], "video 1 subtitlle2"],
                [[50, 61], "video 1 subtitlle3"]
            ]
        ]
    }

