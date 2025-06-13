# Government Outcomes Tracker API


Data Model

`Government`:
  Think of this as the core tenant. This is currently unused, but is useful for future development where we want to track
  provincial governments in addition to the federal government.


## Using AI


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
