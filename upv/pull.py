import yaml, os, subprocess, sys

print("Pulling submodules from upv.yaml")

build_paths = sys.argv[1:] if len(sys.argv) > 1 else None
if build_paths and len(build_paths) > 0 and build_paths[0] == "pull":
    build_paths = build_paths[1:]
if os.path.exists('./upv.yaml'):
    with open('./upv.yaml') as f:
        data = yaml.load(f)
    pull_tag = data.get('push_tag')
    if pull_tag and (not build_paths or "." in build_paths):
        subprocess.call(['docker', 'pull', pull_tag])
    submodules = data.get('submodules')
    if submodules:
        for submodule in submodules:
            if submodule.get('path'):
                if not build_paths or submodule['path'] in build_paths:
                    submodule_upv_yaml = os.path.join(submodule['path'], 'upv.yaml')
                    if os.path.exists(submodule_upv_yaml):
                        with open(submodule_upv_yaml) as f:
                            data = yaml.load(f)
                        pull_tag = data.get('push_tag')
                        if pull_tag:
                            subprocess.call(['docker', 'pull', pull_tag])
