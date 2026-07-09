# MLA-Wise Work Summary — FY 2023-24 (Data Documentation)

**Companion data file:** \`mlaladsup_MLAWise_summary_VidhanSabha_FY2023-24.json\`
**Source portal:** https://mlaladsup.in/ — विधान मण्डल क्षेत्र विकास निधि योजना
(MLA Local Area Development Scheme), ग्राम्य विकास विभाग, उत्तर प्रदेश (Rural Development
Department, Government of Uttar Pradesh)
**Source page:** https://mlaladsup.in/main/MLAWiseWorkCounts ("मा० विधायक वार कार्य का विवरण")
**Financial year:** 2023-24 (\`yearId = 2\`)
**Seat type:** विधान सभा — Legislative Assembly (\`seatTypeId = 1\`)
**Records:** 403 MLAs (plus one state-wide totals row)
**Downloaded (UTC):** 2026-07-09T20:11:27.984Z

---

## 1. What this data is

This is a **summary count of works** under the UP MLA Local Area Development Scheme,
aggregated **per Member of the Legislative Assembly (MLA)** for the financial year
2023-24. Each row corresponds to one MLA / assembly constituency and reports how many
works that legislator recommended and where those works stand in the approval pipeline
(pending, sanctioned, or rejected), bucketed by how long they have been in each stage.

This is **aggregate/summary data only** — it is one number-per-status per MLA, not the
list of individual works. (The portal's per-work drilldown for the MLA view is
non-functional; individual work records are available instead via the district-level
report, \`DistrictWiseWorkCounts\`, where each work also carries its proposer/MLA.)

### State-wide totals (FY 2023-24, Legislative Assembly)
| Metric | Value |
|---|---|
| Recommended works | 23,574 |
| Total pending (awaiting sanction) | 51 |
| Total sanctioned | 23,630 |
| Rejected | 3 |

---

## 2. File format

The file is UTF-8 JSON (Hindi text is stored as native Unicode) with this structure:

\`\`\`
{
  "meta": {
    "source", "report", "level", "seatType", "seatTypeId", "yearId",
    "financialYear", "columns_hindi": [...], "columns_english": [...]
  },
  "scraped_at": "<ISO-8601 UTC timestamp>",
  "total_row": { ...state-wide totals... },
  "mla_count": 403,
  "records": [ { ...one object per MLA... }, ... ]
}
\`\`\`

### Field dictionary
Each object in \`records\` (and \`total_row\`) has these fields. Count fields are integers;
\`0\` means the source cell was blank.

| JSON field (english) | Source column (Hindi) | Meaning |
|---|---|---|
| \`mla_id\` | (from drilldown attribute) | Internal MLA identifier used by the portal |
| \`sr_no\` | क्रमसंo | Serial number in the table |
| \`mla_name_constituency\` | माननीय विधायक का नाम व क्षेत्र | MLA name + constituency (number & name) |
| \`financial_year\` | वित्तीय वर्ष | Financial year (all "2023-24") |
| \`nodal_district\` | नोडल जनपद | Nodal district administering the funds |
| \`recommended_works\` | अनुशंसित कार्य | Works recommended by the MLA |
| \`pending_0_45\` | स्वीकृति के लिए लंबित कार्य (45 दिन में) | Pending sanction, ≤45 days |
| \`pending_45_60\` | स्वीकृति के लिए लंबित कार्य (45-60 दिन में) | Pending sanction, 45-60 days |
| \`pending_60_plus\` | स्वीकृति के लिए लंबित कार्य (60 दिन के बाद) | Pending sanction, >60 days |
| \`total_pending\` | कुल लंबित कार्य | Total pending sanction |
| \`sanctioned_0_45\` | स्वीकृत कार्य (45 दिन में) | Sanctioned within 45 days |
| \`sanctioned_45_60\` | स्वीकृत कार्य (45-60 दिन में) | Sanctioned in 45-60 days |
| \`sanctioned_60_plus\` | स्वीकृत कार्य (60 दिन के बाद) | Sanctioned after 60 days |
| \`total_sanctioned\` | कुल स्वीकृत कार्य | Total sanctioned |
| \`rejected\` | रिजेक्ट कार्य | Rejected works |

---

## 3. Exactly how it was downloaded

The MLAWiseWorkCounts page renders its report as a client-side jQuery **DataTable**,
loading all rows into the DOM on report generation. No login is required. The data was
read directly from that rendered table (rather than replaying an API call), which
guarantees it matches exactly what the portal displays.

### Steps
1. Open https://mlaladsup.in/main/MLAWiseWorkCounts in a browser.
2. In the filter bar, leave the seat type as **विधान सभा** (Legislative Assembly),
   set the year dropdown to **2023-24**, and click **Get Report**. Wait for the full
   table (~404 rows) to render.
3. Open the DevTools console and run the extraction script below.
4. It reads the table \`#simpledatatable\`, converts count columns to integers, pulls each
   MLA's id from the row's drilldown \`onclick\` attribute, separates out the "- Total"
   row, wraps everything with metadata, and triggers a JSON download.

### Extraction + download script

\`\`\`js
(function scrapeAndDownload(){
  const tbl = document.getElementById('simpledatatable');
  if (!tbl) throw new Error('summary table not found — did the report load?');

  const fieldNames = [
    'sr_no','mla_name_constituency','financial_year','nodal_district',
    'recommended_works','pending_0_45','pending_45_60','pending_60_plus','total_pending',
    'sanctioned_0_45','sanctioned_45_60','sanctioned_60_plus','total_sanctioned','rejected'
  ];
  const headersHindi = [...tbl.querySelectorAll('thead th')]
    .map(h => h.textContent.trim().replace(/\s+/g,' '));
  const toNum = s => { if (s===''||s==null) return 0; const n=Number(String(s).replace(/,/g,'')); return isNaN(n)?s:n; };

  const records = []; let totalRow = null;
  for (const tr of tbl.querySelectorAll('tbody tr')){
    const cells = [...tr.cells].map(td => td.textContent.trim().replace(/\s+/g,' '));
    if (cells.length < 14) continue;

    // MLA id lives in the drilldown onclick: getMlaWorkDetailsPopup(name,status,<ID>,...)
    const oc = [...tr.querySelectorAll('[onclick]')]
      .map(e => e.getAttribute('onclick'))
      .find(x => x && /WorkDetailsPopup/i.test(x));
    let mlaId = null;
    if (oc){ const m = oc.match(/getMlaWorkDetailsPopup\(([^)]*)\)/); if (m){ const p = m[1].split(','); mlaId = p[2] ? p[2].trim() : null; } }

    const rec = { mla_id: mlaId };
    fieldNames.forEach((f, idx) => { rec[f] = idx >= 4 ? toNum(cells[idx]) : cells[idx]; });

    if (rec.sr_no === '' && /Total/i.test(rec.mla_name_constituency)) totalRow = rec;
    else records.push(rec);
  }

  const out = {
    meta: {
      source: 'mlaladsup.in', report: 'MLAWiseWorkCounts',
      level: 'MLA/assembly-constituency summary',
      seatType: 'विधान सभा (Legislative Assembly)', seatTypeId: 1,
      yearId: 2, financialYear: '2023-24',
      columns_hindi: headersHindi,
      columns_english: ['mla_id', ...fieldNames]
    },
    scraped_at: new Date().toISOString(),
    total_row: totalRow,
    mla_count: records.length,
    records
  };

  // Download as one compact/pretty JSON file
  const payload = JSON.stringify(out, null, 2);
  const blob = new Blob([payload], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url; a.download = 'mlaladsup_MLAWise_summary_VidhanSabha_FY2023-24.json';
  document.body.appendChild(a); a.click();
  setTimeout(() => { URL.revokeObjectURL(url); a.remove(); }, 3000);
  console.log('Downloaded', records.length, 'MLA rows');
})();
\`\`\`

---

## 4. Reproducing / adapting

- **Other financial years:** in step 2 pick a different year in the dropdown
  (2023-24 = 2, 2024-25 = 3, 2025-26 = 4, 2026-27 = 5), regenerate the report, and re-run
  the script (update the \`yearId\`/\`financialYear\` in \`meta\` and the output filename).
- **Legislative Council members:** change the seat-type dropdown to **विधान परिषद**
  (\`seatTypeId = 2\`) before generating the report.
- **Alternative export:** the page also offers a native **Excel** export button
  (top-left of the table) that produces the same rows without any scripting.

---

## 5. Caveats

- These are **portal-reported aggregate counts**, refreshed by the source at its own
  cadence; totals may change if you re-download later. The \`scraped_at\` timestamp records
  when this snapshot was taken.
- Blank cells in the source are stored as \`0\`.
- Names/constituencies are kept verbatim in Hindi (including the source's original
  spacing/abbreviations such as "विo सo" for विधान सभा).
- The MLA per-work drilldown on this page is non-functional in the source site, so this
  file intentionally contains **summary counts only**. For individual work records, use
  the district-level \`DistrictWiseWorkCounts\` dataset.

_End of document._
