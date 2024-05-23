# Make a tibble of metadata about all the current subdirectories in "projects/",
# with four columns:
#
# 1. `name`: The subdirectory name (e.g. "causal-model")
# 2. `path`: The relative path to the subdirectory from the project root
#    (e.g. "projects/causal-model")
# 3. `sym`: A symbol / R expression version of the subdirectory name that will
#    be used as the name of the target (e.g. "proj_causal_model")
# 4. `zip_sym`: A symbol version of the name of the target for the results of
#    zipping the folder (e.g. "zip_proj_causal_model")

projects <- tibble::tibble(
  name = list.dirs(here_rel("projects"), full.names = FALSE, recursive = FALSE)
) |>
  mutate(
    path = as.character(here_rel("projects", name)),
    sym = syms(janitor::make_clean_names(paste0("proj_", name))),
    zip_sym = syms(janitor::make_clean_names(paste0("zip_proj_", name)))
  )

make_data_and_zip_projects <- list(
  # Run all the data building and copying targets
  save_data,
  
  # Link all these data building and copying targets into individual dependencies
  tar_combine(copy_data, tar_select_targets(save_data, starts_with("copy_"))),
  tar_combine(build_data, tar_select_targets(save_data, starts_with("data_"))),
  
  # Use metaprogramming (https://books.ropensci.org/targets/static.html#metaprogramming)
  # to dynamically create static targets for each of the project folders
  tar_eval(
    tar_files_input(target_name, files),
    values = list(
      target_name = projects$sym,
      files = projects$path
    )
  ),
  
  # Use metaprogramming to dynamically create targets for .zip files for each of
  # the project folders and zip them
  tar_eval(
    tar_target(
      target_name,
      {
        # Make the copying and building targets are dependencies here
        copy_data
        build_data
        
        # Zip things up
        zip::zip(
          zipfile = paste0(project, ".zip"),
          files = project,
          mode = "cherry-pick"
        )
      },
      format = "file"
    ),
    values = list(
      target_name = projects$zip_sym,
      project = projects$sym
    )
  )
)
