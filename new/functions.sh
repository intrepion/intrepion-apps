exit_if_file_does_not_exist() {
    if [ ! -f $1 ]; then
        echo "File $1 does not exist."
        exit 1
    fi
}

exit_if_file_exists() {
    if [ -f $1 ]; then
        echo "File $1 already exists."
        exit 1
    fi
}

exit_if_folder_exists() {
    if [ -d $1 ]; then
        echo "Folder $1 already exists."
        exit 1
    fi
}

exit_on_error() {
    exit_code=$1
    last_command=${@:2}
    if [ $exit_code -ne 0 ]; then
        >&2 echo "\"${last_command}\" command failed with exit code ${exit_code}."
        exit $exit_code
    fi
}

set -o history -o histexpand
