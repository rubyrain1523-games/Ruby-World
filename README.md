# RUBY WORLD
An original 2D platformer and level maker in plain HTML/CSS/JavaScript (Canvas). No frameworks.

## Controls
A/Left, D/Right move; Space/W/Up jump; R restart; Esc exit.
**Sprint:** double-tap A or D (window adjustable in Settings). Holding a key does not sprint.

## Run locally
ES modules need a server: in this folder run `python3 -m http.server 8000`, then open http://localhost:8000.

## Deploy to GitHub Pages
Push to GitHub → repo **Settings → Pages** → Source: *Deploy from a branch* → `main` / root → Save.

## Structure
`js/config.js` (tuning + public Supabase keys), `input.js` (keys, double-tap), `game.js` (player, physics, camera), `level.js` (JSON format, validation, Ruby Plains), `render.js` (drawing), `editor.js`, `storage.js` (LevelStorage + settings, localStorage), `main.js` (menus). `supabase/` has `schema.sql` and setup steps.

## Security
Only the public anon key goes in the browser. Never the service_role key. RLS protects data.

## Roadmap
[x] Foundation, movement, jumping, double-tap sprint, camera, JSON levels, basic editor, local saving
[ ] Supabase auth, profiles, online levels, drafts, publishing, Course World from DB, search, likes, favorites, stats, leaderboards, publish validation UI, graphics, more objects/enemies, music, controller/mobile
