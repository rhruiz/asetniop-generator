## what?

Parses a QMK keymap file (just the `LAYOUTS` macro call) from an ergodox layout
I found to find qmk `LT` s and build a [asetniop] based keymap.

I tried both with QMK combos and LTs and found the COMBOs solution better.
I didn't get [gboards] code to build with qmk master.

By mixing parser.ex and run.exs you can generate a CRKBD layout with asetinop in
the top row.

## why?

had spare time, found a mosquito, had a bazooka.

## thanks

- [Gary Bernhardt] for the compiler from
scratch cast that is the base for the parser.
- [Jack Humbert] and the [QMK community] for QMK
- Pointesa LLC for [asetniop]

[Gary Bernhardt]: https://www.destroyallsoftware.com/
[Jack Humbert]: https://github.com/jackhumbert
[QMK community]: https://github.com/qmk/qmk_firmware
[asetniop]: https://asetniop.com
[gboards]: https://www.gboards.ca
