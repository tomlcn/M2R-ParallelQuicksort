library(ggplot2)
library(dplyr)
library(tidyr)

# File definition and data transformation
directory <- "data/tom6/"
files <- list.files(path = directory, pattern = "\\.txt$", full.names = TRUE)

read_data <- function(file_path) {
  lines <- trimws(readLines(file_path, warn = FALSE))
  data_list <- list()
  current_size <- NA
  
  for (line in lines) {
    if (grepl("^Size:", line)) {
      current_size <- as.numeric(sub("Size:", "", line))
    } else if (grepl("quicksort took:", line) && !is.na(current_size)) {
      parts <- strsplit(line, "quicksort took:")[[1]]
      data_list[[length(data_list) + 1]] <- data.frame(
        size = current_size,
        type = trimws(parts[1]),
        time = as.numeric(sub("sec\\.", "", trimws(parts[2])))
      )
    }
  }
  
  d <- do.call(rbind, data_list)
  d$type <- ifelse(tolower(d$type) == "built-in", "builtin", tolower(d$type))
  
  name_raw <- sub("\\.txt$", "", basename(file_path))
  rest <- sub("^measurements_", "", name_raw)
  d$experiment <- ifelse(grepl("^(all|random|reps|size)_", rest), sub("_.*$", "", rest), "baseline")
  d$run <- sub("^(all|random|reps|size)_", "", rest)
  
  return(d)
}

df <- do.call(rbind, lapply(files, read_data))

# Linear regression analysis for crossover point
print("\n Crossover Point Analysis")
df_wide <- df %>% pivot_wider(names_from = type, values_from = time, values_fn = mean)

if("parallel" %in% names(df_wide) && "sequential" %in% names(df_wide)) {
  df_wide <- df_wide %>% mutate(ratio = parallel / sequential)
  
  p_reg <- ggplot(df_wide, aes(x = size, y = ratio)) +
    geom_point(alpha = 0.4, color = "#1F77B4") +
    geom_smooth(method = "loess", color = "#B22222", fill = "#ffcccc", se = TRUE) +
    geom_hline(yintercept = 1, linetype = "dashed", color = "black", linewidth = 0.8) +
    scale_x_log10(labels = scales::label_number(scale_cut = scales::cut_short_scale())) +
    labs(title = "Crossover Point Analysis",
         subtitle = "Ratio of Parallel to Sequential Execution Time",
         x = "Array size (log scale)", y = "Ratio (Parallel / Sequential)") +
    theme_bw()
  
  ggsave(file.path(directory, "regression_crossover.png"), p_reg, width = 10, height = 6)
}

# Individual plots for each experiment
print("\n Generating Individual Plots \n")

type_labels <- c(sequential = "sequential (1 thread)",
                 parallel   = "parallel (several threads)",
                 builtin    = "builtin (C library qsort)")

pal <- c("#1F77B4", "#FF7F0E", "#B22222")
shp <- c(16, 17, 15)
lty <- c("solid", "solid", "dashed")
names(pal) <- names(shp) <- names(lty) <- type_labels

for (exp_name in unique(df$experiment)) {
  d_sub <- filter(df, experiment == exp_name)
  if (nrow(d_sub) == 0) next
  
  s_sub <- d_sub %>%
    group_by(size, type) %>%
    summarise(n = n(), mean = mean(time), sd = sd(time),
              ci = qt(0.975, n - 1) * sd / sqrt(n), .groups = "drop") %>%
    mutate(lower = mean - ci, upper = mean + ci)
  
  s_sub$type_label <- factor(type_labels[as.character(s_sub$type)], levels = type_labels)
  
  p_indiv <- ggplot(s_sub, aes(x = size, y = mean, color = type_label, shape = type_label, linetype = type_label)) +
    geom_errorbar(aes(ymin = lower, ymax = upper), width = 0.07, linewidth = 0.6) +
    geom_line(linewidth = 0.8) +
    geom_point(size = 2.5) +
    scale_color_manual(values = pal) +
    scale_shape_manual(values = shp) +
    scale_linetype_manual(values = lty) +
    scale_x_log10(labels = scales::label_number(scale_cut = scales::cut_short_scale())) +
    scale_y_log10(labels = scales::label_number(accuracy = 0.00001, drop0trailing = TRUE)) +
    labs(title = paste0("Benchmark : ", exp_name),
         x = "Array size (log scale)", y = "Sorting Time (log scale)",
         color = "Algorithm", shape = "Algorithm", linetype = "Algorithm") +
    theme_bw() + theme(legend.position = "bottom")
  
  ggsave(file.path(directory, paste0("fig_curve_", exp_name, ".png")), p_indiv, width = 10, height = 5)
}

# Anova test
print("\n Anova Test\n")
anova_model <- aov(time ~ type * factor(size), data = df)
print(summary(anova_model))