#!/bin/bash

# User Variables - modified by user:
miniconda3_directory=~ # Directory where miniconda3 is found

# Program variables - do not modify
script_path=$(pwd)
conda_available=0

check_and_suggest_path_envvar() {
# Parameter MUST be absolute path to a directory OR relative path from pwd to a directory
    if [ $# == 1 ]; then
        local path=$1
        if [ -d $path ]; then
            local win_path=$path

            # Check if path name is greater than 2. Hint it is an absolute path (must contain "/c/" or "/d/")
            if [ ${#win_path} -gt 2 ]; then
                # Check if path is absolute. 1st and 3rd char is "/". If not absolute then make it absolute.
                if [[ "${path:0:1}" != "/" || "${path:2:1}" != "/" ]]; then
                    win_path=$(pwd)/$win_path
                fi
            else
                win_path=$(pwd)/$win_path
            fi

            disk_letter=${win_path:1:1}
            # Check if disk letter is present. Hint the path is absolute
            if [[ "$disk_letter" =~ ^[A-Za-z]$ ]]; then
                disk_letter=${disk_letter^^} # Capitalize disk letter, e.g. "c" goes to "C"
                win_path=$disk_letter:${win_path:2}
            fi

            win_path="${win_path//\//\\}" # Change all the instances of the character "/" to "\" as per windows convention
            echo Add $win_path to PATH environment variable
        else
            echo check_and_suggest_path: path is not a directory
        fi
    else
        echo check_and_suggest_path: no parameters found
    fi
}

if [ $OSTYPE == "msys" ]; then

    # Check if miniconda3 is installed.
    if command -v conda > /dev/null; then
        echo Conda is installed
        conda_available=1
    else
        echo conda command not found: install miniconda, add the path to environment variables and rerun script.
        cd $miniconda3_directory # In windows C:/users/{my_user}
        if ls | grep -q miniconda3; then
            echo miniconda3 is available on the current user
            cd miniconda3

            # Suggest the paths to be added to the PATH environment variable
            check_and_suggest_path_envvar $(pwd)

            if ls | grep -q Scripts; then
                check_and_suggest_path_envvar Scripts
            else
                echo conda executable not found: Scripts folder from miniconda not found.
            fi

            if ls | grep -q Library; then
                check_and_suggest_path_envvar Library/bin
            else
                echo conda executable not found: Library/bin folder from miniconda not found.
            fi
        else
            echo miniconda3 directory not found: Modify miniconda3_directory variable to the path of miniconda3.
        fi
    fi # End of command -v conda check

    cd $script_path
else
    echo Script was tested only in Bash CLI used in Windows environment.
fi
