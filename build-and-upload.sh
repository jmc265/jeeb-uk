#!/bin/bash
set -ex

source .env

rm -rf output

npm run build

az login --service-principal -u ${AZURE_CLIENT_ID} -p ${AZURE_CLIENT_SECRET} --tenant ${AZURE_TENANT_ID}
az storage blob sync --account-name jeebstorage -c '$web' --source output