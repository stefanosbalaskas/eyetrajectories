#!/usr/bin/env python3
"""Fail-closed live author-source SHA256 verification, separate from synthetic unit packets.

This script must never be mocked in experimental candidate qualification.
Historical author-reviewed closure flags are not independent scientific
certifications. A source or test file changed after its SHA256-pinned
six-domain review must undergo renewed review before this check can pass.
"""
from __future__ import annotations

import sys
from source_gap_inventory import SourceGapInventoryError, read_inventory


def main() -> int:
    try:
        counts = read_inventory()
    except SourceGapInventoryError as error:
        print("LIVE_AUTHOR_SOURCE_REVIEW_SHA256=FAIL", flush=True)
        print("LIVE_AUTHOR_SOURCE_REVIEW_BLOCKER=" + str(error), flush=True)
        print("INDEPENDENT_508_CERTIFICATION=FALSE", flush=True)
        return 2
    print("LIVE_AUTHOR_SOURCE_REVIEW_SHA256=PASS", flush=True)
    print("HISTORICAL_CALLABLE_SOURCE_WITNESSES=" +
          str(counts.historical_callable), flush=True)
    print("CURRENT_AUTHOR_OPEN_SOURCE_GAPS=" +
          str(counts.open_total), flush=True)
    print("INDEPENDENT_508_CERTIFICATION=FALSE", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
