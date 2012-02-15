#!/bin/bash

# This script is based on Jefromi's answer on the following link:
# http://stackoverflow.com/questions/2312387/git-is-there-a-quicker-way-to-merge-from-one-branch-to-multiple-branches-than-d
#
# Also, he advises that this should be used only when merging into production
# branches, and not development branches.

# Reading flags.
force=
while getopts f name
do
  case $name in
    f) force=1;;
  esac
done

# Discarding flags from arguments.
shift $(($OPTIND - 1))

# Assert at least one branch was specified.
if [ $# -lt 1 ]
then
  echo "No branch was specified"
  echo
  echo "Usage: $0 [-f] branch0 [... branchN]"
  exit 2
fi

for branch in "$@"
do
  if ! ( git checkout $branch && git merge --no-ff master ); then
    if [ -z $force ]
    then
      # Exit on the first error
      exit 1
    else
      # If you want to just plow ahead, do something like this:
      git reset --hard       # make sure there aren't merge conflicts in the tree
      failed_merges="$failed_merges $branch"  # remember for later
    fi
  fi
done

# If you plowed ahead above, print the branches which failed to checkout+merge
if [ -n $force -a -n "$failed_merges" ]; then
    echo "Failed merges: $failed_merges"
fi

