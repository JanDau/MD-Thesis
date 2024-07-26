###############################################################################
###           Generate Sequences | v1.5 | J. Daudert | 10/03/2018           ###
###############################################################################

# -------------
# 0. Explanation of user_settings
# -----------------------------------------------------------------------------
# num_files:      Number of .fna files to be generated                    [int]
# num_seq:        Number of sequences per .fna file                       [int]
# rand_pos:       Number of random positions inside a sequence            [int]
# stringent_only: Stringent seq only?                                    [bool]
# base_weight:    Named vector with percentages of occurance OR NA        [dbl]
# max_dist:       Maximum allowed distance from stringent structure       [int]
# dist_rel:       Vector containing the % distribution of sequences in the
#                 final file with a dist of 0 (1st pos.), 1 (2nd pos.), ... 
#                 => the number of vector entries has to be max_dist + 1  [dbl]
# perc_real:      % of non error-derived sequence in final file           [dbl]
# perc_daughters: % of error-derived seq that descend from a "mother" seq [dbl]
# max_err:        Maximum number of errors inside the same distance       [int]
# err_rel:        Vector containing the % distribution of seq of the same
#                 dist with 1 (1st pos.), 2 (2nd pos.), ... errors.
#                 => the number of vector entries has to be max_err       [dbl]

# -------------
# 1. User Settings
# -----------------------------------------------------------------------------
user_settings <- list(
  num_files = 1,
  num_seq = 1000,
  rand_pos = 16,
  stringent_only = TRUE,
  base_weight = NA, # c("A" = 0.35, "T" = 0.35, "C" = 0.15, "G" = 0.15), # set NA for equal
  max_dist = 3,
  dist_rel = c(0.5, 0.25, 0.15, 0.1),
  perc_real = 0.025,
  perc_daughters = 0.95,
  max_err = 3,
  err_rel = c(0.65, 0.3, 0.05)
)

# -------------
# 2. Functions
# -----------------------------------------------------------------------------
GenerateStringent <- function(num, rands) {
  # Generates random sequences with a stringent structure.
  #
  # Args:
  #   num: Number of sequences to generate.
  #   rands: Number of random positions.
  #
  # Returns:
  #   A data frame with columns 'Sequence', 'Reads' (= 1) and 'Distance' (= 0)
  df <- data.frame("Sequence" = character(), "Reads" = numeric(),
                   "Distance" = numeric(), stringsAsFactors = FALSE)
  fix_base <- c("CTA", "CAG", "CTT", "CGA", "CTA", "CTT", "GGA") # mCherry
  
  for (i in seq(num)) {
    if(all(is.na(user_settings$base_weight))) prob_tmp <- rep(1/4, 4) else prob_tmp <- user_settings$base_weight
    rand_base <- sample(c("A", "T", "C", "G"), rands, replace = TRUE, prob = prob_tmp)
    rand_seq <- "ATCTA"
    
    z <- 0
    for (x in seq(rands)) {
      if (z==2) {
        rand_seq <- paste0(rand_seq, fix_base[x/2])
        z <- 0
      }
      rand_seq <- paste0(rand_seq, rand_base[x])
      z <- z + 1
    }
    
    rand_seq <- paste0(rand_seq, "GATCT")
    df <- rbind(df, data.frame(Sequence = rand_seq, Reads = 1, Distance = 0,
                               stringsAsFactors = FALSE))
  }
  return(df)
}

CreateErrors <- function(df, dist, numb, err) {
  vec_base <- c("A","T","C","G")
  vec_var_pos <- c(6, 7, 11, 12, 16, 17, 21, 22, 26, 27, 31, 32, 36, 37, 41, 42)
  
  for (i in seq(nrow(df))) {
    str_seq <- df$Sequence[i]

    for (x in seq(numb)) {
      if(exists("str_seq_new")) str_seq <- str_seq_new
      int_seq_len <- nchar(str_seq)
      
      if (missing(err)) {
        rand_pos <- sample(2:(int_seq_len-1), 1, replace = F) # random pos. in sequence, min. 2, max. vorletzte
        rand_error <- sample(c("del","ins","sub"), 1, replace = F, prob = c(0.25, 0.33, 0.42)) # zufällige AUswahl, ob del, ins oder sub
        if (rand_error == "sub") {
          var_temp <- 2:(int_seq_len-1)
          rand_pos <- sample(var_temp[!var_temp %in% vec_var_pos], 1, replace = F)
        }
      } else {
        rand_pos <- sample(vec_var_pos, 1, replace = F) # zufällige Stelle der variablen Positionen
        rand_error <- "sub"
      }
      
      if (rand_error == "del") {
        str_seq_new <- substr(str_seq, 1, rand_pos-1)
        str_seq_new <- paste0(str_seq_new, substr(str_seq, rand_pos+1, int_seq_len))
      } else if (rand_error == "ins") {
        str_seq_new <- substr(str_seq, 1, rand_pos-1)
        str_seq_new <- paste0(str_seq_new, sample(vec_base, 1, replace=F))
        str_seq_new <- paste0(str_seq_new, substr(str_seq, rand_pos, int_seq_len))
      } else if (rand_error == "sub") {
        str_seq_new <- str_seq
        substr(str_seq_new, rand_pos, rand_pos) <- sample(vec_base[!vec_base %in% substr(str_seq_new, rand_pos, rand_pos)], 1, replace=F)
      }
    }
    df$Sequence[i] <- str_seq_new
    df$Distance[i] <- dist
    rm(str_seq, int_seq_len, str_seq_new, rand_pos, rand_error)
  }
  return (df)
}

# -------------
# 3. Main Routine
# -----------------------------------------------------------------------------
for (a in seq(user_settings$num_files)) {
  cat(paste0("\rFile ", a, " of ", user_settings$num_files))
  
  # 3.1 Stringent sequences ===========
  df_final <- GenerateStringent(user_settings$num_seq, user_settings$rand_pos)

  # 3.2 Sequences with errors =========
  if (!user_settings$stringent_only) {
    df_stringent <- df_final
    rm(df_final)
    df <- list()
    
    # 3.2.1 Number of sequences per distance
    if (user_settings$max_dist == 0) {
      int_seq <- nrow(df_stringent)
    } else {
      int_seq <- round(user_settings$dist_rel * nrow(df_stringent), 0)
    }
    
    # 3.2.1 Loop over distances (b)
    for (b in seq(0, user_settings$max_dist)) {
      # 3.2.1.1 Entry in df
      df[[length(df) + 1]] <- list("Real" = data.frame(), "Daughters" = data.frame(), "Randoms" = data.frame(), "Total" = data.frame())
      names(df)[length(df)] <- paste0("Dist", b)
      
      # 3.2.1.2 Sample a set of real existing barcodes
      if (b == 0) {
        vec_seq_real <- sample(seq(nrow(df_stringent)), int_seq * user_settings$perc_real, replace = F)
        df[[b + 1]]$Real <- df_stringent[vec_seq_real, ]
        rm(vec_seq_real)
      }
      
      # 3.2.1.3 Sample a set of mother sequences from the sequences of 3.2.1.2
      vec_daughters <- sample(seq(nrow(df[[1]]$Real)), round((int_seq[b + 1] - nrow(df[[b + 1]]$Real)) * user_settings$perc_daughters), replace = T)
      int_daughters_rel <- round(user_settings$err_rel * length(vec_daughters), 0)
      
      # 3.2.1.4 Inside the same distance sequences can have different amount of errors (c)
      for (c in seq(user_settings$max_err)) {
        if (b == 0) {
          df_set <- df[[1]]$Real
        } else {
          df_set <- df[[b]]$Total
        }
        df_daughters_temp <- df_set[sample(vec_daughters, int_daughters_rel[c], replace = T),]
        df[[b + 1]]$Daughters <- rbind(df[[b + 1]]$Daughters, CreateErrors(df_daughters_temp, b, c, "sub"))
        rm(df_set, df_daughters_temp)
      }
      rm(vec_daughters, int_daughters_rel, c)
      
      # 3.2.1.5 Sample a set of random, non descending sequences
      int_rands <- int_seq[b + 1] - nrow(df[[b + 1]]$Real) - nrow(df[[b + 1]]$Daughters)
      vec_rands <- sample(seq(nrow(df_stringent)), int_rands, replace = F)
      df[[b + 1]]$Randoms <- CreateErrors(df_stringent[vec_rands, ], b, b)
      rm(int_rands, vec_rands)
      
      # 3.2.1.6 Join the set of real sequences (only b == 0), daughters and randoms
      df[[b + 1]]$Total <- rbind(df[[b + 1]]$Real, df[[b + 1]]$Daughters, df[[b + 1]]$Randoms)
    }
    rm(int_seq, b)
    
    # 3.2.2 Join the data frames of 3.2.1.6 to a final list (lapply) and transfer to a data frame (do.call)
    df_final <- do.call(rbind.data.frame, lapply(df, "[[", 4))
  }
  
  # 3.3 Export ========================
  #write.table(df_final, file=paste0("Gen_", user_settings$num_seq, "_", a, ".fna"), quote = F, row.names = F)
}
rm(a)
cat(paste0("\rDone.                                       "))

# Plot distance =======================
# df_final_dist <- adist(df_final$Sequence)
# tbl <- table(df_final_dist)
# tbl <- tbl[c(2:length(tbl))]/2
# tbl <- tbl/sum(tbl)
# plot(dbinom(1:16, 16, 3/4))
# lines(tbl, color = "red")
