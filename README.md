Esto correrlo en diferentes terminales

iex -S mix
System.cmd("epmd", ["-daemon"])
:inet.getifaddrs
Node.start(:"main@192.168.0.4")
Node.set_cookie(:esteban)

iex -S mix
System.cmd("epmd", ["-daemon"])
:inet.getifaddrs
Node.start(:"a@192.168.0.4")
Node.set_cookie(:esteban)
Node.connect(:"main@192.168.0.4")

iex -S mix
System.cmd("epmd", ["-daemon"])
:inet.getifaddrs
Node.start(:"b@192.168.0.4")
Node.set_cookie(:esteban)
Node.connect(:"main@192.168.0.4")

Dentro del nodo principal correr
Parallelism.main
