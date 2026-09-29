# =============================================================================
# Introduction to R — Code Club (Pharmacy Edition)
# =============================================================================


# SECTION 1: RStudio and your working directory ------------------------------

# RStudio has four panes: Source (this script), Console (where code actually
# runs), Environment/History (top-right), and Files/Plots/Packages/Help
# (bottom-right).
#
# Writing code in the Source pane and running it (Ctrl+Enter) sends it to the
# Console one line/selection at a time - this is how you build something you
# can save, re-run, and hand to someone else. Typing directly in the Console
# works too, but nothing there is saved when you close RStudio.

# Your working directory is the folder R looks in (and saves to) by default.
getwd()          # show the current working directory

# You *can* set it with setwd("path/to/folder"), but hard-coding a path only
# works on your own machine. The reliable fix is an RStudio Project:
# File > New Project - this sets the working directory automatically to
# wherever the project lives, every time you open it. 


# SECTION 2: R as a calculator ------------------------------------------------

# R can be used just like a calculator. Try running each line.
2 + 3
10 - 4
6 * 7
100 / 4
2 ^ 8          # exponentiation

# Parentheses work as expected
(2 + 3) * 4
2 + 3 * 4      # note: multiplication happens before addition


# SECTION 3: Variables ---------------------------------------------------------

# Use <- to assign a value to a variable ("object")
caffeine_mg <- 80      # mg of caffeine in a can of Red Bull
volume_mL   <- 250     # mL in the can

# Now use the variables in a calculation
caffeine_mg_per_100mL <- caffeine_mg / volume_mL * 100
caffeine_mg_per_100mL   # just type the name and run the line to print it

# Variables can also hold text 
product_name <- "Red Bull"
category     <- "Energy Drink"

# Print a message combining text and a variable
cat("Product:", product_name, "| Category:", category)
cat("Caffeine density:", round(caffeine_mg_per_100mL, 1), "mg per 100 mL")

# Try running this line to see a common error message:
product_naem   # typo - object not found


# SECTION 4: Data types ---------------------------------------------------------

# The three types you'll meet most often:

# Numeric
caffeine_mg <- 80
class(caffeine_mg)

# Character (text) - also called "string" in other programming languages
excipient <- "Microcrystalline cellulose"
class(excipient)

# Logical (TRUE / FALSE) - also called "boolean" in other languages
meets_spec   <- TRUE
failed_assay <- FALSE
class(meets_spec)


# SECTION 5: Vectors -------------------------------------------------------------

# A vector is a sequence of values of the same type.
# Think of it as a single column of data. c() means "combine".

# Numeric vector - caffeine content (mg) of five popular energy drinks
energy_drink_caffeine_mg <- c(80, 160, 200, 300, 150)

# Character vector - the matching product names
energy_drink_names <- c("Red Bull", "Monster", "Celsius", "Bang Energy", "Rockstar")

# Logical vector - does each drink pack more than 150 mg?
over_150mg <- energy_drink_caffeine_mg > 150
over_150mg

# Vectors are vectorised - an operation applies to every element at once
energy_drink_caffeine_mg / 1000                           # convert mg to g
energy_drink_caffeine_mg - mean(energy_drink_caffeine_mg) # deviation from the average

# Useful summary functions
mean(energy_drink_caffeine_mg)
median(energy_drink_caffeine_mg)
max(energy_drink_caffeine_mg)
length(energy_drink_caffeine_mg)   # how many drinks in the vector?

# Indexing a vector: use [ ] with a position or a condition
energy_drink_caffeine_mg[3]                         # third drink
energy_drink_caffeine_mg[2:4]                       # second through fourth drink
energy_drink_names[energy_drink_caffeine_mg > 150]  # names of drinks above 150 mg


# SECTION 6: Data frames -------------------------------------------------------

# A data frame is a table: columns are vectors of the same length, all
# lined up row by row. This is the main structure you'll work with in R.
# tibble() is the tidyverse's version of a data frame - try building one:

drinks <- tibble(
  product     = c("Brewed coffee", "Red Bull", "Coca-Cola", "Green tea", "Monster Energy"),
  category    = c("Coffee", "Energy Drink", "Soda", "Tea", "Energy Drink"),
  caffeine_mg = c(96, 80, 34, 28, 160)
)

# ^ That should have failed with something like:
#   "could not find function 'tibble'"
# That's R telling you it doesn't know this function yet. tibble() lives in
# a package we haven't loaded - more on that in the next section.


# SECTION 7: Libraries ----------------------------------------------------------

# Base R is powerful, but packages extend it enormously. tidyverse is a
# bundle of packages (ggplot2, dplyr, tidyr, readr, tibble, and more) built
# around a consistent, readable style
#
# Install once (only needed the first time on a new machine):
#   install.packages("tidyverse")
# Load every session:
library(tidyverse)

# Now re-run the tibble from Section 6 - it should work this time.
drinks <- tibble(
  product     = c("Brewed coffee", "Red Bull", "Coca-Cola", "Green tea", "Monster Energy"),
  category    = c("Coffee", "Energy Drink", "Soda", "Tea", "Energy Drink"),
  caffeine_mg = c(96, 80, 34, 28, 160)
)

drinks          # print the whole tibble

# SECTION 8: Pulling columns and rows out of a data frame ----------------------

# Before we get to the tidyverse way of doing this (coming up soon), it's
# worth knowing how to grab pieces of a data frame directly 

# $ pulls a single column out as a plain vector
drinks$caffeine_mg

# Once it's a vector, every function from Section 5 works on it directly
mean(drinks$caffeine_mg)
max(drinks$caffeine_mg)

# [row, column] indexing grabs specific pieces of the table
drinks[1, ]                    # first row, all columns
drinks[, "caffeine_mg"]        # all rows, one column
drinks[2, "product"]           # a single cell
drinks[1:3, ]                  # first three rows

# This bracket style works everywhere, but once the condition gets more
# complex than "row 2", the dplyr verbs coming up (filter(), select()) read
# a lot more clearly


# SECTION 9: Functions -----------------------------------------------------------

# R has many built-in functions. The pattern is always: function_name(argument)

# Simple functions that take one argument
sqrt(144)          # square root
log(100)           # natural log
log10(100)         # log base 10
round(3.14159)     # round to the nearest whole number

# Many functions take more than one argument, e.g. round() also accepts how
# many decimal places you want:
round(x = 3.14159, digits = 2)   # argument given by name
round(3.14159, 2)            # same result - argument given by position

# seq() takes several arguments and makes a sequence of numbers
seq(from = 0, to = 20, by = 5)          # every step spelled out by name
seq(0, 20, 5)                           # identical result, given by position
seq(1, 10, length.out = 5)              # 5 evenly spaced values from 1 to 10

# Mixing named and positional arguments works too, but is easiest to read
# when you name anything after the first argument or two.

# Getting help: put ? before any function name to open its help page
?round
?seq

# For plain-language walkthroughs (with runnable examples) of the functions
# and concepts used in this course, see our R documentation site:
#   https://cpdse-edux.github.io/R_documentation/ 


# SECTION 10: Importing data -----------------------------------------------------

# For the rest of today we'll work with a real dataset: caffeine (and sugar)
# content across 60+ coffee, tea, energy drink, soda, and hot chocolate
# products. Make sure caffeine.csv is in your working directory (Section 1),
# then:

df <- read_csv("caffeine.csv")   # tidyverse version (preferred)

# Note: read_csv() expects the English standard - comma-separated, dot as
# the decimal mark. Danish-format files (semicolon-separated, comma as the
# decimal mark) use read_csv2() instead.

# Always inspect a dataset right after reading it in
glimpse(df)   # column names, types, and a preview
head(df)      # first 6 rows
View(df)      # opens a spreadsheet-like view in RStudio

# SECTION 11: Data wrangling with dplyr ------------------------------------------

# dplyr verbs are the core toolkit for reshaping and summarising a data
# frame. They're often chained together with the pipe operator %>%.
# Read %>% as "and then": data %>% filter(x > 1) takes data and then
# filters it, same result as filter(data, x > 1) but easier to read when
# you chain several steps.

# --- filter(): keep rows matching a condition ---
df %>% filter(category == "Energy Drink")
df %>% filter(caffeine_mg > 200)
df %>% filter(category == "Coffee", caffeine_mg > 200)          # AND
df %>% filter(category == "Soda" | category == "Tea")           # OR

# --- select(): keep or drop columns ---
df %>% select(product, category, caffeine_mg)
df %>% select(-brand)    # drop a column with -

# --- mutate(): create or modify columns ---
df %>% mutate(caffeine_mg_per_100mL = caffeine_mg / serving_size_mL * 100)
df %>% mutate(high_caffeine = caffeine_mg > 200)   # flag strong products

# --- arrange(): sort rows ---
df %>% arrange(caffeine_mg)          # ascending - weakest first
df %>% arrange(desc(caffeine_mg))    # descending - strongest first

# --- group_by() + summarise(): summary statistics by group ---
df %>%
  group_by(category) %>%
  summarise(
    n_products      = n(),
    mean_caffeine    = mean(caffeine_mg),
    max_caffeine     = max(caffeine_mg),
    mean_sugar       = mean(sugar_g)
  )

# --- Chaining multiple steps together ---
df %>%
  mutate(caffeine_mg_per_100mL = round(caffeine_mg / serving_size_mL * 100, 1)) %>%
  select(product, category, caffeine_mg, caffeine_mg_per_100mL) %>%
  arrange(desc(caffeine_mg_per_100mL))


# SECTION 12: Plotting with ggplot2 -----------------------------------------------

# ggplot2 builds plots in layers:
#   ggplot(data, aes(x = ..., y = ...)) +    # canvas + axes
#   geom_*() +                               # what to draw
#   labs() +                                 # labels
#   theme_*()                                # overall look

# --- Scatter plot: does a bigger serving mean more caffeine? ---
ggplot(df, aes(x = serving_size_mL, y = caffeine_mg, colour = category)) +
  geom_point(size = 3, alpha = 0.8) +
  labs(
    title  = "Caffeine content vs. serving size",
    x      = "Serving size (mL)",
    y      = "Caffeine (mg)",
    colour = "Category"
  ) +
  theme_minimal()

# --- Scatter plot: does more caffeine mean more sugar? ---
# Watch what happens here: energy drinks and soda split into two clouds
# (sugared vs. "zero sugar" versions), coffee and tea sit almost entirely
# along the bottom (0 g sugar, since these are all unsweetened), and hot
# chocolate flips the pattern completely - high sugar, almost no caffeine.
ggplot(df, aes(x = caffeine_mg, y = sugar_g, colour = category)) +
  geom_point(size = 3, alpha = 0.8) +
  labs(
    title  = "Caffeine vs. sugar content",
    x      = "Caffeine (mg)",
    y      = "Sugar (g)",
    colour = "Category"
  ) +
  theme_minimal()

# --- Boxplot: caffeine by category, against the daily guidance line ---

# EFSA's guidance for healthy adults: caffeine intake up to 400 mg/day is
# not generally associated with safety concerns.
daily_limit_mg <- 400   # mg - EFSA single-day caffeine guidance for adults

ggplot(df, aes(x = category, y = caffeine_mg, fill = category)) +
  geom_boxplot(show.legend = FALSE, alpha = 0.7) +
  geom_hline(yintercept = daily_limit_mg, linetype = "dashed", colour = "red") +
  annotate("text", x = 0.6, y = daily_limit_mg + 15,
           label = "EFSA daily guidance (400 mg)", colour = "red",
           size = 3.5, hjust = 0) +
  labs(
    title = "Caffeine per serving by category",
    x     = "Category",
    y     = "Caffeine (mg)"
  ) +
  theme_minimal()


# Saving a plot (saves the last plot displayed by default)
# ggsave("caffeine_plot.png", width = 7, height = 4, dpi = 300)
