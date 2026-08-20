## Permutation test for cross-linguistic shape-organization differences.
##
## Given a long-format ratings data frame with columns `uni_lemma`,
## `language`, `response`, and `proportion`, this script returns the
## observed per-language shape-density curves and a per-language null
## envelope obtained by permuting language labels n_perm times. The same
## procedure is used for English Sample 1 (Study 1A) and English Sample 2
## (Study 1B) by passing the corresponding data frame.
##
## Usage (inside a knitted Rmd):
##   source(here::here("analysis", "permutation_test.R"))
##   res <- run_shape_permutation(english_sample1, response_label = "shape",
##                                n_perm = 500, seed = 123)
##   res$obs_density_df    # observed density per language
##   res$null_envelopes    # 95 percent null envelope per language
##
## The companion knitr chunk in writeup/manuscript.Rmd renders Figure
## permutateddisteng1 from these objects without re-running by hand.

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(purrr)
})

get_density_on_grid <- function(x_values, grid_x) {
  x_vals <- x_values[!is.na(x_values)]
  if (length(unique(x_vals)) < 2) {
    return(rep(0, length(grid_x)))
  }
  d <- density(x_vals, from = 0, to = 1, n = length(grid_x))
  approx(d$x, d$y, xout = grid_x, rule = 2)$y
}

shape_prop_by_item <- function(ratings_df, item_col = "word") {
  ratings_df %>%
    filter(block == "category_organization") %>%
    distinct(.data[[item_col]], matching_response, proportion) %>%
    group_by(.data[[item_col]]) %>%
    summarise(
      shape_prop = proportion[matching_response == "shape"][1],
      .groups = "drop"
    ) %>%
    mutate(shape_prop = replace_na(shape_prop, 0))
}

compute_observed_densities <- function(df, grid_x) {
  df %>%
    group_by(language) %>%
    summarize(dens = list(get_density_on_grid(proportion, grid_x)),
              .groups = "drop") %>%
    unnest_longer(dens, values_to = "density") %>%
    group_by(language) %>%
    mutate(x = grid_x) %>%
    ungroup()
}

one_permuted_densities <- function(df, grid_x) {
  df %>%
    mutate(language = sample(language)) %>%
    compute_observed_densities(grid_x = grid_x)
}

run_shape_permutation <- function(ratings_df,
                                  response_label = "shape",
                                  n_perm = 500,
                                  seed = 123,
                                  grid_n = 100,
                                  item_col = "word",
                                  all_words = FALSE) {
  set.seed(seed)
  if (all_words) {
    shape_df <- shape_prop_by_item(ratings_df, item_col = item_col) %>%
      left_join(
        ratings_df %>%
          filter(block == "category_organization") %>%
          distinct(.data[[item_col]], language),
        by = item_col
      ) %>%
      rename(uni_lemma = .data[[item_col]], proportion = shape_prop)
  } else {
    shape_df <- ratings_df %>%
      filter(response == response_label) %>%
      replace_na(list(proportion = 0)) %>%
      select(uni_lemma, language, proportion)
  }

  grid_x <- seq(0, 1, length.out = grid_n)

  obs_density_df <- compute_observed_densities(shape_df, grid_x)

  perm_densities <- map_dfr(seq_len(n_perm), function(i) {
    one_permuted_densities(shape_df, grid_x) %>%
      mutate(perm = i)
  })

  null_envelopes <- perm_densities %>%
    group_by(language, x) %>%
    summarize(lower = quantile(density, 0.025),
              upper = quantile(density, 0.975),
              .groups = "drop")

  list(obs_density_df = obs_density_df,
       null_envelopes = null_envelopes,
       perm_densities = perm_densities,
       n_perm = n_perm,
       seed = seed)
}
