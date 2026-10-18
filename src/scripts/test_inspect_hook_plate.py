"""Small G-code regressions: preserve material totals and follow real arcs."""
import math
import unittest

import numpy as np

from inspect_hook_plate import gcode_features, matrix


class ToolpathTests(unittest.TestCase):
    def test_both_arc_directions(self):
        lengths,roles=gcode_features(
            'G90\nM83\nG1 X1 Y0 Z.2\n; FEATURE: Support\n'
            'G3 X0 Y1 I-1 J0 E2\nG2 X1 Y0 I0 J-1 E3\n')
        self.assertEqual(lengths['Support'],5)
        self.assertAlmostEqual(sum(v[6] for v in roles['Support']),5)
        self.assertGreaterEqual(len(roles['Support']),36)
        for segment in roles['Support']:
            self.assertAlmostEqual(math.hypot(*segment[:2]),1)

    def test_closed_arc_is_not_dropped(self):
        lengths,roles=gcode_features(
            'G90\nM83\nG1 X1 Y0 Z.2\n; FEATURE: Support interface\n'
            'G2 I-1 J0 E4\n')
        self.assertEqual(lengths['Support interface'],4)
        self.assertGreaterEqual(len(roles['Support interface']),72)

    def test_absolute_e_retraction_not_counted(self):
        lengths,_=gcode_features(
            'G90\nM82\nG92 E0\n; FEATURE: Outer wall\n'
            'G1 X1 E2\nG1 E1\nG1 E2\nG1 X2 E3\n'
            '; FEATURE: Custom\nG1 X3 E8\n')
        self.assertEqual(lengths,{'Outer wall':3})

    def test_3mf_matrix_order(self):
        value=matrix('0 0 -1 0 1 0 1 0 0 10 20 30')
        self.assertTrue(np.allclose(value@np.array([1,2,3,1]),[13,22,29,1]))


if __name__=='__main__':
    unittest.main()
