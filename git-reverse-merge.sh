#!/bin/bash

# Name: Git reverse merge
#
# Brief: Merges from the current branch into the given branches.
#
# Flags:
#
#   a - Enabling this flag has the same effect as specifying all local branches
#   other than the source (current one).
#
#   f - If enabled, the script tries to merge into all branches and, at the end
#   of the execution, prints the ones which failed; otherwise, stops at the
#   first error.
#
#   h - Prints usage information.
#
# Arguments:
#
#   <branch>... - a list of branches into which the current branch will be merged.
# 
#
# Acknowledgement:
#
#   This script is based on Jefromi's answer on the following link:
#   <http://stackoverflow.com/questions/2312387/git-is-there-a-quicker-way-to-
#   merge-from-one-branch-to-multiple-branches-than-d>
#
#   Also, he advises that this should be used only when merging into production
#   branches and not into development branches.

# Get current branch as source.
source_branch="$(git symbolic-ref HEAD 2>/dev/null)"
source_branch=${source_branch##refs/heads/}

# Branches to merge into.
target_branches=

all=
force=
usage=

function usage()
{
  echo "Usage:"
  echo "    $0 [-f] <target_branch>..."
  echo "    $0 [-f] -a"
  return 0
}

# Reading flags.
while getopts afh name
do
  case $name in
    a) all=1;;
    f) force=1;;
    h) usage=1;;
  esac
done

# Print usage and exit.
if [ -n "$usage" ]
then
  usage
  exit 0
fi

# Assert we are not in a detached branch.
if [ -z $source_branch ]
then
  echo "It is not possible to merge from a detached branch"
  echo
  exit 2
fi

# Discarding flags from arguments.
shift $(($OPTIND - 1))

if [ -n "$all" ]
then
  if [ $# -ne 0 ]
  then
    echo "Cannot specify a branch with '-a'"
    echo
    usage
    exit 2
  fi

  # Get all target branches.
  target_branches=$(git branch)
  target_branches=${target_branches/\* $source_branch}
else
  target_branches="$@"
fi

if [ -z "$target_branches" ]
then
  echo "Please, specify a target branch"
  echo
  usage
  exit 2
fi

for branch in $target_branches
do
  if ! ( git checkout $branch && git merge --no-ff $source_branch ); then
    if [ -z "$force" ]
    then
      echo "Something went wrong for branch $branch"
      git checkout $source_branch
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

