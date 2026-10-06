import { cp, mkdir, readFile, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';

const root = process.cwd();
const out = resolve(root, 'dist');
await mkdir(out, { recursive: true });
for (const entry of ['index.html', 'app.js', 'styles.css', 'brand-overrides.css', 'manifest.webmanifest', 'sw.js', 'robots.txt', 'sitemap.xml', '_redirects', 'static', 'supabase']) {
  await cp(resolve(root, entry), resolve(out, entry), { recursive: true });
}
const config = {
  siteUrl: process.env.SITE_URL || '',
  supabaseUrl: process.env.SUPABASE_URL || '',
  supabaseAnonKey: process.env.SUPABASE_ANON_KEY || ''
};
await writeFile(resolve(out, 'config.js'), `window.APP_CONFIG = ${JSON.stringify(config)};\n`);
console.log('Static site built in dist/');
