library(surveydown)
library(dplyr)
library(lubridate)

# Read survey data --------------------------------------------------------

db <- sd_db_connect()
data <- sd_get_data(db)

# Convert timestamps to EST and calculate durations -----------------------

# Convert all timestamp columns to POSIXct in EST timezone
data <- data %>%
  mutate(across(
    starts_with("time_"),
    ~ with_tz(ymd_hms(., tz = "UTC"), tzone = "America/New_York")
  ))

# Calculate survey duration
data <- data %>%
  mutate(
    total_duration_sec = as.numeric(difftime(
      time_end,
      time_start,
      units = "secs"
    )),
    total_duration_min = round(total_duration_sec / 60, 2)
  )

# Calculate page durations
data <- data %>%
  mutate(
    # Welcome page
    dur_p_welcome = as.numeric(difftime(
      time_p_honeypot,
      time_p_welcome,
      units = "secs"
    )),

    # Honeypot page (has multiple questions)
    dur_p_honeypot = as.numeric(difftime(
      time_p_consistency,
      time_p_honeypot,
      units = "secs"
    )),

    # Consistency page (has multiple questions)
    dur_p_consistency = as.numeric(difftime(
      time_p_attention_check_page,
      time_p_consistency,
      units = "secs"
    )),

    # Attention check page (has multiple questions)
    dur_p_attention_check_page = as.numeric(difftime(
      time_p_logic_trap,
      time_p_attention_check_page,
      units = "secs"
    )),

    # Logic trap page (has multiple questions)
    dur_p_logic_trap = as.numeric(difftime(
      time_p_complete,
      time_p_logic_trap,
      units = "secs"
    )),

    # Complete page
    dur_p_complete = as.numeric(difftime(
      time_end,
      time_p_complete,
      units = "secs"
    ))
  )

# Calculate question durations (time from start to when question was answered)
data <- data %>%
  mutate(
    dur_q_name = as.numeric(difftime(time_q_name, time_start, units = "secs")),
    dur_q_favorite_director = as.numeric(difftime(
      time_q_favorite_director,
      time_start,
      units = "secs"
    )),
    dur_q_movie_frequency = as.numeric(difftime(
      time_q_movie_frequency,
      time_start,
      units = "secs"
    )),
    dur_q_streaming_services = as.numeric(difftime(
      time_q_streaming_services,
      time_start,
      units = "secs"
    )),
    dur_q_fake_movie = as.numeric(difftime(
      time_q_fake_movie,
      time_start,
      units = "secs"
    )),
    dur_q_simple_math = as.numeric(difftime(
      time_q_simple_math,
      time_start,
      units = "secs"
    )),
    dur_q_movie_enjoyment = as.numeric(difftime(
      time_q_movie_enjoyment,
      time_start,
      units = "secs"
    )),
    dur_q_attention_check = as.numeric(difftime(
      time_q_attention_check,
      time_start,
      units = "secs"
    )),
    dur_q_movie_frequency_check = as.numeric(difftime(
      time_q_movie_frequency_check,
      time_start,
      units = "secs"
    )),
    dur_q_movie_year = as.numeric(difftime(
      time_q_movie_year,
      time_start,
      units = "secs"
    )),
    dur_q_movie_description = as.numeric(difftime(
      time_q_movie_description,
      time_start,
      units = "secs"
    ))
  )


# Bot detection flags -----------------------------------------------------

data <- data %>%
  mutate(
    # Flag 1: Honeypot field filled (should be empty)
    bot_flag_honeypot = !is.na(favorite_director) & favorite_director != "",

    # Flag 2: Selected fake streaming service
    bot_flag_fake_service = if_else(
      !is.na(streaming_services),
      grepl("fake_service", streaming_services),
      FALSE
    ),

    # Flag 3: Claimed to have seen non-existent movie
    bot_flag_fake_movie = if_else(
      !is.na(fake_movie),
      fake_movie == "yes",
      FALSE
    ),

    # Flag 4: Failed math question (answer should be 12)
    bot_flag_math = if_else(
      !is.na(simple_math),
      as.numeric(simple_math) != 12,
      FALSE
    ),

    # Flag 5: Failed attention check (should select "action")
    bot_flag_attention = if_else(
      !is.na(attention_check),
      attention_check != "action",
      FALSE
    ),

    # Flag 6: Inconsistent frequency responses
    bot_flag_inconsistent_frequency = case_when(
      is.na(movie_frequency) | is.na(movie_frequency_check) ~ FALSE,
      movie_frequency == "daily" & movie_frequency_check == "daily_equivalent" ~
        FALSE,
      movie_frequency == "weekly" &
        movie_frequency_check == "weekly_equivalent" ~
        FALSE,
      movie_frequency == "monthly" &
        movie_frequency_check == "monthly_equivalent" ~
        FALSE,
      movie_frequency == "rarely" &
        movie_frequency_check == "rarely_equivalent" ~
        FALSE,
      movie_frequency == "never" & movie_frequency_check == "never_equivalent" ~
        FALSE,
      TRUE ~ TRUE
    ),

    # Flag 7: Impossible logic (said never to theaters but also recent visit)
    bot_flag_logic = if_else(
      !is.na(movie_frequency) & !is.na(movie_year),
      movie_frequency == "never" & movie_year %in% c("week", "month", "year"),
      FALSE
    ),

    # Flag 8: Too-short text response (less than 10 characters suggests bot)
    bot_flag_short_text = if_else(
      !is.na(movie_description),
      nchar(movie_description) < 10,
      FALSE
    ),

    # Flag 9: Suspiciously fast completion (less than 15 seconds total)
    bot_flag_too_fast = total_duration_sec < 15,

    # Flag 10: Honeypot page completed too quickly (less than 2 seconds)
    bot_flag_fast_honeypot = !is.na(dur_p_honeypot) & dur_p_honeypot < 2,

    # Calculate total flags per respondent
    total_flags = bot_flag_honeypot +
      bot_flag_fake_service +
      bot_flag_fake_movie +
      bot_flag_math +
      bot_flag_attention +
      bot_flag_inconsistent_frequency +
      bot_flag_logic +
      bot_flag_short_text +
      bot_flag_too_fast +
      bot_flag_fast_honeypot,

    # Classify as likely bot (2+ flags)
    likely_bot = total_flags >= 2
  )


# View results ------------------------------------------------------------

# View all data with flags and durations
View(data)

# View just the bot flags and key metrics
data %>%
  select(
    session_id,
    name,
    total_flags,
    likely_bot,
    total_duration_sec,
    starts_with("bot_flag")
  ) %>%
  View()

# View likely bots
data %>%
  filter(likely_bot) %>%
  select(session_id, name, total_flags, total_duration_sec, everything()) %>%
  View()

# Export flagged responses
data %>%
  filter(likely_bot) %>%
  write.csv("flagged_responses.csv", row.names = FALSE)
