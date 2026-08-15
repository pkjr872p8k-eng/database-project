# Biobank and Biospecimen Management System

A relational database project for **CSCI305 — Fundamentals of Databases**, built around a
research biobank that tracks donors, informed consent, specimen collection, freezer
inventory, research projects, and specimen usage.

DBMS: **MySQL 8.0**

## Repository layout

```
.
├── README.md                      This file
├── report.docx                    Full written project report (all required sections)
├── presentation.pptx               12-slide project presentation
├── sql/
│   ├── create_tables.sql          DDL: database, tables, keys, constraints, indexes
│   ├── load_data.sql              DML: test data (10+ records per main table)
│   ├── views.sql                  3 views
│   ├── triggers_procedures.sql    2 triggers, 1 stored procedure, 1 function
│   └── queries.sql                Retrieval, joins, aggregation, subqueries, CRUD
└── diagrams/
    ├── erd.png                    Chen-notation ER diagram
    └── schema.png                 Relational schema (mapped tables) diagram
```

## Getting started

### 1. Create and populate the database

Run the SQL scripts **in this exact order** against a MySQL 8.0 server:

```bash
mysql -u root -p < sql/create_tables.sql
mysql -u root -p < sql/load_data.sql
mysql -u root -p < sql/views.sql
mysql -u root -p < sql/triggers_procedures.sql
```

`sql/queries.sql` is a standalone showcase file — run individual statements from it as
needed; it is not part of the setup sequence (its final section modifies data, so running
it more than once will not reproduce identical results).

## Design summary

- **13 tables**: 9 strong/lookup entities, 2 weak entities (`CONSENT`, owned by `DONOR`;
  `ALIQUOT`, owned by `SAMPLE`), and 2 associative tables resolving many-to-many
  relationships (`PROJECT_RESEARCHER`, `SAMPLE_USAGE`).
- **Normalization**: every table satisfies 3NF; see Section 5 of `report.docx` for the
  full reasoning, including why `SAMPLE_TYPE` and `STORAGE_LOCATION` were factored out as
  separate lookup entities.
- **database layer**:
  - An aliquot's volume can never exceed its parent sample's recorded volume
    (`trg_aliquot_volume_check`).
  - Consuming part of an aliquot automatically deducts the volume and marks it
    `Depleted` once exhausted (`trg_usage_depletes_aliquot`).
  - Registering a test request and its specimen usage happens atomically, with
    availability validated first (`sp_register_test_request`).

See `report.docx` for the complete write-up (problem statement, ER diagram, relational
schema, normalization discussion, testing, and conclusion) and `presentation.pptx` for a
slide summary.
