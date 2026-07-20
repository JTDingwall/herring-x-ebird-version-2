read_model_registry <- function(path = "config/model_registry.yml") {
  x <- yaml::read_yaml(path)$models
  dt <- data.table::rbindlist(lapply(x, data.table::as.data.table), fill = TRUE)
  required <- c("id", "tier", "question", "response", "design", "family", "engine", "status")
  assert_columns(dt, required, "model registry")
  assert_unique_key(dt, "id", "model registry")
  dt
}
