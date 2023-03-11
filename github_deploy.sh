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
# External Environments (External Environments have not sense inside of ~/.github_deploy/ files, instead export them before calling this script):
# (str) PROJECT_REGEX: A regex to search for files in the ~/.github_deploy/
# (bool) GPG_PROJECT: If it is yes or any value is defined then include GPG projects otherwise skip them (default: GPG not included) 

mkdir -p temp # creates the temp folder in the current directory if not exists. 
mkdir -p ~/.github_deploy/ # Creates a folder for saving the .env(s) to automatically deploy projects
chmod 700 ~/.github_deploy # Ensure anyone but the user who is running this script is capable of reading those envs
result=0 # Declare a standard result

project_regex=".*"

if [ $PROJECT_REGEX ]; then # If the environmet  PROJECT_REGEX exist then load the deploy instead of all projects.
  project_regex=$PROJECT_REGEX
fi

function load_from_data(){
  key=$1;
  if [[ ${#1} > 0 ]]; then
    echo $(grep $1 .env  | cut -d ":" -f 2 | xargs);
    return 0;
  else
    # If anyone wants here we can implement that if this functions is called without a param we can load here the entire local .env
    echo "TODO: NOT IMPLEMENTED YET";
    return -1;
  fi
}
project_regex="^$project_regex.env(.gpg)?$"
files="$(ls ~/.github_deploy/ | grep -E -e $project_regex )"
files=( $files )
for file in "${files[@]}"; # iterates over each .env file searching for the ones matching our requirements
do
  2>/dev/null 1>/dev/null grep -E -e '(.gpg)$' <<< $file;
  is_gpg=$?
  if [ $is_gpg == 0 ] && [ $GPG_PROJECT ]; then
    echo -n "Enter your GPG Key ID: "
    read gpg_id # Read the GPG ID usually an email associated to your key is enough
    echo 
    echo -n "Enter your GPG passphrase: "
    eval "$(gpg -r $gpg_id -d ~/.github_deploy/$file)"; # load the environment so now we can deploy easily 
  elif [ $is_gpg != 0 ]; then
    eval "$(cat ~/.github_deploy/$file)";
  else
    continue
  fi
  result=$?
  if [[ $result != 0 ]]; then # if the last result it didnt return 0 means an error ocurred
    echo "Something were wrong when trying to decrypt the project file"
    break
  fi
  zip temp/artifact $@ # Zip All files given as arguments to this script inside a file called temp/artifact.zip
  result=$?
  if [[ $result != 0 ]]; then
    echo "Something happen while zipping the artifacts..."
    break
  fi 
  # Publish on github
  echo "Publishing to github, repo: $REPOSITORY..."
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
  release_json=$(tr \' \" <<< $release_json) # Replace those  ' by " for json compatibility
  
  release=$(\
  2>/dev/null curl \
    -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $PAT" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    -d "$release_json" \
    $url
  ) # Do the actual request to create the release.
  result=$?
  if [[ $result != 0 ]]; then
    echo "Something happen while creating the release..."
    break
  fi 
  # Extract the id of the release from the creation response
  id=$(echo "$release" | sed -n -e 's/"id":\ \([0-9]\+\),/\1/p' | head -n 1 | sed 's/[[:blank:]]//g')
  # Upload the artifact
  2>/dev/null curl \
    -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $PAT" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    -H "Content-Type: application/octet-stream" \
    https://uploads.github.com/repos/$GD_USERNAME/$REPOSITORY/releases/$id/assets?name=$REPOSITORY.zip \
    --data-binary "@temp/artifact.zip" # Here we upload the requested artifact
  result=$?
  if [[ $result != 0 ]]; then
    echo "Something happen while updating the release and adding the artifact..."
    break
  fi 
done

rm temp/artifact.zip
rmdir temp 
exit $result

