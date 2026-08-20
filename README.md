# Lexical statistics in early noun vocabularies

Cross-linguistic study of the **shape bias** and the *statistical generalization* account: do the lexical statistics of early-learned nouns (solidity, count/mass syntax, shape-based organization) explain why children learning different languages show different shape biases?

This repository contains the data, analysis code, and manuscript for a project that:

1. Collects adult ratings on early-learned nouns sourced from the [Wordbank](https://wordbank.stanford.edu) MCDI repository in 16 languages, judged on three dimensions: **solidity**, **count/mass syntax**, and **organizing feature** (shape, color, material, none). [Studies 1A, 1B]
2. Replicates those ratings with a Korean-speaking sample (both online and in-country) to test rater-origin effects. [Studies 2A, 2B]
3. Uses the resulting shape ratings to predict the **age of acquisition (AoA)** of those words from Wordbank, controlling for word frequency, concreteness, solidity, and countability. [Study 3]

The headline findings are: shape-organized categories are **not** numerically dominant in early lexicons, yet shape uniquely predicts earlier acquisition above and beyond frequency and concreteness, and Korean adult ratings of shape are *higher* not lower than English.

## Repository layout

```
.
├── analysis/permutation_test.R  # sourced by the manuscript at knit time
├── data/
│   ├── ratings/      # word lists and mappings used by the Rmds
│   ├── predictors/   # processed files used by the manuscript and supplement
│   ├── demographics/ # participant demographics (local only)
│   └── figures/      # exported figures (knitr also writes here)
├── experiment files/ # jsPsych HTML/JS for Studies 1A & 2A (see Supplement + below)
├── writeup/
│   ├── manuscript.Rmd
│   ├── supplementary_materials.Rmd
│   ├── manuscript.pdf
│   ├── r-references.bib
│   ├── meta-shapebias.bib
│   └── apa6.csl
├── helper.R
├── renv.lock
└── README.md
```

## Reproducing the manuscript

Prerequisites:

- R (>= 4.2)
- A LaTeX distribution capable of building APA papers (TinyTeX or MacTeX)
- The R packages declared in `renv.lock` — restore them with:

  ```r
  install.packages("renv")
  renv::restore()
  ```

To build the manuscript:

```r
rmarkdown::render("writeup/manuscript.Rmd")
```

This will produce `writeup/manuscript.pdf` using the `papaja` APA template.

## Experiment implementations (jsPsych)

The folder [`experiment files/`](experiment%20files/) holds the **exact** browser tasks for **Study 1A** (`solidity-ratings.html` + `solidity-ratings.js`) and **Study 2A** (`vocab_comp.html`, `vocab_comp.js`, and `words.js`). The Supplementary Materials PDF describes trial structure and how these files relate to the manuscript; open the HTML files locally to inspect instructions and trial flow (classic scripts work from `file://`).

> **Note:** The jsPsych library and stimulus images are excluded from this repository (gitignored) to keep the repo size manageable. To run the experiments locally, download [jsPsych](https://www.jspsych.org) and place the `jspsych/` folder and `images/` folder inside `experiment files/`, matching the paths referenced in the HTML and JS files.

## Data

Processed, ready-to-use rating files live in `data/predictors/` (e.g. `english_sample1_props.csv`, `korean_sample1_props.csv`, `ratings_aoa.csv`, `reliability_long_alldata.csv`).

Raw per-trial response files live in `data/ratings/`.

Participant-level demographics are kept locally and excluded from version control via `.gitignore`.

## Contact

The corresponding author can be found in the manuscript front matter ([`writeup/manuscript.Rmd`](writeup/manuscript.Rmd)).
