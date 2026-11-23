#!/bin/bash
# Creates the conda environment for this project. Works in Git Bash on Windows and in bash on Linux.

# User Variables - modified by user:
miniconda3_directory=~ # Directory where miniconda3 is found
anaconda3_directory="C:\\ProgramData"
conda_environment_name=LDK  # Lane Detection Keras

# Program variables - do not modify
temp_path=None
script_path=$(pwd)
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)  # Directory of this script (where requirements.txt is)

check_and_suggest_path_envvar() {
# Function: Prints windows-style path suggestion from unix-style path (absolute or relative).
# $1: Parameter MUST be absolute path to a directory OR relative path from pwd to a directory
    if [ $# == 1 ]; then
        local path=$1
        if [ -d $path ]; then
            local unix_dp=$path  # Absolute unix-style path
            local win_dp=  # Absolute windows-style path

            # Create absolute path from relative path if necessary.
            # Check if path name is greater than 2. This is a hint of an absolute path (must contain "/c/" or "/d/")
            if [ ${#unix_dp} -gt 2 ]; then

                # Path relative to current directory.
                if [[ ${path:0:2} == "./" ]]; then
                    unix_dp=${unix_dp:2}
                fi
                
                # Path is absolute if 1st and 3rd char are "/". If it is relative, add pwd to it.
                if [[ "${path:0:1}" != "/" || "${path:2:1}" != "/" ]]; then
                    unix_dp=$(pwd)/$unix_dp
                fi
            else
                unix_dp=$(pwd)/$unix_dp
            fi

            # Convert Unix-style path to Windows path
            disk_letter=${unix_dp:1:1}
            # Check if disk letter is present.
            if [[ "$disk_letter" =~ ^[A-Za-z]$ ]]; then
                disk_letter=${disk_letter^^} # Capitalize disk letter, e.g. "c" goes to "C"
                win_dp=$disk_letter:${unix_dp:2} # Concatenate the strings "$disk_letter", ":" and "${unix_dp:2}"
            fi

            win_dp="${win_dp//\//\\}" # Change all the instances of the character "/" to "\" as per windows convention
            echo Add $win_dp to PATH environment variable
        else
            echo check_and_suggest_path: path is not a directory
        fi
    else
        echo check_and_suggest_path: no parameters found
    fi
}

check_command_available()
{
# Function: Checks if cmd is available. If not, function checks if the directory name "dirname(i)" is available at the path "dir(i)" and provides suggestions for config.
# Params: --cmd(1): The name of the searched command.
#         --dir(n): The path where the directory of the command implementation should be available
#         --dirname(n): The directory name of the command implementation
    local crt_path=$(pwd)

    local cmd_name_s=""  # Command name - String
    local v_dp=()  # Array of directory paths.
    local v_dn=()  # Array of the corresponding directory names.
    
    local temp=""
    local temp_2=""
    local temp_path=""

    # Fetch parameters for both command attributes --cmd and --dir.
    while [[ $# -gt 0 ]]; do
        if [[ "$1" == "--cmd" ]]; then  # Can receive only one parameter.
            shift
            if [[ -n "$1" ]]; then
                cmd_name_s="$1"
            fi
        fi
        if [[ "$1" == "--dir" ]]; then  # Can receive multiple parameters for --dir
            temp=$2
            while [[ -n $temp && "${temp:0:1}" != "-" ]]; do
                shift
                if [[ -n "$1" ]]; then
                    v_dp+=("$1")
                fi
                temp=$2
            done
        fi
        if [[ "$1" == "--dirname" ]]; then  # Can receive multiple parameters for --dirname
            temp=$2
            while [[ -n $temp && "${temp:0:1}" != "-" ]]; do
                shift
                if [[ -n "$1" ]]; then
                    v_dn+=("$1")
                fi
                temp=$2
            done
        fi
        shift
    done

    # Check if command exists
    if [[ -n $cmd_name_s ]]; then
        if command -v $cmd_name_s > /dev/null; then
            echo Command $cmd_name_s is available
            return 0
        fi
    fi

    # Check if the number of directory paths equals the number of directory names:
    local v_dp_len=${#v_dp[@]}
    local v_dn_len=${#v_dn[@]}
    [ "$v_dp_len" -eq "$v_dn_len" ]
    local flag_len=$?

    if [ $flag_len != 0 ]; then
        echo "The number of arguments passed to \"--dir\" doesn't match the number of arguments passed to \"--dirname\""
        return 1
    elif [ $v_dp_len == 0 ]; then
        echo "No directory paths given, cannot provide suggestions"
        return 1
    fi
            
    # Check if the directory names can be found at the directory paths provided as parameters.
    local i=0
    local v_dir_available=()  # If dirname(i) is available at dir(i) then v_dir_available(i) = 1, otherwise 0
    while [[ i -lt $v_dp_len ]]; do
        if [[ -d ${v_dp[i]} ]]; then
            temp_path=$(pwd)
            cd ${v_dp[i]}
            if ls | grep -q ${v_dn[i]}; then  # Check if the filename is present at the location of directory.
                v_dir_available[i]=1
            else
                v_dir_available[i]=0
            fi
            cd $temp_path
        else
            v_dir_available[i]=0
        fi
        ((i++))
    done

    # Suggest which paths need to be added for command to be available
    local bool_sum=0;
    for (( i=0; i<${#v_dir_available[@]}; i++ )); do
        # A directory-filename pair has been found and should pe added to the path.
        
        if [[ ${v_dir_available[i]} == 1 ]]; then
            local cmd_dp="${v_dp[i]}/${v_dn[i]}"
            temp_path=$(pwd)
            cd $cmd_dp
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
            cd $temp_path
            ((bool_sum++))
        fi # End of flag check
    done

    if [ $bool_sum == 0 ]; then
        for (( i=0; i<${#v_dir_available[@]}; i++ )); do
            local cmd_dp="${v_dp[i]}/${v_dn[i]}"
            echo "$cmd_dp was not found"
        done
        echo "Install $cmd_name_s and rerun script"
    fi

    cd $crt_path
    return 1
}

# Linux: makes the "conda" command usable in this script when conda is installed but not on PATH.
find_conda_unix() {
    if command -v conda > /dev/null; then
        return 0
    fi
    local d
    for d in "$HOME/miniconda3" "$HOME/anaconda3" "$HOME/miniforge3" "$HOME/mambaforge" /opt/conda /opt/miniconda3 /opt/anaconda3; do
        if [ -f "$d/etc/profile.d/conda.sh" ]; then
            source "$d/etc/profile.d/conda.sh"
            echo Found conda at $d
            return 0
        fi
    done
    echo "conda was not found. Install Miniconda3 (https://www.anaconda.com/docs/getting-started/miniconda/install#linux) and rerun the script."
    return 1
}

# Creates the conda environment and installs the dependencies (same steps on Windows and Linux).
# $1: platform, "windows" or "linux"
setup_environment() {
    local platform=$1

    # Makes "conda activate" work inside a script.
    eval "$(conda shell.bash hook)" 2>/dev/null || source activate

    # Check if environment is present, if not create one
    local env_list=$(conda env list)

    local env_exists=1
    if echo "$env_list" | awk '{print $1}' | grep -qx "$conda_environment_name"; then  # Exact name match
        env_exists=0
        read -p "Conda environment $conda_environment_name already exists. Reuse it and (re)install the dependencies in it? [y/n] (to start from scratch: conda env remove -n $conda_environment_name): " input_val
    else
        read -p "Conda environment $conda_environment_name will be created and configured. Do you want to continue? [y/n]: " input_val
    fi
    if [[ $input_val != "y" ]]; then
        return 0
    fi

    conda tos accept > /dev/null 2>&1 || true  # Accept conda Terms of Service (only exists in recent conda versions, ignore the error on older ones).

    if [ $env_exists != 0 ]; then  # If conda env doesn't exist, create it
        conda create -y -n $conda_environment_name python=3.7  # Create conda environment.
        echo Created conda environment with the name: $conda_environment_name and python 3.7 # "conda remove -y -n $conda_environment_name --all" to remove it.
    fi

    conda activate $conda_environment_name

    # Ignore packages from the user-level Python (e.g. %APPDATA%\\Python\\Python37 or ~/.local), so that only the conda environment is used.
    # Without this, pip can report "already satisfied" for a package that lives outside the environment and skip installing it.
    # The variable is also stored in the environment, so it stays active after "conda activate".
    export PYTHONNOUSERSITE=1
    conda env config vars set PYTHONNOUSERSITE=1 -n $conda_environment_name > /dev/null 2>&1 || true

    if [[ $CONDA_DEFAULT_ENV == $conda_environment_name ]]; then  # conda env is activated
        # Optional: CUDA 11.2 + cuDNN 8.1 for NVIDIA GPUs. tensorflow==2.10.1 is the last TensorFlow with native Windows GPU support,
        # but it only sees the GPU if these libraries are installed. Without them training silently runs on the CPU (very slow).
        read -p "Install CUDA 11.2 and cuDNN 8.1 for NVIDIA GPU training? (~1 GB, skip if you have no NVIDIA GPU) [y/n]: " gpu_val
        if [[ $gpu_val == "y" ]]; then
            # --no-update-deps keeps conda-forge from replacing the python/openssl of the environment.
            conda install -y -c conda-forge --no-update-deps cudatoolkit=11.2 cudnn=8.1.0
            if [[ $platform == "linux" ]]; then
                # On Linux TensorFlow finds the CUDA libraries through LD_LIBRARY_PATH.
                mkdir -p "$CONDA_PREFIX/etc/conda/activate.d"
                echo 'export LD_LIBRARY_PATH="$CONDA_PREFIX/lib:$LD_LIBRARY_PATH"' > "$CONDA_PREFIX/etc/conda/activate.d/cuda_libs.sh"
                export LD_LIBRARY_PATH="$CONDA_PREFIX/lib:$LD_LIBRARY_PATH"
            fi
        fi

        # Add the dependencies of our conda environment.
        pip install -r "$script_dir/requirements.txt"
        echo Installed python dependency modules for the $conda_environment_name conda environment

        # Report whether TensorFlow can see a GPU.
        local tf_ok=1
        if python -c "import tensorflow as tf; print('GPUs visible to TensorFlow:', tf.config.list_physical_devices('GPU'))"; then
            tf_ok=0
        else
            echo "TensorFlow could not be imported, see the error above. The environment was created but is not ready."
        fi

        conda deactivate  # Deactivate the environment at the end.

        if [ $tf_ok == 0 ]; then
            if [[ $platform == "windows" ]]; then
                echo "Done. Next steps: source activate $conda_environment_name, then jupyter lab"
            else
                echo "Done. Next steps: conda activate $conda_environment_name (in a new terminal if you just ran conda init), then jupyter lab"
            fi
        fi
    fi
}

case "$OSTYPE" in
    msys*|cygwin*|win32*)  # Git Bash on Windows
        # Check if conda is installed.
        conda_ok=1
        if [ -n "$miniconda3_directory" ] && [ -n "$anaconda3_directory" ]; then
            check_command_available --cmd conda --dir $miniconda3_directory $anaconda3_directory --dirname miniconda3 anaconda3
            conda_ok=$?
        elif [ -n "$miniconda3_directory" ]; then
            check_command_available --cmd conda --dir $miniconda3_directory --dirname miniconda3
            conda_ok=$?
        elif [ -n "$anaconda3_directory" ]; then
            check_command_available --cmd conda --dir $anaconda3_directory --dirname anaconda3
            conda_ok=$?
        fi

        if [ $conda_ok == 0 ]; then  # Conda is available.
            setup_environment windows
        fi
        ;;
    linux*)
        if find_conda_unix; then
            setup_environment linux
        fi
        ;;
    *)
        echo "Unsupported system: $OSTYPE. The script supports Git Bash on Windows and Linux."
        ;;
esac

# Abbreviation Table
# dp = directory path (e.g. /c/git/LaneDetectionKeras)
# dn = directory name (e.g. LaneDetectionKeras)
# fp = file path (e.g. /c/git/LaneDetectionKeras/dependency_check.sh)