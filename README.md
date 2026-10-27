# Dineflow

Find the restaurant deals that are live near you right now. Restaurant owners publish a time-limited offer in under a minute.

iOS app built with SwiftUI. A working prototype with 340 sample restaurants across 17 cities, instrumented with Mixpanel.

> **Status:** working prototype, no backend. Data resets when the app relaunches. Restaurants, menus, prices and offers are sample data. See [Known gaps](#known-gaps).

---

## The problem

**Diners** have plenty of apps that rank restaurants by rating and cuisine. None of them answers the question a hungry person actually has: what is on offer near me, right now, and for how long? Deals live in Instagram stories, WhatsApp forwards and signs at the door.

**Restaurant owners** with empty tables at 3 pm have no quick way to push a same-day offer to people nearby. Existing platforms are built around delivery integrations and listing fees. A small owner wants to type a title, pick a duration and go live.

## The idea

A feed built around live, expiring offers, filtered by city. A publishing flow short enough to use during a slow lunch.

## Who it is for

| User | What they need |
|---|---|
| Diner | Find a deal that is live now. Compare by rating, price and cuisine. See what a place serves before going. Switch city when travelling |
| Restaurant owner | Get an offer in front of nearby diners fast. Keep menu and hours correct. See the listing the way a diner sees it |

## What it does

**Diner side**
- Home feed with a live-offers carousel. Every offer has a countdown
- Filter by cuisine, price band, distance and rating. Sort and search
- Map of restaurants in the active city
- Restaurant page with up to 10 photos, menu by category and live offers
- Offer page with "Claim This Offer"
- City picker with 17 cities. GPS detects the city, or pick one by hand

**Owner side**
- Dashboard with a live preview of the listing
- Publish an offer: title, details, discount or BOGO, duration presets
- Menu manager: add, edit, delete, dish photos
- Business hours per day
- Three-step restaurant registration

## Goals and how I would measure them

| Goal | Where it shows up in the product |
|---|---|
| A diner finds a live offer within two taps | Offers carousel on Home, countdown on every card |
| A diner narrows restaurants by what matters to them | Cuisine chips, sort, filters, search, map |
| An owner publishes without training | One-screen publish form with duration presets |
| An owner keeps the listing accurate | Menu manager, hours, account screen, preview |
| Every key step is measurable | 30+ Mixpanel events plus screen and tap tracking on every screen |

**North Star:** offers opened per week.

**Supporting metrics:** feed-to-offer rate, offer claim rate, search success rate, publish completion, registration completion, location permission grant, login failure rate.

**Counter-metrics:** publish abandoned, registration abandoned, registration validation failures.

Targets are not set. The only data so far comes from one test device, so any number would be made up. Plan: recruit 10 to 20 testers, exclude my own device, then set targets from the baseline.

## Product decisions worth explaining

- **No backend on purpose.** The goal of v1 was to test the diner and owner flows end to end. Accounts, storage and redemption come after the flows prove useful.
- **Offers expire.** Every offer carries an end time and a visible countdown. Urgency is the product, so the UI shows it everywhere.
- **Two offers per restaurant.** Keeps the owner's publish flow short and keeps the feed readable.
- **City first.** The feed filters by city before anything else. A deal in another city is noise.
- **Measure before optimising.** Mixpanel went in before any growth work, so there is a baseline to improve against.
- **Honest sample data.** Menus and offers are demo content and the app says so. Real names and real photos make it believable without claiming real prices.

## Version history

| Version | What changed | Why |
|---|---|---|
| 1.0 | Core app: login and roles, feed, search, location and map, restaurant and offer pages, owner tools | First working prototype. Built April to June 2026 |
| 2.0 | Mixpanel analytics. Fixed Home tab not responding after a city change | v1.0 could not measure any goal |
| 2.1 | 340 restaurants in 17 cities, 11 regional menus, 2 offers per restaurant tied to menu items. Google Places photos. Cached image loader. Fixes for hours saving, account back button, menu price edit, rupee signs, publish validation | Demos showed an empty city, repeated stock photos and unfinished owner screens |

## Known gaps

Listed here so nobody finds them before I tell them.

| Gap | Severity |
|---|---|
| Login accepts any non-empty email and password. No real accounts | High |
| All data lives in memory. Published offers and menu edits are lost on relaunch | High |
| Claiming an offer is local only. No code, no redemption, no merchant confirmation | Medium |
| Analytics identify a device, not a person. One tester's data so far | Medium |
| Restaurant names in tier-2 cities were written from memory. A script checks them against Google Places | Medium |
| Ratings, menus, prices and offers on new restaurants are samples | Medium |
| Distance filter uses GPS position, not the city picked by hand | Low |
| Search covers all cities | Low |
| Share button does nothing. Favourites are not saved | Low |

## What I would do next

1. Real accounts and a backend, so offers and menus persist
2. Redemption: a code the diner shows, confirmed by the owner. This is the metric that proves value to a restaurant
3. Push notification when a saved restaurant publishes an offer
4. Recruit testers and set targets from a real baseline
5. Decide whether search should follow the selected city

## Tech

| Layer | What it is |
|---|---|
| UI | SwiftUI, custom floating tab bar, one navigation stack per tab |
| State | Shared observable store for restaurants, the owner's restaurant and hours. Location manager for GPS, detected city and manual override |
| Location | CoreLocation and MapKit |
| Photos | Google Places (New) with on-device cache. Cached image loader with retries and placeholder |
| Analytics | Mixpanel Swift SDK behind one Analytics helper |
| Seed data | Python scripts in `tools/` generate restaurants and menus. A second script checks every name against Google Places |
| Backend | None |

## Run it

1. Open `Dineflow.xcodeproj` in Xcode. iOS 17 or later.
2. Pick a simulator and press Run.
3. Photos: without a Google key the app shows stock photos. For real restaurant photos, add a string row `PLACES_API_KEY` to the target's Info tab. Create the key in Google Cloud, restrict it to Places API (New) and set a quota. Never commit the key.
4. Analytics: add your own Mixpanel project token in `Analytics.swift`.

Check restaurant names against Google Places:
```
export PLACES_API_KEY=your_key
cd tools
python3 verify_places.py
```

## Docs

- Product requirements document (v2.1): `docs/Dineflow_PRD_v2.1.md`
- One-pager: `docs/Dineflow_OnePager.md`

## About

Built by Nivedh Mohanan as a product management portfolio project. Design, product decisions, instrumentation and the code are mine.
Portfolio: https://nivedhmohanan.vercel.app
