# =============================================================================
#  Ibuprofen Tablet Assay – Code-Along Exercise
#  Based on UV-Vis absorbance measurement
#
#  Learning objectives:
#    1. Import an Excel file with multiple sheets
#    2. Define variables and explore a data frame
#    3. Convert absorbance → concentration
#    4. Calculate summary statistics per batch
#    5. Visualise results as a bar chart with ggplot2
#    6. (Extra) Build a standard curve using linear regression

# =============================================================================
# -----------------------------------------------------------------------------
#  BACKGROUND – Experimental setup
# -----------------------------------------------------------------------------
#
#  Three batches of ibuprofen tablets (A, B, C) have been manufactured.
#  Each tablet has a nominal (intended) content of 200 mg ibuprofen.
#
#  To verify the actual drug content, the following procedure was carried out:
#
#    1. Six tablets were sampled from each batch (18 tablets in total).
#    2. Each tablet was dissolved individually in 500 mL of solvent.
#    3. The resulting solution was diluted by a factor of 40 before measurement.
#    4. The absorbance of each diluted solution was measured by UV-Vis
#       spectrophotometry.
#
#  A standard curve was prepared alongside the samples:
#    - Ibuprofen reference solutions of known concentrations were measured.
#    - This allows us to convert absorbance readings into concentrations.
#
#  Our goal: use the standard curve to back-calculate the ibuprofen content
#  (in mg per tablet) for each sample, and compare the three batches.


# -----------------------------------------------------------------------------
# Load libraries
# -----------------------------------------------------------------------------

# tidyverse gives us ggplot2 (plotting) and dplyr (data manipulation)
# readxl lets us import Excel files
# writexl lets us save dataframes as excel files
# Install these first if needed: install.packages(c("tidyverse", "writexl"))
install.packages("writexl")

library(tidyverse)
library(readxl)
library(writexl)
# -----------------------------------------------------------------------------
# STEP 1: Import the data
# -----------------------------------------------------------------------------

# We have two sheets in our Excel file:
#   - "samples"        : absorbance readings for tablets from 3 batches
#   - "standard_curve" : known concentrations + measured absorbances

# Change this path to wherever you saved the file!
file_path <- "ibuprofen_assay.xlsx"

# Import each sheet into its own data frame (object)
std_curve <- read_excel(file_path, sheet = "standard_curve")
samples   <- read_excel(file_path, sheet = "samples")

# Let's take a look at what we've imported
std_curve   # print the standard curve table
samples     # print the sample table

# Useful functions for exploring a data frame:
nrow(samples)     # how many rows?
ncol(samples)     # how many columns?
colnames(samples) # what are the column names?

# -----------------------------------------------------------------------------
# STEP 2: Define some variables
# -----------------------------------------------------------------------------

# In R, we assign values to variables using the <- operator
# These represent our assay parameters

label_claim_mg  <- 200  # nominal ibuprofen content per tablet (mg)
V_solvent_mL    <- 500  # amount of solvent used to dissolve tablets (mL)
dilution_factor <- 40   # samples were diluted 1:40 before measurement

# We also define the parameters from the standard curve.
# Here it is done from a know standard curve.
# At the end it is shown how it can be done using the data from the excel sheet

# From a standard curve of absorbance at 222 nm (y) against mg/mL Ibuprofen (x)
slope     = 0.04478
intercept = -0.0002667

# We can do arithmetic with variables just like a calculator
# For example, to reverse a dilution:
# undiluted_conc <- measured_conc_mg_per_L * dilution_factor

# -----------------------------------------------------------------------------
# STEP 3: Convert sample absorbances to concentrations
# -----------------------------------------------------------------------------

# Rearranging  A = slope * C + intercept  gives:
# C = (A - intercept) / slope

# We use mutate() from dplyr to add a new column to the samples data frame
# This applies the formula to every row automatically

samples <- samples %>% 
  mutate(
    # Initial concentration in the 500 mL of solvent
    conc_mg_per_L = ((absorbance - intercept) / slope) * dilution_factor,

    # Convert to mg per tablet
    ibu_content_mg = conc_mg_per_L * V_solvent_mL/1000  # 500 mL = 0.5 L
  )

# Take a look at the updated data frame
samples

# Save the dataframe as csv or excel file
write_csv(samples, "samples_treated.csv")
write_xlsx(samples, "samples_treated.xlsx")

# -----------------------------------------------------------------------------
# STEP 4: Summary statistics per batch
# -----------------------------------------------------------------------------

# group_by() + summarise() is the tidyverse way to get stats per group

batch_summary <- samples %>%
  group_by(batch) %>%
  summarise(
    n       = n(), # number of observations/samples per batch
    mean_mg = mean(ibu_content_mg), # mean content
    sd_mg   = sd(ibu_content_mg),   # standard deviation
    min_mg  = min(ibu_content_mg),  # lowest value
    max_mg  = max(ibu_content_mg)   # highest value
  ) %>% 
  ungroup()

# Print the summary table
batch_summary

# -----------------------------------------------------------------------------
# STEP 5: Bar chart – mean ibuprofen content per batch
# -----------------------------------------------------------------------------

ggplot(batch_summary, aes(x = batch, y = mean_mg, fill = batch)) +

  # Draw the bars
  geom_col(width = 0.5, color = "black") +

  # Add error bars (± 1 SD)
  geom_errorbar(
    aes(ymin = mean_mg - sd_mg, ymax = mean_mg + sd_mg), 
    width = 0.2,
    linewidth = 1
    ) +

  # Horizontal lines for the label caim (mg)
  geom_hline(yintercept = label_claim_mg, linetype = "dashed") +

  # Labels
  labs(
    title    = "Mean Ibuprofen Content per Batch",
    x        = "Batch",
    y        = "Ibuprofen content (mg)"
  ) +

  # Adjust y-axis
  scale_y_continuous(limits = c(0, 250), expand = c(0,0)) +

  # Clean theme
  theme_classic() +
  
  # Control the size and appearance of axis titles/tick labels and make them bold
  theme(
    axis.title = element_text(size = 15, face = "bold"),
    axis.text = element_text(size = 12),
    legend.position = "none"
    )

# Save a picture of the plot - this method only saves your latest plot
ggsave("bar_plot.png", dpi = 300)

# -----------------------------------------------------------------------------
# STEP 6: (extra) Build the standard curve (linear regression)
# -----------------------------------------------------------------------------

# A standard curve models the relationship: Absorbance = slope * Concentration + intercept
# In R, we use lm() (linear model) to fit this line

std_model <- lm(absorbance ~ concentration_mg_per_L, data = std_curve)

# Inspect the model output
summary(std_model)

# Extract the intercept and slope for later use
intercept <- coef(std_model)[1]
slope     <- coef(std_model)[2]

# Print them nicely
cat("Intercept:", signif(intercept, 3), " 
Slope:    ", signif(slope, 3))

# Quick plot of the standard curve to check it looks right
ggplot(std_curve, aes(x = concentration_mg_per_L, y = absorbance)) +
  geom_point(size = 3) +
  geom_smooth(method = "lm", se = FALSE, linetype = "dashed") +
  labs(
    title    = "Standard Curve – Ibuprofen",
    x        = "Concentration (mg/L)",
    y        = "Absorbance (AU)"
  ) +
  theme_classic()
