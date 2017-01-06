#!/bin/sh

# This attempts to update git repos under ~/devstack and ~/openstack

find ~/devstack ~/openstack -name .git -type d | while read dir; do
  working=$(dirname "$dir")
  pushd "$working" >/dev/null

  # Don't update if we're not on the master branch
  if [ $(git rev-parse HEAD master | uniq | wc -l) != "1" ]; then
      echo "Skipping $working: not on master branch"
      continue
  fi

  out=$(mktemp)
  error=

  # Check the working tree and the index for uncommitted changes
  if git diff --no-ext-diff --quiet --exit-code && \
     git diff-index --cached --quiet HEAD --
  then
     stashed=
  else
     stashed="yes"
     echo "Stashing changes in $working before pulling"
     git stash >>"$out"
  fi

  git pull >>"$out" 2>&1
  if [ $? != 0 ]; then
      error="yes"
  fi

  if [ -n "$stashed" ]; then
      git stash pop >>"$out"
      if [ $? != 0 ]; then
          error="yes"
      fi
  fi

  if [ -n "$error" ]; then
      echo "Error updating $working:"
      cat "$out"
      echo
  fi

  rm "$out"
done
