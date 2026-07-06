# AGENTS.md — Giffer

Guidance for AI agents (and humans) making changes to this repo. The same code
must keep working in **two environments**: run locally via `node serve.js`, and
deployed to Cloudflare (Workers static assets) from a synced fork.

## Architecture in one paragraph

Giffer is a fully static, client-side app with **no build step**. The entire
app lives in `public/index.html` (HTML + CSS + JS in one file). `serve.js` is a
tiny Node static server used only for local development. `wrangler.jsonc`
deploys `public/` to Cloudflare. This repo intentionally has no deploy
workflow: a fork on another GitHub account syncs from this repo periodically,
and Cloudflare's git integration (Workers Builds) deploys from that fork.

## Rules to keep both environments working

1. **All deployable files go in `public/`.** Cloudflare serves *only* the
   `public/` directory (see `assets.directory` in `wrangler.jsonc`). A file
   referenced by the app but placed outside `public/` will work locally only if
   you break rule 2 — and will 404 in production.

2. **`serve.js` must keep serving from `public/`** (`root` is
   `path.join(__dirname, 'public')`). Don't point it back at the repo root, or
   local and deployed behavior will diverge.

3. **No build step, no server-side code.** Don't add a bundler, framework, npm
   dependencies, or API endpoints. The Cloudflare deploy is assets-only (no
   Worker script), so any server-side logic would silently not run in
   production. If a new runtime library is needed, load it as an ES module from
   a CDN (jsDelivr `/+esm`), like the existing `gifuct-js` and `gifenc` imports
   in `public/index.html`.

4. **Use relative URLs for any new local assets** (`./foo.gif`, not
   `/Users/...` or absolute `http://localhost:...` URLs), and add the file's
   extension to the `types` map in `serve.js` if it isn't already there
   (currently only `.html .js .css .gif` get correct Content-Type locally;
   Cloudflare infers types on its own — a mismatch here shows up as
   local-only breakage, e.g. ES modules refused for wrong MIME type).

5. **Assume HTTPS-only browser APIs are fine, but test locally.** Features like
   `getDisplayMedia` (screen recording) require a secure context. `localhost`
   counts as secure, and the Cloudflare deploy is HTTPS, so both work — but any
   other plain-`http` host will not.

6. **Everything stays client-side.** The README promises "nothing is
   uploaded". Don't add analytics, uploads, or remote processing without the
   owner explicitly asking.

## Verifying a change (do this before calling it done)

1. Local: restart the dev server (`node serve.js`, port 4599 — or the preview
   server config in `.claude/launch.json`) and load the app; check the browser
   console for errors. The server caches nothing, but a moved/renamed file
   needs a restart if the server was started before the move.
2. Deploy config: `npx wrangler deploy --dry-run` must succeed and its
   "Read N file(s) from the assets directory" output should include any files
   you added.
3. If you changed `wrangler.jsonc`, remember deploys are run by Cloudflare's
   git integration from the synced fork. Do not add deploy workflows, deploy
   secrets, or hardcoded credentials to this repo.

## Things that look wrong but aren't

- `index.html` being 1700+ lines with inline CSS/JS is intentional — single
  file, no build step. Don't split it into modules unless asked.
- `Start Giffer.command` is a macOS convenience launcher; keep it in sync if
  the local run steps change.
- The production domain is `giffer.nrudra.in` (custom-domain route in
  `wrangler.jsonc`). Don't change it without the owner asking.
