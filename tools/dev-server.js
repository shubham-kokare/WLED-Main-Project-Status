/**
 * Local development server for WLED Web UI
 * Runs with pure Node.js (no external dependencies)
 * Serves wled00/data/ and provides mock /json endpoints for in-browser testing
 */
const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = process.env.PORT || 8080;
const DATA_DIR = path.join(__dirname, '..', 'wled00', 'data');

const effects = [
  "Solid", "Blink", "Breathe", "Wipe", "Wipe Random", "Random Colors", "Sweep", "Dynamic", "Colorloop",
  "Rainbow", "Scan", "Dual Scan", "Fade", "Chase", "Chase Rainbow", "Sparkle", "Sparkle Dark", "Sparkle+",
  "Strobe", "Strobe Rainbow", "Mega Strobe", "Blink Rainbow", "Android", "Chase Flash", "Chase Flash R",
  "Rainbow Runner", "Colorful", "Traffic Light", "Sweep Random", "Running 2", "Red & Blue", "Stream",
  "Scanner", "Lighthouse", "Fireworks", "Rain", "Merry Christmas", "Fire 2012", "Gradient", "Loading",
  "Police", "Police All", "Two Dots", "Two Areas", "Circus", "Halloween", "Tri Chase", "Tri Wipe",
  "Tri Fade", "Lightning", "ICU", "Multi Comet", "Dual Scanner", "Stream 2", "Oscillate", "Pride 2015",
  "Juggle", "Palette", "Fire Flicker", "Colorwaves", "Bpm", "Fill Noise", "Noise 1", "Noise 2", "Noise 3",
  "Noise 4", "Colortwinkle", "Lake", "Meteor", "Meteor Smooth", "Railway", "Ripple", "Twinklefox",
  "Twinklecat", "Halloween Eyes", "Solid Pattern", "Solid Pattern Tri", "Spots", "Spots Fade", "Glitter",
  "Candle", "Fireworks Starburst", "Fireworks 1D", "Bouncing Balls", "Sinelon", "Sinelon Dual", "Sinelon Rainbow",
  "Popcorn", "Drip", "Plasma", "Percent", "Ripple Rainbow", "Heartbeat", "Pacifica", "Candle Multi",
  "Sunrise", "Phased", "Twinkleup", "Noise Pal", "Sine", "Phased Noise", "Flow", "Chunchun", "Dancing Shadows",
  "Washing Machine", "Candy Cane", "Blends", "TV Simulator", "Dynamic Smooth", "Audio Reactive"
];

const palettes = [
  "Default", "* Random Cycle", "* Color 1", "* Colors 1&2", "* Color Gradient", "* Colors Only",
  "Party", "Cloud", "Lava", "Ocean", "Forest", "Rainbow", "Rainbow Bands", "Sunset", "Rivendell",
  "Breeze", "Red & Blue", "Yellowout", "Analogous", "Splash", "Pastel", "Sunset 2", "Beach",
  "Vintage", "Departure", "Landscape", "Beech", "Sherbet", "Hult", "Hult 64", "Drywet", "Jul",
  "Grintage", "Rewhi", "Tertiary", "Fire", "Icefire", "Cyane", "Light Pink", "Autumn", "Magenta",
  "Magred", "Yelmag", "Yelblu", "Orange & Teal", "Tiamat", "April Night", "Orangery", "C9", "Sakura",
  "Aurora", "Atlantica", "C9 2", "C9 New", "Temperature", "Aurora 2", "Retro Clown", "Candy"
];

let state = {
  on: true,
  bri: 128,
  transition: 7,
  ps: -1,
  pl: -1,
  nl: { on: false, dur: 60, mode: 1, tbri: 0, rem: -1 },
  udpn: { send: false, recv: true, nn: false },
  lor: 0,
  mainseg: 0,
  seg: [
    {
      id: 0,
      start: 0,
      stop: 30,
      len: 30,
      grp: 1,
      spc: 0,
      of: 0,
      on: true,
      frz: false,
      bri: 255,
      cct: 127,
      col: [[255, 160, 0], [0, 0, 0], [0, 0, 0]],
      fx: 0,
      sx: 128,
      ix: 128,
      c1: 128,
      c2: 128,
      c3: 16,
      pal: 0,
      sel: true,
      rev: false,
      mi: false
    }
  ]
};

const info = {
  ver: "17.0.0-dev",
  vid: 2607201,
  leds: { count: 30, pwr: 0, fps: 42, maxpwr: 850, maxseg: 32, seglock: false },
  str: false,
  name: "WLED (Dev Mock)",
  udpport: 21324,
  live: false,
  liveseg: -1,
  lm: "",
  lip: "127.0.0.1",
  ws: 0,
  fxcount: effects.length,
  palcount: palettes.length,
  cpalcount: 0,
  maps: [],
  wifi: { bssid: "00:00:00:00:00:00", rssi: -45, signal: 100, channel: 1 },
  fs: { u: 10, t: 1024, pmt: 0 },
  ndc: 0,
  arch: "esp32",
  core: "v5.5",
  freeheap: 185000,
  uptime: 3600,
  opt: 127,
  brand: "WLED",
  product: "FOSS",
  mac: "aabbccddeeff",
  ip: "127.0.0.1"
};

const mimeTypes = {
  '.htm': 'text/html; charset=utf-8',
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css',
  '.js': 'application/javascript',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.ico': 'image/x-icon',
  '.svg': 'image/svg+xml'
};

const server = http.createServer((req, res) => {
  const parsedUrl = new URL(req.url, `http://${req.headers.host}`);
  const pathname = parsedUrl.pathname;

  // CORS headers for local development
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  // Handle Mock API endpoints
  if (pathname === '/json/state') {
    if (req.method === 'POST') {
      let body = '';
      req.on('data', chunk => { body += chunk; });
      req.on('end', () => {
        try {
          const update = JSON.parse(body);
          if (update.on !== undefined) state.on = update.on;
          if (update.bri !== undefined) state.bri = update.bri;
          if (update.seg && Array.isArray(update.seg)) {
            update.seg.forEach((s, idx) => {
              if (state.seg[idx]) Object.assign(state.seg[idx], s);
              else state.seg.push(s);
            });
          }
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify(state));
        } catch (e) {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: e.message }));
        }
      });
      return;
    }
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(state));
    return;
  }

  if (pathname === '/json/info') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(info));
    return;
  }

  if (pathname === '/json/si') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ state, info }));
    return;
  }

  if (pathname === '/json/effects' || pathname === '/json/eff') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(effects));
    return;
  }

  if (pathname === '/json/palettes' || pathname === '/json/pal') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(palettes));
    return;
  }

  if (pathname === '/json/fxdata') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify([]));
    return;
  }

  if (pathname === '/json/palx') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ p: [] }));
    return;
  }

  if (pathname === '/json/nodes') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ nodes: [] }));
    return;
  }

  if (pathname === '/json/cfg') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({}));
    return;
  }

  if (pathname === '/json' && req.method === 'GET') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ state, info, effects, palettes }));
    return;
  }

  if (pathname === '/presets.json') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({}));
    return;
  }

  // File serving from wled00/data/
  let filePath = pathname === '/' ? 'index.htm' : pathname.replace(/^\//, '');
  if (filePath.startsWith('settings')) {
    if (filePath === 'settings') filePath = 'settings.htm';
    else if (!path.extname(filePath)) filePath += '.htm';
  }

  let fullPath = path.join(DATA_DIR, filePath);

  if (!fs.existsSync(fullPath) || fs.statSync(fullPath).isDirectory()) {
    // Check if .htm exists
    if (fs.existsSync(fullPath + '.htm')) {
      fullPath += '.htm';
    } else {
      res.writeHead(404, { 'Content-Type': 'text/plain' });
      res.end('404 Not Found');
      return;
    }
  }

  const ext = path.extname(fullPath).toLowerCase();
  const contentType = mimeTypes[ext] || 'application/octet-stream';

  fs.readFile(fullPath, (err, data) => {
    if (err) {
      res.writeHead(500, { 'Content-Type': 'text/plain' });
      res.end('500 Internal Server Error');
      return;
    }
    res.writeHead(200, { 'Content-Type': contentType });
    res.end(data);
  });
});

server.on('error', (err) => {
  if (err.code === 'EADDRINUSE') {
    const nextPort = Number(PORT) + 1;
    console.log(`Port ${PORT} in use, automatically trying http://localhost:${nextPort}...`);
    server.listen(nextPort);
  } else {
    console.error(err);
  }
});

server.listen(PORT, () => {
  const currentPort = server.address().port;
  console.log(`\n========================================`);
  console.log(`  WLED Web UI running locally!`);
  console.log(`  URL: http://localhost:${currentPort}`);
  console.log(`========================================\n`);
});
