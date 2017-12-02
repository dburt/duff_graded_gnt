# Greek New Testament graded against Duff's Elements of New Testament Greek

## Quiz

A Greek-English and English-Greek quiz based on verses readable after a given chapter of Duff.

* Command-line (relies on Mac's `say` command for speech but can easily be changed to use `espeak`): `./quiz.rb`
* Sinatra web app: `rackup`

## Graded Reader Document

* Loads GNT as submodule, so `git submodule update --init`.
* Usable as a Ruby library with `require`, providing Duff parsing by chapter.
* When run as a command, copies whole parsed GNT with required Duff chapters added for each word to morphgnt_duff.csv, and readable whole verses for each chapter to reader_duff.md.

### Sources:

* Duff vocab: http://www.denisowski.org/NT_Greek/EONTG/EONTG.html
* Duff parsing by chapter: derived by author
* Morphologically tagged Greek New Testament: https://github.com/morphgnt/sblgnt

### Yields:

* Each word in the GNT tagged with the Duff chapters for the vocabulary and for the parsing (morphgnt_duff.csv)
* A graded reader formatted in markdown (reader_duff.md)

### Can be used to calculate:

* Lists of readable verses after each chapter of Duff
* Occurring inflections (parsings) not covered in Duff

