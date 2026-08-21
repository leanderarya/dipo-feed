# DipoFeed Task A Refinement Design

## Goal

Deliver foundation changes for DipoFeed: CSV-backed feed data, safe CSV replacement import/export, Indonesian number formatting, manual nutrition calculation, and stepper flows for Cek Kecukupan Pakan and Rekomendasi Pakan.

## Scope

Task A includes:

- Move runtime seed data from JSON to `assets/data/bahan_pakan.csv`.
- Keep `assets/data/bahan_pakan.json` as backup only.
- Convert existing `limbah` and `energi` seed categories to `lainnya`.
- Classify only `hijauan` as forage in recommendation logic; every other category is concentrate.
- Add CSV import from the platform file picker in Database Pakan.
- Add CSV export of all active feed data through the platform share sheet.
- Replace active local data atomically on every successful import.
- Add Indonesian number parsing and formatting for CSV and displayed calculation values.
- Change Cek Kandungan Pakan to manual calculation while preserving its single-page layout.
- Add a three-step flow to Cek Kecukupan Pakan.
- Add a three-step flow to Rekomendasi Pakan.
- Add unit/widget tests and update project documentation.

Task B starts only after Task A verification and handoff.

## Confirmed Product Decisions

### Cek Kecukupan Pakan

Stepper stages:

1. Data Sapi
2. Kebutuhan Nutrien dan Pemberian Pakan
3. Hasil Evaluasi Nutrisi

The parent screen owns all form, feed, requirement, and result state. Users may return to completed stages and edit data. Editing prerequisite data invalidates the current result. Future stages cannot be opened until the preceding stage is valid.

### Rekomendasi Pakan

Stepper stages:

1. Data Sapi
2. Bahan Pakan Tersedia
3. Hasil Rekomendasi

The parent screen owns profile, feed selection, requirement, and recommendation state. Users may return to completed stages and edit data. Editing profile or selected feeds invalidates the recommendation result.

### Cek Kandungan Pakan

Keep one page. The calculation result is a snapshot produced only after the user presses `Hitung`. Adding, removing, changing, or replacing a feed marks the result as not calculated until `Hitung` succeeds again. The result remains inline on the same page.

### CSV format

- File: UTF-8 CSV.
- Delimiter: `;`.
- Decimal separator: `,`.
- Thousands separator: `.`.
- Exact header: `nama;kategori;BK;abu;lemak;serat;PK;BETN;TDN;ME;harga;Ca;P`.
- `id` and `isActive` are not exported or imported.
- All imported rows become active.
- Export precision is deterministic: `BK`, `abu`, `lemak`, `serat`, `PK`, `BETN`, `TDN`, `ME`, `Ca`, and `P` use 2 decimal places; `harga` uses 0 decimal places.
- Numeric values use the same Indonesian separators in import and export; exported values retain the defined precision, including trailing zeroes.

### CSV import behavior

- Import is available only in Database Pakan.
- A file picker accepts CSV files.
- Normalize names using trim and case-insensitive comparison.
- Duplicate normalized names inside one CSV use the last row.
- A normalized name matching existing data updates the existing record and preserves its ID.
- A new normalized name receives a new ID.
- Existing records absent from the imported CSV are permanently deleted.
- Any invalid row rejects the entire import; Hive data remains unchanged.
- Before replacement, show a confirmation explaining that old records absent from the file will be deleted.
- After success, show counts for added, updated, and deleted records.
- After failure, show the validation error and leave the database unchanged.
- Parse, normalize, validate, and build the complete replacement set and counts in memory before persistence.
- Commit the replacement through one controlled repository operation. If clearing or writing Hive fails, restore the previous dataset when possible, keep the repository data consistent with the previous dataset, and report the import as failed.
- Persistence failure and rollback behavior are covered by tests.

### CSV export behavior

- Export includes all active records only.
- Export uses the confirmed header and Indonesian number format.
- Export creates a `.csv` file and opens the native share sheet.
- Cancelled sharing is not treated as an export failure after the file is generated.

## Architecture

Keep current feature folders and repository ownership. Add a focused CSV codec/service under `lib/data/` for parsing, validation, serialization, and import result counts. Keep replacement orchestration in `BahanPakanRepository` or a repository-adjacent service so UI does not mutate Hive directly.

`BahanPakanLocalSource` loads the CSV asset when Hive has no records and on reset. JSON remains in assets for backup and is not used by runtime seed loading. CSV file picking and share-sheet calls remain at the Database Pakan UI boundary, while byte parsing and CSV generation remain testable without Flutter platform channels.

Use existing Hive storage and Flutter widgets. Add `file_picker` for CSV selection and `share_plus` for native export sharing. Do not add a spreadsheet dependency.

## Data rules

Seed conversion starts from the current 19 JSON records. The canonical seed CSV assigns `id = row index + 1` deterministically during seed parsing; `id` is not stored as a CSV column. Reset replaces Hive with records generated from the canonical seed row order. Existing Hive identity is preserved when the canonical seed row order remains unchanged; changing that row order in a future seed release is a data migration and must not be treated as an identity-preserving edit. Runtime imports preserve IDs by normalized-name matching and generate IDs above the current maximum for new names. Existing `energi` and `limbah` values become `lainnya` in the CSV seed.

Recommendation classification becomes category-based: `kategori.trim().toLowerCase() == 'hijauan'` means forage; every other category is concentrate. Keyword inference from feed names or additional category keywords is removed from the recommendation decision.

## Number rules

Create one reusable non-currency formatter/parser for display and CSV numeric fields. It must support values such as `2,57`, `1.234,50`, and `4500`, and output values such as `2,57`, `1.234,50`, and `4.500` according to the requested decimal precision. Existing Rupiah behavior remains compatible with current tests.

## Feedback state contract

Task A exposes calculation state that UI can render consistently:

- `belumDihitung`: no valid result exists for current inputs.
- `berhasil`: current inputs produced a valid result.
- `gagal`: the latest calculation attempt failed validation or calculation.

Cek Kecukupan and Rekomendasi use this state around step transitions. Cek Kandungan uses it around the manual `Hitung` button. Validation messages remain specific to the missing or invalid input.

## Testing strategy

Add tests for:

- CSV parsing with semicolon delimiter, Indonesian decimals, thousands separators, header validation, missing values, invalid numeric values, duplicate-last-row behavior, and name normalization.
- CSV serialization of all active records, exact header/order, and exact per-field precision.
- Repository replacement counts, ID preservation, new ID generation, permanent deletion of absent records, atomic rejection on invalid input, and persistence failure rollback.
- Seed CSV loading and category migration.
- Recommendation classification where `hijauan` is forage and `lainnya`, `konsentrat`, and any other category are concentrate.
- Indonesian numeric formatting and parsing.
- Manual Cek Kandungan calculation invalidation and successful snapshot calculation.
- Stepper navigation validation, back/edit behavior, result invalidation, and successful result-stage transitions.

Run:

```bash
flutter analyze
flutter test
```

## Documentation

Update `README.md` and add a focused rules document under `docs/` covering:

- CSV schema and replacement semantics.
- Category classification for recommendation.
- Indonesian number format.
- Nutrient calculation/status rules and their source formulas.
- Stepper stage order and edit behavior.

## Handoff to Task B

Task A is ready for handoff only when the CSV seed, import/export flow, repository rules, manual calculation, both steppers, tests, documentation, `flutter analyze`, and `flutter test` are complete. Task B must branch from the verified Task A commit and should not change the CSV contract, repository replacement rules, category classification, or calculation APIs without coordination.
