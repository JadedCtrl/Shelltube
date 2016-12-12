#!/bin/sh
#####################
# Name: yt-download.sh
# Date: 2016-12-10
# Lisc: GPLv2
# Auth: iluaster
# Main: jadedctrl
# Desc: Fetches YT videos.
#####################

# Based on https://github.com/iluaster/Youtube_downloader
# Usage: yt-download.sh $video_id

if [ "$1" == "-s" ]
then
    stream_mode=1
    id=$2
else
    stream_mode=0
    id=$1
fi

if echo "$id" | grep "youtube.com"
then 
    id="$(echo $id | sed 's/.*video_id=//')"
elif [ -z $id ]
then
    echo "No video specified."
    exit 1
else
    id="$id"
fi
    
name="http://www.youtube.com/get_video_info?video_id=$id"

declare -i line=0

function select_option ()
{
    echo "Formats:"
    for i in $(cat /tmp/video_type_option.txt)
    do
        line=$((line+1))
        echo "${line}. $i"
    done
    printf "\033[0;32m>>\033[0m "
    read -r n

    if [ "$n" -le "$line" ];
    then
        head -n "$n" /tmp/tmp3.txt | tail -n 1 > /tmp/tmp4.txt
    else
        echo "Input Error!"
        line=0
        select_option
    fi
}


if type "wget" &> /dev/null
then
    wget -q "$name" -O "/tmp/${id}_url.txt" 
elif type "curl" &> /dev/null
then
    curl -s "$name" -o "/tmp/${id}_url.txt"
else
    echo "Please install wget or curl."
    exit 1
fi

# Cut and filter mp4 url

cp "/tmp/${id}_url.txt" /tmp/tmp2.txt
sed -e 's/&/\n/g' /tmp/tmp2.txt| grep 'url_encoded_fmt_stream_map'> /tmp/tmp3.txt
sed -i -e 's/%2C/,/g' /tmp/tmp3.txt 
sed -i -e 's/,/\n/g' /tmp/tmp3.txt

# Print out total video format name and quality
perl -ne 'print "$2,$1\n" if /quality%3D(.*?)%.*video%252F(.*?)(%|\n)/' /tmp/tmp3.txt > /tmp/video_type_option.txt

# If video format name is prior to quality
perl -ne 'print "$1,$2\n" if /video%252F(.*?)%.*quality%3D(.*?)(%|\n)/' /tmp/tmp3.txt >> /tmp/video_type_option.txt
sed -i -e 's/x-flv/flv/g' /tmp/video_type_option.txt

select_option
  
# Set file extension name variable and video quality variable
extension_name=$(head -n "$n" /tmp/video_type_option.txt | tail -n 1 | cut -d "," -f 1)
quality_name=$(head -n "$n" /tmp/video_type_option.txt | tail -n 1 | cut -d "," -f 2)

sed -i -e 's/%26/\&/g' /tmp/tmp4.txt
sed -i -e 's/&/\n/g' /tmp/tmp4.txt
grep 'http' /tmp/tmp4.txt > /tmp/tmp5.txt
grep 'sig%3D' /tmp/tmp4.txt >> /tmp/tmp5.txt
perl -pe 's/\n//g' /tmp/tmp5.txt | sed -e 's/sig%3D/\&signature%3D/g' > /tmp/tmp6.txt
sed -i -e 's/url%3D//g' /tmp/tmp6.txt
# url decoding
cat /tmp/tmp6.txt | sed -e 's/%25/%/g' -e 's/%25/%/g' -e 's/%3A/:/g' -e 's/%2F/\//g' -e 's/%3F/\?/g' -e 's/%3D/=/g' -e 's/%26/\&/g' > /tmp/tmp7.txt


if [ $stream_mode -eq 1 ]
then
    if type "vlc" &> /dev/null
    then
        vlc $(cat /tmp/tmp7.txt)
    elif type "mplayer" &> /dev/null
    then
        mplayer $(cat /tmp/tmp7.txt)
    elif type "kaffeine" &> /dev/null
    then
        kaffeine $(cat /tmp/tmp7.txt)
    else
        echo "Please install either vlc, mplayer, or kaffeine."
        exit 1
    fi
else
    if type "wget" &> /dev/null
    then
        wget --show-progress -qi /tmp/tmp7.txt -O "${id_name}_${quality_name}.${extension_name}"
    elif type "curl" &> /dev/null
    then
        curl -# $(cat /tmp/tmp7.txt) -o "${id_name}_${quality_name}.${extension_name}"
    else
        echo "Please install wget or curl."
        exit 1
    fi
fi
  
rm -f /tmp/tmp[2-7].txt /tmp/${id}_url.txt /tmp/video_type_option.txt