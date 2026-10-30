# Family Construction Timekeeping

Mobile-first PWA for clocking in/out at job sites (GPS + optional photo), weekly totals, history, and an admin view with CSV export. Backend: Supabase (free tier). Hosting: any static host (e.g. Netlify).

## Setup
1. Create a free Supabase project. In **SQL Editor**, run `supabase-setup.sql`.
2. In **Project Settings > API**, copy the Project URL and `anon` public key into the top of the script in `index.html` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`). The anon key is safe to ship; RLS protects data.
3. Deploy the folder as a static site (Netlify drag-and-drop or connect this repo; no build step).
4. Sign up in the app, then make yourself admin in SQL Editor:
   `update public.profiles set role='admin' where email='you@example.com';`

## iPhone
Open the site in Safari > Share > **Add to Home Screen**. Allow Location when clocking in.
