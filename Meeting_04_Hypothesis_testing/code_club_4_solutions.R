# =============================================================================
# Code Club 4: Exercise Solutions
# =============================================================================

library(tidyverse)
library(ggpubr)
library(rstatix)
library(car)
library(multcomp)


# =============================================================================
# DATA
# =============================================================================

set.seed(42)

tablets <- data.frame(
  content = c(rnorm(30, mean = 200, sd = 3.2),
              rnorm(30, mean = 204, sd = 4.5)),
  line    = rep(c("A", "B"), each = 30)
)

bp_before <- rnorm(25, mean = 148, sd = 12)
bp <- data.frame(
  id   = rep(1:25, 2),
  time = factor(rep(c("Before", "After"), each = 25),
                levels = c("Before", "After")),
  bp   = c(
    bp_before,
    bp_before - rnorm(25, mean = 5, sd = 4)
  )
)

release <- data.frame(
  pct_released = c(rnorm(20, 72, 4), rnorm(20, 78, 4),
                   rnorm(20, 68, 4), rnorm(20, 82, 4)),
  formulation  = factor(rep(c("A", "B", "C", "D"), each = 20))
)

set.seed(7)
analgesic <- data.frame(
  pain_score = c(rnorm(15, mean = 65, sd = 10),
                 rnorm(15, mean = 48, sd = 10),
                 rnorm(15, mean = 52, sd = 10),
                 rnorm(15, mean = 61, sd = 10)),
  group = factor(rep(c("Control", "Drug X", "Drug Y", "Drug Z"), each = 15),
                 levels = c("Control", "Drug X", "Drug Y", "Drug Z"))
)


# =============================================================================
# EXERCISE 1 — Assumption checking
# =============================================================================

# --- Normality: Q-Q plot ---
# Points should fall roughly along the diagonal line
# Deviations at the tails indicate non-normality
ggqqplot(tablets, x = "content", facet.by = "line")

# --- Normality: Shapiro-Wilk test ---
# H0: data is normally distributed
# A non-significant p-value means no evidence against normality —
# it does NOT prove the data is normal, just that we can't reject H0
# Unreliable for n > 50: small samples have low power to detect non-normality,
# large samples detect trivially small deviations — always combine with Q-Q plot
tablets %>%
  group_by(line) %>%
  shapiro_test(content)

# --- Equal variances: Levene's test ---
# H0: variances are equal across groups
# p > 0.05 here -> no evidence of unequal variances -> either test is fine
# p < 0.05 -> variances differ -> use Welch's t-test (the default in R)
leveneTest(content ~ line, data = tablets)

# With these data: Shapiro-Wilk is non-significant for both groups and
# Levene's test is non-significant -> assumptions are met -> Welch or
# Student's t-test are both appropriate. Welch is still the safer default.


# =============================================================================
# EXERCISE 2 — ANOVA plot in plain ggplot2
# =============================================================================

res_aov <- release %>% anova_test(pct_released ~ formulation)
pwc     <- release %>%
  tukey_hsd(pct_released ~ formulation) %>%
  add_xy_position(x = "formulation")

ggplot(release, aes(x = formulation, y = pct_released, fill = formulation)) +
  geom_boxplot() +
  geom_jitter(width = 0.15) +
  stat_pvalue_manual(pwc, hide.ns = TRUE, step.increase = 0.05) +
  theme_classic() +
  theme(legend.position = "none") +
  labs(
    x        = "Formulation",
    y        = "Drug Release at 30 min (%)",
  )


# =============================================================================
# EXERCISE 3 — Dunnett's test
# =============================================================================

# Steps 1-4 are provided in the exercise sheet — reproduced here for completeness

ggplot(analgesic, aes(x = group, y = pain_score, fill = group)) +
  geom_boxplot(alpha = 0.7) +
  geom_jitter(width = 0.15, alpha = 0.5) +
  theme_classic() +
  labs(x = NULL, y = "Pain Score (VAS 0-100)")

aov_analgesic <- aov(pain_score ~ group, data = analgesic)
summary(aov_analgesic)

dunnett_res  <- glht(aov_analgesic, linfct = mcp(group = "Dunnett"))
dunnett_summ <- summary(dunnett_res)
dunnett_summ

dunnett_df <- data.frame(
  group1 = "Control",
  group2 = gsub(" - Control", "", names(dunnett_summ$test$coefficients)),
  p.adj  = dunnett_summ$test$pvalues
) %>%
  mutate(p.adj.signif = case_when(
    p.adj < 0.001 ~ "***",
    p.adj < 0.01  ~ "**",
    p.adj < 0.05  ~ "*",
    TRUE          ~ "ns"
  )) %>%
  add_xy_position(data    = analgesic,
                  formula = pain_score ~ group,
                  x       = "group")

# --- Step 5: plot ---
ggboxplot(analgesic, x = "group", y = "pain_score",
          fill = "group", add = "jitter", legend = "none",
          xlab = NULL, ylab = "Pain Score (VAS 0-100)") +
  stat_pvalue_manual(dunnett_df, label = "p.adj.signif",
                     hide.ns = TRUE, step.increase = 0.05) +
  labs(caption = "Dunnett's test vs. Control")

# Drug X (p < 0.05) and Drug Y (p < 0.05) are significantly different from
# control. Drug Z is not — its mean is close to control and the CI overlaps.
# This matches the visual impression from the boxplot.

# --- Bonus: compare with Tukey ---
# Tukey tests all 6 pairs; Dunnett tests only 3 (vs. control).
# Dunnett is more powerful for this specific question — if a borderline result
# exists, Dunnett may flag it while Tukey does not.
analgesic %>%
  tukey_hsd(pain_score ~ group) %>%
  filter(group1 == "Control" | group2 == "Control")
# Compare p.adj values to dunnett_df$p.adj — Dunnett's are slightly smaller


# =============================================================================
# EXERCISE 4 — Built-in dataset example: sleep (paired t-test)
# =============================================================================
# The sleep dataset records extra hours of sleep gained with two soporific drugs
# (drug 1 and drug 2) in 10 patients — a classic paired design

data(sleep)
?sleep

# Visualise
ggpaired(sleep, x = "group", y = "extra", id = "ID",
         fill = "group", line.color = "gray60",
         xlab = "Drug", ylab = "Extra Sleep (hours)") +
  stat_compare_means(method = "t.test", paired = TRUE,
                     comparisons = list(c("1", "2")),
                     label = "p.format")

# Paired t-test
sleep %>% t_test(extra ~ group, paired = TRUE)

# Interpretation: Drug 2 produces significantly more extra sleep than Drug 1.
# The paired design is appropriate because the same 10 patients received both drugs.


# =============================================================================
# EXERCISE 5 — Two-way ANOVA
# =============================================================================

set.seed(42)
release_2way <- data.frame(
  pct_released = c(
    rnorm(10, 72, 4), rnorm(10, 68, 4),
    rnorm(10, 78, 4), rnorm(10, 73, 4),
    rnorm(10, 68, 4), rnorm(10, 64, 4),
    rnorm(10, 82, 4), rnorm(10, 70, 4)
  ),
  formulation = factor(rep(rep(c("A","B","C","D"), each = 10), 2)),
  medium      = factor(rep(c("pH 6.8", "pH 1.2"), each = 40))
)

# --- Task 1: visualise ---
# Faceted boxplot
ggplot(release_2way, aes(x = formulation, y = pct_released,
                          fill = formulation)) +
  geom_boxplot(alpha = 0.7) +
  geom_jitter(width = 0.15, alpha = 0.5) +
  facet_wrap(~ medium) +
  theme_classic() +
  theme(legend.position = "none") +
  labs(x = "Formulation", y = "Drug Release at 30 min (%)")

# Interaction plot — easier to see whether lines are parallel or crossing
ggline(release_2way, x = "formulation", y = "pct_released",
       color = "medium", add = "mean_se",
       xlab = "Formulation", ylab = "Drug Release at 30 min (%)")
# Parallel lines would indicate no interaction — crossing lines indicate one

# --- Task 2: two-way ANOVA ---
res_2way <- release_2way %>%
  anova_test(pct_released ~ formulation * medium)
res_2way

# --- Task 3: interpret ---
# formulation:   p < 0.05 -> significant main effect
# medium:        p > 0.05 -> non-significant main effect
# formulation:medium interaction: check p value
#
# If the interaction is NOT significant:
# interpret main effects directly — formulation and medium each independently
# affect drug release, and the effect of formulation is consistent regardless
# of which medium was used.
#
# If the interaction WERE significant, you would need to break it down:
release_2way %>%
  group_by(medium) %>%
  anova_test(pct_released ~ formulation)
# This runs a separate one-way ANOVA for each medium level, letting you see
# whether the formulation effect holds within each medium independently
