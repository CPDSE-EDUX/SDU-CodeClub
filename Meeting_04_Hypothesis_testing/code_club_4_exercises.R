# =============================================================================
# Code Club 4: Exercises
# =============================================================================
# These exercises are intentionally open-ended — the goal is to explore,
# make mistakes, and figure things out. Use the main script as a reference,
# and don't hesitate to ask questions or look things up.
#
# Useful resources:
#   - rstatix documentation:  https://rpkgs.datanovia.com/rstatix/
#   - ggpubr documentation:   https://rpkgs.datanovia.com/ggpubr/
#   - ANOVA in R (datanovia): https://www.datanovia.com/en/lessons/anova-in-r/
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

# --- Tablet content (mg): two production lines, target = 200 mg ---
tablets <- data.frame(
  content = c(rnorm(30, mean = 200, sd = 3.2),
              rnorm(30, mean = 204, sd = 4.5)),
  line    = rep(c("A", "B"), each = 30)
)

# --- Blood pressure (mmHg): 25 patients before and after treatment ---
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

# --- Drug release (% released at 30 min): four tablet formulations ---
release <- data.frame(
  pct_released = c(rnorm(20, 72, 4), rnorm(20, 78, 4),
                   rnorm(20, 68, 4), rnorm(20, 82, 4)),
  formulation  = factor(rep(c("A", "B", "C", "D"), each = 20))
)

# Analgesic study: pain score (0-100 VAS) in control vs. three drugs
# Lower score = less pain
set.seed(7)
analgesic <- data.frame(
  pain_score = c(rnorm(15, mean = 65, sd = 10),   # Control (vehicle)
                 rnorm(15, mean = 48, sd = 10),   # Drug X
                 rnorm(15, mean = 52, sd = 10),   # Drug Y
                 rnorm(15, mean = 61, sd = 10)),  # Drug Z
  group = factor(rep(c("Control", "Drug X", "Drug Y", "Drug Z"), each = 15),
                 levels = c("Control", "Drug X", "Drug Y", "Drug Z"))
  # Control is the first level — important for Dunnett's test
)


# =============================================================================
# EXERCISE 1 — Assumption checking
# =============================================================================
# Before running a two-sample t-test, it is good practice to check:
#   (a) Are the data approximately normally distributed?
#   (b) Are the variances equal between groups?
#
# Your task: run the assumption checks for the tablets dataset
#
# For normality:
#   - Visual check: make a qqplot using ggqqplot() from ggpubr — try the facet.by argument
#   - Formal test: shapiro_test() from rstatix — use group_by() first
#   - What does a non-significant Shapiro-Wilk result mean?
#   - Why shouldn't you rely on Shapiro-Wilk alone?
#
# For equal variances:
#   - leveneTest() from the car package
#   - Based on the result: should you use Welch or Student's t-test?


# =============================================================================
# EXERCISE 2 — ANOVA plot in plain ggplot2
# =============================================================================
# In the main script the ANOVA plot was built using ggpubr.
# Reproduce it using only ggplot2 — stat_pvalue_manual() works the same way.
#
# The Tukey results are computed for you below. Your task is to build the plot.

res_aov <- release %>% anova_test(pct_released ~ formulation)
pwc     <- release %>%
  tukey_hsd(pct_released ~ formulation) %>%
  add_xy_position(x = "formulation")

# Hint: geom_boxplot() + geom_jitter() + stat_pvalue_manual() + theme_classic()


# =============================================================================
# EXERCISE 3 — Dunnett's test
# =============================================================================
# The analgesic dataset compares three drugs against a vehicle control.
# We only care whether each drug differs from control — not from each other.
# This is exactly the situation where Dunnett's test is appropriate.
#
# The code below runs the full pipeline — work through it step by step,
# make sure you understand what each part does, and then build the plot yourself.

# Step 1: visualise the data first
ggplot(analgesic, aes(x = group, y = pain_score, fill = group)) +
  geom_boxplot(alpha = 0.7) +
  geom_jitter(width = 0.15, alpha = 0.5) +
  theme_classic() +
  labs(x = NULL, y = "Pain Score (VAS 0-100)")

# Step 2: run ANOVA — is there any overall group difference?
aov_analgesic <- aov(pain_score ~ group, data = analgesic)
summary(aov_analgesic)

# Step 3: Dunnett's test via multcomp
# glht() = generalised linear hypothesis test
# mcp()  = multiple comparison procedure
# "Dunnett" compares all groups to the FIRST factor level (Control here)
dunnett_res  <- glht(aov_analgesic, linfct = mcp(group = "Dunnett"))
dunnett_summ <- summary(dunnett_res)
dunnett_summ

# Step 4: extract results into a tidy data frame for plotting
dunnett_df <- data.frame(
  group1 = "Control",
  group2 = gsub(" - Control", "",
                names(dunnett_summ$test$coefficients)),
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

# Step 5: your task — build the plot using ggboxplot() or ggplot() and
# stat_pvalue_manual() with the dunnett_df results
#
# Questions to consider:
#   - Which drugs are significantly different from control?
#   - Does this match what you expected from the visualisation in Step 1?
#   - How would the result differ if you had used Tukey instead of Dunnett?
#     Try it: release %>% tukey_hsd(pain_score ~ group) — do any conclusions change?


# =============================================================================
# EXERCISE 4 — Apply to your own data
# =============================================================================
# Find a dataset you have worked with previously — from a course, lab report,
# or your own research — and apply one of the tests from today's session.
#
# Some questions to guide you:
#   - What is your research question?
#   - Which test is appropriate and why? (one-sample, two-sample, paired, ANOVA)
#   - If ANOVA: which post-hoc test makes sense — Tukey or Dunnett?
#   - Check the assumptions — do they hold?
#   - Make a plot with significance annotations
#
# If you don't have your own data, try one of R's built-in datasets:
#   - PlantGrowth  (one-way ANOVA — control + two treatments)
#   - ToothGrowth  (two-way ANOVA — dose and supplement type)
#   - sleep        (paired t-test — two sleep drugs, same subjects)
#
# To explore: data(PlantGrowth); ?PlantGrowth


# =============================================================================
# EXERCISE 5 (stretch) — Two-way ANOVA
# =============================================================================
# We extend the drug release experiment by adding a second factor:
# dissolution medium (phosphate buffer pH 6.8 vs. simulated gastric fluid pH 1.2).
# Different media mimic different environments in the GI tract.
#
# Questions to answer:
#   - Does dissolution medium affect drug release?
#   - Does formulation affect drug release?
#   - Do dissolution medium and formulation INTERACT?
#     i.e. does the effect of formulation depend on which medium it was tested in?

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

# Task 1: visualise the data
# Hint: try fill = formulation and facet_wrap(~ medium)
# Or try an interaction plot:
#   ggline(release_2way, x = "formulation", y = "pct_released",
#          color = "medium", add = "mean_se")
# Parallel lines suggest no interaction — crossing lines suggest one

# Task 2: run a two-way ANOVA
# Hint: anova_test(pct_released ~ formulation * medium)
# The * fits both main effects AND the interaction term

# Task 3: interpret the output
# - Is the interaction term significant?
# - If YES: the main effects alone are misleading — you need to break down
#   the interaction by looking at each formulation separately within each medium
#   Hint: group_by(medium) %>% anova_test(pct_released ~ formulation)
# - If NO: interpret the main effects directly