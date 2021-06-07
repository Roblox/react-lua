#!/bin/bash

for file in *.js
do
  mv "$file" "${file/.js/.lua}"
done

for file in *.lua
do
  sed -i '' -e "s/\/\*/--[[/g" "$file"
  sed -i '' -e "s/\*\//]]/g" "$file"
  sed -i '' -e "s/\/\//--/g" "$file"
  sed -i '' -e "s/;$//g" "$file"
  sed -i '' -e "s/let\ /local\ /g" "$file"
  sed -i '' -e "s/const\ /local\ /g" "$file"
  sed -i '' -e "s/===/==/g" "$file"
  sed -i '' -e "s/!==/!=/g" "$file"
  sed -i '' -e "s/!=/~=/g" "$file"
  sed -i '' -e "s/&&/and/g" "$file"
  sed -i '' -e "s/||/or/g" "$file"
  sed -i '' -e "s/\ null/\ nil/g" "$file"
  sed -i '' -e "s/^’\s}$/end/g" "$file"
  sed -i '' -e "s/\s\}$/\ end/g" "$file"
  sed -i '' -e "s/if\ (/if\ /g" "$file"
  sed -i '' -e "s/export\ function\ /exports./g" "$file"
  sed -i '' -e "s/)\ {$/)/g" "$file"
  sed -i '' -e "s/^}$/end/g" "$file"
  sed -i '' -e "s/'object'/'table’'/g" "$file"
  sed -i '' -e "s/import\ /local\ /g" "$file"
  sed -i '' -e "s/\ from\ '/\ =\ require(Packages./g" "$file"
#  sed -i '' -E -e "s/(typeof\s+)(\w+)/typeof($2)/g" "$file"
done
