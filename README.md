# ♡ Her Little Month

A shared wellness tracker for two phones.

## Setup

1. Run `supabase-patch.sql` in your Supabase SQL Editor.
2. Edit `config.js` with your Supabase **Project URL** and **Publishable key**.
3. Never put the Supabase secret/service_role key in this repository.
4. The first authenticated user automatically claims the existing Her Little Month space as owner.
5. The owner gets a private invite code.
6. Create the partner's Auth account later and have her enter that invite code.
7. Enable GitHub Pages: Settings → Pages → Deploy from a branch → `main` → `/(root)`.

The app uses Supabase Auth + Postgres + RLS for shared state.
