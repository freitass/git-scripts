#!/bin/bash

# Name: Git multi checkout
#
# Brief: Checks out remote branches into local branches.
#
# Flags:
#
#   a - Checks out all branches of the specified remote.
#
#   h - Prints usage information.
#
# Arguments:
#
#   <remote>... - the repository to checkout branches from.

# Get current branch.
initial_branch="$(git symbolic-ref HEAD 2>/dev/null)"
initial_branch=${initial_branch##refs/heads/}

# Branches to merge into.
remote=

all=
usage=

function usage()
{
  echo "Usage:"
  echo "    $0 [-p] <remote>"
  return 0
}

# Reading flags.
while getopts ph name
do
  case $name in
    p) pretend=1;;
    h) usage=1;;
  esac
done

# Print usage and exit.
if [ -n "$usage" ]
then
  usage
  exit 0
fi

# Discarding flags from arguments.
shift $(($OPTIND - 1))

if [ $# -ne 1 ]
then
  echo "Please, specify a single remote"
  echo
  usage
  exit 2
fi

remote="$@"

if [ -z "$remote" ]
then
  echo "Please, specify a remote repository"
  echo
  usage
  exit 2
fi

if [ -n "$pretend" ]
then
  echo "Pretending..."
fi

# When adding support to various remotes, change this to a for.
remote_branches=$(git branch -a | grep "^\ *remotes/${remote}/")
remote_branches=${remote_branches//remotes\/}

for remote_branch in $remote_branches
do
  local_branch=${remote_branch/${remote}\/}
  git show-ref --verify --quiet refs/heads/${local_branch}
  if [ $? -ne 0 ]
  then
    if [ -n "$pretend" ]
    then
      echo "Checking out '$remote_branch' in '$local_branch'"
    else
      git checkout -b $local_branch $remote_branch
    fi
  else
    echo "Branch '$local_branch' already exists"
    failed_checkouts="$failed_checkouts $local_branch"
  fi
done

# Checking out initial_branch
git checkout $initial_branch

if [ -n "$failed_checkouts" ]
then
  echo "Failed checkouts: $failed_checkouts"
fi


