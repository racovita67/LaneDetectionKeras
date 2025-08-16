#!/bin/bash

# User Variables - modified by user:
miniconda3_directory=~ # Directory where miniconda3 is found
anaconda3_directory=C:\\ProgramData
conda_environment_name=LDK  # Lane Detection Keras

# Program variables - do not modify
temp_path=None
script_path=$(pwd)
command_available_b=0

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

check_command_available()
{
    local crt_path=$(pwd)

    local cmd_name_s=""
    local dir_paths_s=()
    local dir_names_v=()
    
    local temp=""
    local temp_2=""
    local temp_path=""
    
    local flag_dirname_present_b=0
    local cmd_variant_s=""

    # Fetch parameters for both command attributes --cmd and --dir.
    while [[ $# -gt 0 ]]; do
        if [[ "$1" == "--cmd" ]]; then  # Can receive only one parameter.
            shift
            if [[ -n "$1" ]]; then
                cmd_name_s="$1"
            fi
        fi
        if [[ "$1" == "--dir" ]]; then  # Can receive multiple parameters.
            temp=$2
            while [[ -n $temp && "${temp:0:1}" != "-" ]]; do
                shift
                if [[ -n "$1" ]]; then
                    dir_paths_s+=("$1")
                fi
                temp=$2
            done
        fi
        if [[ "$1" == "--dirname" ]]; then  # Directory names searched in each dir from above.
            temp=$2
            while [[ -n $temp && "${temp:0:1}" != "-" ]]; do
                shift
                if [[ -n "$1" ]]; then
                    dir_names_v+=("$1")
                fi
                temp=$2
            done
        fi
        shift
    done

    # Function logic starts here
    if [[ -n $cmd_name_s ]]; then
        command_available_b=0
        if command -v $cmd_name_s > /dev/null; then
            echo Command $cmd_name_s is available
            command_available_b=1
        else  # Command is not available, give suggestions on how to add it
            echo Command $cmd_name_s is NOT available. Install $cmd_name_s, modify PATH environment variable.
            
            # Check if any filenames can be found at the directory provided as parameters.
            local i=0
            while [[ i -lt ${#dir_paths_s[@]} ]]; do  # Iterate through each directory paths.

                temp=${dir_paths_s[i]}  # Store directory path
                # The filenames shall equal the amount of directories provided to the command, otherwise assign empty string.
                if [[ i -lt ${#dir_names_v[@]} ]]; then  # Store filename
                    temp_2=${dir_names_v[i]}
                else
                    temp_2=""
                fi

                # If the name is also available
                if [[ -d $temp && -n $temp_2 ]]; then  # Check if temp is a directory and temp_2 is not null.
                    temp_path=$(pwd)
                    cd $temp # In windows C:/users/{my_user}
                    if ls | grep -q $temp_2; then  # Check if the filename is present at the location of directory.
                        flag_dirname_present_b=1
                        cmd_variant_s=$temp_2
                    else
                        cd $temp_path
                    fi
                fi
                ((i++))
            done

            # echo $flag_dirname_present_b si $cmd_variant_s

            # A directory-filename pair has been found and should pe added to the path.
            if [[ $flag_dirname_present_b == 1 ]]; then
                cd $cmd_variant_s
                # Suggest the paths to be added to the PATH environment variable
                check_and_suggest_path_envvar $(pwd)
                if [[ $cmd_name_s == "conda" ]]; then  # Conda is a special case with 3 paths
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
                fi
            else
                echo Anaconda not found: change miniconda3_directory or anaconda3_directory to the directory where it is located.
            fi # End of flag check
        fi
    fi

    cd $crt_path
}

if [ $OSTYPE == "msys" ]; then
    # Check if conda is installed.
    check_command_available --cmd conda --dir $miniconda3_directory $anaconda3_directory --dirname miniconda3 anaconda3

    # Conda is available.
    if [ $command_available_b == 1 ]; then
        # Check if environment is present, if not create one
        env_list=$(conda env list)

        read -p "Conda environment $conda_environment_name will be created and configured. Do you want to continue? [y/n]: " input_val
        if [[ $input_val == "y" ]]; then

            if [[ "$env_list" != *"$conda_environment_name"* ]]; then  # If conda env doesn't exist, create it
                yes yes | conda create -n $conda_environment_name python=3.7  # Create conda environment.
                
                echo Created conda environment with the name: $conda_environment_name and python 3.7 # "yes | conda remove -n $conda_environment_name --all" to remove it.
            fi

            source activate $conda_environment_name
            conda activate $conda_environment_name

            if [[ $CONDA_DEFAULT_ENV == $conda_environment_name ]]; then  # conda env is activated
                # Add the dependencies of our conda environment.
                pip install -r requirements.txt
                echo Installed python dependency modules for the $conda_environment_name conda environment
                conda deactivate  # Deactivate the environment at the end.
            fi
        fi  # input_val == "y"
    fi  # $command_available_b == 2
else
    echo Script was tested only in Bash CLI used in Windows environment.
fi
