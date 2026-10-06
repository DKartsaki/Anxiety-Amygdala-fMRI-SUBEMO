# ============================================================
# SUBEMO: R statistical analyses

# ============================================================

# ---------------------------
# 1. Packages and paths
# ---------------------------
install.packages(c(
  "readxl",
  "readr",
  "dplyr",
  "tidyr",
  "stringr",
  "ggplot2",
  "afex",
  "emmeans",
  "lme4",
  "lmerTest",
  "boot",
  "WRS2",
  "patchwork"
))
library(readxl)
library(readr)
library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(afex)
library(emmeans)
library(lme4)
library(lmerTest)
library(boot)
library(WRS2)
library(patchwork)

DATA_DIR <- "PATH/TO/DATA"


# Change these names to match the ROI/contrast outputs used in your analysis.
ROI_DIR <- file.path(DATA_DIR, "ROI_results")
AUDITORY_FEAR_FILE    <- "auditory_fear.csv"
AUDITORY_NEUTRAL_FILE <- "auditory_neutral.csv"
VISUAL_FEAR_FILE      <- "visual_fear.csv"
VISUAL_NEUTRAL_FILE   <- "visual_neutral.csv"
AUDITORY_DIFF_FILE    <- "auditory_neutral_vs_fear.csv"

# ---------------------------
# 2. Participant-level STAI data
# ---------------------------

subjects_stai <- c(
  sprintf("sub-%02d", 1:31),
  sprintf("sub-%02d", 33:37)
)

stai_state <- c(
  50, 10, 10, 35, 60, 30, 45, 45, 40, 30,
  40, 15, 55, 10, 70, 13, 3, 12, 10, 15,
  25, 45, 50, 5, 3, 50, 10, 40, 5, 25,
  40, 10, 40, 60, 65, 50
)

stai_trait <- c(
  5, 10, 5, 50, 80, 5, 50, 60, 65, 75,
  45, 50, 60, 3, 3, 23, 5, 69, 13, 45,
  30, 30, 15, 5, 5, 60, 30, 30, 25, 25,
  45, 30, 13, 40, 85, 60
)

stai_df <- data.frame(
  subject = subjects_stai,
  stai_state = stai_state,
  stai_trait = stai_trait
)

stopifnot(nrow(stai_df) == 36)

# ---------------------------
# 3. Behavioral stimulus-validation analyses
# ---------------------------

ratings <- read_excel(file.path(DATA_DIR, "ratings.xlsx"))

ratings_collapsed <- ratings %>%
  group_by(Subject, Phase, Emotion) %>%
  summarise(
    Arousal = mean(Arousal, na.rm = TRUE),
    Valence = mean(Valence, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    Subject = factor(Subject),
    Emotion = factor(Emotion, levels = c("Neu", "Fear")),
    Phase = factor(Phase, levels = c("Face", "Voice"))
  )

# 2 x 2 repeated-measures ANOVAs: Emotion x Modality
anova_arousal <- aov_ez(
  id = "Subject",
  dv = "Arousal",
  data = ratings_collapsed,
  within = c("Emotion", "Phase"),
  type = 3
)

anova_valence <- aov_ez(
  id = "Subject",
  dv = "Valence",
  data = ratings_collapsed,
  within = c("Emotion", "Phase"),
  type = 3
)

nice(anova_arousal, correction = "none", es = "pes")
nice(anova_valence, correction = "none", es = "pes")

# Follow-up estimated marginal means
emm_arousal <- emmeans(anova_arousal, ~ Emotion | Phase)
emm_valence <- emmeans(anova_valence, ~ Emotion | Phase)

pairs(emm_arousal)
pairs(emm_valence)

# Paired Fear vs Neutral comparisons within each modality
ratings_wide <- ratings_collapsed %>%
  pivot_wider(
    names_from = Emotion,
    values_from = c(Arousal, Valence)
  )

face_wide <- ratings_wide %>% filter(Phase == "Face")
voice_wide <- ratings_wide %>% filter(Phase == "Voice")

t_face_arousal <- t.test(
  face_wide$Arousal_Fear, face_wide$Arousal_Neu,
  paired = TRUE
)
t_face_valence <- t.test(
  face_wide$Valence_Fear, face_wide$Valence_Neu,
  paired = TRUE
)
t_voice_arousal <- t.test(
  voice_wide$Arousal_Fear, voice_wide$Arousal_Neu,
  paired = TRUE
)
t_voice_valence <- t.test(
  voice_wide$Valence_Fear, voice_wide$Valence_Neu,
  paired = TRUE
)

paired_tests <- data.frame(
  test = c(
    "Face Fear vs Neutral: Arousal",
    "Face Fear vs Neutral: Valence",
    "Voice Fear vs Neutral: Arousal",
    "Voice Fear vs Neutral: Valence"
  ),
  p = c(
    t_face_arousal$p.value,
    t_face_valence$p.value,
    t_voice_arousal$p.value,
    t_voice_valence$p.value
  )
) %>%
  mutate(p_bonferroni = p.adjust(p, method = "bonferroni"))

paired_tests

# Cohen's dz for paired Fear-Neutral comparisons
face_arousal_diff <- face_wide$Arousal_Fear - face_wide$Arousal_Neu
face_valence_diff <- face_wide$Valence_Fear - face_wide$Valence_Neu
voice_arousal_diff <- voice_wide$Arousal_Fear - voice_wide$Arousal_Neu
voice_valence_diff <- voice_wide$Valence_Fear - voice_wide$Valence_Neu

cohens_dz <- data.frame(
  test = paired_tests$test,
  dz = c(
    mean(face_arousal_diff, na.rm = TRUE) / sd(face_arousal_diff, na.rm = TRUE),
    mean(face_valence_diff, na.rm = TRUE) / sd(face_valence_diff, na.rm = TRUE),
    mean(voice_arousal_diff, na.rm = TRUE) / sd(voice_arousal_diff, na.rm = TRUE),
    mean(voice_valence_diff, na.rm = TRUE) / sd(voice_valence_diff, na.rm = TRUE)
  )
)

cohens_dz

# Behavioral Fear-Neutral difference scores and STAI correlations
stai_behavior <- data.frame(
  Subject = c(1:31, 33:37),
  STAI_State = stai_state,
  STAI_Trait = stai_trait
)

rating_diffs <- ratings_collapsed %>%
  select(Subject, Phase, Emotion, Arousal, Valence) %>%
  pivot_wider(
    names_from = Emotion,
    values_from = c(Arousal, Valence)
  ) %>%
  mutate(
    Arousal_diff = Arousal_Fear - Arousal_Neu,
    Valence_diff = Valence_Fear - Valence_Neu
  ) %>%
  mutate(Subject = as.numeric(as.character(Subject))) %>%
  inner_join(stai_behavior, by = "Subject")

diff_results <- rating_diffs %>%
  pivot_longer(
    cols = c(Arousal_diff, Valence_diff),
    names_to = "Rating",
    values_to = "Difference"
  ) %>%
  group_by(Phase, Rating) %>%
  summarise(
    N = sum(complete.cases(Difference, STAI_State, STAI_Trait)),
    rho_state = cor(Difference, STAI_State,
                    method = "spearman", use = "complete.obs"),
    p_state = cor.test(Difference, STAI_State,
                       method = "spearman", exact = FALSE)$p.value,
    rho_trait = cor(Difference, STAI_Trait,
                    method = "spearman", use = "complete.obs"),
    p_trait = cor.test(Difference, STAI_Trait,
                       method = "spearman", exact = FALSE)$p.value,
    .groups = "drop"
  )

# Bonferroni correction across the 8 difference-score correlations
all_diff_p <- c(diff_results$p_state, diff_results$p_trait)
all_diff_p_bonf <- p.adjust(all_diff_p, method = "bonferroni")

diff_results$p_state_bonf <-
  all_diff_p_bonf[seq_len(nrow(diff_results))]
diff_results$p_trait_bonf <-
  all_diff_p_bonf[(nrow(diff_results) + 1):(2 * nrow(diff_results))]

diff_results

# ---------------------------
# 4. Amygdala ROI: condition-specific responses
# ---------------------------

voice_fear <- read_csv(
  file.path(ROI_DIR, AUDITORY_FEAR_FILE),
  show_col_types = FALSE
) %>%
  rename(voice_fear = amygdala_mean)

voice_neutral <- read_csv(
  file.path(ROI_DIR, AUDITORY_NEUTRAL_FILE),
  show_col_types = FALSE
) %>%
  rename(voice_neutral = amygdala_mean)

face_fear <- read_csv(
  file.path(ROI_DIR, VISUAL_FEAR_FILE),
  show_col_types = FALSE
) %>%
  rename(face_fear = amygdala_mean)

face_neutral <- read_csv(
  file.path(ROI_DIR, VISUAL_NEUTRAL_FILE),
  show_col_types = FALSE
) %>%
  rename(face_neutral = amygdala_mean)

roi_all <- voice_fear %>%
  inner_join(voice_neutral, by = "subject") %>%
  inner_join(face_fear, by = "subject") %>%
  inner_join(face_neutral, by = "subject") %>%
  left_join(stai_df, by = "subject")

stopifnot(nrow(roi_all) == 36)
stopifnot(!anyNA(roi_all$stai_state))
stopifnot(!anyNA(roi_all$stai_trait))

# Fear and Neutral vs implicit baseline
auditory_condition_results <- data.frame(
  comparison = c(
    "Voice Fear vs STAI-State",
    "Voice Neutral vs STAI-State",
    "Voice Fear vs STAI-Trait",
    "Voice Neutral vs STAI-Trait"
  ),
  rho = c(
    unname(cor.test(roi_all$voice_fear, roi_all$stai_state,
                    method = "spearman", exact = FALSE)$estimate),
    unname(cor.test(roi_all$voice_neutral, roi_all$stai_state,
                    method = "spearman", exact = FALSE)$estimate),
    unname(cor.test(roi_all$voice_fear, roi_all$stai_trait,
                    method = "spearman", exact = FALSE)$estimate),
    unname(cor.test(roi_all$voice_neutral, roi_all$stai_trait,
                    method = "spearman", exact = FALSE)$estimate)
  ),
  p = c(
    cor.test(roi_all$voice_fear, roi_all$stai_state,
             method = "spearman", exact = FALSE)$p.value,
    cor.test(roi_all$voice_neutral, roi_all$stai_state,
             method = "spearman", exact = FALSE)$p.value,
    cor.test(roi_all$voice_fear, roi_all$stai_trait,
             method = "spearman", exact = FALSE)$p.value,
    cor.test(roi_all$voice_neutral, roi_all$stai_trait,
             method = "spearman", exact = FALSE)$p.value
  )
) %>%
  mutate(p_bonferroni = p.adjust(p, method = "bonferroni"))

auditory_condition_results

# Visual condition-specific correlations
visual_condition_results <- data.frame(
  comparison = c(
    "Face Fear vs STAI-State",
    "Face Neutral vs STAI-State",
    "Face Fear vs STAI-Trait",
    "Face Neutral vs STAI-Trait"
  ),
  rho = c(
    unname(cor.test(roi_all$face_fear, roi_all$stai_state,
                    method = "spearman", exact = FALSE)$estimate),
    unname(cor.test(roi_all$face_neutral, roi_all$stai_state,
                    method = "spearman", exact = FALSE)$estimate),
    unname(cor.test(roi_all$face_fear, roi_all$stai_trait,
                    method = "spearman", exact = FALSE)$estimate),
    unname(cor.test(roi_all$face_neutral, roi_all$stai_trait,
                    method = "spearman", exact = FALSE)$estimate)
  ),
  p = c(
    cor.test(roi_all$face_fear, roi_all$stai_state,
             method = "spearman", exact = FALSE)$p.value,
    cor.test(roi_all$face_neutral, roi_all$stai_state,
             method = "spearman", exact = FALSE)$p.value,
    cor.test(roi_all$face_fear, roi_all$stai_trait,
             method = "spearman", exact = FALSE)$p.value,
    cor.test(roi_all$face_neutral, roi_all$stai_trait,
             method = "spearman", exact = FALSE)$p.value
  )
)

visual_condition_results

# ---------------------------
# 5. Formal modality analysis:
#    STAI x Emotion x Modality
# ---------------------------

roi_long <- roi_all %>%
  pivot_longer(
    cols = c(face_fear, face_neutral, voice_fear, voice_neutral),
    names_to = c("Modality", "Emotion"),
    names_sep = "_",
    values_to = "Amygdala"
  ) %>%
  mutate(
    Modality = factor(
      Modality,
      levels = c("face", "voice"),
      labels = c("Face", "Voice")
    ),
    Emotion = factor(
      Emotion,
      levels = c("fear", "neutral"),
      labels = c("Fear", "Neutral")
    ),
    subject = factor(subject),
    state_z = as.numeric(scale(stai_state)),
    trait_z = as.numeric(scale(stai_trait))
  )

stopifnot(nrow(roi_long) == 144)

model_state <- lmer(
  Amygdala ~ state_z * Emotion * Modality + (1 | subject),
  data = roi_long
)

model_trait <- lmer(
  Amygdala ~ trait_z * Emotion * Modality + (1 | subject),
  data = roi_long
)

anova(model_state)
summary(model_state)
confint(
  model_state,
  parm = "state_z:EmotionNeutral:ModalityVoice",
  method = "Wald"
)

anova(model_trait)
summary(model_trait)
confint(
  model_trait,
  parm = "trait_z:EmotionNeutral:ModalityVoice",
  method = "Wald"
)

# ---------------------------
# 6. State-Trait overlap
# ---------------------------

stai_state_trait <- cor.test(
  roi_all$stai_state,
  roi_all$stai_trait,
  method = "spearman",
  exact = FALSE
)

stai_state_trait

roi_all <- roi_all %>%
  mutate(
    auditory_emotion_effect = voice_neutral - voice_fear,
    state_z = as.numeric(scale(stai_state)),
    trait_z = as.numeric(scale(stai_trait))
  )

model_both <- lm(
  auditory_emotion_effect ~ state_z + trait_z,
  data = roi_all
)

summary(model_both)
confint(model_both)

# ---------------------------
# 7. Whole-amygdala Voice Neutral > Fear:
#    main correlations and robustness analyses
# ---------------------------

neutral_fear <- read_csv(
  file.path(ROI_DIR, AUDITORY_DIFF_FILE),
  show_col_types = FALSE
) %>%
  left_join(stai_df, by = "subject")

stopifnot(nrow(neutral_fear) == 36)
stopifnot(!anyNA(neutral_fear$stai_state))
stopifnot(!anyNA(neutral_fear$stai_trait))

state_diff <- cor.test(
  neutral_fear$amygdala_mean,
  neutral_fear$stai_state,
  method = "spearman",
  exact = FALSE
)

trait_diff <- cor.test(
  neutral_fear$amygdala_mean,
  neutral_fear$stai_trait,
  method = "spearman",
  exact = FALSE
)

state_diff
trait_diff

# BCa bootstrap confidence intervals (5,000 resamples)
boot_state <- function(data, indices) {
  d <- data[indices, ]
  cor(
    d$amygdala_mean,
    d$stai_state,
    method = "spearman",
    use = "complete.obs"
  )
}

boot_trait <- function(data, indices) {
  d <- data[indices, ]
  cor(
    d$amygdala_mean,
    d$stai_trait,
    method = "spearman",
    use = "complete.obs"
  )
}

set.seed(1234)
state_boot <- boot(
  data = neutral_fear,
  statistic = boot_state,
  R = 5000
)
boot.ci(state_boot, type = c("perc", "bca"))

set.seed(1234)
trait_boot <- boot(
  data = neutral_fear,
  statistic = boot_trait,
  R = 5000
)
boot.ci(trait_boot, type = c("perc", "bca"))

# Percentage-bend correlations
pb_state <- pbcor(
  neutral_fear$amygdala_mean,
  neutral_fear$stai_state
)

pb_trait <- pbcor(
  neutral_fear$amygdala_mean,
  neutral_fear$stai_trait
)

pb_state
pb_trait

# Cook's-distance screening using 4/N
lm_state <- lm(
  amygdala_mean ~ stai_state,
  data = neutral_fear
)

lm_trait <- lm(
  amygdala_mean ~ stai_trait,
  data = neutral_fear
)

cook_state <- cooks.distance(lm_state)
cook_trait <- cooks.distance(lm_trait)
cook_cutoff <- 4 / nrow(neutral_fear)

influence_table <- neutral_fear %>%
  mutate(
    cook_state = cook_state,
    cook_trait = cook_trait
  ) %>%
  filter(
    cook_state > cook_cutoff |
      cook_trait > cook_cutoff
  ) %>%
  select(
    subject,
    amygdala_mean,
    stai_state,
    stai_trait,
    cook_state,
    cook_trait
  )

influence_table

# Sensitivity analyses excluding observations exceeding 4/N
state_sensitivity <- neutral_fear %>%
  filter(!subject %in% c("sub-15", "sub-33", "sub-37"))

trait_sensitivity <- neutral_fear %>%
  filter(!subject %in% c("sub-33", "sub-36", "sub-37"))

cor.test(
  state_sensitivity$amygdala_mean,
  state_sensitivity$stai_state,
  method = "spearman",
  exact = FALSE
)

cor.test(
  trait_sensitivity$amygdala_mean,
  trait_sensitivity$stai_trait,
  method = "spearman",
  exact = FALSE
)

# ---------------------------
# 8. Sex sensitivity analyses
# ---------------------------
# Sex mapping corresponds to actual subjects 1-31 and 33-37.
# Subject 32 is absent from the analysis sample.

sex_all_37 <- c(
  "F","M","F","F","M","F","F","F","F","M",
  "M","M","M","F","F","F","M","M","M","F",
  "F","M","F","F","M","F","F","M","F","M",
  "M","F","F","F","F","M","M"
)

sex_36 <- sex_all_37[-32]

sex_df <- data.frame(
  subject = subjects_stai,
  sex = factor(sex_36, levels = c("F", "M"))
)

voice_neu_fear_sex <- neutral_fear %>%
  select(subject, amygdala_mean, stai_state, stai_trait) %>%
  left_join(sex_df, by = "subject")

stopifnot(nrow(voice_neu_fear_sex) == 36)
stopifnot(!anyNA(voice_neu_fear_sex$sex))

# Anxiety effects adjusted for sex
model_state_sex <- lm(
  amygdala_mean ~ stai_state + sex,
  data = voice_neu_fear_sex
)

model_trait_sex <- lm(
  amygdala_mean ~ stai_trait + sex,
  data = voice_neu_fear_sex
)

summary(model_state_sex)
confint(model_state_sex)

summary(model_trait_sex)
confint(model_trait_sex)

# Exploratory moderation analyses
model_state_sex_int <- lm(
  amygdala_mean ~ stai_state * sex,
  data = voice_neu_fear_sex
)

model_trait_sex_int <- lm(
  amygdala_mean ~ stai_trait * sex,
  data = voice_neu_fear_sex
)

summary(model_state_sex_int)
confint(model_state_sex_int)

summary(model_trait_sex_int)
confint(model_trait_sex_int)

# ---------------------------
# 9. Voice-Neutral amygdala response and behavioral ratings
# ---------------------------

voice_neu_ratings <- ratings %>%
  filter(
    Phase == "Voice",
    Emotion == "Neu"
  ) %>%
  group_by(Subject) %>%
  summarise(
    voice_neu_valence = mean(Valence, na.rm = TRUE),
    voice_neu_arousal = mean(Arousal, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    subject = sprintf("sub-%02d", as.numeric(Subject))
  )

voice_neu_behaviour <- roi_all %>%
  select(subject, voice_neutral) %>%
  inner_join(
    voice_neu_ratings %>%
      select(subject, voice_neu_valence, voice_neu_arousal),
    by = "subject"
  )

neu_valence_cor <- cor.test(
  voice_neu_behaviour$voice_neutral,
  voice_neu_behaviour$voice_neu_valence,
  method = "spearman",
  exact = FALSE
)

neu_arousal_cor <- cor.test(
  voice_neu_behaviour$voice_neutral,
  voice_neu_behaviour$voice_neu_arousal,
  method = "spearman",
  exact = FALSE
)

voice_neu_rating_results <- data.frame(
  outcome = c("Valence", "Arousal"),
  rho = c(
    unname(neu_valence_cor$estimate),
    unname(neu_arousal_cor$estimate)
  ),
  p = c(
    neu_valence_cor$p.value,
    neu_arousal_cor$p.value
  )
) %>%
  mutate(p_bonferroni = p.adjust(p, method = "bonferroni"))

voice_neu_rating_results

# ---------------------------
# 10. Acoustic-feature analyses
# ---------------------------

audio <- read_csv(
  file.path(DATA_DIR, "audio_features_final3.csv"),
  show_col_types = FALSE
) %>%
  separate(
    file_name,
    into = c("Emotion", "AM", "Sound"),
    sep = "_",
    remove = FALSE
  ) %>%
  mutate(
    Sound = str_remove(Sound, "\\.wav$"),
    Emotion = factor(
      Emotion,
      levels = c("Neu", "Fear"),
      labels = c("Neutral", "Fear")
    ),
    AM = factor(
      AM,
      levels = c("Broad", "Low", "High")
    ),
    Stimulus = factor(
      paste(Emotion, Sound, sep = "_")
    )
  )

model_f0 <- lmer(
  f0_mean ~ Emotion * AM + (1 | Stimulus),
  data = audio
)

model_envelope <- lmer(
  temporal_envelope_mean ~ Emotion * AM + (1 | Stimulus),
  data = audio
)

model_harmonicity <- lmer(
  harmonicity_mean ~ Emotion * AM + (1 | Stimulus),
  data = audio
)

model_roughness <- lmer(
  roughness_aspers_mean ~ Emotion * AM + (1 | Stimulus),
  data = audio
)

model_centroid <- lmer(
  centroid_mean ~ Emotion * AM + (1 | Stimulus),
  data = audio
)

anova(model_f0)
anova(model_envelope)
anova(model_harmonicity)
anova(model_roughness)
anova(model_centroid)

posthoc_f0 <- emmeans(
  model_f0,
  pairwise ~ Emotion | AM,
  adjust = "holm"
)

posthoc_envelope <- emmeans(
  model_envelope,
  pairwise ~ Emotion | AM,
  adjust = "holm"
)

posthoc_harmonicity <- emmeans(
  model_harmonicity,
  pairwise ~ Emotion | AM,
  adjust = "holm"
)

posthoc_roughness <- emmeans(
  model_roughness,
  pairwise ~ Emotion | AM,
  adjust = "holm"
)

posthoc_centroid <- emmeans(
  model_centroid,
  pairwise ~ Emotion | AM,
  adjust = "holm"
)

posthoc_f0
posthoc_envelope
posthoc_harmonicity
posthoc_roughness
posthoc_centroid

# Descriptive statistics by Emotion x AM
acoustic_desc <- audio %>%
  group_by(Emotion, AM) %>%
  summarise(
    n = n(),
    f0_M = mean(f0_mean, na.rm = TRUE),
    f0_SD = sd(f0_mean, na.rm = TRUE),
    envelope_M = mean(temporal_envelope_mean, na.rm = TRUE),
    envelope_SD = sd(temporal_envelope_mean, na.rm = TRUE),
    harmonicity_M = mean(harmonicity_mean, na.rm = TRUE),
    harmonicity_SD = sd(harmonicity_mean, na.rm = TRUE),
    roughness_M = mean(roughness_aspers_mean, na.rm = TRUE),
    roughness_SD = sd(roughness_aspers_mean, na.rm = TRUE),
    centroid_M = mean(centroid_mean, na.rm = TRUE),
    centroid_SD = sd(centroid_mean, na.rm = TRUE),
    .groups = "drop"
  )

acoustic_desc

# ---------------------------
# 11. Four-panel condition-specific ROI figure
# ---------------------------

plot_theme <- theme_classic(
  base_size = 14,
  base_family = "Times New Roman"
) +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    plot.subtitle = element_text(hjust = 0.5, size = 11),
    legend.position = "top"
  )

make_roi_plot <- function(data, x_var, modality, title, subtitle) {
  ggplot(
    data %>% filter(Modality == modality),
    aes(
      x = .data[[x_var]],
      y = Amygdala,
      colour = Emotion,
      shape = Emotion
    )
  ) +
    geom_point(size = 2.5, alpha = 0.70) +
    geom_smooth(
      method = "lm",
      formula = y ~ x,
      se = TRUE,
      linewidth = 1
    ) +
    scale_colour_manual(
      values = c("Fear" = "#E64B35", "Neutral" = "#4DBBD5")
    ) +
    scale_shape_manual(
      values = c("Fear" = 16, "Neutral" = 17)
    ) +
    scale_x_continuous(
      limits = c(0, 100),
      breaks = seq(0, 100, 20)
    ) +
    labs(
      title = title,
      subtitle = subtitle,
      x = ifelse(
        x_var == "stai_state",
        "STAI-State percentile score",
        "STAI-Trait percentile score"
      ),
      y = "Mean amygdala contrast estimate",
      colour = NULL,
      shape = NULL
    ) +
    plot_theme
}

fig_A <- make_roi_plot(
  roi_long, "stai_state", "Voice",
  "Auditory - STAI-State",
  "Fear: rho = .06, p = .721    Neutral: rho = .21, p = .223"
)

fig_B <- make_roi_plot(
  roi_long, "stai_state", "Face",
  "Visual - STAI-State",
  "Fear: rho = .08, p = .628    Neutral: rho = .08, p = .656"
)

fig_C <- make_roi_plot(
  roi_long, "stai_trait", "Voice",
  "Auditory - STAI-Trait",
  "Fear: rho = -.01, p = .944    Neutral: rho = .20, p = .254"
)

fig_D <- make_roi_plot(
  roi_long, "stai_trait", "Face",
  "Visual - STAI-Trait",
  "Fear: rho = -.02, p = .914    Neutral: rho = -.02, p = .895"
)

combined_figure <- wrap_plots(
  fig_A, fig_B, fig_C, fig_D,
  ncol = 2,
  guides = "collect"
) +
  plot_annotation(tag_levels = "A") &
  theme(
    legend.position = "top",
    text = element_text(family = "Times New Roman")
  )

combined_figure

# ============================================================
# End of analysis script
# ============================================================
