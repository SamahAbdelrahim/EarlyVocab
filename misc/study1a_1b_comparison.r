# Study 1A vs 1B Comparison and Reliability Analysis
# ==================================================

library(tidyverse)
library(lme4)
library(lmerTest)
library(psych)
library(irr)
library(ggplot2)
library(corrr)
library(broom)
library(effectsize)
library(patchwork)

# Load your data (adjust file paths as needed)
study1a_data <- read_csv(here("data/predictors","study1a_data.csv"))

#fix names of columns
study1a_data <- study1a_data %>%
  rename(participant_id = `_id`)

study1b_data <-  read_csv(here("data/predictors","study1b_data.csv"))
study1b_data <- study1b_data %>%
  rename(participant_id = `_id`)


# 1. DATA PREPARATION
# ===================

# Combine datasets with study identifier
combined_data <- bind_rows(
  study1a_data %>% 
    select(participant_id, uni_lemma, language, shape_rating) %>%
    mutate(study = "1A"),
  study1b_data %>% 
    select(participant_id, uni_lemma, language, shape_rating) %>%
    mutate(study = "1B")
) %>%
  filter(!is.na(shape_rating))  # Remove missing values

# Create wide format for reliability analysis
ratings_wide <- combined_data %>%
  pivot_wider(names_from = study, 
              values_from = shape_rating,
              names_prefix = "Study_") %>%
  filter(!is.na(Study_1A) & !is.na(Study_1B))  # Only words rated in both studies

# 2. DESCRIPTIVE STATISTICS
# =========================

# Summary statistics by study
descriptive_stats <- combined_data %>%
  group_by(study) %>%
  summarise(
    n_ratings = n(),
    n_words = n_distinct(uni_lemma),
    n_participants = n_distinct(participant_id),
    mean_rating = mean(shape_rating, na.rm = TRUE),
    sd_rating = sd(shape_rating, na.rm = TRUE),
    median_rating = median(shape_rating, na.rm = TRUE),
    q25 = quantile(shape_rating, 0.25, na.rm = TRUE),
    q75 = quantile(shape_rating, 0.75, na.rm = TRUE),
    .groups = "drop"
  )

print("Descriptive Statistics by Study:")
print(descriptive_stats)

# Summary by language and study
descriptive_by_language <- combined_data %>%
  group_by(study, language) %>%
  summarise(
    n_ratings = n(),
    mean_rating = mean(shape_rating, na.rm = TRUE),
    sd_rating = sd(shape_rating, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  pivot_wider(names_from = study, 
              values_from = c(mean_rating, sd_rating),
              names_sep = "_Study_")

print("Descriptive Statistics by Language:")
print(descriptive_by_language)

# 3. RELIABILITY ANALYSIS
# =======================

# Test-retest reliability (Pearson correlation)
overall_reliability <- cor.test(ratings_wide$Study_1A, 
                               ratings_wide$Study_1B, 
                               use = "complete.obs")

print(paste("Overall Test-Retest Reliability (r):", 
            round(overall_reliability$estimate, 3)))
print(paste("95% CI:", 
            round(overall_reliability$conf.int[1], 3), "to", 
            round(overall_reliability$conf.int[2], 3)))

# Intraclass Correlation Coefficient (ICC)
icc_data <- ratings_wide %>%
  select(Study_1A, Study_1B) %>%
  as.matrix()

icc_results <- ICC(icc_data)
print("Intraclass Correlation Coefficients:")
print(icc_results)

# Reliability by language
reliability_by_language <- ratings_wide %>%
  group_by(language) %>%
  summarise(
    n_words = n(),
    correlation = cor(Study_1A, Study_1B, use = "complete.obs"),
    .groups = "drop"
  ) %>%
  arrange(desc(correlation))

print("Test-Retest Reliability by Language:")
print(reliability_by_language)

# 4. STATISTICAL COMPARISON
# =========================

# Mixed-effects model comparing studies
comparison_model <- lmer(shape_rating ~ study + 
                        (1 | uni_lemma) + 
                        (1 | language),
                        data = combined_data)

summary(comparison_model)

# Effect size for study difference
study_effect <- eta_squared(comparison_model, partial = TRUE)
print("Effect size for study difference:")
print(study_effect)

# Paired t-test on word-level means
word_means <- combined_data %>%
  group_by(uni_lemma, study) %>%
  summarise(mean_rating = mean(shape_rating, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = study, values_from = mean_rating) %>%
  filter(!is.na(`1A`) & !is.na(`1B`))

paired_test <- t.test(word_means$`1A`, word_means$`1B`, paired = TRUE)
print("Paired t-test results:")
print(paired_test)

# Cohen's d for the difference
cohens_d_result <- cohens_d(word_means$`1A`, word_means$`1B`, paired = TRUE)
print(paste("Cohen's d:", round(cohens_d_result$Cohens_d, 3)))

# 5. LANGUAGE-SPECIFIC ANALYSIS
# =============================

# Test for study × language interaction
interaction_model <- lmer(shape_rating ~ study * language + 
                         (1 | uni_lemma),
                         data = combined_data)

# Compare models
model_comparison <- anova(comparison_model, interaction_model)
print("Model comparison (study main effect vs study × language interaction):")
print(model_comparison)

# If interaction is significant, examine by language
if (model_comparison$`Pr(>Chisq)`[2] < 0.05) {
  library(emmeans)
  
  study_by_language <- emmeans(interaction_model, ~ study | language)
  language_contrasts <- contrast(study_by_language, "pairwise")
  
  print("Study differences by language:")
  print(language_contrasts)
}

# 6. AGREEMENT AND CONSISTENCY ANALYSIS
# ====================================

# Bland-Altman analysis
bland_altman_data <- ratings_wide %>%
  mutate(
    mean_rating = (Study_1A + Study_1B) / 2,
    diff_rating = Study_1B - Study_1A
  )

# Calculate limits of agreement
mean_diff <- mean(bland_altman_data$diff_rating, na.rm = TRUE)
sd_diff <- sd(bland_altman_data$diff_rating, na.rm = TRUE)
upper_loa <- mean_diff + 1.96 * sd_diff
lower_loa <- mean_diff - 1.96 * sd_diff

print("Bland-Altman Analysis:")
print(paste("Mean difference:", round(mean_diff, 3)))
print(paste("95% Limits of Agreement:", 
            round(lower_loa, 3), "to", round(upper_loa, 3)))

# 7. VISUALIZATIONS
# =================

# Plot 1: Scatterplot of Study 1A vs 1B ratings
p1 <- ggplot(ratings_wide, aes(x = Study_1A, y = Study_1B)) +
  geom_point(alpha = 0.6) +
  geom_smooth(method = "lm", se = TRUE, color = "blue") +
  geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "red") +
  labs(title = "Test-Retest Reliability: Study 1A vs 1B",
       subtitle = paste("r =", round(overall_reliability$estimate, 3)),
       x = "Study 1A Shape Rating",
       y = "Study 1B Shape Rating") +
  theme_minimal() +
  coord_fixed()

# Plot 2: Distribution comparison
p2 <- ggplot(combined_data, aes(x = shape_rating, fill = study)) +
  geom_density(alpha = 0.7) +
  geom_vline(data = descriptive_stats, 
             aes(xintercept = mean_rating, color = study),
             linetype = "dashed", size = 1) +
  labs(title = "Distribution of Shape Ratings by Study",
       x = "Shape Rating",
       y = "Density") +
  theme_minimal() +
  scale_fill_brewer(type = "qual", palette = "Set1")

# Plot 3: Bland-Altman plot
p3 <- ggplot(bland_altman_data, aes(x = mean_rating, y = diff_rating)) +
  geom_point(alpha = 0.6) +
  geom_hline(yintercept = mean_diff, color = "blue") +
  geom_hline(yintercept = c(upper_loa, lower_loa), 
             color = "red", linetype = "dashed") +
  labs(title = "Bland-Altman Plot",
       subtitle = paste("Mean difference =", round(mean_diff, 3)),
       x = "Mean Rating [(1A + 1B) / 2]",
       y = "Difference (1B - 1A)") +
  theme_minimal()

# Plot 4: Language-specific comparison
p4 <- ggplot(combined_data, aes(x = study, y = shape_rating, fill = study)) +
  geom_violin(alpha = 0.7) +
  geom_boxplot(width = 0.2, alpha = 0.8) +
  stat_summary(fun = mean, geom = "point", size = 2, color = "red") +
  facet_wrap(~ language, scales = "free_y") +
  labs(title = "Shape Ratings by Study and Language",
       x = "Study",
       y = "Shape Rating") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  scale_fill_brewer(type = "qual", palette = "Set1")

# Combine plots
combined_plots <- (p1 + p2) / (p3 + p4)
print(combined_plots)

# 8. SUMMARY INTERPRETATION
# ========================

cat("\n=== SUMMARY INTERPRETATION ===\n")

# Reliability interpretation
reliability_interpretation <- case_when(
  overall_reliability$estimate >= 0.9 ~ "Excellent reliability",
  overall_reliability$estimate >= 0.8 ~ "Good reliability",
  overall_reliability$estimate >= 0.7 ~ "Acceptable reliability",
  overall_reliability$estimate >= 0.6 ~ "Questionable reliability",
  TRUE ~ "Poor reliability"
)

cat("1. Test-Retest Reliability:", reliability_interpretation, 
    paste0("(r = ", round(overall_reliability$estimate, 3), ")\n"))

# Effect size interpretation
effect_size_interpretation <- case_when(
  abs(cohens_d_result$Cohens_d) < 0.2 ~ "negligible",
  abs(cohens_d_result$Cohens_d) < 0.5 ~ "small",
  abs(cohens_d_result$Cohens_d) < 0.8 ~ "medium",
  TRUE ~ "large"
)

cat("2. Study Difference:", effect_size_interpretation, "effect size",
    paste0("(d = ", round(cohens_d_result$Cohens_d, 3), ")\n"))

# Statistical significance
if (paired_test$p.value < 0.05) {
  cat("3. Statistical Significance: Significant difference between studies (p =", 
      round(paired_test$p.value, 4), ")\n")
} else {
  cat("3. Statistical Significance: No significant difference between studies (p =", 
      round(paired_test$p.value, 3), ")\n")
}

cat("4. Number of words with reliable ratings:", nrow(ratings_wide), 
    "out of", length(unique(combined_data$uni_lemma)), "total words\n")

# 9. RECOMMENDATIONS FOR MANUSCRIPT
# ================================

cat("\n=== RECOMMENDATIONS FOR MANUSCRIPT ===\n")
cat("- Report the test-retest reliability coefficient in your results\n")
cat("- Include the Bland-Altman analysis if there are systematic differences\n")
cat("- Discuss any language-specific patterns in reliability\n")
cat("- Address whether the improved instructions in 1B changed the results\n")
cat("- Consider using the average of 1A and 1B ratings for subsequent analyses\n")