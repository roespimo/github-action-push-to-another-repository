#!/bin/sh -l

set -e  # if a command fails it stops the execution
set -u  # script fails if trying to access to an undefined variable

MAX_RETRIES=5
RETRY_DELAY=10 

retry_count=0

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

  # Verify that there (potentially) some access to the destination repository
  # and set up git (with GIT_CMD variable) and GIT_CMD_REPOSITORY
  if [ -n "${SSH_DEPLOY_KEY:=}" ]
  then
  	echo "[+] Using SSH_DEPLOY_KEY"
  
  	# Inspired by https://github.com/leigholiver/commit-with-deploy-key/blob/main/entrypoint.sh , thanks!
  	mkdir --parents "$HOME/.ssh"
  	DEPLOY_KEY_FILE="$HOME/.ssh/deploy_key"
  	echo "${SSH_DEPLOY_KEY}" > "$DEPLOY_KEY_FILE"
  	chmod 600 "$DEPLOY_KEY_FILE"
  
  	SSH_KNOWN_HOSTS_FILE="$HOME/.ssh/known_hosts"
  	ssh-keyscan -H "$GITHUB_SERVER" > "$SSH_KNOWN_HOSTS_FILE"
  
  	export GIT_SSH_COMMAND="ssh -i "$DEPLOY_KEY_FILE" -o UserKnownHostsFile=$SSH_KNOWN_HOSTS_FILE"
  
  	GIT_CMD_REPOSITORY="git@$GITHUB_SERVER:$DESTINATION_REPOSITORY_USERNAME/$DESTINATION_REPOSITORY_NAME.git"
  
  elif [ -n "${API_TOKEN_GITHUB:=}" ]
  then
  	echo "[+] Using API_TOKEN_GITHUB"
  	GIT_CMD_REPOSITORY="https://$DESTINATION_REPOSITORY_USERNAME:$API_TOKEN_GITHUB@$GITHUB_SERVER/$DESTINATION_REPOSITORY_USERNAME/$DESTINATION_REPOSITORY_NAME.git"
  else
  	echo "::error::API_TOKEN_GITHUB and SSH_DEPLOY_KEY are empty. Please fill one (recommended the SSH_DEPLOY_KEY)"
  	exit 1
  fi

  # Resto del contenido del entrypoint.sh
  # ... (mantén el resto del contenido sin cambios)

  # Agregar una verificación después del bloque de git push
  echo "[+] Pushing git commit"
  # --set-upstream: sets de branch when pushing to a branch that does not exist
  git push "$GIT_CMD_REPOSITORY" --set-upstream "$TARGET_BRANCH"
  
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
