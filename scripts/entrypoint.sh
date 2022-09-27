#!/bin/bash
set -e

export SETTINGS_FILE="${GITHUB_WORKSPACE}/$1/settings.py"
export SHELL_FILE_NAME="set_env.sh"
export ENV_FILE_NAME=$4
export DATABASE_URL=postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME
export MANAGEPY_DIR="${GITHUB_WORKSPACE}/$5"

service postgresql start

# Setup database
python /modify_settings.py
echo "Added postgres config to your settings file"

# Setup user environment vars
if [[ ! -z $ENV_FILE_NAME ]]; then
    echo "Setting up your environment variables"
    python /setup_env_script.py
    . ./$SHELL_FILE_NAME
fi

pip install -r $3
pip install coverage
echo "Migrating DB"
python ${MANAGEPY_DIR}/manage.py migrate

echo "Running your tests"

# TODO: Find a better alternative
if [ "${2,,}" == "true" ]; then
    echo "Enabled Parallel Testing"
    # replaced by coverage test
    # python ${MANAGEPY_DIR}/manage.py test api --parallel
    coverage run --source=${MANAGEPY_DIR} ${MANAGEPY_DIR}/manage.py test api
    coverage report
else 
    # replaced by coverage test
    # python ${MANAGEPY_DIR}/manage.py test api
    coverage run --source=${MANAGEPY_DIR} ${MANAGEPY_DIR}/manage.py test api
    coverage report    
fi
