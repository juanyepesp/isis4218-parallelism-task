# Parallelism

With this project comes a PDF file that explains how it works. However, here are some commands and tips that might help with installing the project.

Installing Nerves and dependencies

```zsh
brew install fwup squashfs coreutils xz pkg-config
mix archive.install hex nerves_bootstrap
# replace yes
```

Create ssh key

```zsh
ssh-keygen -b 4096 -t rsa
# default dir
# overwrite yes
# no pass
ssh-add
```

Create project

```zsh
# don't install dependencies
mix nerves.new parallelism

cd parallelism
```

Inside the project folder for installing into raspi

```zsh
export MIX_TARGET=rpi4

mix deps.get

# mix firmware.gen.script
# ./upload.sh
# mix upload nerves.local

mix firmware

mix burn
```

To connect to rapsi and inside the ssh shell of the raspi

````zsh

```zsh
ssh nerves.local

System.cmd("epmd", ["-daemon"])

# connect to wifi
VintageNetWiFi.quick_configure("<username>", "<password>")
# VintageNetWiFi.quick_configure("RedmiNote10S", "some1234")

# wait for connection until an address appears in wlan0
:inet.getifaddrs

# start node with `nerves-<raspi-serial>` and ip from previous step wlan
Node.start(:"nerves-9155@192.168.2.15")

# set cookie, needs to be the same for all devices to connect
Node.set_cookie(:esteban)

# Connect to main node with its user and ip
Node.connect(:"main@192.168.2.7")
````

Inside own computer to create a node

```zsh
System.cmd("epmd", ["-daemon"])

# wait for connection until an address appears in en0
:inet.getifaddrs

# start the node
Node.start(:"main@192.168.2.7")

# set cookie, needs to be the same for all devices to connect
Node.set_cookie(:esteban)

# Connect to other nodes
# Node.connect(:"nerves-9155@192.168.2.15")
```

Other functions

```zsh
# can view node list
Node.list

# can look cookie with coomand
Node.get_cookie

# can stop node with command
Node.stop
```
