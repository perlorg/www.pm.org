# ALEI prefixes

A lookup table of Authoritative Legal Entity Identifier (ALEI) prefixes per
country, e.g. Norway = `NO.RBE`.

An ALEI is the identifier a government business register assigns to a legal
entity, written as `<prefix>:<registration number>`, e.g. `US-DE.BER:3031657`
(Delaware Business Entity Register). The format is defined by ISO 8000-116 and
the scheme is run by ECCMA (Electronic Commerce Code Management Association).
The prefix is an ISO 3166-1/3166-2 country (and subdivision) code, a `.`, and
an acronym for the register.

## Why a copy lives here

We could not find an open, authoritative, downloadable list of ALEI prefixes.
ISO 8000-116 is a paid standard, and ECCMA does not publish the prefix list as
open data. The only machine-readable source we found is the data behind the
map on ECCMA's eALEI statistics page, so we keep a snapshot of it here.

## Source

- Page: https://www.ealei.org/demo/statistics
- Data endpoint (what the page's map loads):
  `POST https://www.ealei.org/demo/statistics/get_data_for_chart` with form
  data `data=get`
- Retrieved: 2026-10-25

To refresh:

    curl -s -X POST -d 'data=get' \
      https://www.ealei.org/demo/statistics/get_data_for_chart

## Files

- `raw/get_data_for_chart.json` - the endpoint's response, unmodified apart
  from pretty-printing.
- `alei_prefixes.json` - the same data reorganized for lookup (below).

## Format of `alei_prefixes.json`

```json
{
  "source": "https://www.ealei.org/demo/statistics/get_data_for_chart",
  "retrieved": "2026-10-25",
  "countries": {
    "Norway": { "iso": "NO", "prefix": "NO.RBE", "count": 144 },
    ...
  },
  "subdivisions": {
    "United States": {
      "US-DE": { "prefix": "US-DE.BER", "count": 10877 },
      ...
    },
    "Brazil": {
      "BR-SP": { "prefix": "BR-SP.CR", "count": 2098 },
      ...
    }
  }
}
```

- `countries` - 218 countries keyed by English name, each with its ISO 3166-1
  alpha-2 code (`iso`), ALEI prefix (`prefix`), and `count`.
- `subdivisions` - the United States (103 entries) and Brazil (28 entries) are
  not listed as whole countries in the source, only per state, so they are
  keyed here by ISO 3166-2 code. United States and Brazil therefore do not
  appear in `countries`.
- `count` - the number the map shows for that area, presumably how many ALEIs
  eALEI holds there. It is not needed for prefix lookup.

## Caveats

The source gives one prefix per country, but some countries have more than one
register, and in those cases the listed prefix looks like a representative
example rather than the only valid one. Germany, for instance, is listed as
`DE-NW.AAC.CR`, which is specific to one state (NW, North Rhine-Westphalia)
and one local register within it. The ECCMA draft of ISO 8000-116 uses this
exact prefix as its example of a country with multiple registers and no
ISO 3166-2 subdivision for each. Treat these prefixes as "a known prefix for
this country", not "the prefix for this country".

## Licensing

We have no license for this data, and we found none to obtain.

- ISO 8000-116:2019 is sold by ISO and national standards bodies (CHF 44 from
  ISO; roughly USD 46-55 from other resellers). It defines the prefix format
  rules with a handful of examples. ECCMA's 2018 draft of it contains no full
  list of country prefixes, so buying the standard would not give us this
  table. An ISO purchase licenses the document for the buyer's own use, not
  for republishing.
- ECCMA assigns the prefixes and serves them through eALEI. ECCMA describes
  the ALEI as a free, public identifier, but we found no license, terms of use
  or open-data statement covering the prefix list. The eALEI statistics page
  links only to a privacy policy.
- In the US, a list of facts such as country-to-prefix codes is generally not
  protected by copyright (Feist Publications v. Rural Telephone Service,
  1991). The EU and EEA, which include Norway, have a separate database right
  that can protect a compiled list even when its facts are not protected.
  Whether that applies to a US organization's list is unclear. This is not
  legal advice.

Until ECCMA grants permission or states a license, keep this copy
unpublished, and credit ECCMA and the retrieval date wherever it is used.
Next step: ask ECCMA for permission to publish it on www.pm.org with credit.

## References

- eALEI statistics page (data source, retrieved 2026-10-25):
  https://www.ealei.org/demo/statistics
- eALEI data endpoint behind that page's map:
  https://www.ealei.org/demo/statistics/get_data_for_chart
- ECCMA privacy policy (the only policy linked from the eALEI page):
  https://eccma.org/privacy-policy/
- ISO 8000-116:2019 (prefix format standard, price):
  https://www.iso.org/standard/75117.html
- ISO/CD 8000-116 ALEI Prefixes, ECCMA draft dated 2018-05-29 (prefix syntax
  rules and the `FR.RC`, `US-DE.BER`, `DE-NW.AAC.CR` examples):
  https://www.eccma.org/docs/White_Papers/ISO_CD_8000-116_ALEI_Prefixes.pdf
- ECCMA Shared Organization Master (eSOM), ECCMA's description of the ALEI as
  a free, public identifier: https://eccma.org/?p=231
- Authoritative Legal Entity Identifier (overview):
  https://en.wikipedia.org/wiki/Authoritative_Legal_Entity_Identifier
- Feist Publications, Inc. v. Rural Telephone Service Co., 499 U.S. 340
  (1991): https://supreme.justia.com/cases/federal/us/499/340/
- EU Database Directive 96/9/EC (database right):
  https://eur-lex.europa.eu/eli/dir/1996/9/oj
