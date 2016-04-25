# Greek New Testament graded against Duff's Elements of New Testament Greek

* Loads GNT as submodule, so `git submodule update --init`.
* Usable as a Ruby library with `require`, providing Duff parsing by chapter.
* When run as a command, copies whole parsed GNT on standard output, with required Duff chapters added for each word.

## Sources:

* Duff vocab: http://www.denisowski.org/NT_Greek/EONTG/EONTG.html
* Duff parsing by chapter: derived by author
* Morphologically tagged Greek New Testament: https://github.com/morphgnt/sblgnt

## Yields:

* Each word in the GNT tagged with the Duff chapters for the vocabulary and for the parsing

## Can be used to calculate:

* Lists of readable verses after each chapter of Duff
* Occurring inflections (parsings) not covered in Duff
