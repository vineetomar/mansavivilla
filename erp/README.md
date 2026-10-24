# MOO 2.0 — Member Opportunity Network

Public portal: https://vineetomar.github.io/mansavivilla/erp/

**Status**: Demo mode until Supabase is configured. GitHub Pages serves the static frontend; it is not a database. In demo mode, edits are only stored in that browser's localStorage and cannot be seen across devices.

## Live setup

1. Create a new Supabase project: https://supabase.com/dashboard
2. In Supabase SQL Editor run the full script in [schema.sql](schema.sql). The script creates tables and row-level security policies for profiles, opportunities and introduction requests.
3. Under Authentication > Providers > Email, enable email authentication. Under URL Configuration set Site URL to `https://vineetomar.github.io/mansavivilla/erp/` and add that URL to redirect URLs. Configure email delivery, verification, limits and abuse prevention. Test onboarding using two distinct email addresses.
4. In Supabase Project Settings > API Keys, copy the **publishable / anon** key (never service_role or secret key) and project URL.
5. In [index.html](index.html) replace `YOUR_SUPABASE_PROJECT_URL` and `YOUR_SUPABASE_PUBLISHABLE_KEY` with those two values and commit. These are browser-public identifiers; RLS is what protects database rows.
6. Verify one person can register, create a profile, consent and publish an opportunity, while a second person can discover the listing and request an introduction.
7. Test deleting, pausing, unpublishing and ensuring private profiles and introductions are inaccessible using a different user.

## MVP capabilities
- Opt-in member profiles with public name, headline, organization, city, biography and LinkedIn.
- Offer / Seek / Build opportunities searchable by keywords, categories and type.
- Email link sign-in, subject to Supabase configuration.
- Direct introduction requests accessible only to request sender and recipient.
- Member-specific share URL and optional QR rendering via qrserver.com (external URL disclosure).
- Privacy: no public phone or email columns in member profiles. Phone number cannot be automatically captured by scanning a QR.

## Limitations for an actual public launch
- Demo data are browser-local and not shared.
- Real email sending and persistence do not function until the Supabase configuration is complete.
- QR generation uses a third party. Replace with client-only QR generation if necessary for privacy.
- No moderation, abuse reports, spam throttling, review workflow, admin dashboard, identity verification, payment, audit log, backup/recovery procedure, DSR export/erasure workflow, or formal DPDP compliance review.
- Profile links currently open a member prompt/dialog in the portal, not a stand-alone SEO profile page.
- The database permits introductions by authenticated users to published profiles; production should enforce sending rate limits and add moderation.
- Phone number remains private and outside this MVP.
- Pilot rollout should use a test group with clearly explained privacy/consent conditions; don't advertise this as a finished ERP or compliance-certified system.
