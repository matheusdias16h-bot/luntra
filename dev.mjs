import { createServer } from 'node:http';
import { readFile, stat } from 'node:fs/promises';
import { extname, join, normalize } from 'node:path';

const root = process.cwd();
const types = { '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css', '.png': 'image/png', '.webmanifest': 'application/manifest+json', '.svg': 'image/svg+xml', '.sql': 'text/plain' };
createServer(async (req, res) => {
  try {
    const pathname = decodeURIComponent(new URL(req.url, 'http://localhost').pathname);
    if (pathname === '/config.js') {
      res.setHeader('Content-Type', 'text/javascript; charset=utf-8');
      res.end('window.APP_CONFIG = {};');
      return;
    }
    let path = normalize(join(root, pathname));
    if (!path.startsWith(root)) throw new Error('invalid path');
    try { if ((await stat(path)).isDirectory()) path = join(path, 'index.html'); } catch { path = join(root, 'index.html'); }
    res.setHeader('Content-Type', `${types[extname(path)] || 'application/octet-stream'}; charset=utf-8`);
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.end(await readFile(path));
  } catch { res.writeHead(404); res.end('Not found'); }
}).listen(Number(process.env.PORT || 4173), () => console.log(`http://localhost:${process.env.PORT || 4173}`));
