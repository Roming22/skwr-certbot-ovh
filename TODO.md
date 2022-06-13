## Fix permission issue
The cerbot is creating all files as root, but traefik is running as `65532`
and cannot access the files unless their permissions are manually changed.
