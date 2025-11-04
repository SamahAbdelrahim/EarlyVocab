extractValue <- function(s) {
  # Split the string by double quotes which will segment the JSON-like structure
  parts <- strsplit(s, "\"")[[1]]
  # The value after "Q0" should be at the fourth position based on the splitting pattern
  if (length(parts) >= 4) {
    return(parts[4])
  } else {
    return(NA)  # Return NA if the expected structure isn't met
  }
}


# Function to clean the JSON string (extracting the value of "Q0")
clean_json_response <- function(response_string) {
  # Check if the string looks like a JSON object using the stringr package
  if (stringr::str_detect(response_string, "^\\{\\\"Q0\\\":\\\".*\\\"\\}$")) {
    # If it's a JSON string, extract the value of "Q0" using the jsonlite package
    library(jsonlite)  # Ensure the jsonlite package is loaded
    parsed_json <- fromJSON(response_string) # Parses the JSON string into an R object
    return(parsed_json$Q0) # Extract the value associated with the key "Q0"
  } else {
    # If it's not a JSON string, return the original string
    return(response_string)
  }
}


solidity_map <- c("solid" = 0, "non-solid" = 1, "unclear/unknown" = 2)
categorical_map <- c("color" = 2, "material" = 1, "shape" = 0, "none of these" = 3)
syntax_map <- c("count noun" = 0, "mass noun" = 1, "unclear/unknown" = 2)  # Assumin

# Define a function to map categories to numeric levels
map_categories <- function(category, block) {
  if (block == "solidity") {
    return(solidity_map[category])
  } else if (block == "category_organization") {
    return(categorical_map[category])
  } else if (block == "count_mass") {
    return(syntax_map[category])
  } else {
    return(NA)  # Handle cases where block is not recognized
  }
}



find_shared_words1 <- function(df1, df2, prop1, prop2) {
  inner_join(
    df1 %>% filter(proportion <= ifelse(prop1 == "low", 0.5, Inf)),
    df2 %>% filter(proportion <= ifelse(prop2 == "low", 0.5, Inf)),
    by = "theword"
  ) %>% 
    select(theword) %>%
    unique()
}

find_shared_words <- function(df1, df2, name1, name2, prop1, prop2) {
  # Filter based on proportion condition (<= 0.5 for "low", > 0.5 for "high")
  filtered_df1 <- df1 %>% filter(proportion <= ifelse(prop1 == "low", 0.5, Inf))
  filtered_df2 <- df2 %>% filter(proportion <= ifelse(prop2 == "low", 0.5, Inf))
  
  # Perform inner join to get shared words
  shared_words <- inner_join(filtered_df1, filtered_df2, by = "theword") %>%
    select(theword) %>%
    unique()
  
  # Add metadata
  shared_words %>%
    mutate(
      source1 = name1,
      source2 = name2,
      condition1 = prop1,
      condition2 = prop2
    )
}

