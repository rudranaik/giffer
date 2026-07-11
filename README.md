# 🎬 Giffer — GIF Caption Studio

A dead-simple, free, **100% local** web app for adding captions to GIFs. Pick a GIF, add one or many captions, style them, control exactly when each appears and disappears, and save the result — without blowing up the file size.

No accounts, no uploads, no paid tiers. Everything runs in your browser.

## Features

- **Load any GIF** — drag & drop or browse.
- **Record your screen** — then trim, crop, or follow the action with a moving camera window.
- **Title-card clips** — insert collapsible, fully styled separators anywhere in the timeline, with optional movable/scalable image or logo assets.
- **Watermarks** — overlay movable, scalable, opacity-adjustable logos or images throughout the finished GIF.
- **Multiple captions**, each fully independent — and **duplicate** any caption (⧉) to reuse its styling.
- **Full styling** — font (Impact, Anton, Bangers & more), size, fill color, outline color/width, background shape (rectangle / rounded / pill) with opacity, alignment, and UPPERCASE.
- **Drag to position** captions directly on the preview.
- **Timing control** — set each caption's start and end with sliders, plus optional fade or slide-up entrance/exit animations. A timeline shows every caption's window with a live playhead.
- **Keep file size down** — re-encodes with color quantization; adjust colors, scale, and speed, and see the new size vs. the original before downloading.

## Running it

The app loads two small encoding libraries as ES modules, so it needs to be served over `http://` (a double-clicked `file://` won't load the modules).

**macOS:** double-click **`Start Giffer.command`** — it starts a tiny local server and opens the app in your browser. Leave that window open while you work.

**Any platform (manual):**

```bash
node serve.js        # then open http://localhost:4599
# or:  python3 -m http.server 4599 --directory public
```

> First launch needs internet once to fetch the two libraries ([gifuct-js](https://github.com/matt-way/gifuct-js) + [gifenc](https://github.com/mattdesl/gifenc)); the browser caches them afterward.

## Deploying (Cloudflare)

The app is fully static (everything in `public/`), deployed as a Cloudflare Worker with static assets at **giffer.nrudra.in**.

Every push to `master` deploys directly through [the GitHub Actions workflow](.github/workflows/deploy.yml). [wrangler.jsonc](wrangler.jsonc) sets the assets directory (`public/`) and the custom domain.

The repository needs these GitHub Actions secrets under **Settings → Secrets and variables → Actions**:

- `CLOUDFLARE_API_TOKEN` — a Cloudflare API token with permission to deploy Workers.
- `CLOUDFLARE_ACCOUNT_ID` — the Cloudflare account ID that owns `nrudra.in`.

The workflow can also be run manually from the repository's **Actions** tab. Keep credentials in GitHub secrets; never commit them to the repository.

## Tech

Plain HTML/CSS/JS — no build step. GIF decoding via `gifuct-js`, re-encoding via `gifenc`, compositing on `<canvas>`.
