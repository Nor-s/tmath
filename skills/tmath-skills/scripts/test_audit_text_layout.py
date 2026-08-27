#!/usr/bin/env python3
"""Regression tests for the text-layout containment ledger."""

from __future__ import annotations

import importlib.util
import sys
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("audit_text_layout.py")
SPEC = importlib.util.spec_from_file_location("audit_text_layout", MODULE_PATH)
AUDIT = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
sys.modules[SPEC.name] = AUDIT
SPEC.loader.exec_module(AUDIT)


class ContainmentLedgerTest(unittest.TestCase):
    def test_reports_text_missing_from_strict_ledger(self):
        expected = {("root", "diagram:title"), ("root", "node:label")}
        containments = [AUDIT.Containment("node:label", "node:body", 12.0)]

        self.assertEqual(
            AUDIT._uncovered_texts(expected, containments, set()),
            {("root", "diagram:title")},
        )

    def test_accepts_contained_and_explicitly_free_text(self):
        expected = {("root", "diagram:title"), ("root", "node:label")}
        containments = [AUDIT.Containment("node:label", "node:body", 12.0)]

        self.assertEqual(
            AUDIT._uncovered_texts(expected, containments, {"diagram:title"}),
            set(),
        )


if __name__ == "__main__":
    unittest.main()
