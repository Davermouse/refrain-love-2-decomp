def apply(config, args):
    config["arch"] = "mipsel"
    config['baseimg'] = f'rom/SLPS_018.40'
    config['myimg'] = f'build/out/SLPS_018.40'
    config['mapfile'] = f'build/out/SLPS_018.40.map'
    config['source_directories'] = [f'src/main', 'include', f'asm/main']