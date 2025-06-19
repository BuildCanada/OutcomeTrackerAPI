module Defuddle
  def self.defuddle(html)
    temp_file = Tempfile.new("entry_html", encoding: "utf-8")
    temp_file.write(html)

    md_json, err, status = Open3.capture3("defuddle", "parse", temp_file.path, "-m", "-j")
    md_html, err, status = Open3.capture3("defuddle", "parse", temp_file.path, "-j")

    # replace anything before the first { deffudle returns errors and is dumb here.
    md_json = "{" + md_json.split("{", 2).last
    html_json = "{" + md_html.split("{", 2).last

    return JSON.parse(md_json)["content"], JSON.parse(html_json)["content"]
  ensure
    temp_file.close
    temp_file.unlink
  end

  def self.prepare_html(html)
    ic = Iconv.new("UTF-8//IGNORE", "UTF-8")

    ic.iconv(html + " ")[0..-2]
  end
end
