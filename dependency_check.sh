#!/bin/bash

# User Variables - modified by user:
miniconda3_directory=~ # Directory where miniconda3 is found
anaconda3_directory=C:\\ProgramData
conda_environment_name=LDK  # Lane Detection Keras

# Program variables - do not modify
temp_path=None
script_path=$(pwd)
conda_available=0
flag_conda_variant_u=0  # 0:None, 1:miniconda, 2:anaconda
conda_variant_s=None

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

    # Check if conda is installed.
    if command -v conda > /dev/null; then
        echo Conda is installed
        conda_available=1
    else
        echo conda command not found: install miniconda, add the path to environment variables and rerun script.

        if [ -d $miniconda3_directory ]; then
            temp_path=$(pwd)
            cd $miniconda3_directory # In windows C:/users/{my_user}
            if ls | grep -q miniconda3; then
                flag_conda_variant_u=1
                conda_variant_s=miniconda3
            else
                cd $temp_path
            fi
        fi

        if [ -d $anaconda3_directory ]; then
            temp_path=$(pwd)
            cd $anaconda3_directory
            if ls | grep -q anaconda3; then
                flag_conda_variant_u=2
                conda_variant_s=anaconda3
            else
                cd $temp_path
            fi
        fi
        
        if [[ $flag_conda_variant_u -eq 1 || $flag_conda_variant_u -eq 2 ]]; then
            cd $conda_variant_s

            # Suggest the paths to be added to the PATH environment variable
            check_and_suggest_path_envvar $(pwd)

            if ls | grep -q Scripts; then
                check_and_suggest_path_envvar Scripts
            else
                echo conda Scripts directory not found: Scripts folder from miniconda not found.
            fi

            if ls | grep -q Library; then
                check_and_suggest_path_envvar Library/bin
            else
                echo conda Library directory not found: Library/bin folder from miniconda not found.
            fi
        else
            echo Anaconda not found: change miniconda3_directory or anaconda3_directory to the directory where it is located.
        fi # End of flag check

    fi # End of command -v conda check

    cd $script_path

    # Conda is available.
    if [ $conda_available == 1 ]; then
        # Check if environment is present, if not create one
        env_list=$(conda env list)
        if [[ "$env_list" != *"$conda_environment_name"* ]]; then  # If conda env doesn't exist, create it
            yes yes | conda create -n $conda_environment_name python=3.7  # Create conda environment.
            
            echo Created conda environment with the name: $conda_environment_name # "yes | conda remove -n $conda_environment_name --all" to remove it.
        fi

        source activate $conda_environment_name
        conda activate $conda_environment_name

        if [[ $CONDA_DEFAULT_ENV == $conda_environment_name ]]; then  # conda env is activated
            # Add the dependencies of our conda environment.
            pip install -r requirements.txt
            conda deactivate  # Deactivate the environment at the end.
        fi
        
    fi
else
    echo Script was tested only in Bash CLI used in Windows environment.
fi
