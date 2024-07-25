#!/bin/bash

for dir in case*; do
  if [ -d "$dir" ]; then
    echo "Running [$dir]"
    ./run-case.sh "$dir"
  fi
done