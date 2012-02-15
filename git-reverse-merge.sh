#!/bin/bash

# This script is based on Jefromi's answer on the following link:
# http://stackoverflow.com/questions/2312387/git-is-there-a-quicker-way-to-merge-from-one-branch-to-multiple-branches-than-d
#
# Also, he advises that this should be used only when merging into production
# branches, and not development branches.

# Get current branch as source.
source_branch="$(git symbolic-ref HEAD 2>/dev/null)"
source_branch=${source_branch##refs/heads/}

# Assert we are not in a detached branch.
if [ -z $source_branch ]
then
  echo "It is not possible to merge from a detached branch"
  echo "Stopping"
  exit 2
fi

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
  echo "No branch specified"
  echo
  echo "Usage: $0 [-f] <branch>..."
  exit 2
fi

for branch in "$@"
do
  if ! ( git checkout $branch && git merge --no-ff $source_branch ); then
    if [ -z "$force" ]
    then
      echo "Something went wrong for branch $branch"
      git checkout $source_branch
      echo "Stopping"
      exit 2
    else
      # Restoring current branch and remember it for later.
      git reset --hard
      failed_merges="$failed_merges $branch"
    fi
  fi
done

# Checking out source_branch
git checkout $source_branch

# If you plowed ahead above, print the branches which failed to checkout+merge.
if [ -n "$force" -a -n "$failed_merges" ]; then
    echo "Failed merges: $failed_merges"
fi

