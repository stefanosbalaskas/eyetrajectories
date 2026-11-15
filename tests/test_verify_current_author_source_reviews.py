"""Unit checks for the unmocked live-author review gate used by the candidate.

Test-specific mocks here validate the gate's FAIL/PASS semantics. The actual
candidate calls the script in a separate Python process with NO mocks.
"""
from __future__ import annotations

import contextlib
import io
import sys
from pathlib import Path
from unittest import TestCase, main
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import verify_current_author_source_reviews as gate
from source_gap_inventory import SourceGapCounts, SourceGapInventoryError


class LiveAuthorSourceReviewGateTests(TestCase):
    def test_stale_implementation_digest_must_fail_and_never_certify(self):
        stream = io.StringIO()
        with patch.object(gate, "read_inventory", side_effect=
                          SourceGapInventoryError(
                              "Native implementation changed after "
                              "full-contract review: synthetic_export")), \
             patch("report_current_source_review_staleness.report") as diagnostics, \
             contextlib.redirect_stdout(stream):
            status = gate.main()
        self.assertEqual(status, 2)
        diagnostics.assert_called_once()
        self.assertIn("LIVE_AUTHOR_SOURCE_REVIEW_SHA256=FAIL",
                      stream.getvalue())
        self.assertIn("synthetic_export", stream.getvalue())
        self.assertIn("INDEPENDENT_508_CERTIFICATION=FALSE",
                      stream.getvalue())

    def test_secondary_diagnostic_failure_cannot_override_hard_failure(self):
        stream = io.StringIO()
        with patch.object(gate, "read_inventory", side_effect=
                          SourceGapInventoryError("stale review SHA256")), \
             patch("report_current_source_review_staleness.report",
                   side_effect=RuntimeError("synthetic diagnostic unavailable")), \
             contextlib.redirect_stdout(stream):
            status = gate.main()
        self.assertEqual(status, 2)
        self.assertIn("LIVE_AUTHOR_SOURCE_REVIEW_SHA256=FAIL",
                      stream.getvalue())
        self.assertIn("synthetic diagnostic unavailable",
                      stream.getvalue())
        self.assertIn("INDEPENDENT_508_CERTIFICATION=FALSE",
                      stream.getvalue())

    def test_valid_author_receipts_never_mean_independent_approval(self):
        fixture = SourceGapCounts(historical_callable=203,
            active_callable=0, resolved_semantic=tuple(),
            historical_nonfunction=1, active_nonfunction=0)
        stream = io.StringIO()
        with patch.object(gate, "read_inventory", return_value=fixture), \
             contextlib.redirect_stdout(stream):
            status = gate.main()
        self.assertEqual(status, 0)
        self.assertIn("LIVE_AUTHOR_SOURCE_REVIEW_SHA256=PASS",
                      stream.getvalue())
        self.assertIn("INDEPENDENT_508_CERTIFICATION=FALSE",
                      stream.getvalue())


if __name__ == "__main__":
    main()
