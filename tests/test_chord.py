import pathlib
import runpy
import unittest

Hold = runpy.run_path(str(pathlib.Path(__file__).resolve().parents[1] / 'bin/cleanlock-chord'))['Hold']

class HoldTests(unittest.TestCase):
    def test_either_super_five_seconds(self):
        for key in (125, 126):
            hold = Hold()
            self.assertEqual(hold.update({('keyboard', key)}, 1), 0)
            self.assertEqual(hold.update({('keyboard', key)}, 5.99), 4)
            self.assertEqual(hold.update({('keyboard', key)}, 6), 5)

    def test_release_cancels_even_after_shift_or_copilot(self):
        hold = Hold()
        hold.update({('keyboard', 125)}, 1)
        self.assertEqual(hold.update(set(), 1.15), 0)
        self.assertEqual(hold.update(set(), 6), 0)

    def test_repress_restarts(self):
        hold = Hold()
        hold.update({('keyboard', 125)}, 1)
        hold.update(set(), 4)
        self.assertEqual(hold.update({('keyboard', 125)}, 4.1), 0)
        self.assertEqual(hold.update({('keyboard', 125)}, 6), 1)

    def test_switching_keys_or_keyboards_restarts(self):
        for key in [('keyboard',126), ('other',125)]:
            hold = Hold()
            hold.update({('keyboard',125)}, 1)
            self.assertEqual(hold.update({key}, 5), 0)
            self.assertEqual(hold.update({key}, 6), 1)

if __name__ == '__main__': unittest.main()
