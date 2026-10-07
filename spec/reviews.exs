# Requirements checked by hand, by requirement ID.
#
# Use this for requirements that tests can't fully cover. Say what was
# checked and how. A requirement whose tests pass doesn't need a review,
# but a review can add what the tests miss.
#
# Update or remove a review when its requirement changes.
%{
  "ARCH-5" =>
    "Layouts follow the LWP 3.0.00 docs. Where the docs contradict themselves: Hub Alert " <>
      "status is sent only with the Update operation, as in the Alert Payload table (the size " <>
      "table swaps up- and downstream); TiltFactoryCalibration uses WriteDirect with " <>
      "orientation 1 = XY, 2 = Z, matching the worked example and its checksum 0x77; " <>
      "SetRgbColors writes R, G, B to mode 1, as in the RGB example; the Mapping input byte " <>
      "comes before the output byte, as in 'xxxx xxxx yyyy yyyy'. Port values are decoded " <>
      "as signed; strings are trimmed at the first zero byte.",
  "DOC-1" =>
    "README plus module and function docs with runnable examples (47 doctests), reviewed " <>
      "for length and clarity. `mix docs` is checked by CI.",
  "TEST-1" =>
    "Tests are grouped in describe \"Given ...\" blocks with " <>
      "test \"when ..., then ...\" names, checked with grep; doctests double as examples."
}
