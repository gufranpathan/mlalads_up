# MLA LADS UP — Work-Level Data

Scraped and cleaned work-level ("order") data from the Uttar Pradesh MLA LADS
portal (**[mlaladsup.in](https://mlaladsup.in/)** — विधान मण्डल क्षेत्र विकास निधि
योजना, ग्राम्य विकास विभाग, उ.प्र.).

## What's here

| Path | Description |
|---|---|
| `data/mlaladsup_ALL_districts_FY2023-24_works.json` | All 75 districts, FY 2023-24. 30,344 unique works (~117 MB). |
| `docs/mlaladsup_scrape_reproducibility.md` | Full reproducibility write-up: reverse-engineered API contract, scraper code, and an end-to-end checklist. |

## The dataset

Data is drawn from the portal's `DistrictWiseWorkCounts` report. Each **work** is
an individual sanctioned/proposed development project (roads, beautification,
buildings, etc.) funded under the MLA area-development scheme, with ~38 fields
(Hindi column names) covering description, block/ward, estimated cost,
implementing agency, tender/DPR dates, physical & financial progress, and links
to DPR / circular PDFs and progress photos.

### File structure

```jsonc
{
  "meta": { "source", "report", "yearId": 2, "financialYear": "2023-24", "districts": 75 },
  "scraped_at": "2026-07-09T18:43:22.681Z",
  "total_rows_across_buckets": 60688,
  "total_unique_works": 30344,
  "districts": [
    {
      "districtId": "240010014",
      "districtName": "सिद्धार्थनगर",
      "yearId": 2,
      "financialYear": "2023-24",
      "bucket_counts": { "proposed": 322, "pending_0_45": 0, /* ... */ "rejected": 0 },
      "unique_works": 322,
      "works": [ { "कार्य आईoडीo": 240010071, /* ~38 fields */, "__bucket": "proposed" } ]
    }
    // ... 75 districts
  ]
}
```

**Key fields inside each work**
- `कार्य आईoडीo` — Work ID (unique key; works are deduplicated on this)
- `कार्य का विवरण` — work description
- `कार्य का प्रकार` — work type
- `जनपद` / `ब्लॉक/निकाय` — district / block
- `कार्यदायी संस्था द्वारा आगणित लागत (लाख में )` — estimated cost (₹ lakh)
- `__bucket` — the status bucket the work was first found under (see below)

### Status buckets

Each work is fetched under one of eight `(type, minDays, maxDays)` buckets:
`proposed`, `pending_0_45`, `pending_45_60`, `pending_60_plus`,
`sanctioned_0_45`, `sanctioned_45_60`, `sanctioned_60_plus`, `rejected`. A work
appears in both its `proposed` bucket and its current-stage bucket, so
`total_rows_across_buckets` (60,688) is roughly double `total_unique_works`
(30,344). Rows are deduplicated by Work ID during consolidation.

## Reproducing / extending

See `docs/mlaladsup_scrape_reproducibility.md`. In short: the scraper runs in the
browser DevTools console on the `DistrictWiseWorkCounts` page and replays the
portal's own AJAX drilldown call for every district × bucket. The one load-bearing
gotcha is the `Content-Type: application/json` header — with any other content
type the same request returns a fund-summary table instead of the work list.

To scrape a **different financial year**, change `yearId` (2 = 2023-24,
3 = 2024-25, 4 = 2025-26, 5 = 2026-27).

## Notes

- **HTML in values:** some fields contain `<a>` tags with PDF/photo URLs; these
  are preserved during cleaning so document links aren't lost.
- **Etiquette:** the scraper uses a 400–500 ms delay between requests (~600
  requests per year) against a public government server — keep the delays in place.
- No login is required; the site is public.
