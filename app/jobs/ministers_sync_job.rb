class MinistersSyncJob < ApplicationJob
  queue_as :default

  def perform
    government = Government.find_by!(slug: "federal")
    departments = government.departments

    # Step 1: Fetch ministries XML
    ministers_data = MinistersFetcher.fetch_ministries
    Rails.logger.info("MinistersSyncJob: Fetched #{ministers_data.size} ministers from ourcommons.ca")

    # Step 2: Scrape contact info for each minister
    ministers_data.each do |minister|
      contact = MinistersFetcher.fetch_contact(minister[:person_id])
      minister[:contact] = contact
      Rails.logger.info("MinistersSyncJob: Scraped contact for #{minister[:first_name]} #{minister[:last_name]}")
    end

    # Step 3: Use LLM to map ministers to departments
    department_info = departments.pluck(:slug, :official_name).map do |slug, name|
      { slug: slug, official_name: name }
    end

    mapper = MinisterDepartmentMapper.create!
    mapper.extract!(mapper.prompt(ministers_data, department_info))

    mappings_by_person_id = mapper.mappings.index_by { |m| m["person_id"] }
    Rails.logger.info("MinistersSyncJob: LLM mapped #{mappings_by_person_id.size} ministers to departments")

    # Step 4: Upsert ministers
    # Remove legacy seed records that lack a person_id
    legacy_count = government.ministers.where(person_id: nil).delete_all
    Rails.logger.info("MinistersSyncJob: Removed #{legacy_count} legacy minister records") if legacy_count > 0

    # End-date any synced ministers no longer in the current ministry
    active_person_ids = ministers_data.map { |m| m[:person_id] }
    government.ministers.where(ended_at: nil).where.not(person_id: active_person_ids).find_each do |minister|
      minister.update!(ended_at: Time.current)
      Rails.logger.info("MinistersSyncJob: End-dated #{minister.full_name}")
    end

    # Create or update each minister
    ministers_data.each do |data|
      mapping = mappings_by_person_id[data[:person_id]] || {}
      department_slugs = mapping["department_slugs"] || []
      role = mapping["role"] || derive_role(data[:title])
      contact = data[:contact] || {}

      department_slugs.each do |slug|
        department = departments.find_by(slug: slug)
        unless department
          Rails.logger.warn("MinistersSyncJob: Unknown department slug '#{slug}' for #{data[:first_name]} #{data[:last_name]}")
          next
        end

        minister = Minister.find_or_initialize_by(
          person_id: data[:person_id],
          department: department,
          government: government
        )

        minister.assign_attributes(
          order_of_precedence: data[:order_of_precedence],
          person_short_honorific: data[:honorific],
          first_name: data[:first_name],
          last_name: data[:last_name],
          title: data[:title],
          role: role,
          started_at: data[:from_date],
          ended_at: data[:to_date].presence,
          avatar_url: contact[:avatar_url],
          email: contact[:email],
          phone: contact.dig(:offices, 0, :telephone),
          constituency: contact[:constituency],
          province: contact[:province],
          party: contact[:party],
          website: contact[:website],
          contact_data: contact
        )

        minister.save!
        attach_photo(minister, contact[:avatar_url])
      end
    end

    Rails.logger.info("MinistersSyncJob: Sync complete")
  end

  private

  def attach_photo(minister, avatar_url)
    return if avatar_url.blank?
    return if minister.photo.attached? && minister.avatar_url_previously_was == minister.avatar_url

    response = HTTP
      .timeout(connect: 10, read: 30)
      .headers("User-Agent" => "BuildCanada/OutcomeTrackerAPI")
      .get(avatar_url)

    return unless response.status.success?

    filename = "#{minister.last_name.parameterize}-#{minister.first_name.parameterize}.jpg"
    minister.photo.attach(
      io: StringIO.new(response.body.to_s),
      filename: filename,
      content_type: response.content_type.mime_type
    )
    Rails.logger.info("MinistersSyncJob: Attached photo for #{minister.full_name}")
  rescue => e
    Rails.logger.warn("MinistersSyncJob: Failed to attach photo for #{minister.full_name}: #{e.message}")
  end

  def derive_role(title)
    if title&.match?(/\bPrime Minister\b/i)
      "Prime Minister"
    elsif title&.match?(/\bSecretary of State\b/i)
      "Secretary of State"
    else
      "Minister"
    end
  end
end
