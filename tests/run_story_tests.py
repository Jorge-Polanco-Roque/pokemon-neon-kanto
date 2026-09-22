#!/usr/bin/env python3
"""Run narrative tests in an isolated copy; the real save is never opened."""
from pathlib import Path
import argparse, shutil, subprocess, tempfile
parser=argparse.ArgumentParser()
parser.add_argument('--godot', default='godot')
parser.add_argument('--suite', choices=['story','city','cyber','campaign','presentation','tactics'], default='story')
args=parser.parse_args()
root=Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix='neon-story-',dir='/private/tmp') as temporary:
    target=Path(temporary)/'project'
    shutil.copytree(root,target,ignore=shutil.ignore_patterns('.git','.godot','.claude','docs','*.app','*.pck'))
    base=target/'base_game.gd'
    base.write_text(base.read_text().replace('user://neon_kanto_v3.json',str(Path(temporary)/'save.json')))
    scene=target/'main.tscn'
    if args.suite in ['story','campaign','presentation','tactics']:
        scene.write_text(scene.read_text().replace('res://campaign_game.gd','res://tests/'+args.suite+'_test.gd'))
    imported=subprocess.run([args.godot,'--headless','--log-file',str(Path(temporary)/'godot.log'),'--path',str(target),'--editor','--import','--quit'],capture_output=True,text=True,timeout=90)
    if imported.returncode or 'SCRIPT ERROR' in imported.stderr:
        raise SystemExit(imported.stdout+imported.stderr)
    command=[args.godot,'--headless','--log-file',str(Path(temporary)/'godot.log'),'--path',str(target)]
    if args.suite not in ['story','campaign','presentation','tactics']: command+=['--','--'+args.suite+'-test']
    try:
        result=subprocess.run(command,capture_output=True,text=True,timeout=40)
    except subprocess.TimeoutExpired as error:
        print((error.stdout or b'').decode() if isinstance(error.stdout,bytes) else error.stdout)
        print((error.stderr or b'').decode() if isinstance(error.stderr,bytes) else error.stderr)
        raise SystemExit('Test did not complete within 40 seconds.')
    print(result.stdout+result.stderr)
    if result.returncode or args.suite.upper()+' PASS:' not in result.stdout or 'SCRIPT ERROR' in result.stderr:
        raise SystemExit(1)
