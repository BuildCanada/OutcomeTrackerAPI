# Government Outcomes Tracker API


## Data Model

`Government`:
  Think of this as the core tenant. All records are currently linked to the federal government,
  but is useful for future development where we want to track
  provincial governments in addition to the federal government.

`Department`:
  Departments are the units within a government. They are associated with a government.

`Minister`:
  Ministers are the individuals who are responsible for a department. They are associated with a department.
  Each department may have multiple ministers. They have a start and end date. There may also be multiple ministers
  associated with a department at the same time if there is both a minister and a secretary of state.

`Promise`:
  Promises are the commitments that the government has made. They are associated with a government.
  These were originally extracted using an LLM, but are currently static. We need to rebuild the ability
  to extract them from source documents. They are associated with a department.

`Feeds`:
  Feeds are sources of information that we scrape to understand what the government is doing.
  They are associated with a government.When we scrape them we generate `Entry` records
  with the raw data. Currently we support RSS feeds, but we would like to also support
  newsletters (using active mailbox), and scraping unstructured webpages.

`Entry`:
  Entries contain the raw data scraped from feeds. They are associated with a feed and a government.
  Some Entries (like those scraped from the Canada Gazette RSS feeds) are indexes of other Entries,
  those are flagged as index_entries and are not used for matching, but are then used to find other Entries
  which are linked using the parent_entry_id column.

`Activity`:
  Activities are the actions that the government is taking. They are associated with an Entry.
  These are extracted using an LLM from the Entry's raw data. Each entry might have multiple activities.

`Evidence`:
  Evidence links an Activity to a Promise. They are linked using an LLM. 



### 🛠 Setup

```bash
# Install dependencies
bundle install

# Setup PostgreSQL (Ubuntu example)
sudo service postgresql start

# Setup database
rails db:create
rails db:migrate
rails db:seed

# Run the server
rails s
```
