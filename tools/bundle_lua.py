#!/usr/bin/env python3
"""Bundle static project modules with a private loader; this does not implement SDK APIs."""
from pathlib import Path
import argparse
import json
import sys
from validate_packages import validate_root, static_requires, safe_path, MODULE_RE


def bundle(root, entry='gameplay.bootstrap'):
    root=Path(root).resolve()
    check=validate_root(root)
    if not check['ok']:
        raise ValueError('contract validation failed: '+json.dumps(check['errors'][:4],ensure_ascii=False))
    if not MODULE_RE.fullmatch(entry):raise ValueError('invalid entry module name')
    modules={};stack=[]
    def visit(name):
        if name in stack:raise ValueError('circular dependency: '+' -> '.join(stack+[name]))
        if name in modules:return
        path=safe_path(root,name.replace('.','/')+'.lua')
        if not path.is_file():raise ValueError('missing module: '+name)
        source=path.read_text(encoding='utf-8')
        imports,errors=static_requires(source)
        if errors:raise ValueError('non-static import in '+name)
        stack.append(name)
        for dependency,_ in imports:visit(dependency)
        stack.pop();modules[name]=source
    visit(entry)
    rows=['-- Generated project scaffold bundle. SDK mapping and gameplay remain unimplemented.',
          'local module_loaders = {}','local module_cache = {}','local loading = {}','local ProjectRequire',
          'ProjectRequire = function(name)',
          '  if module_cache[name] ~= nil then return module_cache[name] end',
          '  if loading[name] then error("CIRCULAR_MODULE:" .. name) end',
          '  local loader = module_loaders[name]',
          '  if not loader then error("UNKNOWN_MODULE:" .. name) end',
          '  loading[name] = true','  local result = loader()',
          '  loading[name] = nil','  if result == nil then error("MODULE_RETURN_REQUIRED:" .. name) end',
          '  module_cache[name] = result','  return result','end']
    for name,source in modules.items():
        rows += ['module_loaders['+json.dumps(name)+'] = function()',
                 '  local require = ProjectRequire',source,'end']
    rows+=['return ProjectRequire('+json.dumps(entry)+')','']
    return '\n'.join(rows),len(modules)

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root',type=Path,default=Path(__file__).resolve().parents[1])
    parser.add_argument('--output',type=Path,default=Path('dist/zaizai_surreal.lua'))
    parser.add_argument('--entry',default='gameplay.bootstrap')
    args=parser.parse_args()
    try:
        output=args.output if args.output.is_absolute() else args.root/args.output
        source,count=bundle(args.root,args.entry)
        output.parent.mkdir(parents=True,exist_ok=True)
        output.write_text(source,encoding='utf-8')
        print(json.dumps({'output':str(output),'modules':count,'scope':'Static scaffold bundle; no editor SDK or gameplay acceptance.'},ensure_ascii=False))
        return 0
    except (ValueError,OSError) as exc:
        print(str(exc),file=sys.stderr);return 1
if __name__=='__main__':raise SystemExit(main())
