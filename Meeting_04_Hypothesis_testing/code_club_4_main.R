# =============================================================================
# Code Club 4: Hypothesis Testing in R
# =============================================================================
# Topics: one-sample, two-sample, paired t-test | one-way ANOVA + Tukey
#         ggplot2 vs. ggpubr | stat_pvalue_manual
# Packages: tidyverse, ggpubr, rstatix
# =============================================================================

# install.packages(c("tidyverse", "ggpubr", "rstatix"))

library(tidyverse)
library(ggpubr)
library(rstatix)


# =============================================================================
# 1. SIMULATE DATA
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

# =============================================================================
# 2. QUICK DATA VISUALISATION
# =============================================================================

# Tablet content — two lines
ggplot(tablets, aes(x = line, y = content, fill = line)) +
  geom_boxplot() +
  geom_jitter(width = 0.15) +
  labs(x = "Production Line", y = "Tablet Content (mg)") +
  theme_classic()

# Blood pressure — before vs. after
ggplot(bp, aes(x = time, y = bp, group = id)) +
  geom_line(alpha = 0.3, color = "gray50") +
  geom_point(aes(color = time), size = 2) +
  labs(x = NULL, y = "Blood Pressure (mmHg)") +
  theme_classic()

# Drug release — four formulations
ggplot(release, aes(x = formulation, y = pct_released, fill = formulation)) +
  geom_boxplot() +
  geom_jitter(width = 0.15) +
  labs(x = "Formulation", y = "Drug Release at 30 min (%)") +
  theme_classic()


# =============================================================================
# 3. T-TESTS  (rstatix)
# =============================================================================
# rstatix returns tidy data frames — easy to read and pipe into plots
# Key assumption: approximate normality; for two-sample also equal variances
# (assumption checks are covered in the exercises)

# --- One-sample: does line A meet the 200 mg target? ---
# Using the t_test() function (rstatix)
tablets %>%
  filter(line == "A") %>%
  t_test(content ~ 1, mu = 200)

# This how it would look using the t.test() function (base R)
tablets %>%
  filter(line == "A") %>%
  select(content) %>%
  t.test(mu = 200)

# --- Two-sample: do lines A and B differ? ---
# Welch's t-test (default) — does NOT assume equal variances; recommended
# Two-sided (default) - is the mean of A different from B (higher or lower)
tablets %>% 
  t_test(content ~ line, alternative = "two.sided")

# One sided - is the mean of A greater or less than B
tablets %>% 
  t_test(content ~ line, alternative = "greater") # asks: is A greater than B?

tablets %>% 
  t_test(content ~ line, alternative = "less")# asks: is A less than B?

# Student's t-test — assumes equal variances; use only if justified
tablets %>% 
  t_test(content ~ line, var.equal = TRUE)

# --- Paired: did blood pressure change after treatment? ---
# paired = TRUE accounts for the within-patient structure
# Ignoring pairing (paired = FALSE) loses power — try both and compare
bp %>% 
  t_test(bp ~ time, paired = TRUE)


# =============================================================================
# 4. ONE-WAY ANOVA + TUKEY POST-HOC  (rstatix)
# =============================================================================
# ANOVA: is there any difference across the four formulations?
# H0: all group means are equal

res_aov <- release %>%
  anova_test(pct_released ~ formulation)
res_aov
# ges = generalised eta squared (effect size): proportion of variance explained

# Tukey's HSD: which specific pairs differ?
# Returns a tidy data frame — group1, group2, p.adj, p.adj.signif
pwc <- release %>%
  tukey_hsd(pct_released ~ formulation) %>%
  add_xy_position(x = "formulation")   # adds xmin, xmax, y.position for plotting

pwc


# =============================================================================
# 5. VISUALISATION
# =============================================================================

# --- ggplot2 vs. ggpubr: same plot, different syntax ---
# Both return a ggplot object — all layers are fully compatible

# ggplot2: explicit, full control
ggplot(tablets, aes(x = line, y = content, fill = line)) +
  geom_boxplot() +
  geom_jitter(width = 0.15) +
  theme(legend.position = "none") +
  labs(
    x = "Production Line", 
    y = "Tablet Content (mg)",
    title = "ggplot2"
    ) +
  theme_classic()

# ggpubr: shorter syntax, publication-ready defaults
ggboxplot(tablets, 
          x = "line", 
          y = "content", 
          fill = "line",
          add = "jitter", 
          legend = "none",
          xlab = "Production Line", 
          ylab = "Tablet Content (mg)",
          title = "ggpubr")

# Key point: because both return ggplot objects, you can add the same layers to either


# --- Two-sample t-test plot with significance bracket ---
# stat_compare_means is a ggplot layer — works on ggplot or ggpubr figures

ggboxplot(tablets, x = "line", y = "content", fill = "line",
          add = "jitter", legend = "none",
          xlab = "Production Line", ylab = "Tablet Content (mg)") +
  stat_compare_means(method = "t.test",
                     comparisons = list(c("A", "B")),
                     label = "p.signif")


# --- ANOVA plot with Tukey brackets via stat_pvalue_manual ---
# This is the key workflow: tukey_hsd() -> add_xy_position() -> stat_pvalue_manual()

ggboxplot(release, x = "formulation", y = "pct_released",
          fill = "formulation", add = "jitter", legend = "none",
          xlab = "Formulation", ylab = "Drug Release at 30 min (%)") +
  stat_pvalue_manual(pwc, hide.ns = TRUE, step.increase = 0.05) 
