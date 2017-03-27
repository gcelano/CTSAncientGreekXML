[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.438311.svg)](https://doi.org/10.5281/zenodo.438311)
# Tokenized CTSized Ancient Greek Texts (v1.1.0)

This repository contains the graphic-word tokenized texts of the following two repositories (I also provide them in zipped format):

* https://github.com/PerseusDL/canonical-greekLit
* https://github.com/OpenGreekAndLatin/First1KGreek

The texts have been generated completely automatically from the original XML files which are well-formed and CTS-compliant (some are not). Some conversion errors are already known to be ascribable to annotation inconsistencies/errors in the original files (which errors I have not tried to solve). For example, an inconsistent cts-urn location in the xml file or lack of numeration for each verse in a poem will generate errors (typically missing text). 

Check the XQuery module in the ```scripts``` folder for details.

Each file contains the following information: 

* the ```@p``` attribute lists the passage (the full cts urn derives from merging this value and the cts urn of the text in the ```@text-cts``` attribute in the text element)
* the ```@n``` attribute shows the running number id for each word (numeration starts again as the passage changes)
* the ```text()``` of each ```t``` element contains the word form
* the optional ```@join``` attribute specifies whether a punctuation mark should be attached to either the preceding (b) or the following (a) word.
* the optional ```@tag``` element shows some special elements which contained the given word: more precisely, the ```add```, ```del```, ```unclear```, ```surplus```, ```supplied``` and ```seg``` elements, which can be of interest to identify editorial interventions. 

# Cite
Cite the following work thus:

* Giuseppe G. A. Celano. (2017). Tokenized CTSized Ancient Greek texts v1.1.0 [Data set]. Zenodo. http://doi.org/10.5281/zenodo.401372

# License
<a rel="license" href="http://creativecommons.org/licenses/by-nc/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-nc/4.0/88x31.png" /></a><br />This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-nc/4.0/">Creative Commons Attribution-NonCommercial 4.0 International License</a>.
