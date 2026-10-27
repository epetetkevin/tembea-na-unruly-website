# TEMBEA NA UNRULY — full-stack starter

A Next.js + TypeScript + Supabase starter for the TEMBEA NA UNRULY adventure and event-booking brand.

## Important status note

This is a functional foundation, not yet a fully production-complete booking platform. It includes a public landing page, event detail pages, a booking form backed by an atomic database function, Supabase-authenticated admin access, a database-backed overview, and a protected CSV export. Payment verification, customer email delivery, QR ticket generation, event/media CRUD screens, refund processing, and complete audit logging still need implementation and testing before accepting real customers.

## Requirements
- Node.js 20 or later
- A Supabase project
- A Vercel account for deployment

## 1. Run locally
1. Download and extract this project.
2. Install Node.js from https://nodejs.org if it is not installed.
3. Open a terminal in this folder and run `npm install`.
4. Copy `.env.example` to `.env.local` and fill in `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` from Supabase Project Settings → API.
5. In Supabase SQL Editor, run the complete `supabase/schema.sql` file.
6. Run `npm run dev` and open http://localhost:3000.

## 2. Create the administrator
1. In Supabase Dashboard → Authentication → Users, add an administrator user with email `unrulyfamily004@gmail.com` and a strong password. Do not use a password in source code or commit it to GitHub.
2. Copy that user's UUID from Authentication → Users.
3. In SQL Editor, run `insert into public.admins(user_id) values ('PASTE-UUID-HERE');` replacing the placeholder with the actual UUID.
4. Open `/admin/login` and sign in. Admin authorization requires both a valid Supabase session and a row in `public.admins`.
5. Use Supabase's password reset flow to change or recover the password.

## 3. Add your first event
Use Supabase Table Editor to insert a row into `events`. Set `published` to true and set a future `event_date`; create at least one `ticket_categories` row with the event UUID, ticket name, price, and capacity. Public events then appear on the homepage. The database function safely checks and reserves ticket inventory when a booking is made.

## 4. M-Pesa details
The current booking confirmation shows Till **8698470**, account name **Leone Lotira**, and contact/WhatsApp **0700006391**. A booking is `awaiting_payment` and its payment is `pending`; the customer's typed reference is not treated as proof. The payment review screen and safe admin verification actions must be completed before live use. Never request an M-Pesa PIN.

## 5. Deploy to Vercel
1. Create a private GitHub repository and upload this project's files. Never upload `.env.local`.
2. Import the repository in Vercel.
3. In Vercel → Project → Settings → Environment Variables, add the same `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` values. Add `NEXT_PUBLIC_SITE_URL` with your production URL.
4. Deploy. Run `npm run build` locally first if possible.
5. Keep Supabase service-role keys server-only; they must never use the `NEXT_PUBLIC_` prefix.

## Environment variables
See `.env.example`. The initial administrator password is created through Supabase Auth and never hardcoded into the application. Keep real secrets out of GitHub and screenshots.

## Security and launch checklist
- Review SQL RLS policies against your business workflows.
- Configure Supabase Auth rate limits, email confirmation, and password recovery.
- Add admin event/media management forms, payment review workflow, transaction-code uniqueness checks and verified-only revenue reporting.
- Configure persistent Storage bucket and admin-only upload policies.
- Configure and test email delivery, backups, logging, privacy policy, terms and refunds.
- Add a rate limiter/bot protection for public booking endpoints and idempotency for repeated submissions.
- Test concurrent bookings, over-capacity requests, duplicate requests, payment rejection, refunds and mobile layouts.
- Verify payments against actual M-Pesa records or a trusted Daraja integration before confirming tickets.

## Brand details
- Brand: TEMBEA NA UNRULY / UnrulyFamily
- Email: unrulyfamily004@gmail.com
- Phone/WhatsApp: 0700006391
- M-Pesa Till: 8698470
- Till account name: Leone Lotira
