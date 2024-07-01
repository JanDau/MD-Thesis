# MD-Thesis

Within this GitHub repository I share my Python and R scripts which I used in my MD thesis as well as the respective version/packaging environment captured in Docker images. I recommend using NotePad++ for minor code adaptions, which will likely be necessary as you have to adapt the path to your repective local directories: [https://notepad-plus-plus.org/downloads/](https://notepad-plus-plus.org/downloads/).

## Table of Contents

[1. Docker Installation](#Docker Installation)

- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)

## 1. Docker Installation
As my scripts were written in the past, the whole environment (operating system, Python, and R version, as well as their included packages and versions) is nowadays deprecated, and scripts won’t work with the current versions, which is common in all programming languages. I, therefore, set up two Docker environments (py_env and r_env) that hold the respective required versions; thus, my scripts can be executed from any machine, regardless of their local environment. Not even Python or R needs to be installed on the host machine; Docker Desktop creates a virtual environment and holds everything within the respective image.

### 1.1 Download
Follow the instructions on [https://www.docker.com/products/docker-desktop/](https://www.docker.com/products/docker-desktop/).

### 1.2 (Optional) Adjust Hardware Resources
You can limit the hardware resources Docker can access on your host machine by creating or editing the “.wslconfig” if you use wsl2. Otherwise, it will use the full capacities, if possible. Windows users will likely need to create that file in their user directory (C:/user/%username%/.wslconfig) and paste (and adapt) the following:

```sh
# Settings apply across all Linux distros running on WSL 2
[wsl2]

# Limits VM memory. For example, if the computer has 64 GB, you may use 32 GB. This can be set as whole numbers using GB or MB.
memory=32GB 

# Sets the number of virtual processors to use for the VM. Use half of your core number.
processors=6

# Sets the amount of swap storage space; default is the double amount of available RAM
swap=64GB
```

You need to restart the machine or at least WSL and Docker for changes to have an effect. Quit Docker Desktop. Execute
```sh
wsl --shutdown
```
Restart Docker Desktop. You can check whether it worked via
```sh
docker run --rm ubuntu nproc
```
and for the memory
```sh
docker run --rm ubuntu free -m
```

### 1.3 Build the Docker Images
Required Dockerfiles are found at ./dockerfiles. The Python environment hasn't many dependencies, though the R has plenty of required packages. It is critical to install them in the designated order (corresponding `r_package_list.txt`, which is automatically loaded during the building process), as the remotes package, which is necessary to install deprecated package versions, cannot install respective (deprecated, non pre-compiled) dependencies. You don't need to have both environments actively running. Instead, each script will create its instance of the environment and will close its instance after fulfilling its job.

#### Python
```sh
cd C:/your/path/docker/python/custom_build
docker build -t py_env .
```
(this may take a while)

#### R
Ensure that `r_package_list.txt` is in the same directory.
```sh
cd C:/your/path/docker/r/custom_build
docker build -t r_env .
```
(may take even longer)


## Installation

You can install AwesomeProject using pip:

```sh
pip install awesomeproject
```

## License
This project is licensed under the MIT License. See the LICENSE file for details.

## Contact
If you want to contact me, you can reach me at your-email@example.com.
