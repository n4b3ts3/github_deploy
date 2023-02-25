#!/usr/bin/env bash
# author: Esteban Chacon Martin
# LICENSE: GPL
# postdata: Enjoy it :)
#
# ENVIRONMENT:
# (str)  GD_USERNAME: The username or organization name, like in the URL https://github.com/organization_name/
# (str)  PAT: Personal Access Token, we encourage you to use fined granted access ;)
# (str)  REPOSITORY: The repository that this release is for 
# (str)  BRANCH: The target commit branch
# (str)  TAG: For example v1.0.0beta etc.. read in github about tags to know more
# (str)  DESCRIPTION: The description for this release
# (bool) PRERELEASE: If it is a prerelease or not 
# (bool) GEN_PREREL_NOTES: If should generate prerelease notes or no.
# (bool) DRAFT: I dont know but it is something this is a TODO for later xD 

mkdir -p temp # creates the temp folder in the current directory if not exists. 
mkdir -p ~/.github_deploy/ # Creates a folder for saving the .env(s) to automatically deploy projects
chmod 700 ~/.github_deploy # Ensure anyone but the user who is running this script is capable of reading those envs

echo -n "Enter your GPG Key ID: "
read gpg_id

for file in "$(ls ~/.github_deploy/ | grep -x '.*.env.gpg$')" # iterates over each .env file searching for the ones matching our requirements
do
  eval "$(gpg -r $gpg_id -d ~/.github_deploy/$file)" # load the environment so now we can deploy easily
  
  zip temp/artifact $@ # Zip All files given as arguments to this script inside a file called temp/artifact.zip
  # Publish on github
  echo "Publishing to github, repo: $REPOSITORY username: $GD_USERNAME..."
  url="https://api.github.com/repos/$GD_USERNAME/$REPOSITORY/releases" # save in a variable your own github url
  release_json="{ \
      'tag_name':'$TAG',\
      'target_commitish':'$BRANCH',\
      'name':'$TAG',\
      'body': '$DESCRIPTION', \
      'draft':$DRAFT, \
      'prerelease':$PRERELEASE, \
      'generate_release_notes': $GEN_PREREL_NOTES \
    } \
  " # create the json separated to be more organized
  release_json=$(replace "'" "\"" <<< $release_json) # Replace those  ' by " for json compatibility
  
  release=$(\
  curl \
    -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $PAT" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    -d "$release_json" \
    $url
  ) # Do the actual request to create the release.

  # Extract the id of the release from the creation response
  id=$(echo "$release" | sed -n -e 's/"id":\ \([0-9]\+\),/\1/p' | head -n 1 | sed 's/[[:blank:]]//g')
  # Upload the artifact
  curl \
    -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $PAT" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    -H "Content-Type: application/octet-stream" \
    https://uploads.github.com/repos/$GD_USERNAME/$REPOSITORY/releases/$id/assets?name=$REPOSITORY.zip \
    --data-binary "@temp/artifact.zip" # Here we upload the requested artifact
done

rm temp/artifact.zip
rmdir temp 
