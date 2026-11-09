# Weekly popular and admin selection

Approved: admin can still select comics manually. Keep seven slots; explicit pins first, then unique readers over rolling seven days, then source suggestions for unmeasured slots. Unchecking excludes an entry. Editing unrelated metadata must not silently pin an automatic entry.

- Private reader table keyed by comic and account (guest: persistent installation UUID); server timestamps. Only aggregate counts public. Record after an image actually decodes, not detail/cover opens. Debounce one successful report per comic/account per session hour; failed analytics cannot break reading.
- Separate repository: rank RPC, catalog overrides, source fallback, hydration. Hidden comics excluded, source switching supported, strict format and dedup.
- Admin editor prechecks current global/type top seven. Only an explicit checkbox change writes popular_override; existing is_popular=true remains compatible.
- Test selection, transport, current checkbox, retry/dedup, SQL seven-day cutoff and permissions in rolled-back transaction. Run full Flutter tests + analyzer.
