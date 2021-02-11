#!/usr/bin/env bash

# read in arguments
# source: https://sookocheff.com/post/bash/parsing-bash-script-arguments-with-shopts/
while getopts ":h :d:" opt; do
  case ${opt} in
    d )
      directory=$OPTARG
      ;;

    h )
cat << EOF
usage: filecounter [-d directory] [-h]

Outputs disk usage and name of each file nested recursively in a given directory.
If no directory is provided, uses current directory as the starting point.
EOF
exit
      ;;
    \? )
      echo "unknown option: $OPTARG" 1>&2
      echo "usage: filecounter [-d directory] [-h]"
      exit
      ;;
    : )
      echo "invalid option: $OPTARG requires an argument" 1>&2
      exit
      ;;
  esac
done
shift $((OPTIND -1))



# create temporary file
# source: https://unix.stackexchange.com/questions/181937/how-create-a-temporary-file-in-shell-script
# source: https://stackoverflow.com/questions/55435352/bad-file-descriptor-when-reading-from-fd-3-pointing-to-a-temp-file
# 2 file pointers are required because &3 is at the end of the file after the previous write
tmpfile=$(mktemp /tmp/filecounter-filelist.XXXXXX)
exec 3>"$tmpfile"   # create file pointer for writing to file
exec 4<"$tmpfile"   # create file pointer for reading from file
rm "$tmpfile"


# get disk usage for each nested file in the given directory
# use current working directory as default value if no directory was supplied
find ${directory:-$(echo $PWD)} -type f -exec du -a {} + >&3

# process usage list
while read -r line; do

  # extract file size and filename
  fsize=$(echo ${line} | cut -d' ' -f1)
  fname=$(echo ${line} | cut -d' ' -f2-100)

  # output file size and basename
  bname=$(basename "$fname")
  echo "$fsize|$bname"

done <&4