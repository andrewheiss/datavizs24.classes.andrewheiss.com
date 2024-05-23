library(targets)
library(tarchetypes)
suppressPackageStartupMessages(library(tidyverse))

class_number <- "PMAP 8551/4551"
base_url <- "https://datavizs24.classes.andrewheiss.com/"
page_suffix <- ".html"

options(
  tidyverse.quiet = TRUE,
  dplyr.summarise.inform = FALSE
)

tar_option_set(
  packages = c("tibble"),
  format = "rds",
  workspace_on_error = TRUE
)

build_graph <- function() {
  out_file <- here_rel("misc/mermaid-graph.md")
  
  output <- tar_mermaid(
    targets_only = TRUE, outdated = FALSE,
    legend = FALSE, color = FALSE,
  )
  
  cat(output, file = out_file, sep = "\n")

  return(out_file)
}

# This needs to run once on the computer/container initially to set up Python
# source("_config_python.R")

# here::here() returns an absolute path, which then gets stored in tar_meta and
# becomes computer-specific (i.e. /Users/andrew/Research/blah/thing.qmd).
# There's no way to get a relative path directly out of here::here(), but
# fs::path_rel() works fine with it (see
# https://github.com/r-lib/here/issues/36#issuecomment-530894167)
here_rel <- function(...) {fs::path_rel(here::here(...))}

# Load functions for the pipeline
source("R/tar_slides.R")
source("R/tar_data.R")
source("R/tar_projects.R")
source("R/tar_calendar.R")


# THE MAIN PIPELINE ----
list(
  ## Slides ----
  # Render all the slides and make PDFs
  build_slides,
  
  # The main index.qmd page loads all_slides as a target to link it as a dependency
  tar_combine(
    all_slides,
    tar_select_targets(build_slides, starts_with("slide_pdf_"))
  ),

  
  ## Project folders ----
  # Create/copy data and zip up all the project folders
  make_data_and_zip_projects,
  
  # The main index.qmd page loads all_zipped_projects as a target to link it as a dependency
  tar_combine(
    all_zipped_projects,
    tar_select_targets(make_data_and_zip_projects, starts_with("zip_"))
  ),
  
  ## Class schedule calendar ----
  tar_target(schedule_file, here_rel("data", "schedule.csv"), format = "file"),
  tar_target(schedule_page_data, build_schedule_for_page(schedule_file)),
  tar_target(
    schedule_ical_data,
    build_ical(
      schedule_file, base_url,
      page_suffix, class_number
    )
  ),
  tar_target(
    schedule_ical_file,
    save_ical(
      schedule_ical_data,
      here_rel("files", "schedule.ics")
    ),
    format = "file"
  ),
  
  
  ## Knit the README ----
  tar_target(workflow_graph, build_graph(), format = "file"),
  tar_quarto(readme, here_rel("README.qmd")),
  

  ## Build site ----
  tar_quarto(site, path = ".", quiet = FALSE),

  
  ## Upload site ----
  tar_target(deploy_script, here_rel("deploy.sh"), format = "file"),
  tar_target(deploy_site, {
    # Force dependencies
    site
    # Run the deploy script
    if (Sys.getenv("UPLOAD_WEBSITES") == "TRUE") {
      processx::run(paste0("./", deploy_script))
    }
  })
)
