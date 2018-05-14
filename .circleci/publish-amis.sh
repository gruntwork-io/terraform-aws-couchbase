#!/bin/bash
#
# Build the example AMI, copy it to all AWS regions, and make all AMIs public.
#
# This script is meant to be run in a CircleCI job.
#

set -e

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

readonly PACKER_TEMPLATE_PATH="$SCRIPT_DIR/../examples/couchbase-ami/couchbase.json"
readonly PACKER_TEMPLATE_DEFAULT_REGION="us-east-1"
readonly AMI_PROPERTIES_FILE="/tmp/ami.properties"
readonly AMI_LIST_MARKDOWN_DIR="$SCRIPT_DIR/../_docs"
readonly GIT_COMMIT_MESSAGE="Add latest AMI IDs."
readonly GIT_USER_NAME="gruntwork-ci"
readonly GIT_USER_EMAIL="ci@gruntwork.io"

# In CircleCI, every build populates the branch name in CIRCLE_BRANCH except builds triggered by a new tag, for which
# the CIRCLE_BRANCH env var is empty. We assume tags are only issued against the master branch.
readonly BRANCH_NAME="${CIRCLE_BRANCH:-master}"

readonly PACKER_BUILD_NAME="$1"

if [[ -z "$PACKER_BUILD_NAME" ]]; then
  echo "ERROR: You must pass in the Packer build name as the first argument to this function."
  exit 1
fi

if [[ -z "$AMI_PUBLISHING_ACCESS_KEY_ID" || -z "$AMI_PUBLISHING_SECRET_ACCESS_KEY" ]]; then
  echo "ERROR: This script expects AWS access keys for publishing public AMIs to be set as the environment variables AMI_PUBLISHING_ACCESS_KEY_ID and AMI_PUBLISHING_SECRET_ACCESS_KEY."
  exit 1
fi

# Publish AMIs to a different AWS account (not our test account) to ensure they don't get deleted by cloud-nuke
export AWS_ACCESS_KEY_ID="$AMI_PUBLISHING_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="$AMI_PUBLISHING_SECRET_ACCESS_KEY"

# Build the example AMI. WARNING! In a production setting, you should build your own AMI to ensure it has exactly the
# configuration you want. We build this example AMI solely to make initial use of this Module as easy as possible.
build-packer-artifact \
  --packer-template-path "$PACKER_TEMPLATE_PATH" \
  --build-name "$PACKER_BUILD_NAME" \
  --output-properties-file "$AMI_PROPERTIES_FILE"

# Copy the AMI to all regions and make it public in each
source "$AMI_PROPERTIES_FILE"
publish-ami \
  --all-regions \
  --source-ami-id "$ARTIFACT_ID" \
  --source-ami-region "$PACKER_TEMPLATE_DEFAULT_REGION" \
  --output-markdown > "$AMI_LIST_MARKDOWN_DIR/$PACKER_BUILD_NAME-list.md" \
  --markdown-title-text "$PACKER_BUILD_NAME: Latest Public AMIs" \
  --markdown-description-text "**WARNING! Do NOT use these AMIs in a production setting.** They are meant only to make
    initial experiments with this module more convenient."

