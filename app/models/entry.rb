class Entry < ApplicationRecord
  belongs_to :feed
  belongs_to :government

  after_commit :fetch_data!, on: [ :create ]

  validates :url, presence: true, uniqueness: true


  def fetch_data!(in_background: true)
    if in_background
      return EntryDataFetcherJob.perform_later(self)
    end
    # Fetch data from external source

    r = HTTP.get(url)
    html = r.body.to_s

    ic = Iconv.new("UTF-8//IGNORE", "UTF-8")
    self.raw_html = ic.iconv(html + " ")[0..-2]

    # Call defuddle to parse the HTML

    temp_file = Tempfile.new("entry_html", encoding: "utf-8")
    temp_file.write(raw_html)

    md_json = `defuddle parse #{temp_file.path} -m -j`
    md_html = `defuddle parse #{temp_file.path} -j`

    # replace anything before the first { deffudle returns errors and is dumb here.
    md_json = "{" + md_json.split("{", 2).last
    md_html = "{" + md_html.split("{", 2).last

    self.parsed_markdown = JSON.parse(md_json)["content"]
    self.parsed_html = JSON.parse(md_html)["content"]

    temp_file.close
    self.save
    create_subentries!
  rescue => e
    puts parsed_markdown
    raise e
  end

  def create_subentries!
    # Some data sources (like the canada gazette have an RSS feed that is just an index of all the entries, so we need to fetch the actual entries from the feed)
  end
end
