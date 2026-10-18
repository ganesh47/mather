#!/usr/bin/env python3
"""Offline integrity checks. No external Python dependencies or network access."""
import hashlib
import json
import math
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
CONTENT = ROOT / 'Content' / 'WorldQuest'


class WorldQuestContentTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.raw = (CONTENT / 'world-quest-map.json').read_bytes()
        cls.map = json.loads(cls.raw)
        cls.manifest = json.loads((CONTENT / 'provenance.json').read_text())
        cls.countries = {c['id']: c for c in cls.map['countries']}
        cls.features = {f['id']: f for f in cls.map['features']}

    def test_pinned_output_and_roster(self):
        self.assertEqual(hashlib.sha256(self.raw).hexdigest(), self.manifest['mapSHA256'])
        self.assertEqual(len(self.countries), 195)
        self.assertEqual(set(self.countries), set(self.manifest['rosterIDs']))
        self.assertTrue(set(self.countries) <= set(self.features))
        self.assertEqual(len(set(self.map['starterIDs'])), 12)
        self.assertEqual(self.map['boundaryViewpoint'], 'India')
        self.assertNotIn('TWN', self.countries)
        self.assertNotIn('GRL', self.countries)
        self.assertIn('GRL', self.features)

    def test_closed_finite_rings_and_no_date_line_streaks(self):
        points = 0
        for feature in self.features.values():
            self.assertTrue(feature['rings'])
            for ring in feature['rings']:
                self.assertGreaterEqual(len(ring), 4)
                self.assertEqual(ring[0], ring[-1])
                for x, y in ring:
                    self.assertTrue(math.isfinite(x) and math.isfinite(y))
                    self.assertTrue(0 <= x <= 1 and 0 <= y <= 1)
                # Antarctica's pole closure legitimately spans the bottom edge.
                if feature['id'] != 'ATA':
                    self.assertTrue(all(abs(a[0]-b[0]) < 0.5 for a,b in zip(ring,ring[1:])))
                points += len(ring)
        self.assertEqual(points, self.manifest['coordinateCount'])

    def test_region_membership_and_markers(self):
        counts = {}
        for country in self.countries.values():
            counts[country['continent']] = counts.get(country['continent'], 0) + 1
            self.assertTrue(country['name'])
            self.assertGreater(country['area'], 0)
            self.assertTrue(all(0 <= v <= 1 for v in country['anchor']))
        self.assertEqual(counts, {'Africa':54,'Asia':48,'Europe':44,'North America':23,'South America':12,'Oceania':14})
        self.assertLess(self.countries['VAT']['area'], 2)
        self.assertGreater(len(self.features['FJI']['rings']), 1)
        self.assertEqual(self.countries['IND']['continent'], 'Asia')


if __name__ == '__main__':
    unittest.main()
