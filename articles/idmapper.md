# Introduction to idmapper

``` r

library(idmapper)
library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
```

## The problem

Say you help run a community running club, and you want to join together
three datasets that all describe the same runners, but were extracted
from different systems that don’t share a common key:

- **`race_results`** - from the race-timing company that ran last
  month’s 10k. One row per runner, identified by whatever **email** they
  used when registering for the race.
- **`fitness_app_leaderboard`** - from a GPS running app some members
  use to track their training. One row per runner, identified by their
  **app username**, and whatever **email** they signed up to the app
  with - which is sometimes the same email they registered for the race
  with, and sometimes a different one entirely.
- **`club_roster`** - the club’s own membership system. One row per
  member, listing their **member ID**, **app username**,
  **race-registration email**, and **app-signup email** all together.

None of this data is real - it’s entirely synthetic, invented for this
example.

``` r

race_results <- tribble(
  ~runner_name,      ~race_email,                       ~finish_time_minutes,
  "Jordan Blake",    "jordan.blake@fictionalmail.com",   47.2,
  "Sam Okafor",      "sam.okafor@fictionalmail.com",     52.8,
  "Nora Fitzgerald", "nora.fitz@fictionalmail.com",      61.5,
  "Yusuf Demir",     "y.demir@fictionalmail.com",        44.9
)

fitness_app_leaderboard <- tribble(
  ~app_username, ~app_email,                        ~total_distance_km,
  "jblake_runs", "jordan.blake@fictionalmail.com",   412,
  "samo_runs",   "samokafor.trains@fastmail.com",    298, # different email to race_results!
  "yusufd",      "y.demir@fictionalmail.com",        520
)

club_roster <- tribble(
  ~member_id, ~app_username,  ~race_email,                      ~app_email,
  "M001",     "jblake_runs",  "jordan.blake@fictionalmail.com", "jordan.blake@fictionalmail.com",
  "M002",     "samo_runs",    "sam.okafor@fictionalmail.com",   "samokafor.trains@fastmail.com",
  "M003",     NA,             "nora.fitz@fictionalmail.com",    NA,
  "M004",     "yusufd",       "y.demir@fictionalmail.com",      "y.demir@fictionalmail.com"
)
```

Notice **Sam Okafor**: `race_results` has the email he registered for
the race with, but `fitness_app_leaderboard` has a different email
entirely - the one he happened to sign up to the running app with years
earlier. Those two rows share *no* identifier directly - the only place
that connects them is `club_roster`, which happens to list both of his
emails side by side.

A plain join on email will simply miss him:

``` r

naive_join <- race_results %>%
  left_join(fitness_app_leaderboard, by = c("race_email" = "app_email"))

naive_join %>% select(runner_name, race_email, total_distance_km)
#> # A tibble: 4 × 3
#>   runner_name     race_email                     total_distance_km
#>   <chr>           <chr>                                      <dbl>
#> 1 Jordan Blake    jordan.blake@fictionalmail.com               412
#> 2 Sam Okafor      sam.okafor@fictionalmail.com                  NA
#> 3 Nora Fitzgerald nora.fitz@fictionalmail.com                   NA
#> 4 Yusuf Demir     y.demir@fictionalmail.com                    520
```

Sam’s `total_distance_km` comes back `NA` - not because he doesn’t use
the app (he’s logged 298 km on it), but because the join has no way to
know `sam.okafor@fictionalmail.com` and `samokafor.trains@fastmail.com`
are the same person. You could patch this one case by hand, but that
doesn’t scale, and you won’t always have a human around to notice the
mismatch.

## Solving it with idmapper

The idea: instead of joining datasets directly to each other, treat
every identifier (an email, a username, a member ID) as a node, and link
two nodes whenever they co-occur on the same row of the same dataset.
Two datasets that never share an identifier directly can still end up in
the same connected component if a third dataset bridges them - exactly
Sam’s case.

### 1. Initialise an identity graph

``` r

init_id_envs("person")
```

### 2. Mark identifier columns, and add each dataset to the graph

[`mark_id()`](https://gdmcdonald.github.io/idmapper/reference/mark_id.md)
tags a column with the entity type (`"person"`) and the kind of
identifier it holds.
[`add_to_identity_graph()`](https://gdmcdonald.github.io/idmapper/reference/add_to_identity_graph.md)
reads those tags and updates the graph. A dataset can mark - and link -
more than one identifier type at once, which is exactly what makes
`club_roster` useful here: it contributes both of Sam’s emails *and* his
app username and member ID, all linked to each other because they’re on
the same row.

``` r

race_results <- race_results %>%
  mark_id(race_email, graph = "person", type = "email") %>%
  add_to_identity_graph()

fitness_app_leaderboard <- fitness_app_leaderboard %>%
  mark_id(app_email, graph = "person", type = "email") %>%
  mark_id(app_username, graph = "person", type = "username") %>%
  add_to_identity_graph()

club_roster <- club_roster %>%
  mark_id(race_email, graph = "person", type = "email") %>%
  mark_id(app_email, graph = "person", type = "email") %>%
  mark_id(member_id, graph = "person", type = "member_id") %>%
  mark_id(app_username, graph = "person", type = "username") %>%
  add_to_identity_graph()
```

### 3. Collapse the graph into master identities

``` r

master_runners <- generate_master_identity_table("person")
#> Processing person graph...
#> Extracting vertex data...
#> Computing components...
#> ID types found: email, username, member_id 
#> Generated master table with 4 entities
#> Preview:
#> # A tibble: 4 × 4
#>   person_id email     username  member_id
#>   <chr>     <list>    <list>    <list>   
#> 1 PERSON-1  <chr [1]> <chr [1]> <chr [1]>
#> 2 PERSON-2  <chr [2]> <chr [1]> <chr [1]>
#> 3 PERSON-3  <chr [1]> <chr [0]> <chr [1]>
#> 4 PERSON-4  <chr [1]> <chr [1]> <chr [1]>
#> Stored master table for 'person'
master_runners
#> # A tibble: 4 × 4
#>   person_id email     username  member_id
#>   <chr>     <list>    <list>    <list>   
#> 1 PERSON-1  <chr [1]> <chr [1]> <chr [1]>
#> 2 PERSON-2  <chr [2]> <chr [1]> <chr [1]>
#> 3 PERSON-3  <chr [1]> <chr [0]> <chr [1]>
#> 4 PERSON-4  <chr [1]> <chr [1]> <chr [1]>
```

Four runners in, four master identities out - as expected, since every
person here is a genuine distinct individual. (If two *different* people
had accidentally shared an identifier - a mistyped email reused by two
membership records, say - this is the step where you’d see them wrongly
merged into one row, which is why it’s worth eyeballing this table
rather than trusting it blindly on a new data source.)

### 4. Attach master IDs back onto each dataset, and join on those instead

``` r

race_results2 <- race_results %>% join_master_ids()
leaderboard2  <- fitness_app_leaderboard %>% join_master_ids()

race_results2 %>% select(runner_name, person_UID)
#> # A tibble: 4 × 2
#>   runner_name     person_UID
#>   <chr>           <chr>     
#> 1 Jordan Blake    PERSON-1  
#> 2 Sam Okafor      PERSON-2  
#> 3 Nora Fitzgerald PERSON-3  
#> 4 Yusuf Demir     PERSON-4
leaderboard2 %>% select(app_username, person_UID)
#> # A tibble: 3 × 2
#>   app_username person_UID
#>   <chr>        <chr>     
#> 1 jblake_runs  PERSON-1  
#> 2 samo_runs    PERSON-2  
#> 3 yusufd       PERSON-4
```

Now join on `person_UID` instead of on email:

``` r

combined <- race_results2 %>%
  left_join(
    leaderboard2 %>% select(person_UID, total_distance_km),
    by = "person_UID"
  )

combined %>% select(runner_name, finish_time_minutes, total_distance_km)
#> # A tibble: 4 × 3
#>   runner_name     finish_time_minutes total_distance_km
#>   <chr>                         <dbl>             <dbl>
#> 1 Jordan Blake                   47.2               412
#> 2 Sam Okafor                     52.8               298
#> 3 Nora Fitzgerald                61.5                NA
#> 4 Yusuf Demir                    44.9               520
```

Sam Okafor’s `total_distance_km` now correctly shows `298` - resolved
via the club roster bridge, with no special-casing required. Nora
Fitzgerald correctly shows `NA`: she’s a genuine race finisher who’s
never used the training app, not a matching failure - the identity graph
didn’t invent a leaderboard record for her, it just didn’t find one.

## Restricting a new dataset to known people

Suppose a fourth dataset arrives - say, RSVPs for a club social run -
and you only want to keep rows for people already known to the identity
graph (as opposed to, say, guests who are tagging along but aren’t club
members).
[`filter_by_existing_identities()`](https://gdmcdonald.github.io/idmapper/reference/filter_by_existing_identities.md)
does this without adding any new identifiers or edges to the graph:

``` r

social_run_rsvps <- tribble(
  ~attendee_name, ~attendee_email,
  "Jordan Blake", "jordan.blake@fictionalmail.com",
  "Sam Okafor",   "samokafor.trains@fastmail.com", # his app email - still resolves, it's in club_roster
  "Talia Reyes",  "talia.r@example.com"            # a friend tagging along, not a club member
)

social_run_rsvps %>%
  mark_id(attendee_email, graph = "person", type = "email") %>%
  filter_by_existing_identities(env_name = "person")
#> # A tibble: 2 × 2
#>   attendee_name attendee_email                
#>   <chr>         <chr>                         
#> 1 Jordan Blake  jordan.blake@fictionalmail.com
#> 2 Sam Okafor    samokafor.trains@fastmail.com
```

Talia Reyes is dropped: her email never appeared anywhere in the graph.
Sam Okafor is kept even though the RSVP list has his *app* email rather
than the one he registered the race with - because `club_roster` already
linked that app email to the rest of his identity.

## Summary

- Mark identifier columns with \[mark_id()\], add each dataset to the
  graph with \[add_to_identity_graph()\].
- \[generate_master_identity_table()\] once, after every dataset has
  been added.
- \[join_master_ids()\] to attach a resolved ID to any dataset, then
  join datasets to each other on that ID instead of on a raw identifier.
- \[filter_by_existing_identities()\] to restrict a new dataset to only
  people/entities already known to the graph.

The payoff over a plain
[`left_join()`](https://dplyr.tidyverse.org/reference/mutate-joins.html)
is specifically in cases like Sam’s: two records that share no
identifier directly, but are transitively linked through a third
dataset. The more data sources you have, the more of these bridges tend
to exist - and the more a naive pairwise join quietly misses.
