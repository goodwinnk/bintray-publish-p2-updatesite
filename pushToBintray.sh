#!/bin/bash
#Sample Usage: pushToBintray.sh username apikey owner repo package version pathToP2Repo versionOfLast? previousVersion? 
API=https://api.bintray.com
BINTRAY_USER=$1
BINTRAY_API_KEY=$2
BINTRAY_OWNER=$3
BINTRAY_REPO=$4
PCK_NAME=$5
PCK_VERSION=$6
PATH_TO_REPOSITORY=$7
BINTRAY_LATEST_PATH=$8
OLD_VERSION=$9

BINTRAY_UPLOAD_VERSION_PATH=${BINTRAY_OWNER}/${BINTRAY_REPO}/${PCK_NAME}/${PCK_VERSION}
BINTRAY_VERSION_PATH=${BINTRAY_UPLOAD_VERSION_PATH}/${PCK_NAME}/${PCK_VERSION}

function main() {
  if [ ! -z "$PATH_TO_REPOSITORY" ]; then
     cd $PATH_TO_REPOSITORY
  fi
  
  deploy_updatesite
  
  if [ ! -z "$OLD_VERSION" ]; then
    replace_last
  fi
}

function deploy_updatesite() {
  FILES=./*
  PLUGINDIR=./plugins/*
  FEATUREDIR=./features/*

  for f in $FILES;
  do
  if [ ! -d $f ]; then
    echo "Processing $f file..."
    if [[ "$f" == *content.jar ]] || [[ "$f" == *artifacts.jar ]] 
    then
      echo "Uploading p2 metadata file directly to the repository"
      curl -X PUT -T $f -u ${BINTRAY_USER}:${BINTRAY_API_KEY} ${API}/content/${BINTRAY_OWNER}/${BINTRAY_REPO}/${PCK_NAME}/${PCK_VERSION}/$f;publish=0
    else 
      curl -X PUT -T $f -u ${BINTRAY_USER}:${BINTRAY_API_KEY} ${API}/content/${BINTRAY_VERSION_PATH}/$f;publish=0
    fi
    echo ""
  fi
  done

  echo "Processing features dir $FEATUREDIR file..."
  for f in $FEATUREDIR;
  do
    echo "Processing feature: $f file..."
    curl -X PUT -T $f -u ${BINTRAY_USER}:${BINTRAY_API_KEY} ${API}/content/${BINTRAY_VERSION_PATH}/$f;publish=0
    echo ""
  done

  echo "Processing plugin dir $PLUGINDIR file..."
  for f in $PLUGINDIR;
  do
    echo "Processing plugin: $f file..."
    curl -X PUT -T $f -u ${BINTRAY_USER}:${BINTRAY_API_KEY} ${API}/content/${BINTRAY_VERSION_PATH}/$f;publish=0
    echo ""
  done
  
  echo "Publishing the new version"
  curl -X POST -u ${BINTRAY_USER}:${BINTRAY_API_KEY} ${API}/content/${BINTRAY_OWNER}/${BINTRAY_REPO}/${PCK_NAME}/${PCK_VERSION}/publish -d "{ \"discard\": \"false\" }"
}

function replace_last() {
  echo "Replace reference to last version"
  
  LAST_TEMP_DIR=temp_${PCK_VERSION}
  BINTRAY_LAST_URL=${BINTRAY_OWNER}/${BINTRAY_REPO}/${PCK_NAME}/${BINTRAY_LATEST_PATH}
  
  mkdir ${LAST_TEMP_DIR}
  
  echo "Download last version files: https://dl.bintray.com/${BINTRAY_LAST_URL}"
  
  curl -L https://dl.bintray.com/${BINTRAY_LAST_URL}/compositeArtifacts.xml -o ${LAST_TEMP_DIR}/compositeArtifacts.xml
  curl -L https://dl.bintray.com/${BINTRAY_LAST_URL}/compositeContent.xml -o ${LAST_TEMP_DIR}/compositeContent.xml
  
  SED_PATTERN="s/${PCK_NAME}\/${OLD_VERSION}/${PCK_NAME}\/${PCK_VERSION}/g"
  echo "Replace with sed: ${SED_PATTERN}"
  
  sed -i.bak ${SED_PATTERN} ${LAST_TEMP_DIR}/compositeArtifacts.xml
  sed -i.bak ${SED_PATTERN} ${LAST_TEMP_DIR}/compositeContent.xml
  
  echo "Uploading files back to last version"
  
  curl -X PUT -T ${LAST_TEMP_DIR}/compositeArtifacts.xml -u ${BINTRAY_USER}:${BINTRAY_API_KEY} ${API}/content/${BINTRAY_LAST_URL}/compositeArtifacts.xml
  echo ""
  curl -X PUT -T ${LAST_TEMP_DIR}/compositeContent.xml -u ${BINTRAY_USER}:${BINTRAY_API_KEY} ${API}/content/${BINTRAY_LAST_URL}/compositeContent.xml
}


main "$@"
