# MLA LADS UP — Work-Level Data Scrape: Reproducibility Document

**Source site:** https://mlaladsup.in/ (विधान मण्डल क्षेत्र विकास निधि योजना, ग्राम्य विकास विभाग, उत्तर प्रदेश)
**Report scraped:** `DistrictWiseWorkCounts` (District-wise work-level / order data)
**Scope of this run:** All 75 districts, Financial Year **2023-24** (`yearId = 2`)
**Output file produced:** `mlaladsup_ALL_districts_FY2023-24_works.json` (~57 MB compact)
**Run timestamp:** 2026-07-09T18:43:22.681Z
**Records:** 30344 unique works (deduplicated by Work ID); 60688 total bucket-rows

---

## 1. Overview

This document records exactly how district-wise, work-level ("order") data was extracted
from the MLA LADS UP portal and saved to a single JSON file, so the process can be
reproduced independently.

The portal renders reports client-side using **jQuery DataTables**. The
`DistrictWiseWorkCounts` page shows a per-district *summary* table; clicking any count
cell opens a popup listing the *individual works* behind that number. The scraper
replays the exact AJAX call that this popup makes, iterating over every district and
every status bucket, then consolidates and deduplicates the results.

All code runs **in the browser's DevTools console / JS context while on the
`DistrictWiseWorkCounts` page** (same-origin, so no CORS issues). No login is required;
the site is public.

---

## 2. The reverse-engineered API contract (the crucial detail)

The work list comes from:

- **Endpoint:** `POST https://mlaladsup.in/Main/DistrictWiseWorkCounts`
- **Header (CRITICAL):** `Content-Type: application/json`
  The server switches response modes based on this header. With `application/json` it
  returns the **per-work list**. With `text/plain` or `application/x-www-form-urlencoded`
  the *same body* returns a **fund-summary** table instead. This is the single most
  important gotcha.
- **Body (sent literally, NOT url-encoded):**
  ```
  {'obj':{"optMode":"getDistrictWorkDetails","districtId":<int>,"yearId":<int>,"minDays":<int>,"maxDays":<int>,"type":"<status>"}}
  ```
  Note the outer wrapper uses single quotes around `obj` — it is a literal string the
  server parses, not standard JSON.
- **Response:** JSON string of the form `{ "Table_0": [ ...work rows... ] }`, where each
  row has ~38 fields (Hindi column names) including कार्य आईoडीo (Work ID), description,
  type, block, estimated cost, contractor, tender dates, physical/financial progress,
  and document links (DPR / circular PDFs, progress photos).

### Financial-year IDs
| Financial Year | yearId |
|---|---|
| 2023-24 | 2 |
| 2024-25 | 3 |
| 2025-26 | 4 |
| 2026-27 | 5 |

### Status buckets
Each summary-table count cell maps to a (type, minDays, maxDays) triple. The eight
buckets used are:

| bucket key | type | minDays | maxDays |
|---|---|---|---|
| proposed | proposed | 0 | 0 |
| pending_0_45 | pending | 0 | 45 |
| pending_45_60 | pending | 45 | 60 |
| pending_60_plus | pending | 61 | 100000 |
| sanctioned_0_45 | sanctioned | 0 | 45 |
| sanctioned_45_60 | sanctioned | 45 | 60 |
| sanctioned_60_plus | sanctioned | 61 | 100000 |
| rejected | Rejected | 0 | 0 |

A single work appears in its `proposed` (recommended) bucket **and** in the status
bucket describing its current stage, so rows are deduplicated by Work ID at the end.

---

## 3. How the contract was verified

1. Loaded https://mlaladsup.in/main/DistrictWiseWorkCounts and read the page's
   dropdowns (`#districtId`, `#yearId`) and DataTables.
2. Hooked `jQuery.ajax` and `XMLHttpRequest.prototype.send` to capture the exact
   request the drilldown popup fires when `getDistrictWorkDetailsPopup(name, status,
   districtId, yearId, minDays, maxDays)` runs.
3. Confirmed the wire body is `{'obj':{...}}` sent literally.
4. Replayed the request via `fetch` with different `Content-Type` values and confirmed
   only `application/json` returns the work list (others return the fund summary).
5. Validated scraped counts against the on-page summary row (e.g. अमेठी FY2024-25:
   recommended 127, pending 18, sanctioned 102, rejected 7 — all matched exactly).

---

## 4. Reference data — all 75 district IDs

```js
const DISTRICTS = [
  { id: 240010014, name: "सिद्धार्थनगर" },
  { id: 230010034, name: "आगरा" },
  { id: 230010030, name: "अलीगढ़" },
  { id: 230010022, name: "अम्बेडकरनगर" },
  { id: 230010024, name: "अमेठी" },
  { id: 230010027, name: "अमरोहा" },
  { id: 230010014, name: "औरैया" },
  { id: 230010021, name: "अयोध्या" },
  { id: 230010064, name: "आजमगढ़" },
  { id: 230010053, name: "बदायूं" },
  { id: 230010018, name: "बागपत" },
  { id: 230010047, name: "बहराइच" },
  { id: 230010066, name: "बलिया" },
  { id: 230010049, name: "बलरामपुर" },
  { id: 230010058, name: "बाँदा" },
  { id: 230010002, name: "बाराबंकी" },
  { id: 230010050, name: "बरेली" },
  { id: 230010067, name: "बस्ती" },
  { id: 230010063, name: "भदोही" },
  { id: 230010028, name: "बिजनौर" },
  { id: 230010020, name: "बुलंदशहर" },
  { id: 230010041, name: "चंदौली" },
  { id: 230010057, name: "चित्रकूट" },
  { id: 230010044, name: "देवरिया" },
  { id: 230010032, name: "एटा" },
  { id: 230010011, name: "इटावा" },
  { id: 230010012, name: "फर्रुखाबाद" },
  { id: 230010055, name: "फतेहपुर" },
  { id: 230010036, name: "फिरोजाबाद" },
  { id: 230010017, name: "गौतमबुद्ध नगर" },
  { id: 230010016, name: "गाजियाबाद" },
  { id: 230010040, name: "गाजीपुर" },
  { id: 230010046, name: "गोंडा" },
  { id: 230010042, name: "गोरखपुर" },
  { id: 230010059, name: "हमीरपुर" },
  { id: 230010019, name: "हापुड़" },
  { id: 230010007, name: "हरदोई" },
  { id: 230010031, name: "हाथरस" },
  { id: 230010071, name: "जालौन" },
  { id: 230010039, name: "जौनपुर" },
  { id: 230010070, name: "झाँसी" },
  { id: 230010013, name: "कन्नौज" },
  { id: 230010010, name: "कानपुर देहात" },
  { id: 230010009, name: "कानपुर नगर" },
  { id: 230010033, name: "कासगंज" },
  { id: 230010056, name: "कौशाम्बी" },
  { id: 230010045, name: "कुशीनगर" },
  { id: 230010008, name: "लखीमपुर खीरी" },
  { id: 230010072, name: "ललितपुर" },
  { id: 230010003, name: "लखनऊ" },
  { id: 230010043, name: "महाराजगंज" },
  { id: 230010060, name: "महोबा" },
  { id: 230010037, name: "मैनपुरी" },
  { id: 230010035, name: "मथुरा" },
  { id: 230010065, name: "मऊ" },
  { id: 230010015, name: "मेरठ" },
  { id: 230010061, name: "मिर्जापुर" },
  { id: 230010025, name: "मुरादाबाद" },
  { id: 230010074, name: "मुजफ्फरनगर" },
  { id: 230010051, name: "पीलीभीत" },
  { id: 230010054, name: "प्रतापगढ़" },
  { id: 230010001, name: "प्रयागराज" },
  { id: 230010005, name: "रायबरेली" },
  { id: 230010026, name: "रामपुर" },
  { id: 230010073, name: "सहारनपुर" },
  { id: 230010029, name: "संभल" },
  { id: 230010069, name: "संतकबीर नगर" },
  { id: 230010052, name: "शाहजहाँपुर" },
  { id: 230010075, name: "शामली" },
  { id: 230010048, name: "श्रावस्ती" },
  { id: 230010006, name: "सीतापुर" },
  { id: 230010062, name: "सोनभद्र" },
  { id: 230010023, name: "सुल्तानपुर" },
  { id: 230010004, name: "उन्नाव" },
  { id: 230010038, name: "वाराणसी" }
];
```

> Tip: instead of hard-coding, you can regenerate this list live on the page with:
> ```js
> [...document.getElementById('districtId').options]
>   .map(o=>({id:+o.value, name:o.textContent.trim()}))
>   .filter(o=>o.id);
> ```

---

## 5. Full scraper code (paste into the DevTools console on the DistrictWiseWorkCounts page)

### 5.1 Scraper core — fetch, retry, idempotent ledger

```js
window.MLAScraper = (function(){
  const ENDPOINT = '/Main/DistrictWiseWorkCounts';
  const SLEEP = ms => new Promise(r=>setTimeout(r,ms));

  const STATUS_BUCKETS = [
    { key:'proposed',         type:'proposed',   minDays:0,  maxDays:0      },
    { key:'pending_0_45',     type:'pending',    minDays:0,  maxDays:45     },
    { key:'pending_45_60',    type:'pending',    minDays:45, maxDays:60     },
    { key:'pending_60_plus',  type:'pending',    minDays:61, maxDays:100000 },
    { key:'sanctioned_0_45',  type:'sanctioned', minDays:0,  maxDays:45     },
    { key:'sanctioned_45_60', type:'sanctioned', minDays:45, maxDays:60     },
    { key:'sanctioned_60_plus',type:'sanctioned',minDays:61, maxDays:100000 },
    { key:'rejected',         type:'Rejected',   minDays:0,  maxDays:0      },
  ];

  // Resumable, idempotent ledgers (survive re-runs in the same tab)
  window.MLA_STATE = window.MLA_STATE || {};  // key -> {status,rows,hash,ts}
  window.MLA_DATA  = window.MLA_DATA  || {};   // key -> Table_0 array
  const stateKey = (d,y,b) => d+'|'+y+'|'+b;

  async function cheapHash(str){
    const buf = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(str));
    return [...new Uint8Array(buf)].slice(0,8).map(b=>b.toString(16).padStart(2,'0')).join('');
  }

  async function fetchBucket(districtId, yearId, bucket, attempt=0){
    // CRITICAL: literal body + application/json content-type
    const body = "{'obj':" + JSON.stringify({
      optMode:'getDistrictWorkDetails',
      districtId:Number(districtId), yearId:Number(yearId),
      minDays:bucket.minDays, maxDays:bucket.maxDays, type:bucket.type
    }) + "}";
    try {
      const r = await fetch(ENDPOINT, {
        method:'POST',
        headers:{'Content-Type':'application/json','X-Requested-With':'XMLHttpRequest','Accept':'*/*'},
        body
      });
      if (!r.ok) throw new Error('HTTP '+r.status);
      const text = await r.text();
      return { rows: JSON.parse(text).Table_0 || [], raw: text };
    } catch(e){
      if (attempt < 3){ await SLEEP(1000*(attempt+1)); return fetchBucket(districtId,yearId,bucket,attempt+1); }
      throw e;
    }
  }

  // Scrape one district for one FY across all buckets. Skips already-done work.
  async function scrapeDistrict(districtId, yearId, opts={}){
    const politeMs = opts.politeMs ?? 500;
    const log = opts.log ?? console.log;
    const results = {};
    for (const bucket of STATUS_BUCKETS){
      const k = stateKey(districtId, yearId, bucket.key);
      if (window.MLA_STATE[k] && window.MLA_STATE[k].status==='done'){
        results[bucket.key] = window.MLA_STATE[k].rows;
        log('skip (done): '+k+' rows='+window.MLA_STATE[k].rows);
        continue;
      }
      try {
        const { rows, raw } = await fetchBucket(districtId, yearId, bucket);
        const hash = await cheapHash(raw);
        window.MLA_DATA[k]  = rows;
        window.MLA_STATE[k] = { status:'done', rows:rows.length, hash, ts:Date.now() };
        results[bucket.key] = rows.length;
        log('ok: '+k+' rows='+rows.length+' hash='+hash);
      } catch(e){
        window.MLA_STATE[k] = { status:'error', error:String(e), ts:Date.now() };
        results[bucket.key] = 'ERROR: '+e.message;
        log('ERR: '+k+' '+e.message);
      }
      await SLEEP(politeMs);
    }
    return results;
  }

  return { STATUS_BUCKETS, scrapeDistrict, fetchBucket, stateKey };
})();
console.log('Scraper installed.');
```

### 5.2 District list

```js
const DISTRICTS = [...document.getElementById('districtId').options]
  .map(o=>({id:+o.value, name:o.textContent.trim()}))
  .filter(o=>o.id);
window.MLA_DISTRICTS = DISTRICTS;
console.log('Districts:', DISTRICTS.length);
```

### 5.3 Run the crawl for FY 2023-24 (chunked to avoid the ~45s console timeout)

> The DevTools/automation JS context aborts a single evaluation after ~45 seconds.
> Running one district at a time (or a small chunk) keeps each call short. Because the
> ledger is idempotent, you can re-run this cell repeatedly until `done === 75`;
> completed districts are skipped instantly. This is also what makes it resumable after
> any interruption.

```js
window.MLA_CRAWL = window.MLA_CRAWL || { yearId:2, done:[] };

async function crawlChunk(startIdx, count){
  const districts = window.MLA_DISTRICTS;
  const end = Math.min(startIdx+count, districts.length);
  const out = [];
  for (let i=startIdx; i<end; i++){
    const d = districts[i];
    const res = await window.MLAScraper.scrapeDistrict(d.id, 2, { politeMs:400, log:()=>{} });
    if (!window.MLA_CRAWL.done.includes(d.id)) window.MLA_CRAWL.done.push(d.id);
    let total=0; for (const k in res) if (typeof res[k]==='number') total+=res[k];
    out.push({ name:d.name, total });
  }
  return out;
}

// Run this line repeatedly, advancing the start index by 6 each time (0, 6, 12, ...),
// OR loop with awaits in separate console evaluations until all 75 are done:
await crawlChunk(0, 6);   // then crawlChunk(6,6), crawlChunk(12,6), ... crawlChunk(72,6)
```

To check progress at any point:

```js
({ done: window.MLA_CRAWL.done.length,
   buckets: Object.keys(window.MLA_STATE).filter(k=>k.split('|')[1]==='2').length,   // expect 600
   errors: Object.entries(window.MLA_STATE).filter(([k,v])=>k.split('|')[1]==='2' && v.status!=='done').length });
```

### 5.4 Consolidate + deduplicate into the final object

```js
function cleanKey(k){ return k.replace(/<\/?br\/?>/g,' ').replace(/\s+/g,' ').trim(); }
function cleanVal(v){ return (typeof v==='string') ? v.replace(/<\/?br\/?>/g,' ').replace(/\r|\n/g,' ').replace(/\s+/g,' ').trim() : v; }
function cleanRow(row){ const o={}; for (const k in row) o[cleanKey(k)] = cleanVal(row[k]); return o; }

(function build(){
  const YEAR=2, FYLABEL='2023-24';
  const districtsOut=[]; const allWorksById={}; let grandBucketRows=0;
  for (const d of window.MLA_DISTRICTS){
    const worksById={}; const bucketCounts={};
    for (const b of window.MLAScraper.STATUS_BUCKETS){
      const k = window.MLAScraper.stateKey(d.id, YEAR, b.key);
      const rows = (window.MLA_DATA[k]||[]).map(cleanRow);
      bucketCounts[b.key] = rows.length; grandBucketRows += rows.length;
      for (const r of rows){
        const id = r['कार्य आईoडीo'];
        if (id!=null){
          worksById[id] = worksById[id]||{}; Object.assign(worksById[id], r);
          if (!worksById[id].__bucket) worksById[id].__bucket = b.key;
          allWorksById[id] = allWorksById[id]||{}; Object.assign(allWorksById[id], r);
          allWorksById[id].__districtId = d.id; allWorksById[id].__districtName = d.name;
        }
      }
    }
    districtsOut.push({ districtId:d.id, districtName:d.name, yearId:YEAR, financialYear:FYLABEL,
      bucket_counts:bucketCounts, unique_works:Object.keys(worksById).length, works:Object.values(worksById) });
  }
  window.MLA_FY2023_24 = {
    meta:{ source:'mlaladsup.in', report:'DistrictWiseWorkCounts', yearId:YEAR, financialYear:FYLABEL, districts:window.MLA_DISTRICTS.length },
    scraped_at:new Date().toISOString(),
    total_rows_across_buckets:grandBucketRows,
    total_unique_works:Object.keys(allWorksById).length,
    districts:districtsOut
  };
  console.log('Built:', window.MLA_FY2023_24.total_unique_works, 'unique works');
})();
```

### 5.5 Download the single compact JSON file

```js
(function download(){
  const payload = JSON.stringify(window.MLA_FY2023_24);   // compact (no pretty-print)
  const blob = new Blob([payload], {type:'application/json'});
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url; a.download = 'mlaladsup_ALL_districts_FY2023-24_works.json';
  document.body.appendChild(a); a.click();
  setTimeout(()=>{ URL.revokeObjectURL(url); a.remove(); }, 5000);
  console.log('Downloaded ~'+(payload.length/1048576).toFixed(1)+' MB');
})();
```

---

## 6. Output file structure

```
{
  "meta": { source, report, yearId, financialYear, districts },
  "scraped_at": "<ISO timestamp>",
  "total_rows_across_buckets": <int>,
  "total_unique_works": <int>,
  "districts": [
    {
      "districtId": <int>,
      "districtName": "<Hindi name>",
      "yearId": 2,
      "financialYear": "2023-24",
      "bucket_counts": { proposed, pending_0_45, ..., rejected },
      "unique_works": <int>,
      "works": [ { ...~38 fields per work, keyed by Hindi column names,
                   including "कार्य आईoडीo" (Work ID) and "__bucket" ... } ]
    }
    // ... one object per district (75 total)
  ]
}
```

---

## 7. Reproduce end-to-end (checklist)

1. Open https://mlaladsup.in/main/DistrictWiseWorkCounts in a browser; open DevTools console.
2. Paste **5.1** (scraper core), then **5.2** (district list).
3. Run **5.3** repeatedly (`crawlChunk(0,6)`, `crawlChunk(6,6)`, … `crawlChunk(72,6)`)
   until the progress check reports `done: 75`, `buckets: 600`, `errors: 0`.
4. Run **5.4** to consolidate, then **5.5** to download the JSON file.
5. Expect roughly 30344 unique works. (Live totals may differ slightly if the
   portal has been updated since 2026-07-09T18:43:22.681Z.)

---

## 8. Notes, caveats & etiquette

- **Politeness:** a 400–500 ms delay between requests is used; ~600 requests total for
  one year. Please keep delays in place to avoid stressing a government server.
- **Content-Type is load-bearing** — see §2. Getting this wrong silently returns the
  wrong (fund-summary) table.
- **HTML in values:** some fields contain `<a>` tags (PDF/photo links). The cleaning
  step preserves them so document URLs aren't lost; strip or split them if you need
  plain values.
- **Other years:** change `yearId` (2/3/4/5) in §5.3 and §5.4 to scrape 2024-25, etc.
- **Idempotency/resumability:** the ledger `window.MLA_STATE` is keyed by
  `districtId|yearId|bucket`; re-running skips completed cells, so interruptions
  (including the ~45s console timeout) are safe — just re-run the crawl cell.

_End of document._
