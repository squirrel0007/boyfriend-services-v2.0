# Boyfriend Services — fresh v2.0

A private, mobile-friendly Next.js app for **Sarah and Boyfriend only**. It includes 28 named services, 20 selectable add-ons, free pricing, a request form, a request history, manual approval/decline and optional confirmation emails.

## What is already built
- Sarah: private email/password login; browse the service catalogue; select multiple add-ons; request a preferred date/time; leave notes; submit requests; see approval status; cancel pending requests.
- Boyfriend: private login; view all incoming booking requests; approve or decline pending requests; view catalogue.
- Privacy: Supabase authentication; access-controlled booking data with PostgreSQL row-level security; no public signup page.
- Design: responsive dark-plum interface, installable PWA manifest, no paid transactions.
- Optional emails: Resend notification to Boyfriend on a new request and Sarah on a decision, after configuration. The database is the source of truth. Notifications are best-effort and require extra environment keys.

## Start here — exact setup order

### 1. Create a fresh GitHub repository
Create a new empty GitHub repo (suggested: `boyfriend-services-v2`). **Extract the ZIP first, then upload the files inside `boyfriend-services-fresh` directly to the repository root.** Do not upload the parent directory itself. GitHub's top level must show `package.json`, `app/`, `lib/`, `supabase/`, and `public/`.

### 2. Create a Supabase project
At https://supabase.com/dashboard create a new project, then open **SQL Editor** and execute the complete `supabase/schema.sql` file. Open **Authentication > Providers > Email** and disable public sign-ups (wording may vary in the dashboard). Ensure email/password authentication is enabled.

### 3. Create exactly two private accounts
Go to Supabase **Authentication > Users** and select **Add user**. Add Sarah's email/password and the boyfriend's email/password. Use two distinct addresses. Copy the generated UUID for each user and run these two statements in SQL Editor, replacing the UUID placeholders:

```sql
insert into public.profiles (id, role, display_name) values ('SARAH_AUTH_USER_UUID','sarah','Sarah') on conflict(id) do update set role='sarah', display_name='Sarah';
insert into public.profiles (id, role, display_name) values ('BOYFRIEND_AUTH_USER_UUID','boyfriend','Boyfriend') on conflict(id) do update set role='boyfriend', display_name='Boyfriend';
```

No role is automatically granted from the browser. This prevents people from assigning themselves an admin role.

### 4. Find the Supabase API settings
In Supabase **Project Settings > API** (or **Connect** in updated dashboards), copy the Project URL and public/publishable anon key. **Never expose your service-role key publicly.**

### 5. Deploy on Vercel
Open https://vercel.com/new and import the fresh GitHub repository. Set **Framework Preset: Next.js** and **Root Directory: `./`**. In **Environment Variables** add:

```
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-public-anon-or-publishable-key
```

Choose **Deploy**. This project has `package.json` at the repository root and includes Next.js as a dependency, preventing the previous `NEXT_NO_VERSION` error.

### 6. Verify the booking workflow
1. Open the Vercel URL, sign in as Sarah and request any service. The app should say *Your request has been sent for approval*.
2. Sign out and sign in as Boyfriend. Open **Requests**, approve the pending request.
3. Sign in as Sarah and confirm the status is now **Approved**.
4. In Supabase **Table Editor > bookings**, you should see the request. If not, check policies and profile UUIDs.

### 7. Optional: enable notification emails
Create an account at https://resend.com, verify a sender domain, and add these **server-side** Vercel environment variables:

```
SUPABASE_SERVICE_ROLE_KEY=your-private-service-role-key
RESEND_API_KEY=your-private-resend-key
NOTIFICATION_FROM=Boyfriend Services <bookings@your-verified-domain.com>
SARAH_EMAIL=sarah@example.com
BOYFRIEND_EMAIL=boyfriend@example.com
```

Redeploy. Notification emails are best-effort; bookings still work without them. For a production app with stronger anti-duplicate guarantees, trigger email from a verified database webhook with deduplication instead of the client-initiated `/api/notify` endpoint.

## Local development

```bash
npm install
cp .env.example .env.local
# Edit .env.local and add your real public Supabase values
npm run dev
```

Visit http://localhost:3000.

## Common problems
- **NEXT_NO_VERSION:** `package.json` must be at the GitHub root and Vercel Root Directory must be `./`. Do not nest the extracted project folder.
- **Account not set up:** add each user's UUID and role to `public.profiles` by running the SQL statements in step 3.
- **Boyfriend account has not been configured:** the `boyfriend` profile row is missing or has the wrong role.
- **Invalid API key:** check the Vercel environment variables and redeploy.
- **Blank content after sign-in:** inspect browser console and Supabase Table Editor; ensure `supabase/schema.sql` was run.

## Security and limitations
For a private two-person app, access is restricted by Supabase Auth and RLS. All service/add-on labels are UI choices, with no payments or automatic service commitments. Both participants are expected to be adults. The PWA manifest allows installation on a phone; full offline operation and push notifications are **not** included in this version. Email delivery is optional and requires Resend setup. Do not commit `.env.local` to GitHub.
