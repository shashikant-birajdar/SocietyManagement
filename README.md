# SocietyManagement

A responsive society-management web app prototype.

## Live application

Visit [SocietyManagement on GitHub Pages](https://shashikant-birajdar.github.io/SocietyManagement/).

The source repository is public: [shashikant-birajdar/SocietyManagement](https://github.com/shashikant-birajdar/SocietyManagement).

## Features

- Society registration and login screens
- Editable society member directory for owners and tenants
- Duplicate society name and duplicate member email/mobile checks
- Product and service catalog
- Occupancy, non-occupancy, parking, and late-payment settings
- Monthly billing cycles with a configurable percentage late fee on prior unpaid balances
- Regeneration of unpaid billing cycles after correcting rates; cycles with recorded payments are protected
- Expense register with date, category, vendor, description, payment method, and amount
- Dashboard income, expense, net totals, and recent expense columns
- Payments, complaints, amenities, bookings, visitor log, notices, and user management
- Printable payment receipts
- Responsive landing page with an illustrated building carousel

## Run locally

Open index.html in a modern browser.

## Database setup

The app uses Supabase Auth and the society row's `app_data` JSON field for shared society records. The browser contains only the Supabase project URL and publishable key; Row Level Security controls access.

If you already ran the original `supabase/schema.sql`, run `supabase/app-data-migration.sql` once in the Supabase SQL Editor to add the app data column. For a fresh project, run the updated `supabase/schema.sql` instead.

In Supabase Authentication settings, add the live GitHub Pages URL (`https://shashikant-birajdar.github.io/SocietyManagement/`) to the allowed redirect URLs so email confirmation can return to the app. Registration may require email confirmation, depending on the project's Auth settings.

## User accounts

Society registration creates the first administrator login. The Users page can keep contact and role records, but inviting those contacts as separate authenticated logins requires a secure server-side invite function and is not enabled by this static GitHub Pages app. Passwords are never stored in society records.

