#!/usr/bin/env bash
## Build
mkdir -p temp
echo $@
zip temp/artifact $@
# Publish on github
echo "Publishing on Github..."
echo -n "Please enter your PAT: "
read -s token && echo
# Get the last tag name 
echo "Getting the last tag name... "
tag=$(2>/dev/null git describe --tags)
if $tag; then
  echo -n "No tag were detected, please set one: "
  read tag
  git tag create $tag
fi 
# Get the full message associated with this tag
message="$(2>/dev/null git for-each-ref refs/tags/$tag --format='%(contents)')"
if $message; then
  echo "No tag message were available from refs contents, please input one or leave blank to default to latest commit message"
  echo -n ">>> " && read message
  if [ -e message ]; then
    message=$(git log -1 --pretty=%B)
  fi
fi
# Get the title and the description as separated variables
name=$(echo "$message" | head -n1)
description=$(echo "$message" | tail -n +3)
description=$(echo "$description" | sed -z 's/\n/\\n/g') # Escape line breaks to prevent json parsing problems
# Create a release
echo "Please enter your username or organization name (as in the url https://github.com/organization_name/): "
echo -n ">>> " && read username # input here your username
echo -n "Please enter your repository: "
read repository
release=$(curl -XPOST -H "Authorization:token $token" --data "{\"tag_name\": \"$tag\", \"target_commitish\": \"master\", \"name\": \"$name\", \"body\": \"$description\", \"draft\": false, \"prerelease\": true}" https://api.github.com/repos/$username/$repository/releases)
# Extract the id of the release from the creation response
id=$(echo "$release" | sed -n -e 's/"id":\ \([0-9]\+\),/\1/p' | head -n 1 | sed 's/[[:blank:]]//g')
# Upload the artifact
curl -XPOST -H "Authorization:token $token" -H "Content-Type:application/octet-stream" --data-binary @temp/artifact.zip https://uploads.github.com/repos/$username/$repository/releases/$id/assets?name=artifact.zip
rm temp/artifact.zip
rmdir temp 
