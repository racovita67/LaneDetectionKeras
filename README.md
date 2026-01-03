# Lane Detection Application

This repository contains a **lane detection application** developed in **JupyterLab** using a **Conda virtual environment**. To simplify setup and ensure reproducibility, a shell script is provided to automatically create and configure the required Conda environment and install all Python dependencies.

---

## Development Environment

* **IDE**: JupyterLab
* **Environment Manager**: Conda (Miniconda / Anaconda)
* **OS**: Windows (Git Bash recommended)

---

## Getting Started

After cloning the repository, follow the steps below to configure the development environment.

### 1. Install Miniconda3

Download and install **Miniconda3** from the official website:

[https://www.anaconda.com/docs/getting-started/miniconda/install#windows-installation](https://www.anaconda.com/docs/getting-started/miniconda/install#windows-installation)

> Anaconda3 is also supported, but Miniconda3 is recommended for a lighter setup.

---

### 2. Add Conda to the PATH Environment Variable

Ensure that Conda is available from the command line:

```bash
conda --version
```

If the command is not recognized, add the appropriate Conda paths to the system **PATH** environment variable. You may use the provided script `conda_venv_script.sh` as guidance for locating the correct directories.

---

### 3. Create the Conda Virtual Environment and Install Dependencies

A setup script is provided to automate environment creation and dependency installation.

#### Run the script

From **Git Bash**, execute:

```bash
./conda_venv_script.sh
```

---

## Conda Virtual Environment Setup Script

The script `conda_venv_script.sh` performs the following actions:

1. Checks whether Conda is available on the system and provides suggestions if it is not properly configured
2. Creates a Conda virtual environment
3. Installs all required Python dependencies into the virtual environment

---

### Script Configuration Parameters

At the top of `conda_venv_script.sh`, the following parameters can be manually modified:

* **`miniconda3_directory`**
  Default: `~`
  On Windows, this typically resolves to:

  ```
  /c/Users/{user_name}
  ```

* **`anaconda3_directory`**
  Default:

  ```
  C:\ProgramData
  ```

* **`conda_environment_name`**
  Default:

  ```
  LDK
  ```

---

### Troubleshooting Conda Detection

If the `conda` command does not work:

* If **Miniconda3** is installed, set `miniconda3_directory` to the directory where Miniconda is located
* If **Anaconda3** is installed, set `anaconda3_directory` to the directory where Anaconda is located

If you want to use a different name for the Conda virtual environment, update the value of:

```bash
conda_environment_name
```

---

## 4. Launch JupyterLab

Once the environment is set up, start JupyterLab from Git Bash:

```bash
jupyter lab
```

Make sure the Conda environment is activated before launching JupyterLab.

---
