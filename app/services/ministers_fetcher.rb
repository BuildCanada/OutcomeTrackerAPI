require "nokogiri"

class MinistersFetcher
  MINISTRIES_URL = "https://www.ourcommons.ca/members/en/ministries/xml"
  PERSON_HTML_URL = "https://www.ourcommons.ca/members/en/%{person_id}"
  PERSON_XML_URL = "https://www.ourcommons.ca/members/en/%{person_id}/xml"

  def self.fetch_ministries
    response = http_get(MINISTRIES_URL, read_timeout: 60)
    parse_ministries_xml(response.body.to_s)
  end

  def self.fetch_contact(person_id)
    profile = fetch_profile_xml(person_id)
    contact = fetch_contact_html(person_id)
    profile.merge(contact)
  end

  class << self
    private

    def http_get(url, read_timeout: 30)
      response = HTTP
        .timeout(connect: 10, read: read_timeout)
        .headers("User-Agent" => "BuildCanada/OutcomeTrackerAPI")
        .get(url)

      unless response.status.success?
        raise "HTTP Error: #{response.status} - #{response.status.reason} for #{url}"
      end

      response
    end

    def parse_ministries_xml(xml_body)
      doc = Nokogiri::XML(xml_body)
      doc.remove_namespaces!

      doc.xpath("//Minister").map do |node|
        {
          person_id: node.at_xpath("PersonId")&.text&.to_i,
          order_of_precedence: node.at_xpath("OrderOfPrecedence")&.text&.to_i,
          honorific: node.at_xpath("PersonShortHonorific")&.text,
          first_name: node.at_xpath("PersonOfficialFirstName")&.text,
          last_name: node.at_xpath("PersonOfficialLastName")&.text,
          title: node.at_xpath("Title")&.text,
          from_date: node.at_xpath("FromDateTime")&.text,
          to_date: node.at_xpath("ToDateTime")&.text,
        }
      end
    end

    def fetch_profile_xml(person_id)
      url = PERSON_XML_URL % { person_id: person_id }
      response = http_get(url)
      doc = Nokogiri::XML(response.body.to_s)
      doc.remove_namespaces!

      role = doc.at_xpath("//MemberOfParliamentRole")
      return {} unless role

      {
        constituency: role.at_xpath("ConstituencyName")&.text,
        province: role.at_xpath("ConstituencyProvinceTerritoryName")&.text,
        party: role.at_xpath("CaucusShortName")&.text,
      }
    rescue => e
      Rails.logger.warn("Failed to fetch profile XML for person #{person_id}: #{e.message}")
      {}
    end

    def fetch_contact_html(person_id)
      url = PERSON_HTML_URL % { person_id: person_id }
      response = http_get(url)
      parse_contact_page(response.body.to_s, person_id)
    rescue => e
      Rails.logger.warn("Failed to fetch contact HTML for person #{person_id}: #{e.message}")
      {}
    end

    def parse_contact_page(html, person_id)
      doc = Nokogiri::HTML(html)
      contact = { url: PERSON_HTML_URL % { person_id: person_id } }

      # Email
      email_links = doc.css('a[href^="mailto:"]')
      emails = email_links.map { |el| el["href"].sub("mailto:", "") }.uniq
      contact[:email] = emails.first if emails.any?

      # Website — look for personal website link in the contact tab
      contact_tab = doc.at_css("#contact") || doc
      contact_tab.css("a").each do |el|
        href = el["href"].to_s
        if href.start_with?("http") && !href.include?("ourcommons.ca") && !href.include?("parl.gc.ca")
          contact[:website] = href
          break
        end
      end

      # Avatar
      img = doc.at_css(".profile-picture img, img.ce-mip-mp-picture")
      if img && img["src"]
        src = img["src"]
        contact[:avatar_url] = src.start_with?("/") ? "https://www.ourcommons.ca#{src}" : src
      end

      # Offices — parse by finding h4 headers ("Hill Office", "Constituency Office")
      offices = []
      doc.css("h4").each do |h4|
        header_text = h4.text.strip
        next unless header_text.match?(/Hill Office|Constituency Office/i)

        # The parent div contains the office info
        container = h4.parent
        next unless container

        office = { type: header_text }

        # Address: grab <p> elements that contain address-like text
        paragraphs = container.css("p")
        if paragraphs.any?
          # First <p> usually has the address
          addr_p = paragraphs.first
          address_text = addr_p.inner_html.gsub(/<br\s*\/?>/, "\n").gsub(/<[^>]+>/, "").strip
          office[:address] = address_text unless address_text.empty?
        end

        # Phone: extract from "Telephone: XXX-XXX-XXXX" text
        container_text = container.text
        phone_match = container_text.match(/Telephone:\s*([\d\-\s]+)/)
        office[:telephone] = phone_match[1].strip if phone_match

        # Fax
        fax_match = container_text.match(/Fax:\s*([\d\-\s]+)/)
        office[:fax] = fax_match[1].strip if fax_match

        offices << office if office[:address] || office[:telephone]
      end

      # Also parse constituency sub-offices
      doc.css(".ce-mip-contact-constituency-office").each do |section|
        office = { type: "Constituency Office" }

        paragraphs = section.css("p")
        if paragraphs.any?
          # First <p> has the office name and address
          addr_text = paragraphs.first.inner_html.gsub(/<br\s*\/?>/, "\n").gsub(/<[^>]+>/, "").strip
          office[:address] = addr_text unless addr_text.empty?
        end

        section_text = section.text
        phone_match = section_text.match(/Telephone:\s*([\d\-\s]+)/)
        office[:telephone] = phone_match[1].strip if phone_match

        fax_match = section_text.match(/Fax:\s*([\d\-\s]+)/)
        office[:fax] = fax_match[1].strip if fax_match

        # Only add if not a duplicate of the h4-based constituency office
        if (office[:address] || office[:telephone]) && offices.none? { |o| o[:telephone] == office[:telephone] }
          offices << office
        end
      end

      # Fallback: extract phone numbers from page text
      if offices.empty?
        phones = doc.text.scan(/\d{3}[-.\s]?\d{3}[-.\s]?\d{4}/).uniq
        contact[:phone_numbers] = phones if phones.any?
      end

      contact[:offices] = offices if offices.any?
      contact
    end
  end
end
