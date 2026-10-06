const CACHE = 'lutra-v4';
const SHELL = ['/', '/index.html', '/app.js', '/styles.css', '/brand-overrides.css', '/manifest.webmanifest', '/static/img/logo.png', '/static/img/mascote.png'];
self.addEventListener('install', event => event.waitUntil(caches.open(CACHE).then(cache => cache.addAll(SHELL))));
self.addEventListener('activate', event => event.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(key => key !== CACHE).map(key => caches.delete(key))))));
self.addEventListener('fetch', event => {
  const url = new URL(event.request.url);
  if (event.request.method !== 'GET' || url.origin !== location.origin || url.pathname.startsWith('/go/')) return;
  event.respondWith(fetch(event.request).then(response => {
    if (response.ok && ['document', 'script', 'style', 'image'].includes(event.request.destination)) {
      const copy = response.clone();
      caches.open(CACHE).then(cache => cache.put(event.request, copy));
    }
    return response;
  }).catch(async () => (await caches.match(event.request)) || (await caches.match('/index.html'))));
});
