#!/bin/env python3
import os
import yaml

def load_deployment(file_path):
    with open(file_path, "r") as fd:
        data = yaml.safe_load(fd)
    with open(file_path, "w") as fd:
        fd.write(yaml.safe_dump(data))
    return data

def patch_deployment(data):
    patch_args(data)
    patch_volumeMounts(data)
    patch_volumes(data)

def patch_args(data):
    args = data["spec"]["template"]["spec"]["containers"][0]["args"]
    patch=[
        "--providers.file.directory=/var/local/traefik",
        "--providers.file.watch=true"
    ]

    remove=[]
    for arg in args:
        for p in patch:
            if arg.startswith(p.split("=")[0]):
                remove.append(arg)
    for arg in remove:
        args.remove(arg)
    args += patch

def patch_volumes(data):
    volumes = data["spec"]["template"]["spec"]["volumes"]
    patch = [
        {
            "name": "traefik-config",
            "configMap": {
                "name": "traefik.config"
            }
        },
        {
            "name": "ssl",
            "persistentVolumeClaim": {
                "claimName": "kube-system.ssl.pvc"
            }
        }
    ]

    remove = []
    for volume in volumes:
        for p in patch:
            if volume["name"] == p["name"]:
                remove.append(volume)
    for volume in remove:
        volumes.remove(volume)
    volumes += patch

def patch_volumeMounts(data):
    mounts = data["spec"]["template"]["spec"]["containers"][0]["volumeMounts"]
    patch = [
        {
            "name": "traefik-config",
            "mountPath": "/var/local/traefik",
            "readOnly": True,
        },
        {
            "name": "ssl",
            "mountPath": "/etc/letsencrypt",
            "readOnly": True,
        }
    ]

    remove = []
    for mount in mounts:
        for p in patch:
            if mount["name"] == p["name"]:
                remove.append(mount)
    for mount in remove:
        mounts.remove(mount)
    mounts += patch

def write_deployment(data, file_path):
    with open(file_path, "w") as fd:
        fd.write(yaml.safe_dump(data))

def main():
    deployment_path=os.getenv("SRC_DIR")+"/deployment.secret.yml"
    data = load_deployment(deployment_path)
    patch_deployment(data)
    write_deployment(data, deployment_path)


if __name__ == "__main__":
    main()
