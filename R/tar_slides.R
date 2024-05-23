slides <- tibble::tibble(
  path = list.files(here_rel("slides"), pattern = "\\.Rmd", full.names = TRUE)
) |>
  mutate(
    name = tools::file_path_sans_ext(basename(path)),
    sym = syms(janitor::make_clean_names(paste0("slide_rmd_", name))),
    sym_html = syms(janitor::make_clean_names(paste0("slide_html_", name))),
    sym_pdf = syms(janitor::make_clean_names(paste0("slide_pdf_", name)))
  )

build_slides <- list(
  tar_eval(
    tar_files_input(target_name, rmd_file),
    values = list(
      target_name = slides$sym,
      rmd_file = slides$path
    )
  ),
  
  tar_eval(
    tar_target(target_name, render_xaringan(rmd_file), format = "file"),
    values = list(
      target_name = slides$sym_html,
      rmd_file = slides$sym
    )
  ),
  
  tar_eval(
    tar_target(target_name, xaringan_to_pdf(html_file), format = "file"),
    values = list(
      target_name = slides$sym_pdf,
      html_file = slides$sym_html
    )
  )
)

# We need to return the path to the rendered HTML file. In this case,
# rmarkdown::render() *does* return a path, but it returns an absolute path,
# which makes the targets pipeline less portable. So we return our own path to
# the HTML file instead.
render_xaringan <- function(slide_path) {
  # crayon does weird things to R Markdown and xaringan output, so we need to
  # disable it here. This is the same thing that tarchetypes::tar_render() does
  # behind the scenes too.
  withr::local_options(list(crayon.enabled = NULL))
  
  rmarkdown::render(
    slide_path, 
    envir = parent.frame(),
    quiet = TRUE
  )
  
  return(paste0(tools::file_path_sans_ext(slide_path), ".html"))
}


# Use pagedown to convert xaringan HTML slides to PDF. Return a relative path to
# the PDF to keep targets happy.
#
# Slides for sessions 12 are huge, so use chromote to convert them instead
xaringan_to_pdf <- function(slide_path) {
  path_sans_ext <- tools::file_path_sans_ext(slide_path)

  if (path_sans_ext == "slides/12-slides") {
    return(here::here("slides/12-slides.pdf"))
  }
  
  renderthis::to_pdf(
    slide_path,
    to = paste0(path_sans_ext, ".pdf")
  )

  return(paste0(tools::file_path_sans_ext(slide_path), ".pdf"))
}
