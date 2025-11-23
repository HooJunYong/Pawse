import sys
import pkgutil
print('sys.executable:', sys.executable)
print('sys.version:', sys.version)
print('sys.path[0:5]:')
for p in sys.path[:5]:
    print('  ', p)
loader = pkgutil.find_loader('dotenv')
print('dotenv loader:', loader)
try:
    import dotenv
    print('dotenv module file:', getattr(dotenv, '__file__', 'n/a'))
except Exception as e:
    print('dotenv import failed:', repr(e))
