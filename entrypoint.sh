#!/bin/sh -l

set -e
set -u
MAX_RETRIES=5
RETRY_DELAY=10 

retry_count=0

# Function to perform git pull
perform_git_pull() {
  git pull origin "$1"
}

# Function to perform git push
perform_git_push() {
  git config user.email "$USER_EMAIL"
  git config user.name "$USER_NAME"
  git add .
  git commit -m "$COMMIT_MESSAGE"
  git push "$GIT_CMD_REPOSITORY" --set-upstream "$TARGET_BRANCH"
}

while [ $retry_count -lt $MAX_RETRIES ]; do
  retry_count=$((retry_count + 1))
  
  echo "[+] Action start (Retry Attempt $retry_count)"
  
  SOURCE_BEFORE_DIRECTORY="${1}"
  SOURCE_DIRECTORY="${2}"
  DESTINATION_GITHUB_USERNAME="${3}"
  DESTINATION_REPOSITORY_NAME="${4}"
  GITHUB_SERVER="${5}"
  USER_EMAIL="${6}"
  USER_NAME="${7}"
  DESTINATION_REPOSITORY_USERNAME="${8}"
  TARGET_BRANCH="${9}"
  COMMIT_MESSAGE="${10}"
  TARGET_DIRECTORY="${11}"
  CREATE_TARGET_BRANCH_IF_NEEDED="${12}"

  if [ -z "$DESTINATION_REPOSITORY_USERNAME" ]
  then
    DESTINATION_REPOSITORY_USERNAME="$DESTINATION_GITHUB_USERNAME"
  fi

  if [ -z "$USER_NAME" ]
  then
    USER_NAME="$DESTINATION_GITHUB_USERNAME"
  fi

  # Verifica si hay acceso al repositorio de destino y configura git
  # ...

  CLONE_DIR=$(mktemp -d)

  # ...

  ABSOLUTE_TARGET_DIRECTORY="$CLONE_DIR/$TARGET_DIRECTORY/"

  # ...

  # Perform a git pull to update the repository with any remote changes
  perform_git_pull "$TARGET_BRANCH"

  # ...

  # Perform git push
  perform_git_push "$TARGET_BRANCH"

  if [ $? -eq 0 ]; then
    echo "Success!"
    break
  else
    echo "Failure..."
    
    if [ $retry_count -lt $MAX_RETRIES ]; then
      echo "Retrying in $RETRY_DELAY seconds..."
      sleep $RETRY_DELAY
    else
      echo "All retry attempts failed."
      exit 1
    fi
  fi
done

