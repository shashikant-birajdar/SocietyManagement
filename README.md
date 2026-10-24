# SocietyManagement

A responsive society-management web app prototype.

## Live application

Visit [SocietyManagement on GitHub Pages](https://shashikant-birajdar.github.io/SocietyManagement/).

The source repository is public: [shashikant-birajdar/SocietyManagement](https://github.com/shashikant-birajdar/SocietyManagement).

## Features

- Society registration and login screens
- Society member directory for owners and tenants
- Duplicate society name and duplicate member email/mobile checks
- Product and service catalog
- Occupancy, non-occupancy, parking, and late-payment settings
- Monthly billing cycles with a configurable percentage late fee on prior unpaid balances
- Payments, complaints, amenities, bookings, visitor log, notices, and user management
- Printable payment receipts
- Responsive landing page with an illustrated building carousel

## Run locally

Open `index.html` in a modern browser.

## Important data and security note

This is a front-end prototype. Society data and login records are stored only in the current browser's local storage, so they do not sync across devices or users. Clearing browser storage can erase that data. The live website is public, and the repository source is public.

It has no shared server-side database or production-grade authentication. Do not use real passwords, payment information, or sensitive resident data until a secure backend, authentication, authorization, and backups are configured. Supabase is the recommended backend candidate; it has not yet been connected.
