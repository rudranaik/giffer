// Tiny static server so the browser can load the app's ES modules.
const http = require('http');
const fs = require('fs');
const path = require('path');
const root = path.join(__dirname, 'public');
const types = { '.html':'text/html', '.js':'text/javascript', '.css':'text/css', '.gif':'image/gif' };
const PORT = process.env.PORT || 4599;
http.createServer((req, res) => {
  let p = decodeURIComponent(req.url.split('?')[0]);
  if (p === '/') p = '/index.html';
  const file = path.join(root, p);
  fs.readFile(file, (err, data) => {
    if (err) { res.writeHead(404); res.end('Not found'); return; }
    res.writeHead(200, { 'Content-Type': types[path.extname(file)] || 'application/octet-stream' });
    res.end(data);
  });
}).listen(PORT, () => console.log(`\n  Giffer is running →  http://localhost:${PORT}\n  (Leave this window open while you use the app. Close it when done.)\n`));
