#!/bin/bash
# Double-click this file to launch Giffer, then it opens in your browser.
cd "$(dirname "$0")"
( sleep 1; open "http://localhost:4599" ) &
if command -v node >/dev/null 2>&1; then
  node serve.js
else
  echo "Node.js not found — falling back to Python."
  python3 -m http.server 4599 --directory public
fi
