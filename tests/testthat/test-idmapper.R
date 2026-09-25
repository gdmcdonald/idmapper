test_that("mark_id tags single and multiple columns correctly", {
  df <- data.frame(email = "a@example.com", unikey = "u1", staff_id = "s1")

  df1 <- mark_id(df, email, graph = "person", type = "email")
  expect_equal(attr(df1$email, "graph"), "person")
  expect_equal(attr(df1$email, "id_type"), "email")
  expect_null(attr(df1$unikey, "graph"))

  df2 <- mark_id(df, c(unikey, staff_id), graph = "person", type = "unikey")
  expect_equal(attr(df2$unikey, "graph"), "person")
  expect_equal(attr(df2$staff_id, "graph"), "person")
})

test_that("mark_id errors informatively on a missing column", {
  df <- data.frame(email = "a@example.com")
  expect_error(mark_id(df, not_a_column, graph = "person", type = "email"),
               "Columns not found")
})

test_that("full pipeline resolves shared identities across two datasets", {
  init_id_envs("person")

  # Dataset A: two people, identified by email + unikey
  hr_data <- data.frame(
    email  = c("a1@example.com", "a2@example.com"),
    unikey = c("u1", "u2"),
    stringsAsFactors = FALSE
  ) %>%
    mark_id(email, graph = "person", type = "email") %>%
    mark_id(unikey, graph = "person", type = "unikey") %>%
    add_to_identity_graph()

  # Dataset B: person 1 re-appears under the same email but a new staff_id;
  # person 3 is genuinely new.
  grant_data <- data.frame(
    email    = c("a1@example.com", "a3@example.com"),
    staff_id = c("s1", "s3"),
    stringsAsFactors = FALSE
  ) %>%
    mark_id(email, graph = "person", type = "email") %>%
    mark_id(staff_id, graph = "person", type = "staff_id") %>%
    add_to_identity_graph()

  master <- generate_master_identity_table("person", verbose = FALSE)

  # 3 distinct people: {a1,u1,s1} merged via shared email, {a2,u2}, {a3,s3}
  expect_equal(nrow(master), 3)
  expect_true(all(c("person_id", "email", "unikey", "staff_id") %in% names(master)))

  # get_master_table() should return the same table
  expect_identical(get_master_table("person"), master)

  hr_data2    <- hr_data    %>% join_master_ids()
  grant_data2 <- grant_data %>% join_master_ids()

  expect_true("person_UID" %in% names(hr_data2))
  expect_true("person_UID" %in% names(grant_data2))

  # person 1 should resolve to the SAME master ID in both datasets
  expect_equal(hr_data2$person_UID[1], grant_data2$person_UID[1])

  # person 2 (hr_data row 2) and person 3 (grant_data row 2) are different people
  expect_false(hr_data2$person_UID[2] == grant_data2$person_UID[2])

  # no NAs - every row here has at least one matching identifier
  expect_false(anyNA(hr_data2$person_UID))
  expect_false(anyNA(grant_data2$person_UID))
})

test_that("join_master_ids returns NA for unmatched rows and warns with no marked columns", {
  init_id_envs("person")

  hr_data <- data.frame(email = "a1@example.com", stringsAsFactors = FALSE) %>%
    mark_id(email, graph = "person", type = "email") %>%
    add_to_identity_graph()

  generate_master_identity_table("person", verbose = FALSE)

  unmatched <- data.frame(email = "unknown@example.com", stringsAsFactors = FALSE) %>%
    mark_id(email, graph = "person", type = "email") %>%
    join_master_ids()

  expect_true(is.na(unmatched$person_UID))

  expect_warning(
    join_master_ids(data.frame(x = 1)),
    "No columns marked"
  )
})

test_that("filter_by_existing_identities keeps only rows already in the graph", {
  init_id_envs("person")

  data.frame(email = "known@example.com", stringsAsFactors = FALSE) %>%
    mark_id(email, graph = "person", type = "email") %>%
    add_to_identity_graph()

  candidates <- data.frame(
    email = c("known@example.com", "stranger@example.com"),
    stringsAsFactors = FALSE
  ) %>%
    mark_id(email, graph = "person", type = "email")

  result <- filter_by_existing_identities(candidates, env_name = "person")

  expect_equal(nrow(result), 1)
  # as.character() strips the graph/id_type attributes mark_id() attached -
  # filter_by_existing_identities() correctly preserves them (it only
  # filters rows, it doesn't strip metadata), so compare on value only.
  expect_equal(as.character(result$email), "known@example.com")
})

test_that("get_master_table errors before generate_master_identity_table has run", {
  init_id_envs("person")
  expect_error(get_master_table("person"), "No master table found")
})
